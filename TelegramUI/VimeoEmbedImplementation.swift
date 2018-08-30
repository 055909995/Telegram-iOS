import Foundation
import WebKit
import SwiftSignalKit

func extractVimeoVideoIdAndTimestamp(url: String) -> (String, Int)? {
    guard let url = URL(string: url), let host = url.host?.lowercased() else {
        return nil
    }
    
    let domain = "player.vimeo.com"
    let match = host == domain || host.contains(".\(domain)")
    
    guard match else {
        return nil
    }
    
    var videoId: String?
    var timestamp = 0
    
    if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
//        if let queryItems = components.queryItems {
//            for queryItem in queryItems {
//                if let value = queryItem.value {
//                    if queryItem.name == "v" {
//                        videoId = value
//                    } else if queryItem.name == "t" || queryItem.name == "time_continue" {
//                        if value.contains("s") {
//
//                        } else {
//                            timestamp = Int(value)
//                        }
//                    }
//                }
//            }
//        }
        
        if videoId == nil {
            let pathComponents = components.path.components(separatedBy: "/")
            var nextComponentIsVideoId = false
            
            for component in pathComponents {
                if nextComponentIsVideoId {
                    videoId = component
                    break
                } else if component == "video" {
                    nextComponentIsVideoId = true
                }
            }
        }
    }
    
    if let videoId = videoId {
        return (videoId, timestamp)
    }
    
    return nil
}

final class VimeoEmbedImplementation: WebEmbedImplementation {
    private var evalImpl: ((String) -> Void)?
    private var updateStatus: ((MediaPlayerStatus) -> Void)?
    private var onPlaybackStarted: (() -> Void)?
    
    private let videoId: String
    private let timestamp: Int
    private var status : MediaPlayerStatus
    
    private var ready: Bool = false
    private var started: Bool = false
    private var ignorePosition: Int?
    
    init(videoId: String, timestamp: Int = 0) {
        self.videoId = videoId
        self.timestamp = timestamp
        self.status = MediaPlayerStatus(generationTimestamp: 0.0, duration: 0.0, dimensions: CGSize(), timestamp: 0.0, seekId: 0, status: .buffering(initial: true, whilePlaying: true))
    }
    
    func setup(_ webView: WKWebView, userContentController: WKUserContentController, evaluateJavaScript: @escaping (String) -> Void, updateStatus: @escaping (MediaPlayerStatus) -> Void, onPlaybackStarted: @escaping () -> Void) {
        let bundle = Bundle(for: type(of: self))
        guard let userScriptPath = bundle.path(forResource: "VimeoUserScript", ofType: "js") else {
            return
        }
        guard let userScriptData = try? Data(contentsOf: URL(fileURLWithPath: userScriptPath)) else {
            return
        }
        guard let userScript = String(data: userScriptData, encoding: .utf8) else {
            return
        }
        guard let htmlTemplatePath = bundle.path(forResource: "Vimeo", ofType: "html") else {
            return
        }
        guard let htmlTemplateData = try? Data(contentsOf: URL(fileURLWithPath: htmlTemplatePath)) else {
            return
        }
        guard let htmlTemplate = String(data: htmlTemplateData, encoding: .utf8) else {
            return
        }
        
        self.evalImpl = evaluateJavaScript
        self.updateStatus = updateStatus
        self.onPlaybackStarted = onPlaybackStarted
        updateStatus(self.status)
        
        let html = String(format: htmlTemplate, self.videoId, "true")
        webView.loadHTMLString(html, baseURL: URL(string: "https://player.vimeo.com/"))
        webView.isUserInteractionEnabled = false
        
        userContentController.addUserScript(WKUserScript(source: userScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false))
    }
    
    func play() {
        if let eval = evalImpl {
            eval("play();")
        }
        
        ignorePosition = 2
    }
    
    func pause() {
        if let eval = evalImpl {
            eval("pause();")
        }
    }
    
    func togglePlayPause() {
        if case .playing = self.status.status {
            pause()
        } else {
            play()
        }
    }
    
    func seek(timestamp: Double) {
        if let eval = evalImpl {
            eval("seek(\(timestamp));")
        }
        
        self.status = MediaPlayerStatus(generationTimestamp: self.status.generationTimestamp, duration: self.status.duration, dimensions: self.status.dimensions, timestamp: timestamp, seekId: self.status.seekId + 1, status: self.status.status)
        if let updateStatus = self.updateStatus {
            updateStatus(self.status)
        }
        
        ignorePosition = 2
    }
    
    func pageReady() {
    }
    
    func callback(url: URL) {
        if url.host == "onState" {
            var newTimestamp = self.status.timestamp
            
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                var playback: Int?
                var position: Double?
                var duration: Double?
                var download: Float?
                var failed: Bool?
                
                if let queryItems = components.queryItems {
                    for queryItem in queryItems {
                        if let value = queryItem.value {
                            if queryItem.name == "playback" {
                                playback = Int(value)
                            } else if queryItem.name == "position" {
                                position = Double(value)
                            } else if queryItem.name == "duration" {
                                duration = Double(value)
                            } else if queryItem.name == "download" {
                                download = Float(value)
                            }
                        }
                    }
                }
                
                if let position = position {
                    if let ticksToIgnore = self.ignorePosition {
                        if ticksToIgnore > 1 {
                            self.ignorePosition = ticksToIgnore - 1
                        } else {
                            self.ignorePosition = nil
                        }
                    } else {
                        newTimestamp = Double(position)
                    }
                }
                
                if let updateStatus = self.updateStatus, let playback = playback, let duration = duration {
                    let playbackStatus: MediaPlayerPlaybackStatus
                    switch playback {
                    case 0:
                        playbackStatus = .paused
                    case 1:
                        playbackStatus = .playing
                    case 2:
                        playbackStatus = .paused
                        newTimestamp = 0.0
                    default:
                        playbackStatus = .buffering(initial: true, whilePlaying: false)
                    }
                    
                    self.status = MediaPlayerStatus(generationTimestamp: self.status.generationTimestamp, duration: Double(duration), dimensions: self.status.dimensions, timestamp: newTimestamp, seekId: self.status.seekId, status: playbackStatus)
                    updateStatus(self.status)
                }
            }
        }
    }
}
