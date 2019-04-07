
//
//  GoogleJsonSpeechRecognizer.swift
//  SpeechToTextAction
//
//  Created by jaksto on 2/24/19.
//  Copyright © 2019 Jakob Stoeck. All rights reserved.
//

import Foundation
import os.log


class GoogleJsonSpeechRecognizer: SpeechRecognizer {
    
    static let sharedInstance = GoogleJsonSpeechRecognizer()
    
    func supports(url: URL) -> Bool {
        let supportedFormats = ["opus", "flac", "ogg"]
        return supportedFormats.contains(url.pathExtension)
    }
    
    func recognize(url: URL, lang: String, onUpdate: @escaping (String) -> (), onEnd: @escaping (String) -> (), onError: @escaping (String) -> ()) {
        guard let audioContent = try? Data(contentsOf: url).base64EncodedString() else {
            return onError(NSLocalizedString("speech.google.loading", value: "Cannot read audio file", comment: "Audio file is not readable"))
        }
        let size = Double(audioContent.lengthOfBytes(using: .ascii))
        let maxSize = 5e7
        if size > maxSize {
            return onError(NSLocalizedString("speech.google.toobig", value: "File too big", comment: "Audio file is too big"))
        }
        
        let suffixToEncoding = [
            "ogg": "OGG_OPUS",
            "opus": "OGG_OPUS",
            "flac": "FLAC",
            ]
        
        guard let audioCode = suffixToEncoding[url.pathExtension] else {
            return onError(NSLocalizedString("speech.google.format", value: "Format unsupported", comment: "Google was requested with unsupported format"))
        }
        
        let data = [
            "audio": [
                "content": audioContent
            ],
            "config": [
                "languageCode": lang,
                "encoding": audioCode,
                "sampleRateHertz": 16000
            ]
        ]
        
        guard JSONSerialization.isValidJSONObject(data) else {
            return onError(NSLocalizedString("speech.google.json", value: "Request failed", comment: "Google request could not be built"))
        }
        
        guard let json = try? JSONSerialization.data(withJSONObject: data) else {
            return onError(NSLocalizedString("speech.google.serializing", value: "Serialization failed", comment: "Google request could not be serialzed"))
        }
        os_log("asking google", log: OSLog.default, type: .debug)
        // there is a streaming API which might be faster than waiting to upload everything
        guard let key = Util.getCloudSpeechApiKey() else {
            return onError(NSLocalizedString("speech.google.cloudkey", value: "Cloud key not found", comment: "Google Cloud Key was not configured in the app"))
        }
        Util.post(url: URL(string: "https://speech.googleapis.com/v1/speech:recognize?key=\(key)")!, data: json) {
            let text = self.parseGoogleResponse($0)
            guard let transcript = Transcript.init(text!) else {
                return onError(NSLocalizedString("speech.google.response", value: "Response invalid", comment: "Google response is in an unknown format"))
            }
            onEnd(transcript.text)
        }
    }
    
    func parseGoogleResponse(_ data: Data) -> String? {
        guard let parsed = try? JSONSerialization.jsonObject(with: data) else {
            return nil
        }
        guard let result = parsed as? [String: Any] else {
            return nil
        }
        if result.isEmpty {
            return nil
        }
        guard let results = result["results"] as? [[String:[[String:Any]]]] else {
            if let error = result["error"] as? [String:Any] {
                return error["message"] as? String
            }
            return nil
        }
        
        // the result may be split in multiple arrays. take the first alternative of each array and concatenate the sentences
        let text = (results).compactMap {
            ($0["alternatives"]![0]["transcript"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            }.joined(separator: " ")
        return text
    }
}
