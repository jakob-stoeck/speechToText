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
        let response = "{\"results\": [{\"alternatives\": [{\"transcript\": \"abc\", \"confidence\": 0.99}]}, {\"alternatives\": [{\"transcript\": \"def\", \"confidence\": 0.6}]}]}"
        let googleTranscript = Transcript.init(googleSpeechApiResponse: response.data(using: .utf8)!)
        XCTAssertNotNil(googleTranscript)
        XCTAssertEqual("abcdef", googleTranscript!.text)
    }

    func testLanguage() {
        XCTAssertEqual("en", Settings.getLanguagePart("en-US"))
        XCTAssertEqual("en", Settings.getLanguagePart("en"))
        XCTAssertEqual("de-DE", Settings.getNormalizedLanguage(code: "de-US", values: ["de-DE", "en-US", "pt-BR"]))
        XCTAssertEqual("de-DE", Settings.getNormalizedLanguage(code: "de_US", values: ["de-DE", "en-US", "pt-BR"]))
        XCTAssertEqual("de-DE", Settings.getNormalizedLanguage(code: "de", values: ["de-DE", "en-US", "pt-BR"]))
    }
}
