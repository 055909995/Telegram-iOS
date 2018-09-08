import Foundation
import SwiftSignalKit
import Postbox
import TelegramCore

public enum PresentationTimeFormat {
    case regular
    case military
}

public final class PresentationData: Equatable {
    public let strings: PresentationStrings
    public let theme: PresentationTheme
    public let chatWallpaper: TelegramWallpaper
    public let fontSize: PresentationFontSize
    public let timeFormat: PresentationTimeFormat
    
    public init(strings: PresentationStrings, theme: PresentationTheme, chatWallpaper: TelegramWallpaper, fontSize: PresentationFontSize, timeFormat: PresentationTimeFormat) {
        self.strings = strings
        self.theme = theme
        self.chatWallpaper = chatWallpaper
        self.fontSize = fontSize
        self.timeFormat = timeFormat
    }
    
    public static func ==(lhs: PresentationData, rhs: PresentationData) -> Bool {
        return lhs.strings === rhs.strings && lhs.theme === rhs.theme && lhs.chatWallpaper == rhs.chatWallpaper && lhs.fontSize == rhs.fontSize && lhs.timeFormat == rhs.timeFormat
    }
}

func dictFromLocalization(_ value: Localization) -> [String: String] {
    var dict: [String: String] = [:]
    for entry in value.entries {
        switch entry {
            case let .string(key, value):
                dict[key] = value
            case let .pluralizedString(key, zero, one, two, few, many, other):
                if let zero = zero {
                    dict["\(key)_zero"] = zero
                }
                if let one = one {
                    dict["\(key)_1"] = one
                }
                if let two = two {
                    dict["\(key)_2"] = two
                }
                if let few = few {
                    dict["\(key)_3_10"] = few
                }
                if let many = many {
                    dict["\(key)_many"] = many
                }
                dict["\(key)_any"] = other
        }
    }
    return dict
}

private func currentTimeFormat() -> PresentationTimeFormat {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale.current
    dateFormatter.dateStyle = .none
    dateFormatter.timeStyle = .medium
    dateFormatter.timeZone = TimeZone.current
    let dateString = dateFormatter.string(from: Date())
    
    if dateString.contains(dateFormatter.amSymbol) || dateString.contains(dateFormatter.pmSymbol) {
        return .regular
    } else {
        return .military
    }
}

public final class InitialPresentationDataAndSettings {
    public let presentationData: PresentationData
    public let automaticMediaDownloadSettings: AutomaticMediaDownloadSettings
    public let loggingSettings: LoggingSettings
    public let callListSettings: CallListSettings
    public let inAppNotificationSettings: InAppNotificationSettings
    public let mediaInputSettings: MediaInputSettings
    public let experimentalUISettings: ExperimentalUISettings
    
    init(presentationData: PresentationData, automaticMediaDownloadSettings: AutomaticMediaDownloadSettings, loggingSettings: LoggingSettings, callListSettings: CallListSettings, inAppNotificationSettings: InAppNotificationSettings, mediaInputSettings: MediaInputSettings, experimentalUISettings: ExperimentalUISettings) {
        self.presentationData = presentationData
        self.automaticMediaDownloadSettings = automaticMediaDownloadSettings
        self.loggingSettings = loggingSettings
        self.callListSettings = callListSettings
        self.inAppNotificationSettings = inAppNotificationSettings
        self.mediaInputSettings = mediaInputSettings
        self.experimentalUISettings = experimentalUISettings
    }
}

