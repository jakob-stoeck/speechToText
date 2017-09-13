//
//  Util.swift
//  SpeechToText
//
//  Created by Jakob Stoeck on 9/13/17.
//  Copyright © 2017 Jakob Stoeck. All rights reserved.
//

import UIKit
import MobileCoreServices
import Speech
import UserNotifications
import os.log

class Util {
    class func post(url: URL, data: Data, completionHandler: @escaping (Data) -> ()) {
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

    class func notify(title: String?, body: String, removePending: Bool = false) {
        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert]
        center.requestAuthorization(options: options) {
            (granted, error) in
            if !granted {
                os_log("Something went wrong", log: OSLog.default, type: .error)
            }
        }
        let content = UNMutableNotificationContent()
        if title != nil {
            content.title = title!
        }
        content.body = body
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.01, repeats: false)
        let identifier = UUID().uuidString
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        if removePending {
            center.removeAllDeliveredNotifications()
            center.removeAllPendingNotificationRequests()
        }
        center.add(request, withCompletionHandler: { (error) in
            if error != nil {
                os_log("Notification went wrong", log: OSLog.default, type: .error)
            }
        })
        os_log("notification request: \"%@\": \"%@\"", log: OSLog.default, type: .debug, title ?? "", body)
    }

    class func errorHandler(_ text: String, title: String = NSLocalizedString("util.error.title", value: "Error", comment: "Title of a generic error message")) {
        os_log("%@: %@", log: OSLog.default, type: .error, title, text)
        notify(title: title, body: text)
    }

}
