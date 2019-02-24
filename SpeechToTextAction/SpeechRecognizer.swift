//
//  SpeechRecognizer.swift
//  SpeechToText
//
//  Created by Jakob Stoeck on 9/13/17.
//  Copyright © 2017 Jakob Stoeck. All rights reserved.
//

import UIKit

protocol SpeechRecognizer {

    static func supports(url: URL) -> Bool
    
    static func recognize(
        url: URL,
        lang: String,
        onUpdate: @escaping (String) -> (),
        onEnd: @escaping (String) -> (),
        onError: @escaping (String) -> ()
    )

}
