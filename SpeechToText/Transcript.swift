//
//  Transcript.swift
//  SpeechToText
//
//  Created by Jakob Stoeck on 5/18/17.
//  Copyright © 2017 Jakob Stoeck. All rights reserved.
//

import Foundation

class Transcript {

    let text: String
    static let lastMessageKey = "Transcript/lastTranscript"
    static let lastMessageDefault = ""

    init?(_ text: String) {
        self.text = text
    }

    class func getLastMessage() -> String {
        guard let text = Settings.defaults.string(forKey: Transcript.lastMessageKey) else {
            return lastMessageDefault
        }
        return text
    }

    func save() {
        Settings.defaults.set(text, forKey: Transcript.lastMessageKey)
    }
}
