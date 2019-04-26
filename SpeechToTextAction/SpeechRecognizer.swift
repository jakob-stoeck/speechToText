//
//  SpeechRecognizer.swift
//  SpeechToText
//
//  Created by Jakob Stoeck on 9/13/17.
//  Copyright © 2017 Jakob Stoeck. All rights reserved.
//

import UIKit

protocol SpeechRecognizer {
    var url: URL { get }
    var delegate: SpeechRecognizerDelegate? { get set }
    init?(url: URL, lang: String, delegate: SpeechRecognizerDelegate?)
    func recognize()
}

protocol SpeechRecognizerDelegate: AnyObject {
    func onUpdate(_ sr: SpeechRecognizer, text: String)
    func onEnd(_ sr: SpeechRecognizer, text: String)
    func onError(_ sr: SpeechRecognizer, text: String)
}

