//
//  ActionViewController.swift
//  SpeechToTextViewer
//
//  Created by jaksto on 2/23/19.
//  Copyright © 2019 Jakob Stoeck. All rights reserved.
//

import UIKit
import MobileCoreServices
import os.log

class ActionViewController: UIViewController {
    
    @IBOutlet weak var message: UITextView!
    
    func receivedUrl(url: URL) {
        onTranscription(text: NSLocalizedString("action.loading_title", value: "Transcribing ...", comment: "Notification title while transcription in progress"))
        
        let candidates: [SpeechRecognizer] = [ GoogleStreamingSpeechRecognizer.sharedInstance, GoogleJsonSpeechRecognizer.sharedInstance, AppleSpeechRecognizer.sharedInstance ]
        guard let best = candidates.first(where: { $0.supports(url: url) }) else {
            return Util.errorHandler("No suitable speech recognizer found")
        }
        
        best.recognize(
            url: url,
            lang: Settings.getLanguage(),
            onUpdate: self.onTranscription,
            onEnd: self.onTranscription,
            onError: { error in Util.errorHandler(error) }
        )
    }
    
    func onTranscription(text: String) {
        os_log("onTranscription: \"%@\"", log: OSLog.default, type: .debug, text)
        guard let strongMessage = self.message else {
            return
        }
        strongMessage.text = text
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        // Get the item[s] we're handling from the extension context.
        // Replace this with something appropriate for the type[s] your extension supports.
        var found = false
        let type = kUTTypeURL as String
//        let type = kUTTypeText as String
        for item in self.extensionContext!.inputItems as! [NSExtensionItem] {
            for provider in item.attachments! {
                if provider.hasItemConformingToTypeIdentifier(type) {
                    provider.loadItem(forTypeIdentifier: type, options: nil) { (item, error) in
                        if error != nil {
                            Util.errorHandler(error as! String)
                        }
                        DispatchQueue.main.async {
                            self.receivedUrl(url: item as! URL)
                        }
                        return
                    }
                    found = true
                    break
                }
            }
            
            if (found) {
                // We only handle one image, so stop looking for more.
                break
            }
        }
        Util.errorHandler(NSLocalizedString("action.error", value: "No attachment found", comment: "There was no attachment which could have been used"))
    }

    @IBAction func done() {
        // Return any edited content to the host app.
        // This template doesn't do anything, so we just echo the passed in items.
        self.extensionContext!.completeRequest(returningItems: self.extensionContext!.inputItems, completionHandler: nil)
    }

}
