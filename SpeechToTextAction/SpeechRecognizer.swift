//
//  SpeechRecognizer.swift
//  SpeechToText
//
//  Created by Jakob Stoeck on 9/13/17.
//  Copyright © 2017 Jakob Stoeck. All rights reserved.
//

import UIKit
import MobileCoreServices
import Speech
import UserNotifications
import os.log

class SpeechRecognizer {

    class func recognizeFile(url: URL, completionHandler: @escaping (Transcript) -> ()) {
        os_log("voice file url: %@", log: OSLog.default, type: .debug, url.absoluteString)
        let googleFormats = ["opus", "flac", "ogg"]
        // let appleFormats = ["aac", "adts", "ac3", "aif", "aiff", "aifc", "caf", "mp3", "mp4", "m4a", "snd", "au", "sd2", "wav"]

        if googleFormats.contains(url.pathExtension) {
            SpeechRecognizer.recognizeFileGoogle(url: url, completionHandler: completionHandler)
        }
        else {
            SpeechRecognizer.recognizeFileApple(url: url, completionHandler: completionHandler)
        }
    }

    class func recognizeFileApple(url: URL, completionHandler: @escaping (Transcript) -> ()) {
        askPermission()
        let localeID = Settings.getLanguage().replacingOccurrences(of: "-", with: "_")
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
                guard let transcript = Transcript.init(result.bestTranscription.formattedString) else {
                    Util.errorHandler(NSLocalizedString("speech.apple.parsing", value: "Result parsing failed", comment: "Apple SR returned an unknown response"))
                    return
                }
                completionHandler(transcript)
            }
        }
    }

    class func recognizeFileGoogle(url: URL, completionHandler: @escaping (Transcript) -> ()) {
        guard let audioContent = try? Data(contentsOf: url).base64EncodedString() else {
            Util.errorHandler(NSLocalizedString("speech.google.loading", value: "Cannot read audio file", comment: "Audio file is not readable"))
            return
        }
        let size = Double(audioContent.lengthOfBytes(using: .ascii))
        let maxSize = 5e7
        if size > maxSize {
            Util.errorHandler(NSLocalizedString("speech.google.toobig", value: "File too big", comment: "Audio file is too big"))
        }

        let suffixToEncoding = [
            "ogg": "OGG_OPUS",
            "opus": "OGG_OPUS",
            "flac": "FLAC",
        ]

        guard let audioCode = suffixToEncoding[url.pathExtension] else {
            Util.errorHandler(NSLocalizedString("speech.google.format", value: "Format unsupported", comment: "Google was requested with unsupported format"))
            return
        }

        let data = [
            "audio": [
                "content": audioContent
            ],
            "config": [
                "languageCode": Settings.getLanguage(),
                "encoding": audioCode,
                "sampleRateHertz": 16000
            ]
        ]

        guard JSONSerialization.isValidJSONObject(data) else {
            Util.errorHandler(NSLocalizedString("speech.google.json", value: "Request failed", comment: "Google request could not be built"))
            return
        }

        guard let json = try? JSONSerialization.data(withJSONObject: data) else {
            Util.errorHandler(NSLocalizedString("speech.google.serializing", value: "Serialization failed", comment: "Google request could not be serialzed"))
            return
        }
        os_log("asking google", log: OSLog.default, type: .debug)
        // there is a streaming API which might be faster than waiting to upload everything
        guard let key = getCloudSpeechApiKey() else {
            Util.errorHandler(NSLocalizedString("speech.google.cloudkey", value: "Cloud key not found", comment: "Google Cloud Key was not configured in the app"))
            return
        }
        Util.post(url: URL(string: "https://speech.googleapis.com/v1/speech:recognize?key=\(key)")!, data: json) {
            let text = parseGoogleResponse($0)
            guard let transcript = Transcript.init(text!) else {
                Util.errorHandler(NSLocalizedString("speech.google.response", value: "Response invalid", comment: "Google response is in an unknown format"))
                return
            }
            completionHandler(transcript)
        }
    }

    class func parseGoogleResponse(_ data: Data) -> String? {
        guard let parsed = try? JSONSerialization.jsonObject(with: data) as! [String:[[String:[[String:Any]]]]] else {
            return nil
        }
        if parsed.isEmpty {
            return nil
        }
        // the result may be split in multiple arrays. take the first alternative of each array and concatenate the sentences
        let text = (parsed["results"]!).flatMap {
            $0["alternatives"]![0]["transcript"] as? String
            }.joined(separator: "")
        return text
    }

    class func askPermission() {
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            if authStatus != .authorized {
                Util.errorHandler(NSLocalizedString("speech.apple.unauthorized", value: "Speech recognition was not authorized", comment: "Apple SR was unauthorized"))
            }
        }
    }

    class func getCloudSpeechApiKey() -> String? {
        return Bundle.main.object(forInfoDictionaryKey: "CloudSpeechApiKey") as? String
    }

}
