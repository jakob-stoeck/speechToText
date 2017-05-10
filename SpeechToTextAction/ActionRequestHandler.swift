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
                    break;
                case .restricted:
                    break
                case .notDetermined:
                    break
                }
            }
        }
    }

    func post(url: URL, data: Data, completionHandler: @escaping ([String: Any]) -> ()) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        let session = URLSession.shared
        session.dataTask(with: request) {data, response, err in
            if err != nil {
                print(err.debugDescription)
            }
            if data != nil {
                print(String(data: data!, encoding: .utf8)!)
                completionHandler(try! JSONSerialization.jsonObject(with: data!) as! [String: Any])
            }
        }.resume()
    }

    func notify(title: String, body: String) {
        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .sound]
        center.requestAuthorization(options: options) {
            (granted, error) in
            if !granted {
                print("Something went wrong")
            }
        }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let identifier = "STTLocalNotification"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request, withCompletionHandler: { (error) in
            if error != nil {
                print("Notification went wrong")
            }
        })
    }

    func recognizeFileGoogle(url: URL, completionHandler: @escaping (String) -> ()) {
        let data = [
            "audio": [
                "content": NSData(contentsOf: url)!.base64EncodedString()
            ],
            "config": [
                "languageCode": "de-DE",
                "encoding": "OGG_OPUS",
                "sampleRateHertz": 16000
            ]
        ]
        let key = "AIzaSyBfLWNF5Ygz2s9MQDNBWK9pY8ZdcAcj2x4"

        guard JSONSerialization.isValidJSONObject(data) else {
            print("json fail")
            return
        }

        guard let json = try? JSONSerialization.data(withJSONObject: data) else {
            print ("serialization fail")
            return
        }
        print("asking google")
        post(url: URL(string: "https://speech.googleapis.com/v1/speech:recognize?key=\(key)")!, data: json, completionHandler: { (dictionary) in
            // TODO map over all results and concatenate the transcripts
            if let results = dictionary["results"] as? [[String: Any]],
                let alternatives = results[0]["alternatives"] as? [[String: Any]],
                let transcript = alternatives[0]["transcript"] as? String {
                    completionHandler(transcript)
            }
        })
    }

    func beginRequest(with context: NSExtensionContext) {
        print("extension requested")
        askPermission()
        self.extensionContext = context

        var found = false

        // Find the item containing the results from the JavaScript preprocessing.
        outer:
            for item in context.inputItems as! [NSExtensionItem] {
                if let attachments = item.attachments {
                    for itemProvider in attachments as! [NSItemProvider] {
                        if itemProvider.hasItemConformingToTypeIdentifier(String(kUTTypeURL)) {
                            itemProvider.loadItem(forTypeIdentifier: String(kUTTypeURL), options: nil, completionHandler: { (item, error) in
                                // file:///private/var/mobile/Containers/Data/Application/4203177E-CF60-49B1-AC06-257D70DF91AA/tmp/documents/C5D72611-79EE-4F83-B93F-38D8C51DD911/2017-05-10-AUDIO-00001224.opus
                                OperationQueue.main.addOperation {
                                    self.recognizeFileGoogle(url: item as! URL, completionHandler: self.done)
//                                    notify(title: "Speech to text", body: result)
                                }
                            })
                            found = true
                            break outer
                        }
                    }
                }
        }
        
        if !found {
            self.done(nil)
        }
    }

    func recognizeFileApple(url: URL, completionHandler: @escaping (String) -> ()) {
        guard let recognizer = SFSpeechRecognizer() else {
            // locale not supported
            return
        }
        if !recognizer.isAvailable {
            // not available, e.g. no internet
            return
        }
        let request = SFSpeechURLRecognitionRequest(url: url)
        print("asking apple")
        recognizer.recognitionTask(with: request) { (result, error) in
            guard let result = result else {
                print(error!)
                return
            }
            if result.isFinal {
                completionHandler(result.bestTranscription.formattedString)
            }
        }
    }

    func done(_ transcript: String?) {
        if transcript != nil {
            self.notify(title: "Speech to text", body: transcript!)
        }
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
        self.extensionContext = nil
    }

//    func doneWithResults(_ resultsForJavaScriptFinalizeArg: [String: Any]?) {
//        if let resultsForJavaScriptFinalize = resultsForJavaScriptFinalizeArg {
//            // Construct an NSExtensionItem of the appropriate type to return our
//            // results dictionary in.
//            
//            // These will be used as the arguments to the JavaScript finalize()
//            // method.
//            
//            let resultsDictionary = [NSExtensionJavaScriptFinalizeArgumentKey: resultsForJavaScriptFinalize]
//            
//            let resultsProvider = NSItemProvider(item: resultsDictionary as NSDictionary, typeIdentifier: String(kUTTypePropertyList))
//            
//            let resultsItem = NSExtensionItem()
//            resultsItem.attachments = [resultsProvider]
//            
//            // Signal that we're complete, returning our results.
//            self.extensionContext!.completeRequest(returningItems: [resultsItem], completionHandler: nil)
//        } else {
//            // We still need to signal that we're done even if we have nothing to
//            // pass back.
//            self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
//        }
//        
//        // Don't hold on to this after we finished with it.
//        self.extensionContext = nil
//    }

}
