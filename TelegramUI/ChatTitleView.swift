import Foundation
import AsyncDisplayKit
import Display
import Postbox
import TelegramCore
import SwiftSignalKit
import LegacyComponents

enum ChatTitleContent {
    case peer(PeerView)
    case group([Peer])
}

private final class ChatTitleNetworkStatusNode: ASDisplayNode {
    private var theme: PresentationTheme
    
    private let titleNode: ASTextNode
    private let activityIndicator: ActivityIndicator
    
    var title: String = "" {
        didSet {
            if self.title != oldValue {
                self.titleNode.attributedText = NSAttributedString(string: title, font: Font.bold(17.0), textColor: self.theme.rootController.navigationBar.primaryTextColor)
            }
        }
    }
    
    init(theme: PresentationTheme) {
        self.theme = theme
        
        self.titleNode = ASTextNode()
        self.titleNode.isLayerBacked = true
        self.titleNode.displaysAsynchronously = false
        self.titleNode.maximumNumberOfLines = 1
        self.titleNode.truncationMode = .byTruncatingTail
        self.titleNode.isOpaque = false
        self.titleNode.isUserInteractionEnabled = false
        
        self.activityIndicator = ActivityIndicator(type: .custom(theme.rootController.navigationBar.primaryTextColor, 22.0, 1.5), speed: .slow)
        let activityIndicatorSize = self.activityIndicator.measure(CGSize(width: 100.0, height: 100.0))
        self.activityIndicator.frame = CGRect(origin: CGPoint(), size: activityIndicatorSize)
        
        super.init()
        
        self.addSubnode(self.titleNode)
        self.addSubnode(self.activityIndicator)
    }
    
    func updateLayout(size: CGSize, transition: ContainedViewLayoutTransition) {
        let indicatorSize = self.activityIndicator.bounds.size
        let indicatorPadding = indicatorSize.width + 6.0
        
        let titleSize = self.titleNode.measure(CGSize(width: max(1.0, size.width - indicatorPadding), height: size.height))
        let combinedHeight = titleSize.height
        
        let titleFrame = CGRect(origin: CGPoint(x: indicatorPadding + floor((size.width - titleSize.width - indicatorPadding) / 2.0), y: floor((size.height - combinedHeight) / 2.0)), size: titleSize)
        transition.updateFrame(node: self.titleNode, frame: titleFrame)
        
        transition.updateFrame(node: self.activityIndicator, frame: CGRect(origin: CGPoint(x: titleFrame.minX - indicatorSize.width - 6.0, y: titleFrame.minY - 1.0), size: indicatorSize))
    }
}

private enum ChatTitleIcon {
    case none
    case lock
    case mute
}

final class ChatTitleView: UIView, NavigationBarTitleView {
    private let account: Account
    
    private var theme: PresentationTheme
    private var strings: PresentationStrings
    private var timeFormat: PresentationTimeFormat
    
    private let contentContainer: ASDisplayNode
    private let titleNode: ASTextNode
    private let titleLeftIconNode: ASImageNode
    private let titleRightIconNode: ASImageNode
    private let infoNode: ASTextNode
    private let typingNode: ASTextNode
    private var typingIndicator: TGModernConversationTitleActivityIndicator?
    private let button: HighlightTrackingButtonNode
    
    private var titleLeftIcon: ChatTitleIcon = .none
    private var titleRightIcon: ChatTitleIcon = .none
    
    private var networkStatusNode: ChatTitleNetworkStatusNode?
    
    private var presenceManager: PeerPresenceStatusManager?
    
