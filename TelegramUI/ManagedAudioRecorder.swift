import Foundation
import SwiftSignalKit
import TelegramUIPrivateModule
import CoreMedia
import AVFoundation
import TelegramCore

private let kOutputBus: UInt32 = 0
private let kInputBus: UInt32 = 1

private func audioRecorderNativeStreamDescription() -> AudioStreamBasicDescription {
    var canonicalBasicStreamDescription = AudioStreamBasicDescription()
    canonicalBasicStreamDescription.mSampleRate = 16000.0
    canonicalBasicStreamDescription.mFormatID = kAudioFormatLinearPCM
    canonicalBasicStreamDescription.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked
    canonicalBasicStreamDescription.mFramesPerPacket = 1
    canonicalBasicStreamDescription.mChannelsPerFrame = 1
    canonicalBasicStreamDescription.mBitsPerChannel = 16
    canonicalBasicStreamDescription.mBytesPerPacket = 2
    canonicalBasicStreamDescription.mBytesPerFrame = 2
    return canonicalBasicStreamDescription
}

private var nextRecorderContextId: Int32 = 0
private func getNextRecorderContextId() -> Int32 {
    return OSAtomicIncrement32(&nextRecorderContextId)
}

private final class RecorderContextHolder {
    weak var context: ManagedAudioRecorderContext?
    
    init(context: ManagedAudioRecorderContext?) {
        self.context = context
    }
}

private final class AudioUnitHolder {
    let queue: Queue
    let audioUnit: Atomic<AudioUnit?>
    
    init(queue: Queue, audioUnit: Atomic<AudioUnit?>) {
        self.queue = queue
        self.audioUnit = audioUnit
    }
}

private var audioRecorderContexts: [Int32: RecorderContextHolder] = [:]
private var audioUnitHolders = Atomic<[Int32: AudioUnitHolder]>(value: [:])

private func addAudioRecorderContext(_ id: Int32, _ context: ManagedAudioRecorderContext) {
    audioRecorderContexts[id] = RecorderContextHolder(context: context)
}

private func removeAudioRecorderContext(_ id: Int32) {
    audioRecorderContexts.removeValue(forKey: id)
}

private func addAudioUnitHolder(_ id: Int32, _ queue: Queue, _ audioUnit: Atomic<AudioUnit?>) {
    audioUnitHolders.modify { dict in
        var dict = dict
        dict[id] = AudioUnitHolder(queue: queue, audioUnit: audioUnit)
        return dict
    }
}

private func removeAudioUnitHolder(_ id: Int32) {
    audioUnitHolders.modify { dict in
        var dict = dict
        dict.removeValue(forKey: id)
        return dict
    }
}

private func withAudioRecorderContext(_ id: Int32, _ f: (ManagedAudioRecorderContext?) -> Void) {
    if let holder = audioRecorderContexts[id], let context = holder.context {
        f(context)
    } else {
        f(nil)
    }
}

private func withAudioUnitHolder(_ id: Int32, _ f: (Atomic<AudioUnit?>, Queue) -> Void) {
    let audioUnitAndQueue = audioUnitHolders.with { dict -> (Atomic<AudioUnit?>, Queue)? in
        if let record = dict[id] {
            return (record.audioUnit, record.queue)
        } else {
            return nil
        }
    }
    if let (audioUnit, queue) = audioUnitAndQueue {
        f(audioUnit, queue)
    }
}

