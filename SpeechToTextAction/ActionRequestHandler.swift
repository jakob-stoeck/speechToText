//
//  ActionRequestHandler.swift
//  SpeechToTextAction
//
//  Created by Jakob Stoeck on 5/9/17.
//  Copyright © 2017 Jakob Stoeck. All rights reserved.
//

import UIKit
import MobileCoreServices
import Speech
import UserNotifications
import os.log

class ActionRequestHandler: NSObject, NSExtensionRequestHandling {

    var extensionContext: NSExtensionContext?

    public func askPermission() {
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    // jay
                    break
                case .denied:
                    fallthrough
                case .restricted:
                    fallthrough
                case .notDetermined:
                    fallthrough
                default:
                    self.errorHandler("Speech recognition was not authorized")
                }
            }
        }
    }

    func post(url: URL, data: Data, completionHandler: @escaping (Data) -> ()) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        let session = URLSession.shared
        session.dataTask(with: request) {data, response, err in
            if err != nil {
                os_log("%@", log: OSLog.default, type: .error, err.debugDescription)
            }
            if data != nil {
                os_log("%@", log: OSLog.default, type: .debug, (String(data: data!, encoding: .utf8)!))
                completionHandler(data!)
            }
        }.resume()
    }

    func notify(title: String, body: String) {
        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert]
        center.requestAuthorization(options: options) {
            (granted, error) in
            if !granted {
                os_log("Something went wrong", log: OSLog.default, type: .error)
            }
        }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.01, repeats: false)
        let identifier = "STTLocalNotification"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request, withCompletionHandler: { (error) in
            if error != nil {
                os_log("Notification went wrong", log: OSLog.default, type: .error)
            }
        })
    }

    func errorHandler(_ text: String, title: String = "Error") {
        os_log("%@: %@", log: OSLog.default, type: .error, title, text)
        notify(title: title, body: text)
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
        self.extensionContext = nil
    }

    func recognizeFileGoogle(url: URL, completionHandler: @escaping (Transcript) -> ()) {
        guard let audioContent = try? Data(contentsOf: url).base64EncodedString() else {
            errorHandler("cannot read audio file")
            return
        }

        notify(
            title: NSLocalizedString("action.loading_title", value: "Transcribing ...", comment: "Notification title while transcription in progress"),
            body: NSLocalizedString("action.loading_body", value: "Please wait a moment", comment: "Notification body while transcription in progress")
        )

        let data = [
            "audio": [
                "content": audioContent
            ],
            "config": [
                "languageCode": Transcript.getLanguage(),
                "encoding": "OGG_OPUS",
                "sampleRateHertz": 16000
            ]
        ]
        // TODO get that out of the app
        let key = "AIzaSyBfLWNF5Ygz2s9MQDNBWK9pY8ZdcAcj2x4"

        guard JSONSerialization.isValidJSONObject(data) else {
            errorHandler("json fail")
            return
        }

        guard let json = try? JSONSerialization.data(withJSONObject: data) else {
            errorHandler("serialization fail")
            return
        }
        os_log("asking google", log: OSLog.default, type: .debug)
        // there is a streaming API which might be faster than waiting to upload everything
        post(url: URL(string: "https://speech.googleapis.com/v1/speech:recognize?key=\(key)")!, data: json) {
            guard let transcript = Transcript.init(googleSpeechApiResponse: $0) else {
                self.errorHandler("response invalid")
                return
            }
            completionHandler(transcript)
        }
    }

    func beginRequest(with context: NSExtensionContext) {
        os_log("extension requested", log: OSLog.default, type: .debug)
        self.extensionContext = context
        var found = false
        outer:
            // filter the correct data type out of the received objects and send it to the callback function
            for item in context.inputItems as! [NSExtensionItem] {
                if let attachments = item.attachments {
                    for itemProvider in attachments as! [NSItemProvider] {
                        if itemProvider.hasItemConformingToTypeIdentifier(String(kUTTypeURL)) {
                            itemProvider.loadItem(forTypeIdentifier: String(kUTTypeURL), options: nil) { (item, error) in
                                if error != nil {
                                    self.errorHandler(error as! String)
                                }
                                self.receivedUrl(url: item as! URL)
                            }
                            found = true
                            break outer
                        }
                    }
                }
        }
        
        if !found {
            errorHandler("No audio found")
        }
    }

    func receivedUrl(url: URL) {
        OperationQueue.main.addOperation {
            self.recognizeFileGoogle(url: url, completionHandler: self.done)
        }
    }

    func recognizeFileApple(url: URL, completionHandler: @escaping (Transcript) -> ()) {
        askPermission()
        guard let recognizer = SFSpeechRecognizer() else {
            errorHandler("locale not supported")
            return
        }
        if !recognizer.isAvailable {
            errorHandler("not available, e.g. no internet")
            return
        }
        let request = SFSpeechURLRecognitionRequest(url: url)
        os_log("asking apple", log: OSLog.default, type: .debug)
        recognizer.recognitionTask(with: request) { (result, error) in
            guard let result = result else {
                self.errorHandler(error as! String)
                return
            }
            if result.isFinal {
                guard let transcript = Transcript.init(appleSpeechApiResponse: result) else {
                    self.errorHandler("result parsing failed")
                    return
                }
                completionHandler(transcript)
            }
        }
    }

    func done(_ transcript: Transcript) {
        os_log("sending notify, saving transcript", log: OSLog.default, type: .debug)
        self.notify(
            title: NSLocalizedString("action.transcript_ready", value: "Speech to text:", comment: "Notification title when transcription is done"),
            body: transcript.text
        )
        transcript.save()
        // clean up request
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
        self.extensionContext = nil
    }

}