    var inputActivities: (PeerId, [(Peer, PeerInputActivity)])? {
        didSet {
            if let (peerId, inputActivities) = self.inputActivities, !inputActivities.isEmpty {
                self.typingNode.isHidden = false
                self.infoNode.isHidden = true
                var stringValue = ""
                var first = true
                var mergedActivity = inputActivities[0].1
                for (_, activity) in inputActivities {
                    if activity != mergedActivity {
                        mergedActivity = .typingText
                        break
                    }
                }
                if peerId.namespace == Namespaces.Peer.CloudUser || peerId.namespace == Namespaces.Peer.SecretChat {
                    switch mergedActivity {
                        case .typingText:
                            stringValue = strings.Conversation_typing
                        case .uploadingFile:
                            stringValue = strings.Activity_UploadingDocument
                        case .recordingVoice:
                            stringValue = strings.Activity_RecordingAudio
                        case .uploadingPhoto:
                            stringValue = strings.Activity_UploadingPhoto
                        case .uploadingVideo:
                            stringValue = strings.Activity_UploadingVideo
                        case .playingGame:
                            stringValue = strings.Activity_PlayingGame
                        case .recordingInstantVideo:
                            stringValue = strings.Activity_RecordingVideoMessage
                        case .uploadingInstantVideo:
                            stringValue = strings.Activity_UploadingVideoMessage
                    }
                } else {
                    for (peer, _) in inputActivities {
                        let title = peer.compactDisplayTitle
                        if !title.isEmpty {
                            if first {
                                first = false
                            } else {
                                stringValue += ", "
                            }
                            stringValue += title
                        }
                    }
                }
                let string = NSAttributedString(string: stringValue, font: Font.regular(13.0), textColor: self.theme.rootController.navigationBar.accentTextColor)
                if self.typingNode.attributedText == nil || !self.typingNode.attributedText!.isEqual(to: string) {
                    self.typingNode.attributedText = string
                    self.setNeedsLayout()
                }
                if self.typingIndicator == nil {
                    let typingIndicator = TGModernConversationTitleActivityIndicator()
                    typingIndicator.setColor(self.theme.rootController.navigationBar.accentTextColor)
                    self.contentContainer.view.addSubview(typingIndicator)
                    self.typingIndicator = typingIndicator
                }
                switch mergedActivity {
                    case .typingText:
                        self.typingIndicator?.setTyping()
                    case .recordingVoice:
                        self.typingIndicator?.setAudioRecording()
                    case .uploadingFile:
                        self.typingIndicator?.setUploading()
                    case .playingGame:
                        self.typingIndicator?.setPlaying()
                    case .recordingInstantVideo:
                        self.typingIndicator?.setAudioRecording()
                    case .uploadingInstantVideo:
                        self.typingIndicator?.setUploading()
                    case .uploadingPhoto:
                        self.typingIndicator?.setUploading()
                    case .uploadingVideo:
                        self.typingIndicator?.setUploading()
                }
            } else {
                self.typingNode.isHidden = true
                self.infoNode.isHidden = false
                self.typingNode.attributedText = nil
                if let typingIndicator = self.typingIndicator {
                    typingIndicator.removeFromSuperview()
                    self.typingIndicator = nil
                }
            }
        }
    }
    
    var networkState: AccountNetworkState = .online {
        didSet {
            if self.networkState != oldValue {
                if case .online = self.networkState {
                    self.contentContainer.isHidden = false
                    if let networkStatusNode = self.networkStatusNode {
                        self.networkStatusNode = nil
                        networkStatusNode.removeFromSupernode()
                    }
                } else {
                    self.contentContainer.isHidden = true
                    let statusNode: ChatTitleNetworkStatusNode
                    if let current = self.networkStatusNode {
                        statusNode = current
                    } else {
                        statusNode = ChatTitleNetworkStatusNode(theme: self.theme)
                        self.networkStatusNode = statusNode
                        self.insertSubview(statusNode.view, belowSubview: self.button.view)
                    }
                    switch self.networkState {
                        case .waitingForNetwork:
                            statusNode.title = self.strings.State_WaitingForNetwork
                        case let .connecting(toProxy):
                            statusNode.title = toProxy ? self.strings.State_ConnectingToProxy : self.strings.State_Connecting
                        case .updating:
                            statusNode.title = self.strings.State_Updating
                        case .online:
                            break
                    }
                    
                }
                
                self.setNeedsLayout()
            }
        }
    }
    
    var pressed: (() -> Void)?
    