private func rendererInputProc(refCon: UnsafeMutableRawPointer, ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>, inTimeStamp: UnsafePointer<AudioTimeStamp>, inBusNumber: UInt32, inNumberFrames: UInt32, ioData: UnsafeMutablePointer<AudioBufferList>?) -> OSStatus {
    let id = Int32(unsafeBitCast(refCon, to: intptr_t.self))
    
    withAudioUnitHolder(id, { (holder, queue) in
        var buffer = AudioBuffer()
        buffer.mNumberChannels = 1;
        buffer.mDataByteSize = inNumberFrames * 2;
        buffer.mData = malloc(Int(inNumberFrames) * 2)
        
        var bufferList = AudioBufferList(mNumberBuffers: 1, mBuffers: buffer)
        
        var status = noErr
        holder.with { audioUnit in
            if let audioUnit = audioUnit {
                status = AudioUnitRender(audioUnit, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, &bufferList)
            } else {
                status = kAudioUnitErr_FailedInitialization
            }
        }
        
        if status == noErr {
            queue.async {
                withAudioRecorderContext(id, { context in
                    if let context = context {
                        context.processAndDisposeAudioBuffer(buffer)
                    } else {
                        free(buffer.mData)
                    }
                })
            }
        } else {
            free(buffer.mData)
            Logger.shared.log("ManagedAudioRecorder", "AudioUnitRender returned \(status)")
        }
    })
    
    /*
    if (status == noErr)
    {
        [[TGOpusAudioRecorder processingQueue] dispatchOnQueue:^
            {
            TGOpusAudioRecorder *recorder = globalRecorder;
            if (recorder != nil && recorder.recorderId == (int)(intptr_t)inRefCon && recorder->_recording) {
            
            if (recorder->_waitForTone) {
            if (CACurrentMediaTime() - recorder->_waitForToneStart > 0.3) {
            [recorder _processBuffer:&buffer];
            }
            } else {
            [recorder _processBuffer:&buffer];
            }
            }
            
            free(buffer.mData);
        }];
    }
    
    sharedQueue.async {
        withAudioRecorderContext(Int32(unsafeBitCast(refCon, to: intptr_t.self)), { context in
            if !context.isPaused {
                
            }
        })
    }*/
    return noErr
}

struct RecordedAudioData {
    let compressedData: Data
    let duration: Double
    let waveform: Data?
}

final class ManagedAudioRecorderContext {
    private let id: Int32
    private let micLevel: ValuePromise<Float>
    private let recordingState: ValuePromise<AudioRecordingState>
    
    private var paused = true
    
    private let queue: Queue
    private let mediaManager: MediaManager
    private let oggWriter: TGOggOpusWriter
    private let dataItem: TGDataItem
    private var audioBuffer = Data()
    
    private let audioUnit = Atomic<AudioUnit?>(value: nil)
    
    private var waveformSamples = Data()
    private var waveformPeak: Int16 = 0
    private var waveformPeakCount: Int = 0
    
    private var micLevelPeak: Int16 = 0
    private var micLevelPeakCount: Int = 0
    
    fileprivate var isPaused = false
    
    private var recordingStateUpdateTimestamp: Double?
    
    private var audioSessionDisposable: Disposable?
    
    init(queue: Queue, mediaManager: MediaManager, micLevel: ValuePromise<Float>, recordingState: ValuePromise<AudioRecordingState>) {
        assert(queue.isCurrent())
        
        self.id = getNextRecorderContextId()
        self.micLevel = micLevel
        self.recordingState = recordingState
        
        self.queue = queue
        self.mediaManager = mediaManager
        self.dataItem = TGDataItem()
        self.oggWriter = TGOggOpusWriter()
        
        addAudioRecorderContext(self.id, self)
        addAudioUnitHolder(self.id, queue, self.audioUnit)
        
        self.oggWriter.begin(with: self.dataItem)
    }
    
    deinit {
        assert(self.queue.isCurrent())
        
        removeAudioRecorderContext(self.id)
        removeAudioUnitHolder(self.id)
        
        self.stop()
        
        self.audioSessionDisposable?.dispose()
    }
    
    func start() {
        assert(self.queue.isCurrent())
        
        self.paused = false
        
        var desc = AudioComponentDescription()
        desc.componentType = kAudioUnitType_Output
        desc.componentSubType = kAudioUnitSubType_RemoteIO
        desc.componentFlags = 0
        desc.componentFlagsMask = 0
        desc.componentManufacturer = kAudioUnitManufacturer_Apple
        guard let inputComponent = AudioComponentFindNext(nil, &desc) else {
            return
        }
        var maybeAudioUnit: AudioUnit? = nil
        AudioComponentInstanceNew(inputComponent, &maybeAudioUnit)
        
        guard let audioUnit = maybeAudioUnit else {
            return
        }
        
        var status = noErr
        
        var one: UInt32 = 1
        guard AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &one, 4) == noErr else {
            AudioComponentInstanceDispose(audioUnit)
            return
        }
        
