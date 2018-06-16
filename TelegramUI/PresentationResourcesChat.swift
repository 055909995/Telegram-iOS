import Foundation
import Display

private func generateLineImage(color: UIColor) -> UIImage? {
    return generateImage(CGSize(width: 2.0, height: 3.0), contextGenerator: { size, context in
        context.clear(CGRect(origin: CGPoint(), size: size))
        context.setFillColor(color.cgColor)
        context.fillEllipse(in: CGRect(origin: CGPoint(), size: CGSize(width: 2.0, height: 2.0)))
        context.fillEllipse(in: CGRect(origin: CGPoint(x: 0.0, y: 1.0), size: CGSize(width: 2.0, height: 2.0)))
    })?.stretchableImage(withLeftCapWidth: 0, topCapHeight: 1)
}

private func generateInstantVideoBackground(fillColor: UIColor, strokeColor: UIColor) -> UIImage? {
    return generateImage(CGSize(width: 214.0, height: 214.0), rotatedContext: { size, context in
        let lineWidth: CGFloat = 0.5
        
        context.clear(CGRect(origin: CGPoint(), size: size))
        
        context.setFillColor(strokeColor.cgColor)
        context.fillEllipse(in: CGRect(origin: CGPoint(), size: size))
        context.setFillColor(fillColor.cgColor)
        context.fillEllipse(in: CGRect(origin: CGPoint(x: lineWidth, y: lineWidth), size: CGSize(width: size.width - lineWidth * 2.0, height: size.height - lineWidth * 2.0)))
    })
}

private func generateInputPanelButtonBackgroundImage(fillColor: UIColor, strokeColor: UIColor) -> UIImage? {
    let radius: CGFloat = 5.0
    let shadowSize: CGFloat = 1.0
    return generateImage(CGSize(width: radius * 2.0, height: radius * 2.0 + shadowSize), contextGenerator: { size, context in
        context.clear(CGRect(origin: CGPoint(), size: size))
        context.setFillColor(strokeColor.cgColor)
        context.fillEllipse(in: CGRect(x: 0.0, y: 0.0, width: radius * 2.0, height: radius * 2.0))
        context.setFillColor(fillColor.cgColor)
        context.fillEllipse(in: CGRect(x: 0.0, y: shadowSize, width: radius * 2.0, height: radius * 2.0))
    })?.stretchableImage(withLeftCapWidth: Int(radius), topCapHeight: Int(radius))
}

