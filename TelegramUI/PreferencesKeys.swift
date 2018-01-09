import Foundation
import TelegramCore
import Postbox

private enum ApplicationSpecificPreferencesKeyValues: Int32 {
    case inAppNotificationSettings = 0
    case presentationPasscodeSettings = 1
    case automaticMediaDownloadSettings = 2
    case generatedMediaStoreSettings = 3
    case voiceCallSettings = 4
    case presentationThemeSettings = 5
    case instantPagePresentationSettings = 6
    case callListSettings = 7
    case experimentalSettings = 8
    case musicPlaybackSettings = 9
}

public struct ApplicationSpecificPreferencesKeys {
    public static let inAppNotificationSettings = applicationSpecificPreferencesKey(ApplicationSpecificPreferencesKeyValues.inAppNotificationSettings.rawValue)
    public static let presentationPasscodeSettings = applicationSpecificPreferencesKey(ApplicationSpecificPreferencesKeyValues.presentationPasscodeSettings.rawValue)
    public static let automaticMediaDownloadSettings = applicationSpecificPreferencesKey(ApplicationSpecificPreferencesKeyValues.automaticMediaDownloadSettings.rawValue)
    public static let generatedMediaStoreSettings = applicationSpecificPreferencesKey(ApplicationSpecificPreferencesKeyValues.generatedMediaStoreSettings.rawValue)
    public static let voiceCallSettings = applicationSpecificPreferencesKey(ApplicationSpecificPreferencesKeyValues.voiceCallSettings.rawValue)
    public static let presentationThemeSettings = applicationSpecificPreferencesKey(ApplicationSpecificPreferencesKeyValues.presentationThemeSettings.rawValue)
    public static let instantPagePresentationSettings = applicationSpecificPreferencesKey(ApplicationSpecificPreferencesKeyValues.instantPagePresentationSettings.rawValue)
    public static let callListSettings = applicationSpecificPreferencesKey(ApplicationSpecificPreferencesKeyValues.callListSettings.rawValue)
    public static let experimentalSettings = applicationSpecificPreferencesKey(ApplicationSpecificPreferencesKeyValues.experimentalSettings.rawValue)
    public static let musicPlaybackSettings = applicationSpecificPreferencesKey(ApplicationSpecificPreferencesKeyValues.musicPlaybackSettings.rawValue)
}
