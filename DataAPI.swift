/////
//
//  DataAPI.swift
//  A service class written for Swift 4.x, to work with the FileMaker 17 Data API
//
//  Created by Brian Hamm on 9/16/18.
//  Copyright © 2018 Brian Hamm. All rights reserved.
//

import Foundation

class DataAPI {
    
//  let auth = UserDefaults.standard.string(forKey: "fm-auth")     // set from CloudKit on launch, or...
//  static let auth = "xxxxxadjfkla;dfj..."
    
//  let path = UserDefaults.standard.string(forKey: "fm-db-path")  // set from CloudKit on launch, or...
//  static let path = "http://xxxxxjala;jk..."
    
    
    
    // active token?
    class func isActiveToken() -> Bool {
        
        let token   = UserDefaults.standard.string(forKey: "fm-token")
        let expiry  = UserDefaults.standard.object(forKey: "fm-token-expiry") as? Date ?? Date(timeIntervalSince1970: 0)
        
        if let _ = token, expiry > Date() {
            return true
        } else {
            return false
        }
    }
    
    
    
    // refresh token -> (token, expiry, error)
    class func refreshToken(for auth: String, completion: @escaping (String, Date, String) -> Void) {
        
        guard   let path = UserDefaults.standard.string(forKey: "fm-db-path"),
                let baseURL = URL(string: path) else { return }
        
        let url = baseURL.appendingPathComponent("/sessions")
        let expiry = Date(timeIntervalSinceNow: 900)   // 15 minutes
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Basic \(auth)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            
            guard   let data      = data, error == nil,
                    let json      = try? JSONSerialization.jsonObject(with: data) as! [String: Any],
                    let response  = json["response"] as? [String: Any],
                    let messages  = json["messages"] as? [[String: Any]],
                    let code      = messages[0]["code"] as? String else { return }
            
            guard let token = response["token"] as? String else {
                print(messages)
                return
            }
            
            UserDefaults.standard.set(token, forKey: "fm-token")
            UserDefaults.standard.set(expiry, forKey: "fm-token-expiry")
            
