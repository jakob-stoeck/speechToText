//
//  GoogleLongrunningOperations.swift
//  SpeechToText
//
//  Created by jaksto on 4/19/19.
//  Copyright © 2019 Jakob Stoeck. All rights reserved.
//

import Foundation
import googleapis

typealias Operation = googleapis.Operation

class GoogleLongrunningOperations {
    private let client: Operations
    private let apiKey: String
    private let pollInterval: Int
 
    init(host: String, apiKey: String, pollInterval: Int = 5) {
        self.client = Operations.init(host: host)
        self.apiKey = apiKey
        self.pollInterval = pollInterval
    }
    
    func wait(op: Operation?, onDone: @escaping (Operation?, Error?) -> Void) {
        return wait(op: op, err: nil, onDone: onDone)
    }

    private func wait(op: Operation?, err: Error?, onDone: @escaping (Operation?, Error?) -> Void) {
        guard let op = op else {
            return onDone(nil, err)
        }
        if op.done {
            return onDone(op, err)
        }
        else {
            // poll until operation is complete
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(pollInterval)) {
                self.get(op: op, onDone: onDone)
            }
        }
    }
    
    private func get(op: Operation, onDone: @escaping (Operation?, Error?) -> Void) {
        let opReq = GetOperationRequest()
        opReq.name = op.name
        let call = client.rpcToGetOperation(with: opReq) { (op, err) in
            if (err != nil) {
                return onDone(nil, err)
            }
            self.wait(op: op, err: err, onDone: onDone)
        }
        call.requestHeaders.setObject(NSString(string:self.apiKey), forKey:NSString(string:"X-Goog-Api-Key"))
        call.requestHeaders.setObject(NSString(string:Bundle.main.bundleIdentifier!), forKey:NSString(string:"X-Ios-Bundle-Identifier"))
        call.start()
    }
}
