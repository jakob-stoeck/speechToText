//
//  File.swift
//  SpeechToTextAction
//
//  Created by jaksto on 4/16/19.
//  Copyright © 2019 Jakob Stoeck. All rights reserved.
//

import Foundation
import googleapis
import os.log

typealias operation = googleapis.Operation

class GoogleAsyncSpeechRecognizer: SpeechRecognizer {

    static let sharedInstance = GoogleAsyncSpeechRecognizer()
    
    private let API_KEY = Util.getCloudSpeechApiKey()!
    private let HOST = "speech.googleapis.com"
    private let SAMPLE_RATE = 16000
    private var sampleRate: Int = 16000
    private var streaming = false
    private var lang = "en-US"
    private var encoding: RecognitionConfig_AudioEncoding!
    private var transcript: [String] = []
    private let suffixToEncoding: [String: RecognitionConfig_AudioEncoding] = [
        "ogg": .oggOpus,
        "opus": .oggOpus,
        "flac": .flac,
    ]
    
    func supports(url: URL) -> Bool {
        return suffixToEncoding.keys.contains(url.pathExtension)
    }
    
    func recognize(url: URL, lang: String, onUpdate: @escaping (String) -> (), onEnd: @escaping (String) -> (), onError: @escaping (String) -> ()) {
        
        self.lang = lang
        self.encoding = suffixToEncoding[url.pathExtension]
        
        if self.encoding == nil {
            return onError(NSLocalizedString("speech.google.format", value: "Format unsupported", comment: "Google was requested with unsupported format"))
        }

        // set up a gRPC connection
        let client = Speech(host:HOST)
        
        let config = RecognitionConfig()
        config.encoding = encoding
        config.sampleRateHertz = Int32(sampleRate)
        config.languageCode = lang
        config.maxAlternatives = 0
        config.enableWordTimeOffsets = false
        config.enableAutomaticPunctuation = true

        guard let audioData = try? Data.init(contentsOf: url) else {
            return onError(NSLocalizedString("speech.google.loading", value: "Cannot read audio file", comment: "Audio file is not readable"))
        }
        let req = LongRunningRecognizeRequest()
        req.config = config
        req.audio.content = audioData
        
        onUpdate(NSLocalizedString("action.loading_title", value: "Transcribing ... This is a longer message. It takes around 30 seconds to transcribe. Please wait.", comment: "Notification that transcription will take a bit"))
        
        let call = client.rpcToLongRunningRecognize(with: req) { op, err in
            if err != nil {
                return onError(err!.localizedDescription)
            }
            
            let operations = GoogleLongrunningOperations(host: self.HOST, apiKey: self.API_KEY)
            operations.wait(op: op) { op, err in
                if err != nil {
                    return onError(err!.localizedDescription)
                }
                do {
                    let data = (op?.response.value)!
                    let longRunningRecognizeResponse = try LongRunningRecognizeResponse.init(data: data)
                    var text = ""

                    for speechRecognitionResult in longRunningRecognizeResponse.resultsArray! {
                        guard let speechRecognitionResult = speechRecognitionResult as? SpeechRecognitionResult else {
                            return onError("Parsing failed")
                        }
                        guard let alternative = speechRecognitionResult.alternativesArray[0] as? SpeechRecognitionAlternative else {
                            return onError("Parsing failed")
                        }
                        if text == "" {
                            text = alternative.transcript
                        } else {
                            text += " " + alternative.transcript
                        }
                    }
                    return onEnd(text)
                } catch {
                    return onError(error.localizedDescription)
                }
            }
        }
        call.requestHeaders.setObject(NSString(string:API_KEY), forKey:NSString(string:"X-Goog-Api-Key"))
        // if the API key has a bundle ID restriction, specify the bundle ID like this
        call.requestHeaders.setObject(NSString(string:Bundle.main.bundleIdentifier!), forKey:NSString(string:"X-Ios-Bundle-Identifier"))
        call.start()
    }
}
