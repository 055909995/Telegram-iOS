import Foundation
import Postbox
import TelegramCore

public func chatListItemStrings(strings: PresentationStrings, message: Message?, chatPeer: RenderedPeer, accountPeerId: PeerId) -> (peer: Peer?, hideAuthor: Bool, messageText: String) {
    let peer: Peer?
    
    var hideAuthor = false
    var messageText: String
    if let message = message {
        if let messageMain = messageMainPeer(message) {
            peer = messageMain
        } else {
            peer = chatPeer.chatMainPeer
        }
        
        messageText = message.text
        if message.text.isEmpty {
            for media in message.media {
                switch media {
                case _ as TelegramMediaImage:
                    if message.text.isEmpty {
                        messageText = strings.Message_Photo
                    }
                case let fileMedia as TelegramMediaFile:
                    if message.text.isEmpty {
                        if let fileName = fileMedia.fileName {
                            messageText = fileName
                        } else {
                            messageText = strings.Message_File
                        }
                        var isAnimated = false
                        inner: for attribute in fileMedia.attributes {
                            switch attribute {
                            case .Animated:
                                isAnimated = true
                                break inner
                            case let .Audio(isVoice, _, title, performer, _):
                                if isVoice {
                                    messageText = strings.Message_Audio
                                    break inner
                                } else {
                                    let descriptionString: String
                                    if let title = title, let performer = performer, !title.isEmpty, !performer.isEmpty {
                                        descriptionString = title + " — " + performer
                                    } else if let title = title, !title.isEmpty {
                                        descriptionString = title
                                    } else if let performer = performer, !performer.isEmpty {
                                        descriptionString = performer
                                    } else if let fileName = fileMedia.fileName {
                                        descriptionString = fileName
                                    } else {
                                        descriptionString = strings.Message_Audio
                                    }
                                    messageText = descriptionString
                                    break inner
                                }
                            case let .Sticker(displayText, _, _):
                                if displayText.isEmpty {
                                    messageText = strings.Message_Sticker
                                    break inner
                                } else {
                                    messageText = displayText + " " + strings.Message_Sticker
                                    break inner
                                }
                            case let .Video(_, _, flags):
                                if flags.contains(.instantRoundVideo) {
                                    messageText = strings.Message_VideoMessage
                                } else {
                                    messageText = strings.Message_Video
                                }
                            default:
                                break
                            }
                        }
                        if isAnimated {
                            messageText = strings.Message_Animation
                        }
                    }
                case _ as TelegramMediaMap:
                    messageText = strings.Message_Location
                case _ as TelegramMediaContact:
                    messageText = strings.Message_Contact
                case let game as TelegramMediaGame:
                    messageText = "🎮 \(game.title)"
                case let invoice as TelegramMediaInvoice:
                    messageText = invoice.title
                case let action as TelegramMediaAction:
                    hideAuthor = true
                    switch action.action {
                    case .phoneCall:
                        if message.effectivelyIncoming {
                            messageText = strings.Notification_CallIncoming
                        } else {
                            messageText = strings.Notification_CallOutgoing
                        }
                    default:
                        if let text = plainServiceMessageString(strings: strings, message: message, accountPeerId: accountPeerId) {
                            messageText = text
                        }
                    }
                case _ as TelegramMediaExpiredContent:
                    if let text = plainServiceMessageString(strings: strings, message: message, accountPeerId: accountPeerId) {
                        messageText = text
                    }
                default:
                    break
                }
            }
        }
    } else {
        peer = chatPeer.chatMainPeer
        messageText = ""
        if chatPeer.peerId.namespace == Namespaces.Peer.SecretChat {
            if let secretChat = chatPeer.peers[chatPeer.peerId] as? TelegramSecretChat {
                switch secretChat.embeddedState {
                    case .active:
                        messageText = strings.Notification_EncryptedChatAccepted
                    case .terminated:
                        messageText = strings.DialogList_EncryptionRejected
                    case .handshake:
                        switch secretChat.role {
                            case .creator:
                                messageText = strings.Notification_EncryptedChatRequested
                            case .participant:
                                messageText = strings.DialogList_EncryptionProcessing
                        }
                }
            }
        }
    }
    
    return (peer, hideAuthor, messageText)
}
