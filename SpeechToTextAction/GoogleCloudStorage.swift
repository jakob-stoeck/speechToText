//
//  GoogleCloudStorage.swift
//  SpeechToText
//
//  Created by jaksto on 5/14/19.
//  Copyright © 2019 Jakob Stoeck. All rights reserved.
//

import Foundation

enum GoogleStorageError: Error {
    case initFailed, uploadLocationMissing, noUploadResponse, uploadWithoutRange, maxRetries, wrongStatusCode(statusCode: Int)
}

extension GoogleStorageError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .wrongStatusCode(let statusCode):
            return String.localizedStringWithFormat(NSLocalizedString("error.wrongStatusCode", value: "Wrong status code: %d", comment: ""), statusCode)
        case .initFailed:
            return NSLocalizedString("error.initFailed", value: "Initial upload failed", comment: "")
        case .maxRetries:
            return NSLocalizedString("error.maxRetries", value: "Upload failed after maximum retries", comment: "")
        case .uploadLocationMissing:
            return NSLocalizedString("error.uploadLocationMissing", value: "Upload failed due to missing URL", comment: "")
        case .noUploadResponse:
            return NSLocalizedString("error.noUploadResponse", value: "Upload failed", comment: "")
        case .uploadWithoutRange:
            return NSLocalizedString("error.uploadWithoutRange", value: "Resume upload failed", comment: "")
        }
    }
}


typealias HTTPCompletionHandler = (HTTPURLResponse?, GoogleStorageError?) -> Void

class Storage {
    var session: URLSession
    let host: String
    let apiKey: String

    init(host: String, apiKey: String) {
        self.session = URLSession.shared
        self.host = host
        self.apiKey = apiKey
    }
    
    func upload(bucket: String, name: String, data: Data, completion: @escaping HTTPCompletionHandler) {
        guard let url = URL.init(string: "https://\(host)/upload/storage/v1/b/\(bucket)/o?uploadType=resumable&name=\(name)&key=\(apiKey)") else {
            return completion(nil, .uploadLocationMissing)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("0", forHTTPHeaderField: "Content-Length")
        request.setValue("\(data.count)", forHTTPHeaderField: "X-Upload-Content-Length")
        request.setValue(Bundle.main.bundleIdentifier!, forHTTPHeaderField: "X-Ios-Bundle-Identifier")

        session.dataTask(with: request) { respData, resp, err in
            if err != nil {
                // todo do something with the original error
                return completion(nil, .initFailed)
            }
            guard let httpResp = resp as? HTTPURLResponse else {
                return completion(nil, .initFailed)
            }
            if httpResp.statusCode != 200 {
                return completion(nil, .wrongStatusCode(statusCode: httpResp.statusCode))
            }
            guard let location = httpResp.allHeaderFields["Location"] as? String, let url = URL.init(string: location) else {
                return completion(nil, .uploadLocationMissing)
            }
            self.dataUpload(url: url, data: data, completion: completion)
        }.resume()
    }
    
    func dataUpload(url: URL, data: Data, lastByte: Int = -1, retries: Int = 10, completion: @escaping HTTPCompletionHandler) {
        let nextByte = lastByte+1
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = data[nextByte...]
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        if nextByte > 0 {
            // resuming download
            request.setValue("\(nextByte)/\(data.count)", forHTTPHeaderField: "Range")
        }
        
        session.dataTask(with: request) { data, resp, err in
            if err != nil {
                return completion(nil, err as? GoogleStorageError)
            }
            guard let resp = resp as? HTTPURLResponse, let data = data else {
                return completion(nil, .noUploadResponse)
            }
            switch resp.statusCode {
            case 200, 201:
                // file is complete
                return completion(resp, nil)
            case 308:
                // file is incomplete, resume upload
                guard let range = resp.allHeaderFields["Range"] as? String, let lastByte = Int(range.split(separator: "-")[1]) else {
                    return completion(nil, .uploadWithoutRange)
                }
                if retries > 0 {
                    self.dataUpload(url: url, data: data, lastByte: lastByte, retries: retries-1, completion: completion)
                } else {
                    return completion(nil, .maxRetries)
                }
            default:
                return completion(nil, .wrongStatusCode(statusCode: resp.statusCode))
            }
        }.resume()
    }
}
