import Foundation
import SwiftSignalKit
import Postbox
import TelegramCore

import TelegramUIPrivateModule

enum SharedMediaPlayerPlaybackControlAction {
    case play
    case pause
    case togglePlayPause
}

enum SharedMediaPlayerControlAction {
    case next
    case previous
    case playback(SharedMediaPlayerPlaybackControlAction)
    case seek(Double)
    case setOrder(MusicPlaybackSettingsOrder)
    case setLooping(MusicPlaybackSettingsLooping)
}

enum SharedMediaPlaylistControlAction {
    case next
    case previous
}

enum SharedMediaPlaybackDataType {
    case music
    case voice
    case instantVideo
}

enum SharedMediaPlaybackDataSource: Equatable {
    case telegramFile(TelegramMediaFile)
    
    static func ==(lhs: SharedMediaPlaybackDataSource, rhs: SharedMediaPlaybackDataSource) -> Bool {
        switch lhs {
            case let .telegramFile(lhsFile):
                if case let .telegramFile(rhsFile) = rhs {
                    return lhsFile.isEqual(rhsFile)
                } else {
                    return false
                }
        }
    }
}

struct SharedMediaPlaybackData: Equatable {
    let type: SharedMediaPlaybackDataType
    let source: SharedMediaPlaybackDataSource
    
    static func ==(lhs: SharedMediaPlaybackData, rhs: SharedMediaPlaybackData) -> Bool {
        return lhs.type == rhs.type && lhs.source == rhs.source
    }
}

struct SharedMediaPlaybackAlbumArt: Equatable {
    let thumbnailResource: TelegramMediaResource
    let fullSizeResource: TelegramMediaResource
    
    static func ==(lhs: SharedMediaPlaybackAlbumArt, rhs: SharedMediaPlaybackAlbumArt) -> Bool {
        if !lhs.thumbnailResource.isEqual(to: rhs.thumbnailResource) {
            return false
        }
        
        if !lhs.fullSizeResource.isEqual(to: rhs.fullSizeResource) {
            return false
        }
        
        return true
    }
}

enum SharedMediaPlaybackDisplayData: Equatable {
    case music(title: String?, performer: String?, albumArt: SharedMediaPlaybackAlbumArt?)
    case voice(author: Peer?, peer: Peer?)
    case instantVideo(author: Peer?, peer: Peer?)
    
    static func ==(lhs: SharedMediaPlaybackDisplayData, rhs: SharedMediaPlaybackDisplayData) -> Bool {
        switch lhs {
            case let .music(lhsTitle, lhsPerformer, lhsAlbumArt):
                if case let .music(rhsTitle, rhsPerformer, rhsAlbumArt) = rhs, lhsTitle == rhsTitle, lhsPerformer == rhsPerformer, lhsAlbumArt == rhsAlbumArt {
                    return true
                } else {
                    return false
                }
            case let .voice(lhsAuthor, lhsPeer):
                if case let .voice(rhsAuthor, rhsPeer) = rhs, arePeersEqual(lhsAuthor, rhsAuthor), arePeersEqual(lhsPeer, rhsPeer) {
                    return true
                } else {
                    return false
                }
            case let .instantVideo(lhsAuthor, lhsPeer):
                if case let .instantVideo(rhsAuthor, rhsPeer) = rhs, arePeersEqual(lhsAuthor, rhsAuthor), arePeersEqual(lhsPeer, rhsPeer) {
                    return true
                } else {
                    return false
                }
        }
    }
}

protocol SharedMediaPlaylistItem {
    var stableId: AnyHashable { get }
    var id: SharedMediaPlaylistItemId { get }
    var playbackData: SharedMediaPlaybackData? { get }
    var displayData: SharedMediaPlaybackDisplayData? { get }
}

func arePlaylistItemsEqual(_ lhs: SharedMediaPlaylistItem?, _ rhs: SharedMediaPlaylistItem?) -> Bool {
    if lhs?.stableId != rhs?.stableId {
        return false
    }
    if lhs?.playbackData != rhs?.playbackData {
        return false
    }
    if lhs?.displayData != rhs?.displayData {
        return false
    }
    return true
}