            completion(token, expiry, code)
            
        }.resume()
    }
    
    
    
    
    // get records -> ([records], error)
    class func getRecords(token: String, layout: String, limit: Int, completion: @escaping ([[String: Any]], String) -> Void) {
        
        guard   let path = UserDefaults.standard.string(forKey: "fm-db-path"),
                let baseURL = URL(string: path) else { return }
        
        let url = baseURL.appendingPathComponent("/layouts/\(layout)/records?_offset=1&_limit=\(limit)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            
            guard   let data      = data, error == nil,
                    let json      = try? JSONSerialization.jsonObject(with: data) as! [String: Any],
                    let response  = json["response"] as? [String: Any],
                    let messages  = json["messages"] as? [[String: Any]],
                    let code      = messages[0]["code"] as? String else { return }
            
            guard let records = response["data"] as? [[String: Any]] else {
                print(messages)
                return
            }
            
            completion(records, code)
            
        }.resume()
    }

    
    
    
    // find request -> ([records], error)
    class func findRequest(token: String, layout: String, payload: [String: Any], completion: @escaping ([[String: Any]], String) -> Void) {
        
        //  payload = ["query": [             payload = ["query": [
        //    ["firstName": "Brian"],           "firstName": "Brian",
        //    ["firstName": Geoff"]             "lastName": "Hamm"
        //  ]]                                ]]
        
        guard   let path = UserDefaults.standard.string(forKey: "fm-db-path"),
                let baseURL = URL(string: path),
                let body = try? JSONSerialization.data(withJSONObject: payload) else { return }
        
        let url = baseURL.appendingPathComponent("/layouts/\(layout)/_find")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            
            guard   let data      = data, error == nil,
                    let json      = try? JSONSerialization.jsonObject(with: data) as! [String: Any],
                    let response  = json["response"] as? [String: Any],
                    let messages  = json["messages"] as? [[String: Any]],
                    let code      = messages[0]["code"] as? String else { return }
            
            guard let records = response["data"] as? [[String: Any]] else {
                print(messages)
                return
            }
            
            completion(records, code)
            
        }.resume()
    }
    
    
    
    
    // get record with id -> (record, error)
    class func getRecordWith(id: Int, token: String, layout: String, completion: @escaping ([String: Any], String) -> Void) {
        
        guard   let path = UserDefaults.standard.string(forKey: "fm-db-path"),
                let baseURL = URL(string: path) else { return }
        
        let url = baseURL.appendingPathComponent("/layouts/\(layout)/records/\(id)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            
            guard   let data      = data, error == nil,
                    let json      = try? JSONSerialization.jsonObject(with: data) as! [String: Any],
                    let response  = json["response"] as? [String: Any],
                    let messages  = json["messages"] as? [[String: Any]],
                    let code      = messages[0]["code"] as? String else { return }
            
            guard let records = response["data"] as? [[String: Any]] else {
                print(messages)
                return
            }
            
            completion(records[0], code)
            
        }.resume()
    }
    
    
    
    
    // delete record with id -> (error)
    class func deleteRecordWith(id: Int, token: String, layout: String, completion: @escaping (String) -> Void) {
        
        guard   let path = UserDefaults.standard.string(forKey: "fm-db-path"),
                let baseURL = URL(string: path) else { return }
        
        let url = baseURL.appendingPathComponent("/layouts/\(layout)/records/\(id)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            
            guard   let data      = data, error == nil,
                    let json      = try? JSONSerialization.jsonObject(with: data) as! [String: Any],
                    let messages  = json["messages"] as? [[String: Any]],
                    let code      = messages[0]["code"] as? String else { return }
            
            guard error == "0" else {
                print(messages)
                return
            }
            
            completion(code)
            
        }.resume()
    }
    
    
    
    
    // edit record with id -> (error)
    class func editRecordWith(id: Int, token: String, layout: String, payload: [String: Any], modID: Int?, completion: @escaping (String) -> Void) {
        
        //  payload = ["fieldData": [
        //    "firstName": "newValue",
        //    "lastName": newValue"
        //  ]]
        
        guard   let path = UserDefaults.standard.string(forKey: "fm-db-path"),
                let baseURL = URL(string: path),
                let body = try? JSONSerialization.data(withJSONObject: payload) else { return }
        
        let url = baseURL.appendingPathComponent("/layouts/\(layout)/records/\(id)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            
            guard   let data      = data, error == nil,
                    let json      = try? JSONSerialization.jsonObject(with: data) as! [String: Any],
                    let messages  = json["messages"] as? [[String: Any]],
                    let code      = messages[0]["code"] as? String else { return }
            
            guard error == "0" else {
                print(messages)
                return
            }
            
            completion(code)
            
        }.resume()
    }
    
    
    
    
    
    /*
     
     400     Bad request             Occurs when the server cannot process the request due to a client error.
     401     Unauthorized            Occurs when the client is not authorized to access the API. If this error occurs when attempting to log in to a database session, then there is a problem with the specified user account or password. If this error occurs with other calls, the access token is not specified or it is not valid.
     403     Forbidden               Occurs when the client is authorized, but the call attempts an action that is forbidden for a different reason.
     404     Not found               Occurs if the call uses a URL with an invalid URL schema. Check the specified URL for syntax errors.
     405     Method not allowed      Occurs when an incorrect HTTP method is used with a call.
     415     Unsupported media type  Occurs if the required header is missing or is not correct for the request: For requests that require "Content-Type: application/json" header, occurs if the "Content-Type: application/json" header is not specified or if a different content type was specified instead of the "application/json" type. For requests that require "Content-Type: multipart/form-data" header, occurs if the "Content-Type: multipart/form-data" header is not specified or if a different content type was specified instead of the "multipart/form-data" type.
     500     FileMaker Server error  Includes FileMaker error messages and error codes. See FileMaker error codes in FileMaker Pro Advanced Help.
     
     */
    
    
}
