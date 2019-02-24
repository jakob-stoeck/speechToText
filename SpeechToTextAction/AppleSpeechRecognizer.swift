//
//  AppleSpeechRecognizer.swift
//  SpeechToTextAction
//
//  Created by jaksto on 2/24/19.
//  Copyright © 2019 Jakob Stoeck. All rights reserved.
//

import Foundation

import Speech
import UserNotifications
import os.log

class AppleSpeechRecognizer: SpeechRecognizer {
    
    class func supports(url: URL) -> Bool {
        let supportedFormats = ["aac", "adts", "ac3", "aif", "aiff", "aifc", "caf", "mp3", "mp4", "m4a", "snd", "au", "sd2", "wav"]
        return supportedFormats.contains(url.pathExtension)
    }
    
    static func recognize(url: URL, lang: String, onUpdate: @escaping (String) -> (), onEnd: @escaping (String) -> (), onError: @escaping (String) -> ()) {
        askPermission()
        let localeID = lang.replacingOccurrences(of: "-", with: "_")
        guard let recognizer = SFSpeechRecognizer(locale: Locale.init(identifier: localeID)) else {
            Util.errorHandler(NSLocalizedString("speech.apple.locale", value: "Locale not supported", comment: "Apple SR does not support the current locale"))
            return
        }
        if !recognizer.isAvailable {
            Util.errorHandler(NSLocalizedString("speech.apple.availability", value: "not available, e.g. no internet", comment: "Apple SR is not available"))
            return
        }
        let request = SFSpeechURLRecognitionRequest(url: url)
        os_log("asking apple", log: OSLog.default, type: .debug)
        recognizer.recognitionTask(with: request) { (result, error) in
            guard let result = result else {
                Util.errorHandler(error!.localizedDescription)
                return
            }
            if result.isFinal {
                onEnd(result.bestTranscription.formattedString)
            }
            else {
                onUpdate(result.bestTranscription.formattedString)
            }
        }
    }
    
    class func askPermission() {
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            if authStatus != .authorized {
                Util.errorHandler(NSLocalizedString("speech.apple.unauthorized", value: "Speech recognition was not authorized", comment: "Apple SR was unauthorized"))
            }
        }
    }

}
