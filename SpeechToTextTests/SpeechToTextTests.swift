//
//  SpeechToTextTests.swift
//  SpeechToTextTests
//
//  Created by Jakob Stoeck on 5/9/17.
//  Copyright © 2017 Jakob Stoeck. All rights reserved.
//

import XCTest
@testable import SpeechToText

class SpeechToTextTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testGoogleResponseInitializationSucceeds() {
        let responses = [
                ["abcdef", "{\"results\": [{\"alternatives\": [{\"transcript\": \"abc\", \"confidence\": 0.99}]}, {\"alternatives\": [{\"transcript\": \"def\", \"confidence\": 0.6}]}]}"],
                ["viel Spaß beim Blutspenden früher habe ich das ganz oft gemacht bestimmt jeden Monat einmal oder so als ich noch in Dresden gewohnt habe", "{\"results\": [{\"alternatives\": [{\"transcript\": \"viel Spaß beim Blutspenden früher habe ich das ganz oft gemacht bestimmt jeden Monat einmal oder so als ich noch in Dresden gewohnt habe\",\"confidence\": 0.9414088}]}]}"],
        ]
        for resp in responses {
            let transcribed = resp[0]
            let rawJson = resp[1]
            let googleTranscript = SpeechRecognizer.parseGoogleResponse(rawJson.data(using: .utf8)!)
            XCTAssertNotNil(googleTranscript)
            XCTAssertEqual(transcribed, googleTranscript!)
        }

        let emptyResponse = "{}"
        let googleTranscript = SpeechRecognizer.parseGoogleResponse(emptyResponse.data(using: .utf8)!)
        XCTAssertNil(googleTranscript)
    }

    func testGoogleResponseErrorHandles() {
        let responseRawJson = "{\"error\": {\"code\": 403, \"message\": \"This API method requires billing to be enabled. Please enable billing on project #1 by visiting https://console.developers.google.com/billing/enable?project=1 then retry. If you enabled billing for this project recently, wait a few minutes for the action to propagate to our systems and retry.\", \"status\": \"PERMISSION_DENIED\", \"details\": [{\"@type\": \"type.googleapis.com/google.rpc.Help\", \"links\": [{\"description\": \"Google developer console API key\", \"url\": \"https://console.developers.google.com/project/1/apiui/credential\"} ] }, {\"@type\": \"type.googleapis.com/google.rpc.Help\", \"links\": [{\"description\": \"Google developers console billing\", \"url\": \"https://console.developers.google.com/billing/enable?project=1\"} ] } ] } }"
        let googleTranscript = SpeechRecognizer.parseGoogleResponse(responseRawJson.data(using: .utf8)!)
        XCTAssertNotNil(googleTranscript)
        XCTAssertEqual("This API method requires billing to be enabled. Please enable billing on project #1 by visiting https://console.developers.google.com/billing/enable?project=1 then retry. If you enabled billing for this project recently, wait a few minutes for the action to propagate to our systems and retry.", googleTranscript!)
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

    func testRecognition() {
        Settings.defaults.set("de-DE", forKey: Settings.languagePrefKey)
        XCTAssertEqual("de-DE", Settings.getLanguage())
        let bundle = Bundle(for: type(of: self))
        struct audioTest {
            var url:URL
            var text:String
        }
        let audioFiles = [
            audioTest(url: bundle.url(forResource: "test", withExtension: "ogg")!, text: "hallo das ist ein Test"),
            audioTest(url: bundle.url(forResource: "test", withExtension: "opus")!, text: "oh wie schön Paris"),
            audioTest(url: bundle.url(forResource: "test", withExtension: "m4a")!, text: "Das funktioniert ja ganz gut eigentlich was kann ich denn dazu sagen Lalalalalala")
        ]
        for audio in audioFiles {
            let expectation = self.expectation(description: audio.url.absoluteString)
            SpeechRecognizer.recognizeFile(url: audio.url) { transcript in
                XCTAssertEqual(audio.text, transcript.text)
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 10)
        Settings.setDefaultLanguage()
    }
}