        var audioStreamDescription = audioRecorderNativeStreamDescription()
        guard AudioUnitSetProperty(audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &audioStreamDescription, UInt32(MemoryLayout<AudioStreamBasicDescription>.size)) == noErr else {
            AudioComponentInstanceDispose(audioUnit)
            return
        }
        
        guard AudioUnitSetProperty(audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &audioStreamDescription, UInt32(MemoryLayout<AudioStreamBasicDescription>.size)) == noErr else {
            AudioComponentInstanceDispose(audioUnit)
            return
        }
        
        var callbackStruct = AURenderCallbackStruct()
        callbackStruct.inputProc = rendererInputProc
        callbackStruct.inputProcRefCon = unsafeBitCast(intptr_t(self.id), to: UnsafeMutableRawPointer.self)
        guard AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, 0, &callbackStruct, UInt32(MemoryLayout<AURenderCallbackStruct>.size)) == noErr else {
            AudioComponentInstanceDispose(audioUnit)
            return
        }
        
        var zero: UInt32 = 1
        guard AudioUnitSetProperty(audioUnit, kAudioUnitProperty_ShouldAllocateBuffer, kAudioUnitScope_Output, 0, &zero, 4) == noErr else {
            AudioComponentInstanceDispose(audioUnit)
            return
        }
        
        guard AudioUnitInitialize(audioUnit) == noErr else {
            AudioComponentInstanceDispose(audioUnit)
            return
        }
        
        self.audioUnit.swap(audioUnit)
        
        if self.audioSessionDisposable == nil {
            let queue = self.queue
            self.audioSessionDisposable = self.mediaManager.audioSession.push(audioSessionType: .playAndRecord, activate: { [weak self] in
                queue.async {
                    if let strongSelf = self, !strongSelf.paused {
                        strongSelf.audioSessionAcquired()
                    }
                }
            }, deactivate: { [weak self] in
                return Signal { subscriber in
                    queue.async {
                        if let strongSelf = self {
                            strongSelf.stop()
                            subscriber.putCompletion()
                        }
                    }
                    
                    return EmptyDisposable
                }
            })
        }
    }
    
    func audioSessionAcquired() {
        self.audioUnit.with { audioUnit -> Void in
            if let audioUnit = audioUnit {
                guard AudioOutputUnitStart(audioUnit) == noErr else {
                    self.stop()
                    return
                }
            }
        }
    }
    
    func stop() {
        assert(self.queue.isCurrent())
        
        self.paused = true
        
        if let audioUnit = self.audioUnit.swap(nil) {
            var status = noErr
            
            status = AudioOutputUnitStop(audioUnit)
            if status != noErr {
                Logger.shared.log("ManagedAudioRecorder", "AudioOutputUnitStop returned \(status)")
            }
            
            status = AudioUnitUninitialize(audioUnit)
            if status != noErr {
                Logger.shared.log("ManagedAudioRecorder", "AudioUnitUninitialize returned \(status)")
            }
            
            status = AudioComponentInstanceDispose(audioUnit)
            if status != noErr {
                Logger.shared.log("ManagedAudioRecorder", "AudioComponentInstanceDispose returned \(status)")
            }
        }
        
        let audioSessionDisposable = self.audioSessionDisposable
        self.audioSessionDisposable = nil
        audioSessionDisposable?.dispose()
    }
    
    func processAndDisposeAudioBuffer(_ buffer: AudioBuffer) {
        assert(self.queue.isCurrent())
        
        defer {
            free(buffer.mData)
        }
        
        let millisecondsPerPacket = 60
        let encoderPacketSizeInBytes = 16000 / 1000 * millisecondsPerPacket * 2
        
        let currentEncoderPacket = malloc(encoderPacketSizeInBytes)!
        defer {
            free(currentEncoderPacket)
        }
        
        var bufferOffset = 0
        
        while true {
            var currentEncoderPacketSize = 0
            
            while currentEncoderPacketSize < encoderPacketSizeInBytes {
                if audioBuffer.count != 0 {
                    let takenBytes = min(self.audioBuffer.count, encoderPacketSizeInBytes - currentEncoderPacketSize)
                    if takenBytes != 0 {
                        self.audioBuffer.withUnsafeBytes { (bytes: UnsafePointer<Int8>) -> Void in
                            memcpy(currentEncoderPacket.advanced(by: currentEncoderPacketSize), bytes, takenBytes)
                        }
                        self.audioBuffer.replaceSubrange(0 ..< takenBytes, with: Data())
                        currentEncoderPacketSize += takenBytes
                    }
                } else if bufferOffset < Int(buffer.mDataByteSize) {
                    let takenBytes = min(Int(buffer.mDataByteSize) - bufferOffset, encoderPacketSizeInBytes - currentEncoderPacketSize)
                    if takenBytes != 0 {
                        self.audioBuffer.withUnsafeBytes { (bytes: UnsafePointer<Int8>) -> Void in
                            memcpy(currentEncoderPacket.advanced(by: currentEncoderPacketSize), buffer.mData?.advanced(by: bufferOffset), takenBytes)
                        }
                        bufferOffset += takenBytes
                        currentEncoderPacketSize += takenBytes
                    }
                } else {
                    break
                }
            }
            
            if currentEncoderPacketSize < encoderPacketSizeInBytes {
                self.audioBuffer.append(currentEncoderPacket.assumingMemoryBound(to: UInt8.self), count: currentEncoderPacketSize)
                break
            } else {
                let previousBytesWritten = self.oggWriter.encodedBytes()
                
                self.processWaveformPreview(samples: currentEncoderPacket.assumingMemoryBound(to: Int16.self), count: currentEncoderPacketSize / 2)
                
                self.oggWriter.writeFrame(currentEncoderPacket.assumingMemoryBound(to: UInt8.self), frameByteCount: UInt(currentEncoderPacketSize))
                
                let timestamp = CACurrentMediaTime()
                if self.recordingStateUpdateTimestamp == nil || self.recordingStateUpdateTimestamp! < timestamp + 0.1 {
                    self.recordingStateUpdateTimestamp = timestamp
                    self.recordingState.set(.recording(duration: oggWriter.encodedDuration(), durationMediaTimestamp: timestamp))
                }
                
                /*NSUInteger currentBytesWritten = [_oggWriter encodedBytes];
                if (currentBytesWritten != previousBytesWritten)
                {
                    [ActionStageInstance() dispatchOnStageQueue:^
                        {
                        TGLiveUploadActor *actor = (TGLiveUploadActor *)[ActionStageInstance() executingActorWithPath:_liveUploadPath];
                        [actor updateSize:currentBytesWritten];
                        }];
                }*/
            }
        }
    }
    
    func processWaveformPreview(samples: UnsafePointer<Int16>, count: Int) {
        for i in 0 ..< count {
            var sample = samples.advanced(by: i).pointee
            if sample < 0 {
                if sample == Int16.min {
                    sample = Int16.max
                } else {
                    sample = -sample
                }
            }
            if self.waveformPeak < sample {
                self.waveformPeak = sample
            }
            self.waveformPeakCount += 1
            
            if self.waveformPeakCount >= 100 {
                self.waveformSamples.count += 2
                var waveformPeak = self.waveformPeak
                withUnsafeBytes(of: &waveformPeak, { bytes -> Void in
                    self.waveformSamples.append(bytes.baseAddress!.assumingMemoryBound(to: UInt8.self), count: 2)
                })
                self.waveformPeak = 0
                self.waveformPeakCount = 0
            }
            
            if self.micLevelPeak < sample {
                self.micLevelPeak = sample
            }
            self.micLevelPeakCount += 1
            
            if self.micLevelPeakCount >= 1200 {
                let level = Float(self.micLevelPeak) / 4000.0
                self.micLevel.set(level)
                self.micLevelPeak = 0
                self.micLevelPeakCount = 0
            }
        }
    }
    
    func takeData() -> RecordedAudioData? {
        if self.oggWriter.writeFrame(nil, frameByteCount: 0) {
            var scaledSamplesMemory = malloc(100 * 2)!
            var scaledSamples: UnsafeMutablePointer<Int16> = scaledSamplesMemory.assumingMemoryBound(to: Int16.self)
            defer {
                free(scaledSamplesMemory)
            }
            memset(scaledSamples, 0, 100 * 2);
            var waveform: Data?
            
            self.waveformSamples.withUnsafeMutableBytes { (samples: UnsafeMutablePointer<Int16>) -> Void in
                let count = self.waveformSamples.count / 2
                for i in 0 ..< count {
                    let sample = samples[i]
                    let index = i * 100 / count
                    if (scaledSamples[index] < sample) {
                        scaledSamples[index] = sample;
                    }
                }
                
                var peak: Int16 = 0
                var sumSamples: Int64 = 0
                for i in 0 ..< 100 {
                    let sample = scaledSamples[i]
                    if peak < sample {
                        peak = sample
                    }
                    sumSamples += Int64(peak)
                }
                var calculatedPeak: UInt16 = 0
                calculatedPeak = UInt16((Double(sumSamples) * 1.8 / 100.0))
                
                if calculatedPeak < 2500 {
                    calculatedPeak = 2500
                }
                
                for i in 0 ..< 100 {
                    var sample: UInt16 = UInt16(Int64(scaledSamples[i]))
                    if sample > calculatedPeak {
                        scaledSamples[i] = Int16(calculatedPeak)
                    }
                }
                
                let resultWaveform = AudioWaveform(samples: Data(bytes: scaledSamplesMemory, count: 100 * 2), peak: Int32(calculatedPeak))
                let bitstream = resultWaveform.makeBitstream()
                waveform = AudioWaveform(bitstream: bitstream, bitsPerSample: 5).makeBitstream()
            }
            
            return RecordedAudioData(compressedData: self.dataItem.data(), duration: self.oggWriter.encodedDuration(), waveform: waveform)
        } else {
            return nil
        }
    }
}

