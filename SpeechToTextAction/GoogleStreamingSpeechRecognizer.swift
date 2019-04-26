import Foundation
import googleapis
import os.log

typealias SpeechRecognitionCompletionHandler = (StreamingRecognizeResponse?, NSError?) -> (Void)

class GoogleStreamingSpeechRecognizer: SpeechRecognizer {
    let MAX_FILE_SIZE = 148000 // Cannot read all audio format metadata, yet. So use magic file size number for ~1 Minute.
    
    let url: URL
    let lang: String

    let API_KEY: String
    let HOST: String
    let SAMPLE_RATE: Int
    let sampleRate: Int
    
    var streaming = false
    var client: Speech!
    var writer: GRXBufferedPipe!
    var call: GRPCProtoCall!
    var encoding: RecognitionConfig_AudioEncoding!
    var transcript: [String] = []
    static let suffixToEncoding: [String: RecognitionConfig_AudioEncoding] = [
        "ogg": .oggOpus,
        "oga": .oggOpus,
        "opus": .oggOpus,
        "flac": .flac,
    ]
    weak var delegate: SpeechRecognizerDelegate?

    required init?(url: URL, lang: String, delegate: SpeechRecognizerDelegate? = nil) {
        self.url = url
        self.lang = lang
        self.HOST = "speech.googleapis.com"
        self.SAMPLE_RATE = 16000
        self.sampleRate = 16000
        self.API_KEY = Util.getCloudSpeechApiKey()!
        self.encoding = GoogleStreamingSpeechRecognizer.suffixToEncoding[url.pathExtension]
        self.delegate = delegate
        if self.encoding == nil {
            delegate?.onError(self, text: NSLocalizedString("speech.google.format", value: "Format unsupported", comment: "Google was requested with unsupported format"))
            return nil
        }
        guard let filesize = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize else {
            return nil
        }
        if (filesize > MAX_FILE_SIZE) {
            return nil
        }
    }
    
    func recognize() {
        // We recommend sending samples in 100ms chunks
        let chunkSize : Int /* bytes/chunk */ = Int(0.1 /* seconds/chunk */
            * Double(SAMPLE_RATE) /* samples/second */
            * 2 /* bytes/sample */);
        
        // byte chunk of url and put into audio data
        guard let audioData = try? Data.init(contentsOf: url) else {
            delegate?.onError(self, text: NSLocalizedString("speech.google.loading", value: "Cannot read audio file", comment: "Audio file is not readable"))
            return
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
                delegate?.onError(self, text: error.localizedDescription)
            } else if let response = response {
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
                delegate?.onUpdate(self, text: semifinalText)
                
                if timer != nil {
                    resetTimer(fun: { () -> Void in
                        self.delegate?.onEnd(self, text: semifinalText)
                        self.stopStreaming()
                        os_log("would be onEnd", type: .debug)
                    })
                }

                if final {
                    baseText = semifinalText
                    resetTimer(fun: { () -> Void in
                        self.delegate?.onEnd(self, text: baseText)
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
            streamAudioData(chunk)
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
        recognitionConfig.enableWordTimeOffsets = false
        recognitionConfig.enableAutomaticPunctuation = true
        
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
