
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
    let url: URL
    let lang: String
    let encoding: String!
    let suffixToEncoding = [
        "ogg": "OGG_OPUS",
        "opus": "OGG_OPUS",
        "flac": "FLAC",
    ]
    weak var delegate: SpeechRecognizerDelegate?

    required init?(url: URL, lang: String, delegate: SpeechRecognizerDelegate? = nil) {
        self.url = url
        self.lang = lang
        self.encoding = suffixToEncoding[url.pathExtension]
        self.delegate = delegate
        if self.encoding == nil {
            delegate?.onError(self, text: NSLocalizedString("speech.google.format", value: "Format unsupported", comment: "Google was requested with unsupported format"))
            return nil
        }
    }
    
    func recognize() {
        guard let audioContent = try? Data(contentsOf: url).base64EncodedString() else {
            delegate?.onError(self, text: NSLocalizedString("speech.google.loading", value: "Cannot read audio file", comment: "Audio file is not readable"))
            return
        }
        let size = Double(audioContent.lengthOfBytes(using: .ascii))
        let maxSize = 5e7
        if size > maxSize {
            delegate?.onError(self, text: NSLocalizedString("speech.google.toobig", value: "File too big", comment: "Audio file is too big"))
            return
        }

        let data = [
            "audio": [
                "content": audioContent
            ],
            "config": [
                "languageCode": lang,
                "encoding": encoding!,
                "sampleRateHertz": 16000,
                "enableWordTimeOffsets": false,
                "enableAutomaticPunctuation": true
            ]
        ]
        
        guard JSONSerialization.isValidJSONObject(data) else {
            delegate?.onError(self, text: NSLocalizedString("speech.google.json", value: "Request failed", comment: "Google request could not be built"))
            return
        }
        
        guard let json = try? JSONSerialization.data(withJSONObject: data) else {
            delegate?.onError(self, text: NSLocalizedString("speech.google.serializing", value: "Serialization failed", comment: "Google request could not be serialzed"))
            return
        }
        os_log("asking google", log: OSLog.default, type: .debug)
        // there is a streaming API which might be faster than waiting to upload everything
        guard let key = Util.getCloudSpeechApiKey() else {
            delegate?.onError(self, text: NSLocalizedString("speech.google.cloudkey", value: "Cloud key not found", comment: "Google Cloud Key was not configured in the app"))
            return
        }
        Util.post(url: URL(string: "https://speech.googleapis.com/v1/speech:recognize?key=\(key)")!, data: json) {
            let text = self.parseGoogleResponse($0)
            guard let transcript = Transcript.init(text!) else {
                self.delegate?.onError(self, text: NSLocalizedString("speech.google.response", value: "Response invalid", comment: "Google response is in an unknown format"))
                return
            }
            self.delegate?.onEnd(self, text: transcript.text)
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