enum AudioRecordingState: Equatable {
    case paused(duration: Double)
    case recording(duration: Double, durationMediaTimestamp: Double)
    
    static func ==(lhs: AudioRecordingState, rhs: AudioRecordingState) -> Bool {
        switch lhs {
            case let .paused(duration):
                if case .paused(duration) = rhs {
                    return true
                } else {
                    return false
                }
            case let .recording(duration, durationMediaTimestamp):
                if case .recording(duration, durationMediaTimestamp) = rhs {
                    return true
                } else {
                    return false
                }
        }
    }
}

final class ManagedAudioRecorder {
    private let queue = Queue()
    private var contextRef: Unmanaged<ManagedAudioRecorderContext>?
    private let micLevelValue = ValuePromise<Float>(0.0)
    private let recordingStateValue = ValuePromise<AudioRecordingState>(.paused(duration: 0.0))
    
    var micLevel: Signal<Float, NoError> {
        return self.micLevelValue.get()
    }
    
    var recordingState: Signal<AudioRecordingState, NoError> {
        return self.recordingStateValue.get()
    }
    
    init(mediaManager: MediaManager) {
        self.queue.async {
            let context = ManagedAudioRecorderContext(queue: self.queue, mediaManager: mediaManager, micLevel: self.micLevelValue, recordingState: self.recordingStateValue)
            self.contextRef = Unmanaged.passRetained(context)
        }
    }
    
    func start() {
        self.queue.async {
            if let context = self.contextRef?.takeUnretainedValue() {
                context.start()
            }
        }
    }
    
    func stop() {
        self.queue.async {
            if let context = self.contextRef?.takeUnretainedValue() {
                context.stop()
            }
        }
    }
    
    func takenRecordedData() -> Signal<RecordedAudioData?, NoError> {
        return Signal { subscriber in
            self.queue.async {
                if let context = self.contextRef?.takeUnretainedValue() {
                    subscriber.putNext(context.takeData())
                    subscriber.putCompletion()
                } else {
                    subscriber.putNext(nil)
                    subscriber.putCompletion()
                }
            }
            return EmptyDisposable
        }
    }
}