final class SharedMediaPlaylistState: Equatable {
    let loading: Bool
    let playedToEnd: Bool
    let item: SharedMediaPlaylistItem?
    let order: MusicPlaybackSettingsOrder
    let looping: MusicPlaybackSettingsLooping
    
    init(loading: Bool, playedToEnd: Bool, item: SharedMediaPlaylistItem?, order: MusicPlaybackSettingsOrder, looping: MusicPlaybackSettingsLooping) {
        self.loading = loading
        self.playedToEnd = playedToEnd
        self.item = item
        self.order = order
        self.looping = looping
    }
    
    static func ==(lhs: SharedMediaPlaylistState, rhs: SharedMediaPlaylistState) -> Bool {
        if lhs.loading != rhs.loading {
            return false
        }
        if !arePlaylistItemsEqual(lhs.item, rhs.item) {
            return false
        }
        if lhs.order != rhs.order {
            return false
        }
        if lhs.looping != rhs.looping {
            return false
        }
        return true
    }
}

protocol SharedMediaPlaylistId {
    func isEqual(to: SharedMediaPlaylistId) -> Bool
}

protocol SharedMediaPlaylistItemId {
    func isEqual(to: SharedMediaPlaylistItemId) -> Bool
}

func areSharedMediaPlaylistItemIdsEqual(_ lhs: SharedMediaPlaylistItemId?, _ rhs: SharedMediaPlaylistItemId?) -> Bool {
    if let lhs = lhs, let rhs = rhs {
        return lhs.isEqual(to: rhs)
    } else if (lhs != nil) != (rhs != nil) {
        return false
    } else {
        return true
    }
}

protocol SharedMediaPlaylistLocation {
    func isEqual(to: SharedMediaPlaylistLocation) -> Bool
}

protocol SharedMediaPlaylist {
    var id: SharedMediaPlaylistId { get }
    var location: SharedMediaPlaylistLocation { get }
    var state: Signal<SharedMediaPlaylistState, NoError> { get }
    var looping: MusicPlaybackSettingsLooping { get }
        
    func control(_ action: SharedMediaPlaylistControlAction)
    func setOrder(_ order: MusicPlaybackSettingsOrder)
    func setLooping(_ looping: MusicPlaybackSettingsLooping)
    
    func onItemPlaybackStarted(_ item: SharedMediaPlaylistItem)
}

final class SharedMediaPlayerItemPlaybackState: Equatable {
    let playlistId: SharedMediaPlaylistId
    let playlistLocation: SharedMediaPlaylistLocation
    let item: SharedMediaPlaylistItem
    let status: MediaPlayerStatus
    let order: MusicPlaybackSettingsOrder
    let looping: MusicPlaybackSettingsLooping
    let playerIndex: Int32
    
    init(playlistId: SharedMediaPlaylistId, playlistLocation: SharedMediaPlaylistLocation, item: SharedMediaPlaylistItem, status: MediaPlayerStatus, order: MusicPlaybackSettingsOrder, looping: MusicPlaybackSettingsLooping, playerIndex: Int32) {
        self.playlistId = playlistId
        self.playlistLocation = playlistLocation
        self.item = item
        self.status = status
        self.order = order
        self.looping = looping
        self.playerIndex = playerIndex
    }
    
    static func ==(lhs: SharedMediaPlayerItemPlaybackState, rhs: SharedMediaPlayerItemPlaybackState) -> Bool {
        if !lhs.playlistId.isEqual(to: rhs.playlistId) {
            return false
        }
        if !arePlaylistItemsEqual(lhs.item, rhs.item) {
            return false
        }
        if lhs.status != rhs.status {
            return false
        }
        if lhs.playerIndex != rhs.playerIndex {
            return false
        }
        if lhs.order != rhs.order {
            return false
        }
        if lhs.looping != rhs.looping {
            return false
        }
        return true
    }
}

enum SharedMediaPlayerState: Equatable {
    case loading
    case item(SharedMediaPlayerItemPlaybackState)
    
    static func ==(lhs: SharedMediaPlayerState, rhs: SharedMediaPlayerState) -> Bool {
        switch lhs {
            case .loading:
                if case .loading = rhs {
                    return true
                } else {
                    return false
                }
            case let .item(item):
                if case .item(item) = rhs {
                    return true
                } else {
                    return false
                }
        }
    }
}

