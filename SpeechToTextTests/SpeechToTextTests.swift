//
//  SpeechToTextTests.swift
//  SpeechToTextTests
//
//  Created by Jakob Stoeck on 5/9/17.
//  Copyright © 2017 Jakob Stoeck. All rights reserved.
//

import XCTest
import googleapis
//@testable import SpeechToText

class SpeechToTextTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
//    func testGoogleResponseWithDifferentConfidences() {
//        let rawJson = "{\"results\": [{\"alternatives\": [{\"transcript\": \"abc\", \"confidence\": 0.99}]}, {\"alternatives\": [{\"transcript\": \"def\", \"confidence\": 0.6}]}]}"
//        let transcribed = "abc def"
//        assertGoogleResponseInitEquals(rawJson: rawJson, transcribed: transcribed)
//    }
//
//    func testGoogleResponseWithOneConfidence() {
//        let rawJson = "{\"results\": [{\"alternatives\": [{\"transcript\": \"viel Spaß beim Blutspenden früher habe ich das ganz oft gemacht bestimmt jeden Monat einmal oder so als ich noch in Dresden gewohnt habe\",\"confidence\": 0.9414088}]}]}"
//        let transcribed = "viel Spaß beim Blutspenden früher habe ich das ganz oft gemacht bestimmt jeden Monat einmal oder so als ich noch in Dresden gewohnt habe"
//        assertGoogleResponseInitEquals(rawJson: rawJson, transcribed: transcribed)
//    }
    
    //    TODO: Move parse functions in own class or use proto for JSON
//    func assertGoogleResponseInitEquals(rawJson: String, transcribed: String) {
//        let googleTranscript = GoogleJsonSpeechRecognizer.sharedInstance.parseGoogleResponse(rawJson.data(using: .utf8)!)
//        XCTAssertNotNil(googleTranscript)
//        XCTAssertEqual(transcribed, googleTranscript!)
//    }
//
//    func testGoogleEmptyResponse() {
//        let emptyResponse = "{}"
//        let googleTranscript = GoogleJsonSpeechRecognizer.sharedInstance.parseGoogleResponse(emptyResponse.data(using: .utf8)!)
//        XCTAssertNil(googleTranscript)
//    }
//
//    func testGoogleResponseErrorHandles() {
//        let responseRawJson = "{\"error\": {\"code\": 403, \"message\": \"This API method requires billing to be enabled. Please enable billing on project #1 by visiting https://console.developers.google.com/billing/enable?project=1 then retry. If you enabled billing for this project recently, wait a few minutes for the action to propagate to our systems and retry.\", \"status\": \"PERMISSION_DENIED\", \"details\": [{\"@type\": \"type.googleapis.com/google.rpc.Help\", \"links\": [{\"description\": \"Google developer console API key\", \"url\": \"https://console.developers.google.com/project/1/apiui/credential\"} ] }, {\"@type\": \"type.googleapis.com/google.rpc.Help\", \"links\": [{\"description\": \"Google developers console billing\", \"url\": \"https://console.developers.google.com/billing/enable?project=1\"} ] } ] } }"
//        let googleTranscript = GoogleJsonSpeechRecognizer.sharedInstance.parseGoogleResponse(responseRawJson.data(using: .utf8)!)
//        let shouldBeTranscribed = "This API method requires billing to be enabled. Please enable billing on project #1 by visiting https://console.developers.google.com/billing/enable?project=1 then retry. If you enabled billing for this project recently, wait a few minutes for the action to propagate to our systems and retry."
//        XCTAssertNotNil(googleTranscript)
//        XCTAssertEqual(shouldBeTranscribed, googleTranscript!)
//    }

    func testGoogleLongRunningOperationResponse() {
        let operationSerialized = "ChM4NzMzMjE0NTI5OTY4OTQ1ODI1EmgKR3R5cGUuZ29vZ2xlYXBpcy5jb20vZ29vZ2xlLmNsb3VkLnNwZWVjaC52MS5Mb25nUnVubmluZ1JlY29nbml6ZU1ldGFkYXRhEh0IZBILCJWX7OUFEIDMmDUaDAiYl+zlBRDQk83PAhgBKm4KR3R5cGUuZ29vZ2xlYXBpcy5jb20vZ29vZ2xlLmNsb3VkLnNwZWVjaC52MS5Mb25nUnVubmluZ1JlY29nbml6ZVJlc3BvbnNlEiMSIQofChhIYWxsbywgZGFzIGlzdCBlaW4gVGVzdC4VyUdrPw=="
        let op = try! Operation.init(data: Data.init(base64Encoded: operationSerialized)!)
        XCTAssertEqual(op.name, "8733214529968945825")
        
        let metadataValue = op.metadata.value
        let longRunningRecognizeMetadata = try! LongRunningRecognizeMetadata.init(data: metadataValue!)
        XCTAssertEqual(longRunningRecognizeMetadata.progressPercent, 100)

        let responseValue = op.response.value
        let longRunningRecognizeResponse = try! LongRunningRecognizeResponse.init(data: responseValue!)
        let result = longRunningRecognizeResponse.resultsArray[0] as! SpeechRecognitionResult
        let alternative = result.alternativesArray[0] as? SpeechRecognitionAlternative
        XCTAssertEqual(alternative?.transcript, "Hallo, das ist ein Test.")
    }
    
    func testLanguage() {
        XCTAssertEqual("en", Settings.getLanguagePart("en-US"))
        XCTAssertEqual("en", Settings.getLanguagePart("en"))
        let codes = ["de-DE", "en-US", "pt-BR"]
        XCTAssertEqual("de-DE", Settings.getNormalizedLanguage(code: "de-US", values: codes))
        XCTAssertEqual("de-DE", Settings.getNormalizedLanguage(code: "de_US", values: codes))
        XCTAssertEqual("de-DE", Settings.getNormalizedLanguage(code: "de", values: codes))
        XCTAssertNil(Settings.getNormalizedLanguage(code: "asdf", values: codes))
    }

    func testSetLanguageWorks() {
        let formerLanguage = Settings.getLanguage()
        let language = "de-DE"
        Settings.defaults.set(language, forKey: Settings.languagePrefKey)
        XCTAssertEqual(language, Settings.getLanguage())
        Settings.setDefaultLanguage()
        XCTAssertEqual(formerLanguage, Settings.getLanguage())
    }
    
    func testGetGoogleApiKeyWorks() {
        let key = Util.getCloudSpeechApiKey()!
        XCTAssertTrue(key.lengthOfBytes(using: .utf8) == 39)
    }