public func currentPresentationDataAndSettings(postbox: Postbox) -> Signal<InitialPresentationDataAndSettings, NoError> {
    return postbox.transaction { transaction -> (PresentationThemeSettings, LocalizationSettings?, AutomaticMediaDownloadSettings, LoggingSettings, CallListSettings, InAppNotificationSettings, MediaInputSettings, ExperimentalUISettings) in
        let themeSettings: PresentationThemeSettings
        if let current = transaction.getPreferencesEntry(key: ApplicationSpecificPreferencesKeys.presentationThemeSettings) as? PresentationThemeSettings {
            themeSettings = current
        } else {
            themeSettings = PresentationThemeSettings.defaultSettings
        }
        
        let localizationSettings: LocalizationSettings?
        if let current = transaction.getPreferencesEntry(key: PreferencesKeys.localizationSettings) as? LocalizationSettings {
            localizationSettings = current
        } else {
            localizationSettings = nil
        }
        
        let automaticMediaDownloadSettings: AutomaticMediaDownloadSettings
        if let value = transaction.getPreferencesEntry(key: ApplicationSpecificPreferencesKeys.automaticMediaDownloadSettings) as? AutomaticMediaDownloadSettings {
            automaticMediaDownloadSettings = value
        } else {
            automaticMediaDownloadSettings = AutomaticMediaDownloadSettings.defaultSettings
        }
        
        let loggingSettings: LoggingSettings
        if let value = transaction.getPreferencesEntry(key: PreferencesKeys.loggingSettings) as? LoggingSettings {
            loggingSettings = value
        } else {
            loggingSettings = LoggingSettings.defaultSettings
        }
        
        let callListSettings: CallListSettings
        if let value = transaction.getPreferencesEntry(key: ApplicationSpecificPreferencesKeys.callListSettings) as? CallListSettings {
            callListSettings = value
        } else {
            callListSettings = CallListSettings.defaultSettings
        }
        
        let inAppNotificationSettings: InAppNotificationSettings
        if let value = transaction.getPreferencesEntry(key: ApplicationSpecificPreferencesKeys.inAppNotificationSettings) as? InAppNotificationSettings {
            inAppNotificationSettings = value
        } else {
            inAppNotificationSettings = InAppNotificationSettings.defaultSettings
        }
        
        let mediaInputSettings: MediaInputSettings
        if let value = transaction.getPreferencesEntry(key: ApplicationSpecificPreferencesKeys.mediaInputSettings) as? MediaInputSettings {
            mediaInputSettings = value
        } else {
            mediaInputSettings = MediaInputSettings.defaultSettings
        }
        
        let experimentalUISettings: ExperimentalUISettings = (transaction.getPreferencesEntry(key: ApplicationSpecificPreferencesKeys.experimentalUISettings) as? ExperimentalUISettings) ?? ExperimentalUISettings.defaultSettings
        
        return (themeSettings, localizationSettings, automaticMediaDownloadSettings, loggingSettings, callListSettings, inAppNotificationSettings, mediaInputSettings, experimentalUISettings)
    }
    |> map { (themeSettings, localizationSettings, automaticMediaDownloadSettings, loggingSettings, callListSettings, inAppNotificationSettings, mediaInputSettings, experimentalUISettings) -> InitialPresentationDataAndSettings in
        let themeValue: PresentationTheme
        
        let effectiveTheme: PresentationThemeReference
        var effectiveChatWallpaper: TelegramWallpaper = themeSettings.chatWallpaper
        
        if automaticThemeShouldSwitchNow(themeSettings.automaticThemeSwitchSetting, currentTheme: themeSettings.theme) {
            effectiveTheme = .builtin(themeSettings.automaticThemeSwitchSetting.theme)
            switch themeSettings.automaticThemeSwitchSetting.theme {
                case .nightAccent:
                    effectiveChatWallpaper = .color(0x18222D)
                case .nightGrayscale:
                    effectiveChatWallpaper = .color(0x000000)
                default:
                    break
            }
        } else {
            effectiveTheme = themeSettings.theme
        }
        
        switch effectiveTheme {
            case let .builtin(reference):
                switch reference {
                    case .dayClassic:
                        themeValue = defaultPresentationTheme
                    case .nightGrayscale:
                        themeValue = defaultDarkPresentationTheme
                    case .nightAccent:
                        themeValue = defaultDarkAccentPresentationTheme
                    case .day:
                        themeValue = makeDefaultDayPresentationTheme(accentColor: themeSettings.themeAccentColor ?? defaultDayAccentColor)
                }
        }
        let stringsValue: PresentationStrings
        if let localizationSettings = localizationSettings {
            stringsValue = PresentationStrings(languageCode: localizationSettings.languageCode, dict: dictFromLocalization(localizationSettings.localization))
        } else {
            stringsValue = defaultPresentationStrings
        }
        let timeFormat = currentTimeFormat()
        return InitialPresentationDataAndSettings(presentationData: PresentationData(strings: stringsValue, theme: themeValue, chatWallpaper: effectiveChatWallpaper, fontSize: themeSettings.fontSize, timeFormat: timeFormat), automaticMediaDownloadSettings: automaticMediaDownloadSettings, loggingSettings: loggingSettings, callListSettings: callListSettings, inAppNotificationSettings: inAppNotificationSettings, mediaInputSettings: mediaInputSettings, experimentalUISettings: experimentalUISettings)
    }
}

private var first = true

private func roundTimeToDay(_ timestamp: Int32) -> Int32 {
    let calendar = Calendar.current
    let offset = 0
    let components = calendar.dateComponents([.hour, .minute, .second], from: Date(timeIntervalSince1970: Double(timestamp + Int32(offset))))
    return Int32(components.hour! * 60 * 60 + components.minute! * 60 + components.second!)
}