struct PresentationResourcesChat {
    static func chatTitleLockIcon(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatTitleLockIcon.rawValue, { theme in
            return generateImage(CGSize(width: 9.0, height: 13.0), rotatedContext: { size, context in
                context.clear(CGRect(origin: CGPoint(), size: size))
                
                context.translateBy(x: 0.0, y: 1.0)
                
                context.setFillColor(theme.rootController.navigationBar.primaryTextColor.cgColor)
                context.setStrokeColor(theme.rootController.navigationBar.primaryTextColor.cgColor)
                context.setLineWidth(1.32)
                
                let _ = try? drawSvgPath(context, path: "M4.5,0.600000024 C5.88071187,0.600000024 7,1.88484952 7,3.46979169 L7,7.39687502 C7,8.9818172 5.88071187,10.2666667 4.5,10.2666667 C3.11928813,10.2666667 2,8.9818172 2,7.39687502 L2,3.46979169 C2,1.88484952 3.11928813,0.600000024 4.5,0.600000024 S ")
                let _ = try? drawSvgPath(context, path: "M1.32,5.65999985 L7.68,5.65999985 C8.40901587,5.65999985 9,6.25098398 9,6.97999985 L9,10.6733332 C9,11.4023491 8.40901587,11.9933332 7.68,11.9933332 L1.32,11.9933332 C0.59098413,11.9933332 1.11022302e-16,11.4023491 0,10.6733332 L2.22044605e-16,6.97999985 C1.11022302e-16,6.25098398 0.59098413,5.65999985 1.32,5.65999985 Z ")
            })
        })
    }
    
    static func chatTitleMuteIcon(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatTitleMuteIcon.rawValue, { theme in
            return generateImage(CGSize(width: 9.0, height: 9.0), rotatedContext: { size, context in
                context.clear(CGRect(origin: CGPoint(), size: size))
                context.setFillColor(theme.rootController.navigationBar.controlColor.cgColor)
                
                let _ = try? drawSvgPath(context, path: "M2.97607626,2.27306995 L5.1424026,0.18411241 C5.25492443,0.0756092198 5.40753677,0.0146527621 5.56666667,0.0146527621 C5.89803752,0.0146527621 6.16666667,0.273688014 6.16666667,0.593224191 L6.16666667,5.47790407 L8.86069303,8.18395735 C9.05193038,8.37604845 9.04547086,8.68126082 8.84626528,8.86566828 C8.6470597,9.05007573 8.33054317,9.0438469 8.13930581,8.85175581 L0.139306972,0.816042647 C-0.0519303838,0.623951552 -0.0454708626,0.318739175 0.153734717,0.134331724 C0.352940296,-0.0500757275 0.669456833,-0.0438469035 0.860694189,0.148244192 L2.97607626,2.27306995 Z M0.933196438,2.75856564 L6.16666667,8.01539958 L6.16666667,8.40677707 C6.16666667,8.56022375 6.10345256,8.70738566 5.99093074,8.81588885 C5.75661616,9.04183505 5.37671717,9.04183505 5.1424026,8.81588885 L2.59763107,6.36200202 C2.53511895,6.30172247 2.45033431,6.26785777 2.36192881,6.26785777 L1.16666667,6.26785777 C0.614381917,6.26785777 0.166666667,5.83613235 0.166666667,5.30357206 L0.166666667,3.6964292 C0.166666667,3.24138962 0.493527341,2.85996592 0.933196438,2.75856564 Z ")
            })
        })
    }
    
    static func principalGraphics(_ theme: PresentationTheme) -> PrincipalThemeEssentialGraphics {
        return theme.object(PresentationResourceKey.chatPrincipalThemeEssentialGraphics.rawValue, { theme in
            return PrincipalThemeEssentialGraphics(theme.chat)
        }) as! PrincipalThemeEssentialGraphics
    }
    
    static func chatBubbleVerticalLineIncomingImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatBubbleVerticalLineIncomingImage.rawValue, { theme in
            return generateLineImage(color: theme.chat.bubble.incomingAccentControlColor)
        })
    }
    
    static func chatBubbleVerticalLineOutgoingImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatBubbleVerticalLineOutgoingImage.rawValue, { theme in
            return generateLineImage(color: theme.chat.bubble.outgoingAccentControlColor)
        })
    }
    
    static func chatServiceVerticalLineImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatServiceVerticalLineImage.rawValue, { theme in
            return generateLineImage(color: theme.chat.serviceMessage.serviceMessagePrimaryTextColor)
        })
    }
    
    static func chatBubbleRadialIndicatorFileIconIncoming(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatBubbleRadialIndicatorFileIconIncoming.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat/Message/RadialProgressIconDocumentIncoming"), color: theme.chat.bubble.incomingFillColor)
        })
    }
    
    static func chatBubbleRadialIndicatorFileIconOutgoing(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatBubbleRadialIndicatorFileIconOutgoing.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat/Message/RadialProgressIconDocumentIncoming"), color: theme.chat.bubble.outgoingFillColor)
        })
    }
    
    static func chatBubbleConsumableContentIncomingIcon(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatBubbleConsumableContentIncomingIcon.rawValue, { theme in
            return generateFilledCircleImage(diameter: 4.0, color: theme.chat.bubble.incomingAccentControlColor)
        })
    }
    
    static func chatBubbleConsumableContentOutgoingIcon(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatBubbleConsumableContentOutgoingIcon.rawValue, { theme in
            return generateFilledCircleImage(diameter: 4.0, color: theme.chat.bubble.outgoingAccentControlColor)
        })
    }
    
    static func chatMediaConsumableContentIcon(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatMediaConsumableContentIcon.rawValue, { theme in
            return generateFilledCircleImage(diameter: 4.0, color: theme.chat.bubble.mediaDateAndStatusTextColor)
        })
    }
    
    static func chatBubbleShareButtonImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatBubbleShareButtonImage.rawValue, { theme in
            return generateImage(CGSize(width: 29.0, height: 29.0), rotatedContext: { size, context in
                context.clear(CGRect(origin: CGPoint(), size: size))
                context.setFillColor(theme.chat.bubble.shareButtonFillColor.cgColor)
                context.fillEllipse(in: CGRect(origin: CGPoint(), size: size))
                let lineWidth: CGFloat = 1.0
                let halfLineWidth = lineWidth / 2.0
                var strokeAlpha: CGFloat = 0.0
                theme.chat.bubble.shareButtonStrokeColor.getRed(nil, green: nil, blue: nil, alpha: &strokeAlpha)
                if !strokeAlpha.isZero {
                    context.setStrokeColor(theme.chat.bubble.shareButtonStrokeColor.cgColor)
                    context.setLineWidth(lineWidth)
                    context.strokeEllipse(in: CGRect(origin: CGPoint(x: halfLineWidth, y: halfLineWidth), size: CGSize(width: size.width - lineWidth, height: size.width - lineWidth)))
                }
                
                if let image = UIImage(bundleImageName: "Chat/Message/ShareIcon") {
                    let imageRect = CGRect(origin: CGPoint(x: floor((size.width - image.size.width) / 2.0), y: floor((size.height - image.size.height) / 2.0)), size: image.size)
                    
                    context.translateBy(x: imageRect.midX, y: imageRect.midY)
                    context.scaleBy(x: 1.0, y: -1.0)
                    context.translateBy(x: -imageRect.midX, y: -imageRect.midY)
                    context.clip(to: imageRect, mask: image.cgImage!)
                    context.setFillColor(theme.chat.bubble.shareButtonForegroundColor.cgColor)
                    context.fill(imageRect)
                }
            })
        })
    }
    
    static func chatBubbleNavigateButtonImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatBubbleNavigateButtonImage.rawValue, { theme in
            return generateImage(CGSize(width: 29.0, height: 29.0), rotatedContext: { size, context in
                context.clear(CGRect(origin: CGPoint(), size: size))
                context.setFillColor(theme.chat.bubble.shareButtonFillColor.cgColor)
                context.fillEllipse(in: CGRect(origin: CGPoint(), size: size))
                let lineWidth: CGFloat = 1.0
                let halfLineWidth = lineWidth / 2.0
                var strokeAlpha: CGFloat = 0.0
                theme.chat.bubble.shareButtonStrokeColor.getRed(nil, green: nil, blue: nil, alpha: &strokeAlpha)
                if !strokeAlpha.isZero {
                    context.setStrokeColor(theme.chat.bubble.shareButtonStrokeColor.cgColor)
                    context.setLineWidth(lineWidth)
                    context.strokeEllipse(in: CGRect(origin: CGPoint(x: halfLineWidth, y: halfLineWidth), size: CGSize(width: size.width - lineWidth, height: size.width - lineWidth)))
                }
                
                if let image = UIImage(bundleImageName: "Chat/Message/NavigateToMessageIcon") {
                    let imageRect = CGRect(origin: CGPoint(x: floor((size.width - image.size.width) / 2.0), y: floor((size.height - image.size.height) / 2.0) + 1.0), size: image.size)
                    
                    context.translateBy(x: imageRect.midX, y: imageRect.midY)
                    context.scaleBy(x: 1.0, y: -1.0)
                    context.translateBy(x: -imageRect.midX, y: -imageRect.midY)
                    context.clip(to: imageRect, mask: image.cgImage!)
                    context.setFillColor(theme.chat.bubble.shareButtonForegroundColor.cgColor)
                    context.fill(imageRect)
                }
            })
        })
    }
    
    static func chatServiceBubbleFillImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatServiceBubbleFillImage.rawValue, { theme in
            return generateImage(CGSize(width: 20.0, height: 20.0), contextGenerator: { size, context -> Void in
                context.clear(CGRect(origin: CGPoint(), size: size))
                context.setFillColor(theme.chat.serviceMessage.serviceMessageFillColor.cgColor)
                context.fillEllipse(in: CGRect(origin: CGPoint(), size: size))
            })?.stretchableImage(withLeftCapWidth: 8, topCapHeight: 8)
        })
    }
    
    static func chatBubbleSecretMediaIcon(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatBubbleSecretMediaIcon.rawValue, { theme in
            generateTintedImage(image: UIImage(bundleImageName: "Chat/Message/SecretMediaIcon"), color: theme.chat.bubble.mediaOverlayControlForegroundColor)
        })
    }
    
    static func chatFreeformContentAdditionalInfoBackgroundImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatFreeformContentAdditionalInfoBackgroundImage.rawValue, { theme in
            return generateStretchableFilledCircleImage(radius: 4.0, color: theme.chat.serviceMessage.serviceMessageFillColor)
        })
    }
    
    static func chatInstantVideoBackgroundImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatInstantVideoBackgroundImage.rawValue, { theme in
            return generateInstantVideoBackground(fillColor: theme.chat.bubble.freeformFillColor, strokeColor: theme.chat.bubble.freeformStrokeColor)
        })
    }
    
    static func chatUnreadBarBackgroundImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatUnreadBarBackgroundImage.rawValue, { theme in
            return generateImage(CGSize(width: 1.0, height: 8.0), contextGenerator: { size, context -> Void in
                context.clear(CGRect(origin: CGPoint(), size: size))
                context.setFillColor(theme.chat.serviceMessage.unreadBarStrokeColor.cgColor)
                context.fill(CGRect(origin: CGPoint(), size: CGSize(width: size.width, height: UIScreenPixel)))
                context.fill(CGRect(origin: CGPoint(x: 0.0, y: size.height - UIScreenPixel), size: CGSize(width: size.width, height: UIScreenPixel)))
                context.setFillColor(theme.chat.serviceMessage.unreadBarFillColor.cgColor)
                context.fill(CGRect(x: 0.0, y: UIScreenPixel, width: size.width, height: size.height - UIScreenPixel - UIScreenPixel))
            })?.stretchableImage(withLeftCapWidth: 1, topCapHeight: 4)
        })
    }
    
    static func chatBubbleActionButtonIncomingMiddleImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatBubbleActionButtonIncomingMiddleImage.rawValue, { theme in
            return messageBubbleActionButtonImage(color: theme.chat.bubble.actionButtonsIncomingFillColor, strokeColor: theme.chat.bubble.actionButtonsIncomingStrokeColor, position: .middle)
        })
    }
    
    static func chatBubbleActionButtonIncomingBottomLeftImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatBubbleActionButtonIncomingBottomLeftImage.rawValue, { theme in
            return messageBubbleActionButtonImage(color: theme.chat.bubble.actionButtonsIncomingFillColor, strokeColor: theme.chat.bubble.actionButtonsIncomingStrokeColor, position: .bottomLeft)
        })
    }
    
    static func chatBubbleActionButtonIncomingBottomRightImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatBubbleActionButtonIncomingBottomRightImage.rawValue, { theme in
            return messageBubbleActionButtonImage(color: theme.chat.bubble.actionButtonsIncomingFillColor, strokeColor: theme.chat.bubble.actionButtonsIncomingStrokeColor, position: .bottomRight)
        })
    }
    
    static func chatBubbleActionButtonIncomingBottomSingleImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatBubbleActionButtonIncomingBottomSingleImage.rawValue, { theme in
            return messageBubbleActionButtonImage(color: theme.chat.bubble.actionButtonsIncomingFillColor, strokeColor: theme.chat.bubble.actionButtonsIncomingStrokeColor, position: .bottomSingle)
        })
    }
    
    static func chatBubbleActionButtonOutgoingMiddleImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatBubbleActionButtonOutgoingMiddleImage.rawValue, { theme in
            return messageBubbleActionButtonImage(color: theme.chat.bubble.actionButtonsOutgoingFillColor, strokeColor: theme.chat.bubble.actionButtonsOutgoingStrokeColor, position: .middle)
        })
    }
    
    static func chatBubbleActionButtonOutgoingBottomLeftImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatBubbleActionButtonOutgoingBottomLeftImage.rawValue, { theme in
            return messageBubbleActionButtonImage(color: theme.chat.bubble.actionButtonsOutgoingFillColor, strokeColor: theme.chat.bubble.actionButtonsOutgoingStrokeColor, position: .bottomLeft)
        })
    }
    
    static func chatBubbleActionButtonOutgoingBottomRightImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatBubbleActionButtonOutgoingBottomRightImage.rawValue, { theme in
            return messageBubbleActionButtonImage(color: theme.chat.bubble.actionButtonsOutgoingFillColor, strokeColor: theme.chat.bubble.actionButtonsOutgoingStrokeColor, position: .bottomRight)
        })
    }
    
    static func chatBubbleActionButtonOutgoingBottomSingleImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatBubbleActionButtonOutgoingBottomSingleImage.rawValue, { theme in
            return messageBubbleActionButtonImage(color: theme.chat.bubble.actionButtonsOutgoingFillColor, strokeColor: theme.chat.bubble.actionButtonsOutgoingStrokeColor, position: .bottomSingle)
        })
    }
    
    static func chatInfoItemBackgroundImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatInfoItemBackgroundImage.rawValue, { theme in
            return messageSingleBubbleLikeImage(fillColor: theme.chat.bubble.infoFillColor, strokeColor: theme.chat.bubble.infoStrokeColor)
        })
    }
    
    static func chatEmptyItemBackgroundImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatEmptyItemBackgroundImage.rawValue, { theme in
            return generateStretchableFilledCircleImage(radius: 14.0, color: theme.chat.serviceMessage.serviceMessageFillColor)
        })
    }
    
    static func chatEmptyItemIconImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatEmptyItemIconImage.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat/EmptyChatIcon"), color: theme.chat.serviceMessage.serviceMessagePrimaryTextColor)
        })
    }
    
    static func chatInputPanelCloseIconImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatInputPanelCloseIconImage.rawValue, { theme in
            return generateImage(CGSize(width: 12.0, height: 12.0), contextGenerator: { size, context in
                context.clear(CGRect(origin: CGPoint(), size: size))
                context.setStrokeColor(theme.chat.inputPanel.panelControlColor.cgColor)
                context.setLineWidth(2.0)
                context.setLineCap(.round)
                context.move(to: CGPoint(x: 1.0, y: 1.0))
                context.addLine(to: CGPoint(x: size.width - 1.0, y: size.height - 1.0))
                context.strokePath()
                context.move(to: CGPoint(x: size.width - 1.0, y: 1.0))
                context.addLine(to: CGPoint(x: 1.0, y: size.height - 1.0))
                context.strokePath()
            })
        })
    }
    
    static func chatInputPanelVerticalSeparatorLineImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatInputPanelVerticalSeparatorLineImage.rawValue, { theme in
            return generateVerticallyStretchableFilledCircleImage(radius: 1.0, color: theme.chat.inputPanel.panelControlAccentColor)
        })
    }
    
    static func chatMediaInputPanelHighlightedIconImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatMediaInputPanelHighlightedIconImage.rawValue, { theme in
            return generateStretchableFilledCircleImage(radius: 9.0, color: theme.chat.inputMediaPanel.panelHighlightedIconBackgroundColor)
        })
    }
    
    static func chatInputMediaPanelSavedStickersIcon(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatInputMediaPanelSavedStickersIconImage.rawValue, { theme in
            return generateImage(CGSize(width: 26.0, height: 26.0), contextGenerator: { size, context in
                context.clear(CGRect(origin: CGPoint(), size: size))
                if let image = generateTintedImage(image: UIImage(bundleImageName: "Chat/Input/Media/SavedStickersTabIcon"), color: theme.chat.inputMediaPanel.panelIconColor) {
                    context.draw(image.cgImage!, in: CGRect(origin: CGPoint(x: floor((size.width - image.size.width) / 2.0), y: floor((size.height - image.size.height) / 2.0)), size: image.size))
                }
            })
        })
    }
    
    static func chatInputMediaPanelRecentStickersIcon(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatInputMediaPanelRecentStickersIconImage.rawValue, { theme in
            return generateImage(CGSize(width: 26.0, height: 26.0), contextGenerator: { size, context in
                context.clear(CGRect(origin: CGPoint(), size: size))
                if let image = generateTintedImage(image: UIImage(bundleImageName: "Chat/Input/Media/RecentTabIcon"), color: theme.chat.inputMediaPanel.panelIconColor) {
                    context.draw(image.cgImage!, in: CGRect(origin: CGPoint(x: floor((size.width - image.size.width) / 2.0), y: floor((size.height - image.size.height) / 2.0)), size: image.size))
                }
            })
        })
    }
    
    static func chatInputMediaPanelRecentGifsIconImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatInputMediaPanelRecentGifsIconImage.rawValue, { theme in
            return generateImage(CGSize(width: 26.0, height: 26.0), contextGenerator: { size, context in
                context.clear(CGRect(origin: CGPoint(), size: size))
                if let image = generateTintedImage(image: UIImage(bundleImageName: "Chat/Input/Media/GifsTabIcon"), color: theme.chat.inputMediaPanel.panelIconColor) {
                    context.draw(image.cgImage!, in: CGRect(origin: CGPoint(x: floor((size.width - image.size.width) / 2.0), y: floor((size.height - image.size.height) / 2.0)), size: image.size))
                }
            })
        })
    }
    
    static func chatInputMediaPanelTrendingIconImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatInputMediaPanelTrendingIconImage.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat/Input/Media/TrendingIcon"), color: theme.chat.inputMediaPanel.panelIconColor)
        })
    }
    
    static func chatInputMediaPanelSettingsIconImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatInputMediaPanelSettingsIconImage.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat/Input/Media/SettingsIcon"), color: theme.chat.inputMediaPanel.panelIconColor)
        })
    }
    
    static func chatInputMediaPanelAddPackButtonImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatInputMediaPanelAddPackButtonImage.rawValue, { theme in
            return generateStretchableFilledCircleImage(diameter: 8.0, color: nil, strokeColor: theme.chat.inputPanel.panelControlAccentColor, strokeWidth: 1.0, backgroundColor: nil)
        })
    }
    
    static func chatInputButtonPanelButtonImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatInputButtonPanelButtonImage.rawValue, { theme in
            return generateInputPanelButtonBackgroundImage(fillColor: theme.chat.inputButtonPanel.buttonFillColor, strokeColor: theme.chat.inputButtonPanel.buttonStrokeColor)
        })
    }
    
    static func chatInputButtonPanelButtonHighlightedImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatInputButtonPanelButtonHighlightedImage.rawValue, { theme in
            return generateInputPanelButtonBackgroundImage(fillColor: theme.chat.inputButtonPanel.buttonHighlightedFillColor, strokeColor: theme.chat.inputButtonPanel.buttonHighlightedStrokeColor)
        })
    }
    
    static func chatInputTextFieldBackgroundImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatInputTextFieldBackgroundImage.rawValue, { theme in
            let diameter: CGFloat = 35.0
            UIGraphicsBeginImageContextWithOptions(CGSize(width: diameter, height: diameter), false, 0.0)
            let context = UIGraphicsGetCurrentContext()!
            context.setFillColor(theme.chat.inputPanel.panelBackgroundColor.cgColor)
            context.fill(CGRect(x: 0.0, y: 0.0, width: diameter, height: diameter))
           
            context.setBlendMode(.clear)
            context.setFillColor(UIColor.clear.cgColor)
            context.fillEllipse(in: CGRect(x: 0.0, y: 0.0, width: diameter, height: diameter))
            context.setBlendMode(.normal)
            context.setStrokeColor(theme.chat.inputPanel.inputStrokeColor.cgColor)
            let strokeWidth: CGFloat = 0.5
            context.setLineWidth(strokeWidth)
            context.strokeEllipse(in: CGRect(x: strokeWidth / 2.0, y: strokeWidth / 2.0, width: diameter - strokeWidth, height: diameter - strokeWidth))
            let image = UIGraphicsGetImageFromCurrentImageContext()!.stretchableImage(withLeftCapWidth: Int(diameter / 2.0), topCapHeight: Int(diameter / 2.0))
            UIGraphicsEndImageContext()
            
            return image
        })
    }
    
    static func chatInputTextFieldClearImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatInputTextFieldClearImage.rawValue, { theme in
            return generateImage(CGSize(width: 14.0, height: 14.0), contextGenerator: { size, context in
                context.clear(CGRect(origin: CGPoint(), size: size))
                context.setFillColor(theme.chat.inputPanel.inputControlColor.cgColor)
                context.setStrokeColor(theme.chat.inputPanel.inputBackgroundColor.cgColor)
                context.fillEllipse(in: CGRect(origin: CGPoint(), size: size))
                
                context.setLineWidth(1.5)
                context.setLineCap(.round)
                context.translateBy(x: size.width / 2.0, y: size.height / 2.0)
                context.rotate(by: CGFloat.pi / 4.0)
                context.translateBy(x: -size.width / 2.0, y: -size.height / 2.0)
                
                let lineHeight: CGFloat = 7.0
                
                context.beginPath()
                context.move(to: CGPoint(x: size.width / 2.0, y: (size.width - lineHeight) / 2.0))
                context.addLine(to: CGPoint(x: size.width / 2.0, y: (size.width - lineHeight) / 2.0 + lineHeight))
                context.strokePath()
                
                context.beginPath()
                context.move(to: CGPoint(x: (size.width - lineHeight) / 2.0, y: size.width / 2.0))
                context.addLine(to: CGPoint(x: (size.width - lineHeight) / 2.0 + lineHeight, y: size.width / 2.0))
                context.strokePath()
            })
        })
    }
    
    static func chatInputPanelSendButtonImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatInputPanelSendButtonImage.rawValue, { theme in
            return generateImage(CGSize(width: 33.0, height: 33.0), rotatedContext: { size, context in
                context.clear(CGRect(origin: CGPoint(), size: size))
                context.setFillColor(theme.chat.inputPanel.actionControlFillColor.cgColor)
                context.fillEllipse(in: CGRect(origin: CGPoint(), size: size))
                context.setStrokeColor(theme.chat.inputPanel.actionControlForegroundColor.cgColor)
                context.setFillColor(theme.chat.inputPanel.actionControlForegroundColor.cgColor)
                context.setLineWidth(2.0)
                context.setLineCap(.round)
                context.setLineJoin(.round)
                let _ = try? drawSvgPath(context, path: "M11,14.6666667 L16.4310816,9.40016333 L16.4310816,9.40016333 C16.4694824,9.36292619 16.5305176,9.36292619 16.5689184,9.40016333 L22,14.6666667 S ")
                let _ = try? drawSvgPath(context, path: "M16.5,9.33333333 C17.0522847,9.33333333 17.5,9.78104858 17.5,10.3333333 L17.5,24 C17.5,24.5522847 17.0522847,25 16.5,25 C15.9477153,25 15.5,24.5522847 15.5,24 L15.5,10.3333333 C15.5,9.78104858 15.9477153,9.33333333 16.5,9.33333333 Z ")
            })
        })
    }
    
    static func chatInputPanelApplyButtonImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatInputPanelApplyButtonImage.rawValue, { theme in
            return generateImage(CGSize(width: 33.0, height: 33.0), rotatedContext: { size, context in
                context.clear(CGRect(origin: CGPoint(), size: size))
                context.setFillColor(theme.chat.inputPanel.actionControlFillColor.cgColor)
                context.fillEllipse(in: CGRect(origin: CGPoint(), size: size))
                context.setStrokeColor(theme.chat.inputPanel.actionControlForegroundColor.cgColor)
                context.setFillColor(theme.chat.inputPanel.actionControlForegroundColor.cgColor)
                context.setLineWidth(2.0)
                context.setLineCap(.round)
                context.setLineJoin(.round)
                let _ = try? drawSvgPath(context, path: "M9.33333333,17.2686567 L14.1849216,22.120245 L14.1849216,22.120245 C14.2235835,22.1589069 14.2862668,22.1589069 14.3249287,22.120245 C14.3261558,22.1190179 14.3273504,22.1177588 14.3285113,22.1164689 L24.3333333,11 S ")
            })
        })
    }
    
    static func chatInputPanelVoiceButtonImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatInputPanelVoiceButtonImage.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat/Input/Text/IconMicrophone"), color: theme.chat.inputPanel.panelControlColor)
        })
    }
    
    static func chatInputPanelVideoButtonImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatInputPanelVideoButtonImage.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat/Input/Text/IconVideo"), color: theme.chat.inputPanel.panelControlColor)
        })
    }
    
    static func chatInputPanelVoiceActiveButtonImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatInputPanelVoiceActiveButtonImage.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat/Input/Text/IconMicrophone"), color: theme.chat.inputPanel.mediaRecordingControl.activeIconColor)
        })
    }
    
    static func chatInputPanelVideoActiveButtonImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatInputPanelVideoActiveButtonImage.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat/Input/Text/IconVideo"), color: theme.chat.inputPanel.mediaRecordingControl.activeIconColor)
        })
    }
    
    static func chatInputPanelAttachmentButtonImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatInputPanelAttachmentButtonImage.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat/Input/Text/IconAttachment"), color: theme.chat.inputPanel.panelControlColor)
        })
    }
    
    static func chatInputPanelExpandButtonImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatInputPanelExpandButtonImage.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat/Input/Text/IconExpandInput"), color: theme.chat.inputPanel.panelControlColor)
        })
    }
    
    static func chatInputPanelMediaRecordingDotImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatInputPanelMediaRecordingDotImage.rawValue, { theme in
            return generateFilledCircleImage(diameter: 9.0, color: theme.chat.inputPanel.mediaRecordingDotColor)
        })
    }
    
    static func chatInputPanelMediaRecordingCancelArrowImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatInputPanelMediaRecordingCancelArrowImage.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat/Input/Text/AudioRecordingCancelArrow"), color: theme.chat.inputPanel.panelControlColor)
        })
    }
    
    static func chatInputTextFieldStickersImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatInputTextFieldStickersImage.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat/Input/Text/AccessoryIconStickers"), color: theme.chat.inputPanel.inputControlColor)
        })
    }
    
    static func chatInputTextFieldInputButtonsImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatInputTextFieldInputButtonsImage.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat/Input/Text/AccessoryIconInputButtons"), color: theme.chat.inputPanel.inputControlColor)
        })
    }
    
    static func chatInputTextFieldCommandsImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatInputTextFieldCommandsImage.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat/Input/Text/AccessoryIconCommands"), color: theme.chat.inputPanel.inputControlColor)
        })
    }
    
    static func chatInputTextFieldSilentPostOnImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatInputTextFieldSilentPostOnImage.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat/Input/Text/AccessoryIconSilentPostOn"), color: theme.chat.inputPanel.inputControlColor)
        })
    }
    
    static func chatInputTextFieldSilentPostOffImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatInputTextFieldSilentPostOffImage.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat/Input/Text/AccessoryIconSilentPostOff"), color: theme.chat.inputPanel.inputControlColor)
        })
    }
    
    static func chatInputTextFieldKeyboardImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatInputTextFieldKeyboardImage.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat/Input/Text/AccessoryIconKeyboard"), color: theme.chat.inputPanel.inputControlColor)
        })
    }
    
    static func chatInputTextFieldTimerImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatInputTextFieldTimerImage.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat/Input/Text/AccessoryIconTimer"), color: theme.chat.inputPanel.inputControlColor)
        })
    }
    
    static func chatHistoryNavigationButtonImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatHistoryNavigationButtonImage.rawValue, { theme in
            return generateImage(CGSize(width: 38.0, height: 38.0), contextGenerator: { size, context in
                context.clear(CGRect(origin: CGPoint(), size: size))
                context.setFillColor(theme.chat.historyNavigation.fillColor.cgColor)
                context.fillEllipse(in: CGRect(origin: CGPoint(x: 0.5, y: 0.5), size: CGSize(width: size.width - 1.0, height: size.height - 1.0)))
                context.setLineWidth(0.5)
                context.setStrokeColor(theme.chat.historyNavigation.strokeColor.cgColor)
                context.strokeEllipse(in: CGRect(origin: CGPoint(x: 0.25, y: 0.25), size: CGSize(width: size.width - 0.5, height: size.height - 0.5)))
                context.setStrokeColor(theme.chat.historyNavigation.foregroundColor.cgColor)
                context.setLineWidth(1.5)
                
                let position = CGPoint(x: 9.0 - 0.5, y: 23.0)
                context.move(to: CGPoint(x: position.x + 1.0, y: position.y - 1.0))
                context.addLine(to: CGPoint(x: position.x + 10.0, y: position.y - 10.0))
                context.addLine(to: CGPoint(x: position.x + 19.0, y: position.y - 1.0))
                context.strokePath()
            })
        })
    }
    
    static func chatHistoryMentionsButtonImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatHistoryMentionsButtonImage.rawValue, { theme in
            return generateImage(CGSize(width: 38.0, height: 38.0), contextGenerator: { size, context in
                context.clear(CGRect(origin: CGPoint(), size: size))
                context.setFillColor(theme.chat.historyNavigation.fillColor.cgColor)
                context.fillEllipse(in: CGRect(origin: CGPoint(x: 0.5, y: 0.5), size: CGSize(width: size.width - 1.0, height: size.height - 1.0)))
                context.setLineWidth(0.5)
                context.setStrokeColor(theme.chat.historyNavigation.strokeColor.cgColor)
                context.strokeEllipse(in: CGRect(origin: CGPoint(x: 0.25, y: 0.25), size: CGSize(width: size.width - 0.5, height: size.height - 0.5)))
                
                if let image = generateTintedImage(image: UIImage(bundleImageName: "Chat/NavigateToMentions"), color: theme.chat.historyNavigation.foregroundColor), let cgImage = image.cgImage {
                    context.draw(cgImage, in: CGRect(origin: CGPoint(x: floor((size.width - image.size.width) / 2.0), y: floor((size.height - image.size.height) / 2.0)), size: image.size))
                }
            })
        })
    }
    
    static func chatHistoryNavigationButtonBadgeImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatHistoryNavigationButtonBadgeImage.rawValue, { theme in
            return generateStretchableFilledCircleImage(diameter: 18.0, color: theme.chat.historyNavigation.badgeBackgroundColor, strokeColor: theme.chat.historyNavigation.badgeStrokeColor, strokeWidth: 1.0, backgroundColor: nil)
        })
    }
    
    static func sharedMediaFileDownloadStartIcon(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.sharedMediaFileDownloadStartIcon.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "List Menu/ListDownloadStartIcon"), color: theme.list.itemAccentColor)
        })
    }
    
    static func sharedMediaFileDownloadPauseIcon(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.sharedMediaFileDownloadPauseIcon.rawValue, { theme in
            return generateImage(CGSize(width: 11.0, height: 11.0), contextGenerator: { size, context in
                context.clear(CGRect(origin: CGPoint(), size: size))
                
                context.setFillColor(theme.list.itemAccentColor.cgColor)
                
                context.fill(CGRect(x: 2.0, y: 0.0, width: 2.0, height: 11.0 - 1.0))
                context.fill(CGRect(x: 2.0 + 2.0 + 2.0, y: 0.0, width: 2.0, height: 11.0 - 1.0))
            })
        })
    }
    
    static func chatInfoCallButtonImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatInfoCallButtonImage.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat/Info/CallButton"), color: theme.list.itemAccentColor)
        })
    }
    
    static func chatInstantMessageInfoBackgroundImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatInstantMessageInfoBackgroundImage.rawValue, { theme in
            return generateImage(CGSize(width: 24.0, height: 24.0), rotatedContext: { size, context in
                context.clear(CGRect(origin: CGPoint(), size: size))
                context.setFillColor(theme.chat.bubble.mediaDateAndStatusFillColor.cgColor)
                context.fillEllipse(in: CGRect(origin: CGPoint(), size: size))
            })?.stretchableImage(withLeftCapWidth: 12, topCapHeight: 12)
        })
    }
    
    static func chatInstantMessageMuteIconImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatInstantMessageMuteIconImage.rawValue, { theme in
            return generateImage(CGSize(width: 24.0, height: 24.0), rotatedContext: { size, context in
                context.clear(CGRect(origin: CGPoint(), size: size))
                
                if let image = generateTintedImage(image: UIImage(bundleImageName: "Chat/Message/InstantVideoMute"), color: .white, backgroundColor: nil) {
                    context.draw(image.cgImage!, in: CGRect(origin: CGPoint(x: floor((size.width - image.size.width) / 2.0), y: floor((size.height - image.size.height) / 2.0)), size: image.size))
                }
            })
        })
    }
    
    static func chatBubbleIncomingCallButtonImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatBubbleIncomingCallButtonImage.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat/Info/CallButton"), color: theme.chat.bubble.incomingAccentControlColor)
        })
    }
    
    static func chatBubbleOutgoingCallButtonImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatBubbleOutgoingCallButtonImage.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat/Info/CallButton"), color: theme.chat.bubble.outgoingAccentControlColor)
        })
    }
    
    static func chatBubbleMapPinImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatBubbleMapPinImage.rawValue, { theme in
            return generateImage(CGSize(width: 62.0, height: 74.0), contextGenerator: { size, context in
                context.clear(CGRect(origin: CGPoint(), size: size))
                if let shadowImage = UIImage(bundleImageName: "Chat/Message/LocationPinShadow"), let cgImage = shadowImage.cgImage {
                    context.draw(cgImage, in: CGRect(origin: CGPoint(), size: shadowImage.size))
                }
                if let backgroundImage = generateTintedImage(image: UIImage(bundleImageName: "Chat/Message/LocationPinBackground"), color: theme.list.itemAccentColor), let cgImage = backgroundImage.cgImage {
                    context.draw(cgImage, in: CGRect(origin: CGPoint(), size: backgroundImage.size))
                }
                if let foregroundImage = generateTintedImage(image: UIImage(bundleImageName: "Chat/Message/LocationPinForeground"), color: theme.list.plainBackgroundColor), let cgImage = foregroundImage.cgImage {
                    context.draw(cgImage, in: CGRect(origin: CGPoint(x: 15.0, y: 26.0), size: foregroundImage.size))
                }
            })
        })
    }
    
    static func chatInputSearchPanelUpImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatInputSearchPanelUpImage.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat/Input/Search/UpButton"), color: theme.chat.inputPanel.panelControlAccentColor)
        })
    }
    
    static func chatInputSearchPanelUpDisabledImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatInputSearchPanelUpDisabledImage.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat/Input/Search/UpButton"), color: theme.chat.inputPanel.panelControlDisabledColor)
        })
    }
    
    static func chatInputSearchPanelDownImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatInputSearchPanelDownImage.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat/Input/Search/DownButton"), color: theme.chat.inputPanel.panelControlAccentColor)
        })
    }
    
    static func chatInputSearchPanelDownDisabledImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatInputSearchPanelDownDisabledImage.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat/Input/Search/DownButton"), color: theme.chat.inputPanel.panelControlDisabledColor)
        })
    }
    
    static func chatInputSearchPanelCalendarImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatInputSearchPanelCalendarImage.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat/Input/Search/Calendar"), color: theme.chat.inputPanel.panelControlAccentColor)
        })
    }
    
    static func chatInputSearchPanelMembersImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatInputSearchPanelMembersImage.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat/Input/Search/Members"), color: theme.chat.inputPanel.panelControlAccentColor)
        })
    }
    
    static func chatTitlePanelInfoImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatTitlePanelInfoImage.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat/Title Panels/InfoIcon"), color: theme.chat.inputPanel.panelControlAccentColor)
        })
    }
    
    static func chatTitlePanelSearchImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatTitlePanelSearchImage.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat/Title Panels/SearchIcon"), color: theme.chat.inputPanel.panelControlAccentColor)
        })
    }
    
    static func chatTitlePanelMuteImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatTitlePanelMuteImage.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat List/RevealActionMuteIcon"), color: theme.chat.inputPanel.panelControlAccentColor)
        })
    }
    
    static func chatTitlePanelUnmuteImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatTitlePanelUnmuteImage.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat List/RevealActionUnmuteIcon"), color: theme.chat.inputPanel.panelControlAccentColor)
        })
    }
    
    static func chatTitlePanelCallImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatTitlePanelCallImage.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat/Info/CallButton"), color: theme.chat.inputPanel.panelControlAccentColor)
        })
    }
    
    static func chatTitlePanelReportImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatTitlePanelReportImage.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat/Title Panels/ReportIcon"), color: theme.chat.inputPanel.panelControlAccentColor)
        })
    }
    
    static func chatTitlePanelGroupingImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatTitlePanelGroupingImage.rawValue, { theme in
            return generateImage(CGSize(width: 32.0, height: 32.0), rotatedContext: { size, context in
                context.clear(CGRect(origin: CGPoint(), size: size))
                
                if let image = generateTintedImage(image: UIImage(bundleImageName: "Chat List/RevealActionGroupIcon"), color: theme.chat.inputPanel.panelControlAccentColor) {
                    context.draw(image.cgImage!, in: CGRect(origin: CGPoint(x: floor((size.width - image.size.width) / 2.0), y: floor((size.height - image.size.height) / 2.0) - 3.0), size: image.size))
                }
            })
        })
    }
    
    static func chatMessageAttachedContentButtonIncoming(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatMessageAttachedContentButtonIncoming.rawValue, { theme in
            return generateStretchableFilledCircleImage(diameter: 9.0, color: nil, strokeColor: theme.chat.bubble.incomingAccentControlColor, strokeWidth: 1.0, backgroundColor: nil)
        })
    }
    
    static func chatMessageAttachedContentHighlightedButtonIncoming(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatMessageAttachedContentHighlightedButtonIncoming.rawValue, { theme in
            return generateStretchableFilledCircleImage(diameter: 9.0, color: theme.chat.bubble.incomingAccentControlColor)
        })
    }
    
    static func chatMessageAttachedContentButtonOutgoing(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatMessageAttachedContentButtonOutgoing.rawValue, { theme in
            return generateStretchableFilledCircleImage(diameter: 9.0, color: nil, strokeColor: theme.chat.bubble.outgoingAccentControlColor, strokeWidth: 1.0, backgroundColor: nil)
        })
    }
    
    static func chatMessageAttachedContentHighlightedButtonOutgoing(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatMessageAttachedContentHighlightedButtonOutgoing.rawValue, { theme in
            return generateStretchableFilledCircleImage(diameter: 9.0, color: theme.chat.bubble.outgoingAccentControlColor)
        })
    }
    
    static func chatMessageAttachedContentButtonIconInstantIncoming(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatMessageAttachedContentButtonIconInstantIncoming.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat/Message/AttachedContentInstantIcon"), color: theme.chat.bubble.incomingAccentControlColor)
        })
    }
    
    static func chatMessageAttachedContentHighlightedButtonIconInstantIncoming(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatMessageAttachedContentHighlightedButtonIconInstantIncoming.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat/Message/AttachedContentInstantIcon"), color: theme.chat.bubble.incomingFillColor)
        })
    }
    
    static func chatMessageAttachedContentButtonIconInstantOutgoing(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatMessageAttachedContentButtonIconInstantOutgoing.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat/Message/AttachedContentInstantIcon"), color: theme.chat.bubble.outgoingAccentControlColor)
        })
    }
    
    static func chatMessageAttachedContentHighlightedButtonIconInstantOutgoing(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatMessageAttachedContentHighlightedButtonIconInstantOutgoing.rawValue, { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat/Message/AttachedContentInstantIcon"), color: theme.chat.bubble.outgoingFillColor)
        })
    }
    
    static func chatLoadingIndicatorBackgroundImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatLoadingIndicatorBackgroundImage.rawValue, { theme in
            return generateStretchableFilledCircleImage(diameter: 30.0, color: theme.chat.serviceMessage.serviceMessageFillColor)
        })
    }
    
    static func chatBubbleReplyThumbnailPlayImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatBubbleReplyThumbnailPlayImage.rawValue, { theme in
            return generateImage(CGSize(width: 16.0, height: 16.0), rotatedContext: { size, context in
                context.clear(CGRect(origin: CGPoint(), size: size))
                context.setFillColor(UIColor(white: 0.0, alpha: 0.5).cgColor)
                context.fillEllipse(in: CGRect(origin: CGPoint(), size: size))
                
                let diameter = size.width
                
                context.setFillColor(UIColor(white: 1.0, alpha: 1.0).cgColor)
                
                context.translateBy(x: -2.0, y: -1.0)
                
                let size = CGSize(width: 10.0, height: 13.0)
                context.translateBy(x: (diameter - size.width) / 2.0 + 1.5, y: (diameter - size.height) / 2.0)
                
                context.translateBy(x: size.width / 2.0, y: size.height / 2.0)
                context.scaleBy(x: 0.4, y: 0.4)
                context.translateBy(x: -size.width / 2.0, y: -size.height / 2.0)
                
                let _ = try? drawSvgPath(context, path: "M1.71891969,0.209353049 C0.769586558,-0.350676705 0,0.0908839327 0,1.18800046 L0,16.8564753 C0,17.9569971 0.750549162,18.357187 1.67393713,17.7519379 L14.1073836,9.60224049 C15.0318735,8.99626906 15.0094718,8.04970371 14.062401,7.49100858 L1.71891969,0.209353049 ")
                context.fillPath()
                
                context.translateBy(x: size.width / 2.0, y: size.height / 2.0)
                context.scaleBy(x: 1.0 / 0.4, y: 1.0 / 0.4)
                context.translateBy(x: -size.width / 2.0, y: -size.height / 2.0)
                
                context.translateBy(x: -(diameter - size.width) / 2.0 - 1.5, y: -(diameter - size.height) / 2.0)
            })
        })
    }
    
    static func chatCommandPanelArrowImage(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatCommandPanelArrowImage.rawValue, { theme in
            return generateImage(CGSize(width: 11.0, height: 11.0), contextGenerator: { size, context in
                context.clear(CGRect(origin: CGPoint(), size: size))
                context.translateBy(x: size.width / 2.0, y: size.height / 2.0)
                context.scaleBy(x: 1.0, y: -1.0)
                context.translateBy(x: -size.width / 2.0, y: -size.height / 2.0)
                
                context.setStrokeColor(theme.list.disclosureArrowColor.cgColor)
                context.setLineCap(.round)
                context.setLineJoin(.round)
                context.setLineWidth(2.0)
                context.setLineJoin(.round)
                
                context.beginPath()
                context.move(to: CGPoint(x: 1.0, y: 2.0))
                context.addLine(to: CGPoint(x: 1.0, y: 10.0))
                context.addLine(to: CGPoint(x: 9.0, y: 10.0))
                context.strokePath()
                
                context.beginPath()
                context.move(to: CGPoint(x: 1.0, y: 10.0))
                context.addLine(to: CGPoint(x: 10.0, y: 1.0))
                context.strokePath()
            })
        })
    }
    
    static func chatSelectionButtonChecked(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatSelectionButtonChecked.rawValue, { theme in
            return generateImage(CGSize(width: 22.0, height: 22.0), rotatedContext: { size, context in
                context.clear(CGRect(origin: CGPoint(), size: size))
                
                context.setFillColor(theme.chat.bubble.selectionControlFillColor.cgColor)
                context.fillEllipse(in: CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: CGSize(width: size.width, height: size.height)))
                
                context.setStrokeColor(theme.chat.bubble.selectionControlForegroundColor.cgColor)
                context.setLineWidth(1.66)
                context.setLineCap(.round)
                context.setLineJoin(.round)
                let _ = try? drawSvgPath(context, path: "M6.22222222,11.5124378 L9.43201945,14.722235 L9.43201945,14.722235 C9.47068136,14.7608969 9.53336469,14.7608969 9.57202659,14.722235 C9.57325367,14.721008 9.57444826,14.7197488 9.57560914,14.718459 L16.2222222,7.33333333 S ")
            })
        })
    }
    
    static func chatSelectionButtonUnchecked(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatSelectionButtonUnchecked.rawValue, { theme in
            return generateImage(CGSize(width: 22.0, height: 22.0), rotatedContext: { size, context in
                context.clear(CGRect(origin: CGPoint(), size: size))
                
                context.setStrokeColor(theme.chat.bubble.selectionControlBorderColor.cgColor)
                context.setLineWidth(1.0)
                context.strokeEllipse(in: CGRect(origin: CGPoint(x: 0.5, y: 0.5), size: CGSize(width: size.width - 1.0, height: size.height - 1.0)))
            })
        })
    }
    
    static func chatEmptyItemLockIcon(_ theme: PresentationTheme) -> UIImage? {
        return theme.image(PresentationResourceKey.chatEmptyItemLockIcon.rawValue, { theme in
            return generateImage(CGSize(width: 9.0, height: 13.0), rotatedContext: { size, context in
                context.clear(CGRect(origin: CGPoint(), size: size))
                
                context.translateBy(x: 0.0, y: 1.0)
                
                context.setFillColor(theme.chat.serviceMessage.serviceMessagePrimaryTextColor.cgColor)
                context.setStrokeColor(theme.chat.serviceMessage.serviceMessagePrimaryTextColor.cgColor)
                context.setLineWidth(1.32)
                
                let _ = try? drawSvgPath(context, path: "M4.5,0.600000024 C5.88071187,0.600000024 7,1.88484952 7,3.46979169 L7,7.39687502 C7,8.9818172 5.88071187,10.2666667 4.5,10.2666667 C3.11928813,10.2666667 2,8.9818172 2,7.39687502 L2,3.46979169 C2,1.88484952 3.11928813,0.600000024 4.5,0.600000024 S ")
                let _ = try? drawSvgPath(context, path: "M1.32,5.65999985 L7.68,5.65999985 C8.40901587,5.65999985 9,6.25098398 9,6.97999985 L9,10.6733332 C9,11.4023491 8.40901587,11.9933332 7.68,11.9933332 L1.32,11.9933332 C0.59098413,11.9933332 1.11022302e-16,11.4023491 0,10.6733332 L2.22044605e-16,6.97999985 C1.11022302e-16,6.25098398 0.59098413,5.65999985 1.32,5.65999985 Z ")
            })
        })
    }
}