    var titleContent: ChatTitleContent? {
        didSet {
            if let titleContent = self.titleContent {
                var string: NSAttributedString?
                var titleLeftIcon: ChatTitleIcon = .none
                var titleRightIcon: ChatTitleIcon = .none
                switch titleContent {
                    case let .peer(peerView):
                        if let peer = peerViewMainPeer(peerView) {
                            if peerView.peerId == self.account.peerId {
                                string = NSAttributedString(string: self.strings.Conversation_SavedMessages, font: Font.medium(17.0), textColor: self.theme.rootController.navigationBar.primaryTextColor)
                            } else {
                                string = NSAttributedString(string: peer.displayTitle, font: Font.medium(17.0), textColor: self.theme.rootController.navigationBar.primaryTextColor)
                            }
                        }
                        if peerView.peerId.namespace == Namespaces.Peer.SecretChat {
                            titleLeftIcon = .lock
                        }
                        if let notificationSettings = peerView.notificationSettings as? TelegramPeerNotificationSettings {
                            if case .muted = notificationSettings.muteState {
                                titleRightIcon = .mute
                            }
                        }
                    case .group:
                        string = NSAttributedString(string: "Feed", font: Font.medium(17.0), textColor: self.theme.rootController.navigationBar.primaryTextColor)
                }
                
                if let string = string, self.titleNode.attributedText == nil || !self.titleNode.attributedText!.isEqual(to: string) {
                    self.titleNode.attributedText = string
                    self.setNeedsLayout()
                }
                
                if titleLeftIcon != self.titleLeftIcon {
                    self.titleLeftIcon = titleLeftIcon
                    switch titleLeftIcon {
                        case .lock:
                            self.titleLeftIconNode.image = PresentationResourcesChat.chatTitleLockIcon(self.theme)
                        default:
                            self.titleLeftIconNode.image = nil
                    }
                    self.setNeedsLayout()
                }
                
                if titleRightIcon != self.titleRightIcon {
                    self.titleRightIcon = titleRightIcon
                    switch titleRightIcon {
                        case .mute:
                            self.titleRightIconNode.image = PresentationResourcesChat.chatTitleMuteIcon(self.theme)
                        default:
                            self.titleRightIconNode.image = nil
                    }
                    self.setNeedsLayout()
                }
                
                self.updateStatus()
            }
        }
    }
    