//    // FIXME APAudioPlayer does not work on all iPhones, cannot use it, yet.
//    func testAudioMetadata() {
//        // AVAsset does not support ogg and flac
//        let bundle = Bundle(for: type(of: self))
//        let urls: [URL: TimeInterval] = [
//            bundle.url(forResource: "test", withExtension: "opus")!: 2,
//            bundle.url(forResource: "test", withExtension: "ogg")!: 4,
//            bundle.url(forResource: "test", withExtension: "m4a")!: 7,
//            bundle.url(forResource: "overoneminute", withExtension: "opus")!: 63,
//            bundle.url(forResource: "twominsofsilence", withExtension: "ogg")!: 120,
//        ]
//        let player = APAudioPlayer()
//        for (url, duration) in urls {
//            player.loadItem(with: url, autoPlay: false)
//            XCTAssertEqual(player.duration().rounded(), duration)
//        }
//    }

    func testBestRecognizer() {
        let candidates: [SpeechRecognizer.Type] = [GoogleStreamingSpeechRecognizer.self, GoogleAsyncSpeechRecognizer.self, AppleSpeechRecognizer.self]
        let bundle = Bundle(for: type(of: self))
        let urls: [URL: SpeechRecognizer.Type] = [
            bundle.url(forResource: "test", withExtension: "opus")!: GoogleStreamingSpeechRecognizer.self,
            bundle.url(forResource: "test", withExtension: "ogg")!: GoogleStreamingSpeechRecognizer.self,
            bundle.url(forResource: "test", withExtension: "m4a")!: AppleSpeechRecognizer.self,
            bundle.url(forResource: "overoneminute", withExtension: "opus")!: GoogleAsyncSpeechRecognizer.self,
            bundle.url(forResource: "twominsofsilence", withExtension: "ogg")!: GoogleAsyncSpeechRecognizer.self,
        ]
        
        for (url, recognizer) in urls {
            let best = candidates.first(where: {
                return $0.init(url: url, lang: "de-DE", delegate: nil) != nil
            })
            let bestType = String(describing: best!)
            let recognizerType = String(describing: recognizer)
            XCTAssertEqual(bestType, recognizerType, "Incorrect recognizer for \(url.lastPathComponent)")
        }
    }

    class SpeechRecognizerDelegateMock: SpeechRecognizerDelegate {
        typealias callback = (String) -> Void
        let onUpdateClosure, onEndClosure, onErrorClosure: callback
        init(onUpdate: @escaping callback, onEnd: @escaping callback, onError: @escaping callback) {
            self.onUpdateClosure = onUpdate
            self.onEndClosure = onEnd
            self.onErrorClosure = onError
        }
        
        func onUpdate(_ sr: SpeechRecognizer, text: String) {
            onUpdateClosure(text)
        }
        
        func onEnd(_ sr: SpeechRecognizer, text: String) {
            onEndClosure(text)
        }
        
        func onError(_ sr: SpeechRecognizer, text: String) {
            onErrorClosure(text)
        }
    }
    
    func assertTranscriptEquals(text: String, recognizer: SpeechRecognizer?, timeout: TimeInterval = 30) {
        guard var rec = recognizer else {
            XCTFail("Recognizer is nil")
            return
        }
        let expectation = self.expectation(description: rec.url.absoluteString)
        let delegate = SpeechRecognizerDelegateMock(
            onUpdate: { transcribedText in
                /* noop */
        }, onEnd: { transcribedText in
            XCTAssertEqual(text, transcribedText)
            expectation.fulfill()
        }, onError: { errorText in
            XCTFail(errorText)
        })
        rec.delegate = delegate
        rec.recognize()
        waitForExpectations(timeout: timeout)
    }
    
    func testRecognitionOggStreaming() {
        let url = Bundle(for: type(of: self)).url(forResource: "test", withExtension: "ogg")!
        let recognizer = GoogleStreamingSpeechRecognizer(url: url, lang: "de-DE")
        assertTranscriptEquals(text: "Hallo, das ist ein Test.", recognizer: recognizer)
    }
    
    func testRecognitionOggSynchronous() {
        let url = Bundle(for: type(of: self)).url(forResource: "test", withExtension: "ogg")!
        let recognizer = GoogleJsonSpeechRecognizer(url: url, lang: "de-DE")
        assertTranscriptEquals(text: "Hallo, das ist ein Test.", recognizer: recognizer)
    }

    func testRecognitionOggAynchronous() {
        let url = Bundle(for: type(of: self)).url(forResource: "test", withExtension: "ogg")!
        let recognizer = GoogleAsyncSpeechRecognizer(url: url, lang: "de-DE")
        assertTranscriptEquals(text: "Hallo, das ist ein Test.", recognizer: recognizer)
    }

    func testRecognitionOpus() {
        let url = Bundle(for: type(of: self)).url(forResource: "test", withExtension: "opus")!
        let recognizer = GoogleStreamingSpeechRecognizer(url: url, lang: "de-DE")
        assertTranscriptEquals(text: "Oh, wie schön Paris.", recognizer: recognizer)
    }
    