private enum SharedMediaPlaybackItem: Equatable {
    case audio(MediaPlayer)
    case instantVideo(OverlayInstantVideoNode)
    
    var playbackStatus: Signal<MediaPlayerStatus, NoError> {
        switch self {
            case let .audio(player):
                return player.status
            case let .instantVideo(node):
                return node.status |> map { status in
                    if let status = status {
                        return status
                    } else {
                        return MediaPlayerStatus(generationTimestamp: 0.0, duration: 0.0, timestamp: 0.0, seekId: 0, status: .paused)
                    }
                }
        }
    }
    
    static func ==(lhs: SharedMediaPlaybackItem, rhs: SharedMediaPlaybackItem) -> Bool {
        switch lhs {
            case let .audio(lhsPlayer):
                if case let .audio(rhsPlayer) = rhs, lhsPlayer === rhsPlayer {
                    return true
                } else {
                    return false
                }
            case let .instantVideo(lhsNode):
                if case let .instantVideo(rhsNode) = rhs, lhsNode === rhsNode {
                    return true
                } else {
                    return false
                }
        }
    }
    
    func setActionAtEnd(_ f: @escaping () -> Void) {
        switch self {
            case let .audio(player):
                player.actionAtEnd = .action(f)
            case let .instantVideo(node):
                node.playbackEnded = f
        }
    }
    
    func play() {
        switch self {
            case let .audio(player):
                player.play()
            case let .instantVideo(node):
                node.play()
        }
    }
    
    func pause() {
        switch self {
            case let .audio(player):
                player.pause()
            case let .instantVideo(node):
                node.pause()
        }
    }
    
    func togglePlayPause() {
        switch self {
            case let .audio(player):
                player.togglePlayPause()
            case let .instantVideo(node):
                node.togglePlayPause()
        }
    }
    
    func seek(_ timestamp: Double) {
        switch self {
            case let .audio(player):
                player.seek(timestamp: timestamp)
            case let .instantVideo(node):
                node.seek(timestamp)
        }
    }
    
    func setSoundEnabled(_ value: Bool) {
        switch self {
            case .audio:
                break
            case let .instantVideo(node):
                node.setSoundEnabled(value)
        }
    }
    
    func setForceAudioToSpeaker(_ value: Bool) {
        switch self {
            case let .audio(player):
                player.setForceAudioToSpeaker(value)
            case let .instantVideo(node):
                node.setForceAudioToSpeaker(value)
        }
    }
}

final class SharedMediaPlayer {
    private weak var mediaManager: MediaManager?
    private let postbox: Postbox
    private let audioSession: ManagedAudioSession
    private let overlayMediaManager: OverlayMediaManager
    private let playerIndex: Int32
    private let playlist: SharedMediaPlaylist
    
    private var proximityManagerIndex: Int?
    private let controlPlaybackWithProximity: Bool
    private var forceAudioToSpeaker = false
    
    private var stateDisposable: Disposable?
    
    private var stateValue: SharedMediaPlaylistState? {
        didSet {
            if self.stateValue != oldValue {
                self.state.set(.single(self.stateValue))
            }
        }
    }
    private let state = Promise<SharedMediaPlaylistState?>(nil)
    
    private let playbackStateValue = Promise<SharedMediaPlayerState?>(nil)
    var playbackState: Signal<SharedMediaPlayerState?, NoError> {
        return self.playbackStateValue.get()
    }
    
    private var playbackItem: SharedMediaPlaybackItem?
    private var currentPlayedToEnd = false
    private var scheduledPlaybackAction: SharedMediaPlayerPlaybackControlAction?
    
    private let markItemAsPlayedDisposable = MetaDisposable()
    
    var playedToEnd: (() -> Void)?
    
    private var inForegroundDisposable: Disposable?
    
