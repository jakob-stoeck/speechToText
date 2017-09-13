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

    func testLanguage() {
        XCTAssertEqual("en", Settings.getLanguagePart("en-US"))
        XCTAssertEqual("en", Settings.getLanguagePart("en"))
        let codes = ["de-DE", "en-US", "pt-BR"]
        XCTAssertEqual("de-DE", Settings.getNormalizedLanguage(code: "de-US", values: codes))
        XCTAssertEqual("de-DE", Settings.getNormalizedLanguage(code: "de_US", values: codes))
        XCTAssertEqual("de-DE", Settings.getNormalizedLanguage(code: "de", values: codes))
        XCTAssertNil(Settings.getNormalizedLanguage(code: "asdf", values: codes))
    }
}
