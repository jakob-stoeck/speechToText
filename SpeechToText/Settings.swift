//
//  Settings.swift
//  SpeechToText
//
//  Created by Jakob Stoeck on 9/6/17.
//  Copyright © 2017 Jakob Stoeck. All rights reserved.
//

import Foundation
import os.log

class Settings {
    static let appGroup = "group.de.jakobstoeck.voicetotext"
    static let defaults = UserDefaults(suiteName: Settings.appGroup)!
    static let languagePrefKey = "language_preference"

    class func getLanguage() -> String {
        return defaults.string(forKey: languagePrefKey)!
    }

    class func setDefaultLanguage() {
        let validValues = getValidValues(forKey: languagePrefKey)
        let fallback = "en-US"
        // get language from explicit settings or implicitly by locale
        // if the exact language region is not available choose a similar
        let normLang =
            getNormalizedLanguage(code: defaults.string(forKey: languagePrefKey), values: validValues) ??
            getNormalizedLanguage(code: Locale.preferredLanguages.first, values: validValues) ??
            fallback
        defaults.set(normLang, forKey: languagePrefKey)
    }

    // en-US -> en
    class func getLanguagePart(_ code: String) -> String {
        return code.components(separatedBy: "-").first!
    }

    // iOS versions have different behavior such as returning de-US, en_GB, en etc.
    // return a specifier which conforms to the values array e.g. "en-US"
    class func getNormalizedLanguage(code: String?, values: Array<String>) -> String? {
        guard code != nil else {
            return nil
        }
        let norm = code!.replacingOccurrences(of: "_", with: "-")
        if values.contains(norm) {
            // language code is in valid values
            return norm
        }
        else {
            // language code may not be in valid values but there might be the same language with another
            // region specifier, e.g. de-US might not exist but de-DE does
            let langPart = getLanguagePart(norm)
            for v in values {
                if getLanguagePart(v) == langPart {
                    return v
                }
            }
        }
        return nil
    }

    class func getSettingsFromSettingsBundle() -> Array<Dictionary<String, AnyObject>> {
        guard let settingsBundle = Bundle.main.path(forResource: "Settings", ofType: "bundle") else {
            os_log("Could not locate Settings.bundle", log: OSLog.default, type: .debug)
            return []
        }

        guard let settings = NSDictionary(contentsOfFile: settingsBundle+"/Root.plist") else {
            os_log("Could not read Root.plist", log: OSLog.default, type: .debug)
            return []
        }

        return settings["PreferenceSpecifiers"] as! Array<Dictionary<String, AnyObject>>
    }

    class func getValidValues(forKey: String) -> Array<String> {
        let preferences = getSettingsFromSettingsBundle()
        for pref in preferences {
            // [Key: language_preference, DefaultValue: abc, ...]
            guard let key = pref["Key"] as? String, let values = pref["Values"] as? Array<String> else {
                continue
            }
            if (key == forKey) {
                return values
            }
        }
        return []
    }
}