    init(mediaManager: MediaManager, inForeground: Signal<Bool, NoError>, postbox: Postbox, audioSession: ManagedAudioSession, overlayMediaManager: OverlayMediaManager, playlist: SharedMediaPlaylist, initialOrder: MusicPlaybackSettingsOrder, initialLooping: MusicPlaybackSettingsLooping, playerIndex: Int32, controlPlaybackWithProximity: Bool) {
        self.mediaManager = mediaManager
        self.postbox = postbox
        self.audioSession = audioSession
        self.overlayMediaManager = overlayMediaManager
        playlist.setOrder(initialOrder)
        playlist.setLooping(initialLooping)
        self.playlist = playlist
        self.playerIndex = playerIndex
        self.controlPlaybackWithProximity = controlPlaybackWithProximity
        
        if controlPlaybackWithProximity {
            self.forceAudioToSpeaker = !DeviceProximityManager.shared().currentValue()
        }
        
        self.stateDisposable = (playlist.state |> deliverOnMainQueue).start(next: { [weak self] state in
            if let strongSelf = self {
                let previousPlaybackItem = strongSelf.playbackItem
                if state.item?.playbackData != strongSelf.stateValue?.item?.playbackData {
                    if let playbackItem = strongSelf.playbackItem {
                        switch playbackItem {
                            case .audio:
                                playbackItem.pause()
                            case let .instantVideo(node):
                               node.setSoundEnabled(false)
                               strongSelf.overlayMediaManager.controller?.removeNode(node)
                        }
                    }
                    strongSelf.playbackItem = nil
                    if let item = state.item, let playbackData = item.playbackData {
                        switch playbackData.type {
                            case .voice, .music:
                                switch playbackData.source {
                                    case let .telegramFile(file):
                                        strongSelf.playbackItem = .audio(MediaPlayer(audioSessionManager: strongSelf.audioSession, postbox: strongSelf.postbox, resource: file.resource, streamable: playbackData.type == .music, video: false, preferSoftwareDecoding: false, enableSound: true, playAndRecord: controlPlaybackWithProximity))
                                }
                            case .instantVideo:
                                if let mediaManager = strongSelf.mediaManager, let item = item as? MessageMediaPlaylistItem {
                                    switch playbackData.source {
                                        case let .telegramFile(file):
                                            let videoNode = OverlayInstantVideoNode(postbox: strongSelf.postbox, audioSession: strongSelf.audioSession, manager: mediaManager.universalVideoManager, content: NativeVideoContent(id: .message(item.message.id, file.fileId), file: file, streamVideo: false, enableSound: false), close: { [weak mediaManager] in
                                                mediaManager?.setPlaylist(nil, type: .voice)
                                            })
                                            strongSelf.playbackItem = .instantVideo(videoNode)
                                            videoNode.setSoundEnabled(true)
                                    }
                                }
                        }
                    }
                    if let playbackItem = strongSelf.playbackItem {
                        playbackItem.setForceAudioToSpeaker(strongSelf.forceAudioToSpeaker)
                        playbackItem.setActionAtEnd({
                            Queue.mainQueue().async {
                                if let strongSelf = self {
                                    switch strongSelf.playlist.looping {
                                        case .item:
                                            strongSelf.playbackItem?.seek(0.0)
                                            strongSelf.playbackItem?.play()
                                        default:
                                            strongSelf.scheduledPlaybackAction = .play
                                            strongSelf.control(.next)
                                    }
                                }
                            }
                        })
                        switch playbackItem {
                            case .audio:
                                break
                            case let .instantVideo(node):
                                strongSelf.overlayMediaManager.controller?.addNode(node)
                        }
                        
                        if let scheduledPlaybackAction = strongSelf.scheduledPlaybackAction {
                            strongSelf.scheduledPlaybackAction = nil
                            switch scheduledPlaybackAction {
                                case .play:
                                    switch playbackItem {
                                        case let .audio(player):
                                            player.play()
                                        case let .instantVideo(node):
                                            node.playOnceWithSound(playAndRecord: controlPlaybackWithProximity)
                                    }
                                case .pause:
                                    playbackItem.pause()
                                case .togglePlayPause:
                                    playbackItem.togglePlayPause()
                            }
                        }
                    }
                }
                
                if strongSelf.currentPlayedToEnd != state.playedToEnd {
                    strongSelf.currentPlayedToEnd = state.playedToEnd
                    if state.playedToEnd {
                        if let playbackItem = strongSelf.playbackItem {
                            switch playbackItem {
                                case let .audio(player):
                                    player.pause()
                                case let .instantVideo(node):
                                    node.setSoundEnabled(false)
                            }
                        }
                        //strongSelf.playbackItem?.seek(0.0)
                        strongSelf.playedToEnd?()
                    }
                }
                
                let updatePlaybackState = strongSelf.stateValue != state || strongSelf.playbackItem != previousPlaybackItem
                strongSelf.stateValue = state
                
                if updatePlaybackState {
                    let playlistId = strongSelf.playlist.id
                    let playlistLocation = strongSelf.playlist.location
                    let playerIndex = strongSelf.playerIndex
                    if let playbackItem = strongSelf.playbackItem, let item = state.item {
                        strongSelf.playbackStateValue.set(playbackItem.playbackStatus |> map { itemStatus in
                            return .item(SharedMediaPlayerItemPlaybackState(playlistId: playlistId, playlistLocation: playlistLocation, item: item, status: itemStatus, order: state.order, looping: state.looping, playerIndex: playerIndex))
                        })
                    strongSelf.markItemAsPlayedDisposable.set((playbackItem.playbackStatus
                        |> filter { status in
                            if case .playing = status.status {
                                return true
                            } else {
                                return false
                            }
                        }
                        |> take(1)
                        |> deliverOnMainQueue).start(next: { next in
                            if let strongSelf = self {
                                strongSelf.playlist.onItemPlaybackStarted(item)
                            }
                        }))
                    } else {
                        if let _ = state.item {
                            strongSelf.playbackStateValue.set(.single(.loading))
                        } else {
                            strongSelf.playbackStateValue.set(.single(nil))
                            if !state.loading {
                                if let proximityManagerIndex = strongSelf.proximityManagerIndex {
                                    DeviceProximityManager.shared().remove(proximityManagerIndex)
                                }
                            }
                        }
                    }
                }
            }
        })
        
        if controlPlaybackWithProximity {
            self.proximityManagerIndex = DeviceProximityManager.shared().add { [weak self] value in
                let forceAudioToSpeaker = !value
                if let strongSelf = self, strongSelf.forceAudioToSpeaker != forceAudioToSpeaker {
                    strongSelf.forceAudioToSpeaker = forceAudioToSpeaker
                    strongSelf.playbackItem?.setForceAudioToSpeaker(forceAudioToSpeaker)
                    if !forceAudioToSpeaker {
                        strongSelf.control(.playback(.play))
                    } else {
                        strongSelf.control(.playback(.pause))
                    }
                }
            }
        }
    }
    
