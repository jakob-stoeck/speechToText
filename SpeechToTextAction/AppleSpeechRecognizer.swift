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
    let url: URL
    let lang: String
    let supportedFormats = ["aac", "adts", "ac3", "aif", "aiff", "aifc", "caf", "mp3", "mp4", "m4a", "snd", "au", "sd2", "wav"]
    weak var delegate: SpeechRecognizerDelegate?

    required init?(url: URL, lang: String, delegate: SpeechRecognizerDelegate?) {
        self.url = url
        self.lang = lang.replacingOccurrences(of: "-", with: "_")
        self.delegate = delegate
        if !supportedFormats.contains(url.pathExtension) {
            os_log("unsupported apple format %@", type: .debug, url.absoluteString)
            return nil
        }
    }
    
    func recognize() {
        SFSpeechRecognizer.requestAuthorization(authComplete)
    }
    
    func authComplete(authStatus: SFSpeechRecognizerAuthorizationStatus) {
        if authStatus != .authorized {
            return Util.errorHandler(NSLocalizedString("speech.apple.unauthorized", value: "Speech recognition was not authorized", comment: "Apple SR was unauthorized"))
        }
        guard let recognizer = SFSpeechRecognizer(locale: Locale.init(identifier: lang)) else {
            delegate?.onError(self, text: NSLocalizedString("speech.apple.locale", value: "Locale not supported", comment: "Apple SR does not support the current locale"))
            return
        }
        if !recognizer.isAvailable {
            delegate?.onError(self, text: NSLocalizedString("speech.apple.availability", value: "not available, e.g. no internet", comment: "Apple SR is not available"))
            return
        }
        let request = SFSpeechURLRecognitionRequest(url: url)
        os_log("asking apple", log: OSLog.default, type: .debug)
        recognizer.recognitionTask(with: request, resultHandler: recognitionTaskCompletion)
    }
    
    func recognitionTaskCompletion(result: SFSpeechRecognitionResult?, error: Error?) {
        if let error = error {
            delegate?.onError(self, text: error.localizedDescription)
        }
        else if let result = result {
            delegate?.onUpdate(self, text: result.bestTranscription.formattedString)
            if result.isFinal {
                delegate?.onEnd(self, text: result.bestTranscription.formattedString)
            }
        }
    }
}
