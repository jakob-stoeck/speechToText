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
    let url: URL
    let lang: String

    let API_KEY: String
    let HOST = "speech.googleapis.com"
    let SAMPLE_RATE = 16000
    let MAX_FILE_SIZE = 10485760
    let sampleRate: Int = 16000
    private var streaming = false
    let encoding: RecognitionConfig_AudioEncoding!
    let suffixToEncoding: [String: RecognitionConfig_AudioEncoding] = [
        "ogg": .oggOpus,
        "oga": .oggOpus,
        "opus": .oggOpus,
        "flac": .flac,
    ]
    weak var delegate: SpeechRecognizerDelegate?
    
    required init?(url: URL, lang: String, delegate: SpeechRecognizerDelegate? = nil) {
        self.url = url
        self.lang = lang
        self.API_KEY = Util.getCloudSpeechApiKey()!
        self.encoding = suffixToEncoding[url.pathExtension]
        self.delegate = delegate
        if self.encoding == nil {
            delegate?.onError(self, text: NSLocalizedString("speech.google.format", value: "Format unsupported", comment: "Google was requested with unsupported format"))
            return nil
        }
    }

    func recognize() {
        // set up a gRPC connection
        let client = Speech(host:HOST)
        
        let config = RecognitionConfig()
        config.encoding = encoding
        config.sampleRateHertz = Int32(sampleRate)
        config.languageCode = lang
        config.maxAlternatives = 0
        config.enableWordTimeOffsets = false
        config.enableAutomaticPunctuation = true

        guard var audioData = try? Data.init(contentsOf: url) else {
            delegate?.onError(self, text: NSLocalizedString("speech.google.loading", value: "Cannot read audio file", comment: "Audio file is not readable"))
            return
        }
        if (audioData.count > MAX_FILE_SIZE) {
            audioData = audioData.prefix(MAX_FILE_SIZE)
            delegate?.onUpdate(self, text: NSLocalizedString("action.loading_title", value: "Transcribing ... Only the first 10 MB of this file are supported. Please wait.", comment: "Notification that transcription will take a bit"))
        }
        else {
            delegate?.onUpdate(self, text: NSLocalizedString("action.loading_title", value: "Transcribing ... This is a longer message. It takes around 30 seconds to transcribe. Please wait.", comment: "Notification that transcription will take a bit"))
        }     
        
        let storageClient = Storage(host: "www.googleapis.com", apiKey: API_KEY)
        let fileName = UUID().uuidString
        let bucketName = "twss"
        storageClient.upload(bucket: bucketName, name: fileName, data: audioData) { resp, err in
            if err != nil {
                self.delegate?.onError(self, text: err!.localizedDescription)
                return
            }
            let req = LongRunningRecognizeRequest()
            req.config = config
            req.audio.uri = "gs://\(bucketName)/\(fileName)"
            
            // start asynchronuous recognize task and poll continuously for progress and completion information
            let call = client.rpcToLongRunningRecognize(with: req, handler: self.longRunningRecognizeCompletion)
            call.requestHeaders.setObject(NSString(string:self.API_KEY), forKey:NSString(string:"X-Goog-Api-Key"))
            call.requestHeaders.setObject(NSString(string:Bundle.main.bundleIdentifier!), forKey:NSString(string:"X-Ios-Bundle-Identifier"))
            call.start()
        }
    }
    
    func longRunningRecognizeCompletion(op: Operation?, err: Error?) {
        if err != nil {
            delegate?.onError(self, text: err!.localizedDescription)
            return
        }
        let operations = GoogleLongrunningOperations(host: self.HOST, apiKey: self.API_KEY)
        operations.wait(op: op, completion: operationsPoll)
    }
    
    func operationsPoll(op: Operation?, err: Error?) {
        if err != nil {
            delegate?.onError(self, text: err!.localizedDescription)
            return
        }
        guard let op = op else {
            return
        }
        if !op.done {
            let metadataValue = op.metadata.value
            let longRunningRecognizeMetadata = try! LongRunningRecognizeMetadata.init(data: metadataValue!)
            delegate?.onUpdate(self, text: "Transcribing ... \(longRunningRecognizeMetadata.progressPercent)% after \(longRunningRecognizeMetadata.lastUpdateTime.seconds-longRunningRecognizeMetadata.startTime.seconds) seconds")
            return
        }
        do {
            let data = (op.response.value)!
            let longRunningRecognizeResponse = try LongRunningRecognizeResponse.init(data: data)
            var text = ""
            
            for speechRecognitionResult in longRunningRecognizeResponse.resultsArray! {
                guard let speechRecognitionResult = speechRecognitionResult as? SpeechRecognitionResult else {
                    delegate?.onError(self, text: "Parsing failed")
                    return
                }
                guard let alternative = speechRecognitionResult.alternativesArray[0] as? SpeechRecognitionAlternative else {
                    delegate?.onError(self, text: "Parsing failed")
                    return
                }
                if text == "" {
                    text = alternative.transcript
                } else {
                    text += " " + alternative.transcript
                }
            }
            delegate?.onEnd(self, text: text)
        } catch {
            delegate?.onError(self, text: error.localizedDescription)
        }
    }
}