    private func updateStatus() {
        var shouldUpdateLayout = false
        if let titleContent = self.titleContent {
            switch titleContent {
                case let .peer(peerView):
                    if let peer = peerViewMainPeer(peerView) {
                        if peer.id == self.account.peerId {
                            let string = NSAttributedString(string: "", font: Font.regular(13.0), textColor: self.theme.rootController.navigationBar.secondaryTextColor)
                            if self.infoNode.attributedText == nil || !self.infoNode.attributedText!.isEqual(to: string) {
                                self.infoNode.attributedText = string
                                shouldUpdateLayout = true
                            }
                        } else if let user = peer as? TelegramUser {
                            if let _ = user.botInfo {
                                let string = NSAttributedString(string: self.strings.Bot_GenericBotStatus, font: Font.regular(13.0), textColor: self.theme.rootController.navigationBar.secondaryTextColor)
                                if self.infoNode.attributedText == nil || !self.infoNode.attributedText!.isEqual(to: string) {
                                    self.infoNode.attributedText = string
                                    shouldUpdateLayout = true
                                }
                            } else if let peer = peerViewMainPeer(peerView), let presence = peerView.peerPresences[peer.id] as? TelegramUserPresence {
                                let timestamp = CFAbsoluteTimeGetCurrent() + NSTimeIntervalSince1970
                                let (string, activity) = stringAndActivityForUserPresence(strings: self.strings, timeFormat: self.timeFormat, presence: presence, relativeTo: Int32(timestamp))
                                let attributedString = NSAttributedString(string: string, font: Font.regular(13.0), textColor: activity ? self.theme.rootController.navigationBar.accentTextColor : self.theme.rootController.navigationBar.secondaryTextColor)
                                if self.infoNode.attributedText == nil || !self.infoNode.attributedText!.isEqual(to: attributedString) {
                                    self.infoNode.attributedText = attributedString
                                    shouldUpdateLayout = true
                                }
                                
                                self.presenceManager?.reset(presence: presence)
                            } else {
                                let string = NSAttributedString(string: strings.LastSeen_ALongTimeAgo, font: Font.regular(13.0), textColor: self.theme.rootController.navigationBar.secondaryTextColor)
                                if self.infoNode.attributedText == nil || !self.infoNode.attributedText!.isEqual(to: string) {
                                    self.infoNode.attributedText = string
                                    shouldUpdateLayout = true
                                }
                            }
                        } else if let group = peer as? TelegramGroup {
                            var onlineCount = 0
                            if let cachedGroupData = peerView.cachedData as? CachedGroupData, let participants = cachedGroupData.participants {
                                let timestamp = CFAbsoluteTimeGetCurrent() + NSTimeIntervalSince1970
                                for participant in participants.participants {
                                    if let presence = peerView.peerPresences[participant.peerId] as? TelegramUserPresence {
                                        let relativeStatus = relativeUserPresenceStatus(presence, relativeTo: Int32(timestamp))
                                        switch relativeStatus {
                                            case .online:
                                                onlineCount += 1
                                            default:
                                                break
                                        }
                                    }
                                }
                            }
                            if onlineCount > 1 {
                                let string = NSMutableAttributedString()
                                
                                string.append(NSAttributedString(string: "\(strings.Conversation_StatusMembers(Int32(group.participantCount))), ", font: Font.regular(13.0), textColor: self.theme.rootController.navigationBar.secondaryTextColor))
                                string.append(NSAttributedString(string: strings.Conversation_StatusOnline(Int32(onlineCount)), font: Font.regular(13.0), textColor: self.theme.rootController.navigationBar.secondaryTextColor))
                                if self.infoNode.attributedText == nil || !self.infoNode.attributedText!.isEqual(to: string) {
                                    self.infoNode.attributedText = string
                                    shouldUpdateLayout = true
                                }
                            } else {
                                let string = NSAttributedString(string: strings.Conversation_StatusMembers(Int32(group.participantCount)), font: Font.regular(13.0), textColor: self.theme.rootController.navigationBar.secondaryTextColor)
                                if self.infoNode.attributedText == nil || !self.infoNode.attributedText!.isEqual(to: string) {
                                    self.infoNode.attributedText = string
                                    shouldUpdateLayout = true
                                }
                            }
                        } else if let channel = peer as? TelegramChannel {
                            if let cachedChannelData = peerView.cachedData as? CachedChannelData, let memberCount = cachedChannelData.participantsSummary.memberCount {
                                let string = NSAttributedString(string: strings.Conversation_StatusMembers(memberCount), font: Font.regular(13.0), textColor: self.theme.rootController.navigationBar.secondaryTextColor)
                                if self.infoNode.attributedText == nil || !self.infoNode.attributedText!.isEqual(to: string) {
                                    self.infoNode.attributedText = string
                                    shouldUpdateLayout = true
                                }
                            } else {
                                switch channel.info {
                                    case .group:
                                        let string = NSAttributedString(string: strings.Group_Status, font: Font.regular(13.0), textColor: self.theme.rootController.navigationBar.secondaryTextColor)
                                        if self.infoNode.attributedText == nil || !self.infoNode.attributedText!.isEqual(to: string) {
                                            self.infoNode.attributedText = string
                                            shouldUpdateLayout = true
                                        }
                                    case .broadcast:
                                        let string = NSAttributedString(string: strings.Channel_Status, font: Font.regular(13.0), textColor: self.theme.rootController.navigationBar.secondaryTextColor)
                                        if self.infoNode.attributedText == nil || !self.infoNode.attributedText!.isEqual(to: string) {
                                            self.infoNode.attributedText = string
                                            shouldUpdateLayout = true
                                        }
                                }
                            }
                        }
                    }
                case .group:
                    break
            }
            
            if shouldUpdateLayout {
                self.setNeedsLayout()
            }
        }
    }
    
