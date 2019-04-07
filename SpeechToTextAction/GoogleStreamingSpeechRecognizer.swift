//
// Copyright 2016 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
import Foundation
import googleapis
import os.log

typealias SpeechRecognitionCompletionHandler = (StreamingRecognizeResponse?, NSError?) -> (Void)

class GoogleStreamingSpeechRecognizer: SpeechRecognizer {
    
    static let sharedInstance = GoogleStreamingSpeechRecognizer()
    
    private let API_KEY = Util.getCloudSpeechApiKey()!
    private let HOST = "speech.googleapis.com"
    private let SAMPLE_RATE = 16000
    private var sampleRate: Int = 16000
    private var streaming = false
    private var client: Speech!
    private var writer: GRXBufferedPipe!
    private var call: GRPCProtoCall!
    private var lang = "en-US"
    private var encoding: RecognitionConfig_AudioEncoding!
    private var transcript: [String] = []
    private let suffixToEncoding = [
        "ogg": RecognitionConfig_AudioEncoding.oggOpus,
        "opus": RecognitionConfig_AudioEncoding.oggOpus,
        "flac": RecognitionConfig_AudioEncoding.flac,
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
        
        // We recommend sending samples in 100ms chunks
        let chunkSize : Int /* bytes/chunk */ = Int(0.1 /* seconds/chunk */
            * Double(SAMPLE_RATE) /* samples/second */
            * 2 /* bytes/sample */);
        
        // byte chunk of url and put into audio data
        guard let audioData = try? Data.init(contentsOf: url) else {
            return onError(NSLocalizedString("speech.google.loading", value: "Cannot read audio file", comment: "Audio file is not readable"))
        }
        let chunks = audioData.count/chunkSize + (audioData.count % chunkSize == 0 ? 0 : 1)
        var baseText = ""
        
        weak var timer: Timer?
        
        func resetTimer(fun: @escaping () -> Void) {
            timer?.invalidate()
            timer = .scheduledTimer(withTimeInterval: 2.0, repeats: false) { timer in
                os_log("resetting timer", type: .debug)
                fun()
            }
        }
        
        func onAudioChunk(response: StreamingRecognizeResponse?, error: NSError?) {
            os_log("audio chunk received", type: .debug)
            if let error = error {
                os_log("error", type: .error)
                self.stopStreaming()
                onError(error.localizedDescription)
            } else if let response = response {
//                os_log("onUpdate: \"%@\"", type: .debug, response)

                var text = ""
                var final = false

                for result in response.resultsArray! {
                    guard let result = result as? StreamingRecognitionResult else {
                        return
                    }
                    guard let alternative = result.alternativesArray[0] as? SpeechRecognitionAlternative else {
                        return
                    }
                    text += alternative.transcript
                    final = result.isFinal || final
                }

                // different results with isFinal: true may arrive multiple times.
                // the text until a "final" result is purged and the next results
                // contain only the text from then on forward, so merge them.
                let separator = baseText != "" ? " " : ""
                let semifinalText = baseText + separator + text
                onUpdate(semifinalText)
                
                if timer != nil {
                    resetTimer(fun: { () -> Void in
                        onEnd(semifinalText)
                        self.stopStreaming()
                        os_log("would be onEnd", type: .debug)
                    })
                }

                if final {
                    baseText = semifinalText
                    resetTimer(fun: { () -> Void in
                        onEnd(baseText)
                        self.stopStreaming()
                        os_log("would be onEnd", type: .debug)
                    })
                }
            }
        }
        
        startStreaming(completion: onAudioChunk)
        
        for i in 0..<chunks {
            let currentIndex = i*chunkSize
            let range = currentIndex..<min(currentIndex+chunkSize, audioData.count)
            let chunk = audioData.subdata(in: range)
            self.streamAudioData(chunk)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
            self.stopStreaming() // TODO why can’t we run stop streaming immediately? It should just mark the buffer as finished.
        }
    }

    func startStreaming(completion: @escaping SpeechRecognitionCompletionHandler) {
        os_log("starting streaming", type: .debug)
        // set up a gRPC connection
        client = Speech(host:HOST)
        writer = GRXBufferedPipe()
        call = client.rpcToStreamingRecognize(withRequestsWriter: writer, eventHandler: { (done, response, error) in
            completion(response, error as NSError?)
        })
        // authenticate using an API key obtained from the Google Cloud Console
        call.requestHeaders.setObject(NSString(string:API_KEY),
                                      forKey:NSString(string:"X-Goog-Api-Key"))
        // if the API key has a bundle ID restriction, specify the bundle ID like this
        call.requestHeaders.setObject(NSString(string:Bundle.main.bundleIdentifier!),
                                      forKey:NSString(string:"X-Ios-Bundle-Identifier"))
        
        call.start()
        streaming = true
        
        // send an initial request message to configure the service
        let recognitionConfig = RecognitionConfig()
        // FIXME: language and encoding should be instance variables
        recognitionConfig.encoding = encoding
        recognitionConfig.sampleRateHertz = Int32(sampleRate)
        recognitionConfig.languageCode = lang
        recognitionConfig.maxAlternatives = 0
        recognitionConfig.enableWordTimeOffsets = true
        
        let streamingRecognitionConfig = StreamingRecognitionConfig()
        streamingRecognitionConfig.config = recognitionConfig
        streamingRecognitionConfig.singleUtterance = false
        streamingRecognitionConfig.interimResults = true
        
        let streamingRecognizeRequest = StreamingRecognizeRequest()
        streamingRecognizeRequest.streamingConfig = streamingRecognitionConfig
        
        writer.writeValue(streamingRecognizeRequest)
    }
    
    func streamAudioData(_ audioData: Data) {
        os_log("streaming data", type: .debug)
        // send a request message containing the audio data
        let streamingRecognizeRequest = StreamingRecognizeRequest()
        streamingRecognizeRequest.audioContent = audioData as Data
        writer.writeValue(streamingRecognizeRequest)
    }
    
    func stopStreaming() {
        os_log("stopping streaming", type: .debug)
        if (!streaming) {
            return
        }
        writer.finishWithError(nil)
        streaming = false
    }

}