private func automaticThemeShouldSwitchNow(_ settings: AutomaticThemeSwitchSetting, currentTheme: PresentationThemeReference) -> Bool {
    switch currentTheme {
        case let .builtin(builtin):
            switch builtin {
                case .nightAccent, .nightGrayscale:
                    return false
                default:
                    break
            }
    }
    switch settings.trigger {
        case .none:
            return false
        case let .timeBased(setting):
            let fromValue: Int32
            let toValue: Int32
            switch setting {
                case let .automatic(automatic):
                    fromValue = automatic.sunset
                    toValue = automatic.sunrise
                case let .manual(fromSeconds, toSeconds):
                    fromValue = fromSeconds
                    toValue = toSeconds
            }
            let roundedTimestamp = roundTimeToDay(Int32(Date().timeIntervalSince1970))
            if roundedTimestamp >= fromValue || roundedTimestamp <= toValue {
                return true
            } else {
                return false
            }
        case let .brightness(threshold):
            return UIScreen.main.brightness <= CGFloat(threshold)
    }
}

private func automaticThemeShouldSwitch(_ settings: AutomaticThemeSwitchSetting, currentTheme: PresentationThemeReference) -> Signal<Bool, NoError> {
    if case .none = settings.trigger {
        return .single(false)
    } else {
        return Signal { subscriber in
            subscriber.putNext(automaticThemeShouldSwitchNow(settings, currentTheme: currentTheme))
            
            let timer = SwiftSignalKit.Timer(timeout: 1.0, repeat: true, completion: {
                subscriber.putNext(automaticThemeShouldSwitchNow(settings, currentTheme: currentTheme))
            }, queue: Queue.mainQueue())
            timer.start()
            
            return ActionDisposable {
                timer.invalidate()
            }
        }
        |> runOn(Queue.mainQueue())
        |> distinctUntilChanged
    }
}

public func updatedPresentationData(postbox: Postbox) -> Signal<PresentationData, NoError> {
    let preferencesKey = PostboxViewKey.preferences(keys: Set([ApplicationSpecificPreferencesKeys.presentationThemeSettings, PreferencesKeys.localizationSettings]))
    return postbox.combinedView(keys: [preferencesKey])
    |> mapToSignal { view -> Signal<PresentationData, NoError> in
        let themeSettings: PresentationThemeSettings
        if let current = (view.views[preferencesKey] as! PreferencesView).values[ApplicationSpecificPreferencesKeys.presentationThemeSettings] as? PresentationThemeSettings {
            themeSettings = current
        } else {
            themeSettings = PresentationThemeSettings.defaultSettings
        }
        
        return automaticThemeShouldSwitch(themeSettings.automaticThemeSwitchSetting, currentTheme: themeSettings.theme)
        |> distinctUntilChanged
        |> map { shouldSwitch in
            let themeValue: PresentationTheme
            let effectiveTheme: PresentationThemeReference
            var effectiveChatWallpaper: TelegramWallpaper = themeSettings.chatWallpaper
            if shouldSwitch {
                effectiveTheme = .builtin(themeSettings.automaticThemeSwitchSetting.theme)
                switch themeSettings.automaticThemeSwitchSetting.theme {
                    case .nightAccent:
                        effectiveChatWallpaper = .color(0x18222D)
                    case .nightGrayscale:
                        effectiveChatWallpaper = .color(0x000000)
                    default:
                        break
                }
            } else {
                effectiveTheme = themeSettings.theme
            }
            switch effectiveTheme {
                case let .builtin(reference):
                    switch reference {
                        case .dayClassic:
                            themeValue = defaultPresentationTheme
                        case .nightGrayscale:
                            themeValue = defaultDarkPresentationTheme
                        case .nightAccent:
                            themeValue = defaultDarkAccentPresentationTheme
                        case .day:
                            themeValue = makeDefaultDayPresentationTheme(accentColor: themeSettings.themeAccentColor ?? defaultDayAccentColor)
                    }
            }
            
            let localizationSettings: LocalizationSettings?
            if let current = (view.views[preferencesKey] as! PreferencesView).values[PreferencesKeys.localizationSettings] as? LocalizationSettings {
                localizationSettings = current
            } else {
                localizationSettings = nil
            }
            
            let stringsValue: PresentationStrings
            if let localizationSettings = localizationSettings {
                stringsValue = PresentationStrings(languageCode: localizationSettings.languageCode, dict: dictFromLocalization(localizationSettings.localization))
            } else {
                stringsValue = defaultPresentationStrings
            }
            
            let timeFormat = currentTimeFormat()
            
            return PresentationData(strings: stringsValue, theme: themeValue, chatWallpaper: effectiveChatWallpaper, fontSize: themeSettings.fontSize, timeFormat: timeFormat)
        }
    }
}