//    It seems that the Apple Speech Recognizer is only testable on a device, not with the simulator. So skip this test.
//    func testRecognitionM4a() {
//        let bundle = Bundle(for: type(of: self))
//        let recognizer = AppleSpeechRecognizer.sharedInstance
//        assertTranscriptEquals(url: bundle.url(forResource: "test", withExtension: "m4a")!, text: "Das funktioniert ja ganz gut eigentlich was kann ich denn dazu sagen Lalalalalala", language: "de-DE", recognizer: recognizer)
//    }

    let overOneMinuteText = "Hallo, guten Morgen Gitti Oma, ich habe den Elias auf dem Video gesehen, das ist ja unglaublich, ich könnte mich so erinnern, dass ihr mit 34 Monaten 3 4 Monaten der Kopf hochgehoben habt. Weiß nicht, ob ich das noch richtig in Erinnerung habe, aber irgendwas nicht mit einem Ort anderthalb sehr lustig. Ja, ich glaube, der muss ja bald aus dem Körbchen raus, weil sonst gibt dann vielleicht zu hoch, damit der was sieht, ne? Wann sind und schön festhalten auf dem Wickeltisch. Ich glaube, er robbt bald los ist ja der Wahnsinn. Sehr sportlich, sehr beweglich lustig, also bis bald. Achso übrigens, die ist aber am Wochenende hier, das war auch sehr schön das erste Mal, dass mir meine Schwester oder überhaupt eine Schwester ein Brot geschmiert und da musste ich erst 57 werden. Bis bald. Ciao."
    
    func testRecognitionOpusAsyncOverOneMinute() {
        let url = Bundle(for: type(of: self)).url(forResource: "overoneminute", withExtension: "opus")!
        let recognizer = GoogleAsyncSpeechRecognizer(url: url, lang: "de-DE")
        assertTranscriptEquals(text: overOneMinuteText, recognizer: recognizer)
    }
    
    func testRecognitionOpusSynchronuousOverOneMinute() {
        let url = Bundle(for: type(of: self)).url(forResource: "overoneminute", withExtension: "opus")!
        let recognizer = GoogleJsonSpeechRecognizer(url: url, lang: "de-DE")
        assertTranscriptEquals(text: overOneMinuteText, recognizer: recognizer)
    }

//    func testRecognitionOfTwoMinuteFileOgg() {
//        let bundle = Bundle(for: type(of: self))
//        let recognizer = GoogleStreamingSpeechRecognizer.sharedInstance
//        assertTranscriptEquals(url: bundle.url(forResource: "twominsofsilence", withExtension: "ogg")!, text: "", language: "de-DE", recognizer: recognizer)
//    }
//
//    func testRecognitionOfupToOneMinuteFileOgg() {
//        let bundle = Bundle(for: type(of: self))
//        assertTranscriptEquals(url: bundle.url(forResource: "59secondsofsilence", withExtension: "ogg")!, text: "", language: "de-DE")
//    }
    
}
