//
//  ViewController.swift
//  SpeechToText
//
//  Created by Jakob Stoeck on 5/9/17.
//  Copyright © 2017 Jakob Stoeck. All rights reserved.
//

import UIKit
import os.log

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.loadData), name: NSNotification.Name(rawValue: "LastTranscriptShouldRefresh"), object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        loadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func loadData() {
        os_log("loading last transcript", log: OSLog.default, type: .debug)
        guard let text = Transcript.init(userDefaultsKey: "lastTranscript")?.text else {
            return
        }
        lastMessageTextField.text = text
    }

    //MARK: Properties
    @IBOutlet weak var lastMessageTextField: UITextView!

    //MARK: Actions
    @IBAction func clearLastMessage(_ sender: UIButton) {
        Transcript.init(text: "(deleted) 👻")?.save(userDefaultsKey: "lastTranscript")
        loadData()
    }

}