    deinit {
        self.stateDisposable?.dispose()
        self.markItemAsPlayedDisposable.dispose()
        self.inForegroundDisposable?.dispose()
        
        if let proximityManagerIndex = self.proximityManagerIndex {
            DeviceProximityManager.shared().remove(proximityManagerIndex)
        }
        
        if let playbackItem = self.playbackItem {
            switch playbackItem {
                case .audio:
                    playbackItem.pause()
                case let .instantVideo(node):
                    node.setSoundEnabled(false)
                    self.overlayMediaManager.controller?.removeNode(node)
            }
        }
    }
    
    func control(_ action: SharedMediaPlayerControlAction) {
        switch action {
            case .next:
                self.scheduledPlaybackAction = .play
                self.playlist.control(.next)
            case .previous:
                self.scheduledPlaybackAction = .play
                self.playlist.control(.previous)
            case let .playback(action):
                if let playbackItem = self.playbackItem {
                    switch action {
                        case .play:
                            playbackItem.play()
                        case .pause:
                            playbackItem.pause()
                        case .togglePlayPause:
                            playbackItem.togglePlayPause()
                    }
                } else {
                    self.scheduledPlaybackAction = action
                }
            case let .seek(timestamp):
                if let playbackItem = self.playbackItem {
                    playbackItem.seek(timestamp)
                }
            case let .setOrder(order):
                self.playlist.setOrder(order)
            case let .setLooping(looping):
                self.playlist.setLooping(looping)
        }
    }
    
    func stop() {
        if let playbackItem = self.playbackItem {
            switch playbackItem {
                case let .audio(player):
                    player.pause()
                case let .instantVideo(node):
                    node.setSoundEnabled(false)
            }
        }
    }
}
