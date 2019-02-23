//
//  ActionRequestHandler.swift
//  SpeechToTextAction
//
//  Created by Jakob Stoeck on 5/9/17.
//  Copyright © 2017 Jakob Stoeck. All rights reserved.
//

import UIKit
import MobileCoreServices
import os.log

class ActionRequestHandler: NSObject, NSExtensionRequestHandling {

    var extensionContext: NSExtensionContext?

    func beginRequest(with context: NSExtensionContext) {
        os_log("extension requested", log: OSLog.default, type: .debug)
        self.extensionContext = context
        var found = false
        outer:
            // filter the correct data type out of the received objects and send it to the callback function
            for item in context.inputItems as! [NSExtensionItem] {
                if let attachments = item.attachments {
                    for itemProvider in attachments {
                        if itemProvider.hasItemConformingToTypeIdentifier(String(kUTTypeURL)) {
                            itemProvider.loadItem(forTypeIdentifier: String(kUTTypeURL), options: nil) { (item, error) in
                                if error != nil {
                                    Util.errorHandler(error as! String)
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
            Util.errorHandler(NSLocalizedString("action.error", value: "No audio found", comment: "There was no item which could have been speech recognized"))
        }
    }

    func receivedUrl(url: URL) {
        Util.notify(
            title: NSLocalizedString("action.loading_title", value: "Transcribing ...", comment: "Notification title while transcription in progress"),
            body: NSLocalizedString("action.loading_body", value: "Please wait a moment", comment: "Notification body while transcription in progress")
        )

        OperationQueue.main.addOperation {
            SpeechRecognizer.recognizeFile(url: url) {transcript in
                Util.notify(
                    title: NSLocalizedString("action.transcript_ready", value: "Speech to text:", comment: "Notification title when transcription is done"),
                    body: transcript.text,
                    removePending: true
                )
                transcript.save()
                self.cleanUp()
            }
        }
    }

    func cleanUp() {
        if self.extensionContext != nil {
            self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
            self.extensionContext = nil
        }
    }
}