    init(account: Account, theme: PresentationTheme, strings: PresentationStrings, timeFormat: PresentationTimeFormat) {
        self.account = account
        self.theme = theme
        self.strings = strings
        self.timeFormat = timeFormat
        
        self.contentContainer = ASDisplayNode()
        
        self.titleNode = ASTextNode()
        self.titleNode.displaysAsynchronously = false
        self.titleNode.maximumNumberOfLines = 1
        self.titleNode.truncationMode = .byTruncatingTail
        self.titleNode.isOpaque = false
        
        self.titleLeftIconNode = ASImageNode()
        self.titleLeftIconNode.isLayerBacked = true
        self.titleLeftIconNode.displayWithoutProcessing = true
        self.titleLeftIconNode.displaysAsynchronously = false
        
        self.titleRightIconNode = ASImageNode()
        self.titleRightIconNode.isLayerBacked = true
        self.titleRightIconNode.displayWithoutProcessing = true
        self.titleRightIconNode.displaysAsynchronously = false
        
        self.infoNode = ASTextNode()
        self.infoNode.displaysAsynchronously = false
        self.infoNode.maximumNumberOfLines = 1
        self.infoNode.truncationMode = .byTruncatingTail
        self.infoNode.isOpaque = false
        
        self.typingNode = ASTextNode()
        self.typingNode.displaysAsynchronously = false
        self.typingNode.maximumNumberOfLines = 1
        self.typingNode.truncationMode = .byTruncatingTail
        self.typingNode.isOpaque = false
        
        self.button = HighlightTrackingButtonNode()
        
        super.init(frame: CGRect())
        
        self.addSubnode(self.contentContainer)
        self.contentContainer.addSubnode(self.titleNode)
        self.contentContainer.addSubnode(self.infoNode)
        self.contentContainer.addSubnode(self.typingNode)
        self.addSubnode(self.button)
        
        self.presenceManager = PeerPresenceStatusManager(update: { [weak self] in
            self?.updateStatus()
        })
        
        self.button.addTarget(self, action: #selector(buttonPressed), forControlEvents: [.touchUpInside])
        self.button.highligthedChanged = { [weak self] highlighted in
            if let strongSelf = self {
                if highlighted {
                    strongSelf.titleNode.layer.removeAnimation(forKey: "opacity")
                    strongSelf.infoNode.layer.removeAnimation(forKey: "opacity")
                    strongSelf.typingNode.layer.removeAnimation(forKey: "opacity")
                    strongSelf.titleNode.alpha = 0.4
                    strongSelf.infoNode.alpha = 0.4
                    strongSelf.typingNode.alpha = 0.4
                } else {
                    strongSelf.titleNode.alpha = 1.0
                    strongSelf.infoNode.alpha = 1.0
                    strongSelf.typingNode.alpha = 1.0
                    strongSelf.titleNode.layer.animateAlpha(from: 0.4, to: 1.0, duration: 0.2)
                    strongSelf.infoNode.layer.animateAlpha(from: 0.4, to: 1.0, duration: 0.2)
                    strongSelf.typingNode.layer.animateAlpha(from: 0.4, to: 1.0, duration: 0.2)
                }
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let size = self.bounds.size
        let transition: ContainedViewLayoutTransition = .immediate
        
        self.button.frame = CGRect(origin: CGPoint(), size: size)
        self.contentContainer.frame = CGRect(origin: CGPoint(), size: size)
        
        var leftIconWidth: CGFloat = 0.0
        var rightIconWidth: CGFloat = 0.0
        
        if let image = self.titleLeftIconNode.image {
            if self.titleLeftIconNode.supernode == nil {
                self.contentContainer.addSubnode(titleLeftIconNode)
            }
            leftIconWidth = image.size.width + 3.0
        } else if self.titleLeftIconNode.supernode != nil {
            self.titleLeftIconNode.removeFromSupernode()
        }
        
        if let image = self.titleRightIconNode.image {
            if self.titleRightIconNode.supernode == nil {
                self.contentContainer.addSubnode(titleRightIconNode)
            }
            rightIconWidth = image.size.width + 3.0
        } else if self.titleRightIconNode.supernode != nil {
            self.titleRightIconNode.removeFromSupernode()
        }
        
        if size.height > 40.0 {
            let titleSize = self.titleNode.measure(CGSize(width: size.width - leftIconWidth - rightIconWidth, height: size.height))
            let infoSize = self.infoNode.measure(size)
            let typingSize = self.typingNode.measure(size)
            let titleInfoSpacing: CGFloat = 0.0
            
            let titleFrame: CGRect
            
            if infoSize.width.isZero && typingSize.width.isZero {
                titleFrame = CGRect(origin: CGPoint(x: floor((size.width - titleSize.width) / 2.0), y: floor((size.height - titleSize.height) / 2.0)), size: titleSize)
                self.titleNode.frame = titleFrame
            } else {
                let combinedHeight = titleSize.height + infoSize.height + titleInfoSpacing
                
                titleFrame = CGRect(origin: CGPoint(x: floor((size.width - titleSize.width) / 2.0), y: floor((size.height - combinedHeight) / 2.0)), size: titleSize)
                self.titleNode.frame = titleFrame
                
                self.infoNode.frame = CGRect(origin: CGPoint(x: floor((size.width - infoSize.width) / 2.0), y: floor((size.height - combinedHeight) / 2.0) + titleSize.height + titleInfoSpacing), size: infoSize)
                self.typingNode.frame = CGRect(origin: CGPoint(x: floor((size.width - typingSize.width + 14.0) / 2.0), y: floor((size.height - combinedHeight) / 2.0) + titleSize.height + titleInfoSpacing), size: typingSize)
                
                if let typingIndicator = self.typingIndicator {
                    typingIndicator.frame = CGRect(x: self.typingNode.frame.origin.x - 24.0, y: self.typingNode.frame.origin.y, width: 24.0, height: 16.0)
                }
            }
            
            if let image = self.titleLeftIconNode.image {
                self.titleLeftIconNode.frame = CGRect(origin: CGPoint(x: titleFrame.minX - image.size.width - 3.0 - UIScreenPixel, y: titleFrame.minY + 4.0), size: image.size)
            }
            if let image = self.titleRightIconNode.image {
                self.titleRightIconNode.frame = CGRect(origin: CGPoint(x: titleFrame.maxX + 3.0, y: titleFrame.minY + 7.0), size: image.size)
            }
        } else {
            let titleSize = self.titleNode.measure(CGSize(width: floor(size.width / 2.0 - leftIconWidth - rightIconWidth), height: size.height))
            let infoSize = self.infoNode.measure(CGSize(width: floor(size.width / 2.0), height: size.height))
            let typingSize = self.typingNode.measure(CGSize(width: floor(size.width / 2.0), height: size.height))
            
            let titleInfoSpacing: CGFloat = 8.0
            let combinedWidth = titleSize.width + leftIconWidth + rightIconWidth + infoSize.width + titleInfoSpacing
            
            let titleFrame = CGRect(origin: CGPoint(x: leftIconWidth + floor((size.width - combinedWidth) / 2.0), y: floor((size.height - titleSize.height) / 2.0)), size: titleSize)
            self.titleNode.frame = titleFrame
            self.infoNode.frame = CGRect(origin: CGPoint(x: floor((size.width - combinedWidth) / 2.0 + titleSize.width + leftIconWidth + rightIconWidth + titleInfoSpacing), y: floor((size.height - infoSize.height) / 2.0)), size: infoSize)
            self.typingNode.frame = CGRect(origin: CGPoint(x: floor((size.width - combinedWidth) / 2.0 + titleSize.width + leftIconWidth + rightIconWidth + titleInfoSpacing), y: floor((size.height - typingSize.height) / 2.0)), size: typingSize)
            
            if let image = self.titleLeftIconNode.image {
                self.titleLeftIconNode.frame = CGRect(origin: CGPoint(x: titleFrame.minX, y: titleFrame.minY + 4.0), size: image.size)
            }
            if let image = self.titleRightIconNode.image {
                self.titleRightIconNode.frame = CGRect(origin: CGPoint(x: titleFrame.maxX - image.size.width - 1.0, y: titleFrame.minY + 6.0), size: image.size)
            }
        }
        
        if let networkStatusNode = self.networkStatusNode {
            transition.updateFrame(node: networkStatusNode, frame: CGRect(origin: CGPoint(), size: size))
            networkStatusNode.updateLayout(size: size, transition: transition)
        }
    }
    
    @objc func buttonPressed() {
        if let pressed = self.pressed {
            pressed()
        }
    }
    
    func animateLayoutTransition() {
        UIView.transition(with: self, duration: 0.25, options: [.transitionCrossDissolve], animations: {
            
        }, completion: nil)
    }
}
