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

let API_KEY = Bundle.main.object(forInfoDictionaryKey: "CloudSpeechApiKey") as! String
let HOST = "speech.googleapis.com"
let SAMPLE_RATE = 16000

typealias SpeechRecognitionCompletionHandler = (StreamingRecognizeResponse?, NSError?) -> (Void)

class GoogleStreamingSpeechRecognizer: SpeechRecognizer {
    
    func supports(url: URL) -> Bool {
        let supportedFormats = ["opus", "flac", "ogg"]
        return supportedFormats.contains(url.pathExtension)
    }
    
    func recognize(url: URL, lang: String, onUpdate: @escaping (String) -> (), onEnd: @escaping (String) -> (), onError: @escaping (String) -> ()) {
        
        // We recommend sending samples in 100ms chunks
        let chunkSize : Int /* bytes/chunk */ = Int(0.1 /* seconds/chunk */
            * Double(SAMPLE_RATE) /* samples/second */
            * 2 /* bytes/sample */);
        
        // byte chunk of url and put into audio data
        guard let audioData = try? Data.init(contentsOf: url) else {
            return onError(NSLocalizedString("speech.google.loading", value: "Cannot read audio file", comment: "Audio file is not readable"))
        }
        let chunks = audioData.count/chunkSize + (audioData.count % chunkSize == 0 ? 0 : 1)
        
        for i in 0..<chunks {
            let currentIndex = i*chunkSize
            let range = currentIndex..<min(currentIndex+chunkSize, audioData.count)
            let chunk = audioData.subdata(in: range)
            
            DispatchQueue.main.async {
                self.streamAudioData(chunk, lang: lang, completion: { (response, error) in
                    if let error = error {
                        self.stopStreaming()
                        return onError(error.localizedDescription)
                    } else if let response = response {
                        for result in response.resultsArray! {
                            if let result = result as? StreamingRecognitionResult {
                                let text:String = (result.alternativesArray[0] as! SpeechRecognitionAlternative).transcript
                                onUpdate(text)
                                if result.isFinal {
                                    self.stopStreaming()
                                    onEnd(text)
                                }
                            }
                        }
                    }
                })
            }
        }
    }
    

    var sampleRate: Int = 16000
    private var streaming = false
    
    private var client : Speech!
    private var writer : GRXBufferedPipe!
    private var call : GRPCProtoCall!
    
    static let sharedInstance = GoogleStreamingSpeechRecognizer()
    
    func streamAudioData(_ audioData: Data, lang: String, completion: @escaping SpeechRecognitionCompletionHandler) {
        if (!streaming) {
            // if we aren't already streaming, set up a gRPC connection
            client = Speech(host:HOST)
            writer = GRXBufferedPipe()
            call = client.rpcToStreamingRecognize(withRequestsWriter: writer,
                                                  eventHandler:
                { (done, response, error) in
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
            recognitionConfig.encoding = .oggOpus
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
        
        // send a request message containing the audio data
        let streamingRecognizeRequest = StreamingRecognizeRequest()
        streamingRecognizeRequest.audioContent = audioData as Data
        writer.writeValue(streamingRecognizeRequest)
    }
    
    func stopStreaming() {
        if (!streaming) {
            return
        }
        writer.finishWithError(nil)
        streaming = false
    }
    
    func isStreaming() -> Bool {
        return streaming
    }

}
