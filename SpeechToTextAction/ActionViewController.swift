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
    @IBOutlet weak var openSettingsButton: UIButton!
    
    func receivedUrl(url: URL) {
        onTranscription(text: NSLocalizedString("action.loading_title", value: "Transcribing ...", comment: "Notification title while transcription in progress"))
        
        let candidates: [SpeechRecognizer] = [ GoogleStreamingSpeechRecognizer.sharedInstance, GoogleAsyncSpeechRecognizer.sharedInstance, AppleSpeechRecognizer.sharedInstance ]
        guard let best = candidates.first(where: { $0.supports(url: url) }) else {
            return Util.errorHandler("No suitable speech recognizer found")
        }
        
        best.recognize(
            url: url,
            lang: Settings.getLanguage(),
            onUpdate: self.onTranscription,
            onEnd: self.onTranscription,
            onError: self.onError
        )
    }
    
    func onError(_ text: String) {
        let alert = UIAlertController(title: "Error",
                                      message: text,
                                      preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "OK",
                                      style: UIAlertAction.Style.default,
                                      handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func onTranscription(text: String) {
        os_log("onTranscription: \"%@\"", log: OSLog.default, type: .debug, text)
        guard let strongMessage = self.message else {
            return
        }
        DispatchQueue.main.async {
            strongMessage.text = text
        }
        Transcript(text)?.save()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        let lang = Settings.getLanguage()
        let format = NSLocalizedString("main.change_language", value: "Voice language: %@. Tap to change.", comment: "Button title to change language")
        self.openSettingsButton.setTitle(String.localizedStringWithFormat(format, lang), for: UIControl.State.normal)
        
        // Get the item[s] we're handling from the extension context.
        // Replace this with something appropriate for the type[s] your extension supports.
        var found = false
        let type = kUTTypeURL as String
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

    //MARK: Actions
    @IBAction func openSettings(_ sender: UIButton) {
        // https://stackoverflow.com/questions/48381778/open-settings-app-from-today-extension-widget
        let url = URL(string:"whatshesaid://settings")!
        extensionContext?.open(url, completionHandler: { (success) in
            if !success {
                var responder = self as UIResponder?
                while (responder != nil){
                    let selectorOpenURL = NSSelectorFromString("openURL:")
                    if responder?.responds(to: selectorOpenURL) == true {
                        _ = responder?.perform(selectorOpenURL, with: url)
                    }
                    responder = responder?.next
                }
            }
        })
    }

    @IBAction func done() {
        // Return any edited content to the host app.
        // This template doesn't do anything, so we just echo the passed in items.
        self.extensionContext!.completeRequest(returningItems: self.extensionContext!.inputItems, completionHandler: nil)
    }

}
