//
//  ViewController.swift
//  SpeechToText
//
//  Created by Jakob Stoeck on 5/9/17.
//  Copyright © 2017 Jakob Stoeck. All rights reserved.
//

// TODO show error messages
// TODO show error when notifications are disabled

import UIKit
import os.log

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.loadData()
        NotificationCenter.default.addObserver(forName: Notification.Name.UIApplicationWillEnterForeground, object: nil, queue: nil) {_ in
            os_log("app will enter foreground", log: OSLog.default, type: .debug)
            self.loadData()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func loadData() {
        os_log("loading last transcript", log: OSLog.default, type: .debug)
        let lang = Settings.getLanguage()
        let format = NSLocalizedString("main.change_language", value: "Voice language: %@. Tap to change.", comment: "Button title to change language")
        self.openSettingsButton.setTitle(String.localizedStringWithFormat(format, lang), for: UIControlState.normal)
        let lastMessage = Transcript.getLastMessage()
        if lastMessage == "" {
            lastMessageTextField.text = NSLocalizedString("main.last_message", value: "Your last speech to text message will appear here", comment: "Placeholder when there is no last message yet")
        }
        else {
            lastMessageTextField.text = lastMessage
        }
    }

    //MARK: Properties
    @IBOutlet weak var lastMessageTextField: UITextView!
    @IBOutlet weak var openSettingsButton: UIButton!

    //MARK: Actions
    @IBAction func clear(_ sender: UIBarButtonItem) {
        Transcript.init(text: NSLocalizedString("main.deleted", value: "(deleted) 👻", comment: "Displayed when text was deleted"))?.save()
        loadData()
    }

    @IBAction func openSettings(_ sender: UIButton) {
        UIApplication.shared.open(URL(string:UIApplicationOpenSettingsURLString)!)
    }
}

