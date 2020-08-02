//  DataAPI.swift
//
//  Created by Brian Hamm on 9/16/18.
//  Copyright © 2018 Brian Hamm. All rights reserved.



import Foundation


class DataAPI {
    
    
                                    /* Environment */
    
/* Set your host, db, and auth values in the AppDelegate, in applicationWillEnterForeground(). */
/* For TESTING, you can set these values with string literals.                                 */
/* For PRODUCTION, you should be fetching these values from elsewhere.                         */
/*                                                                                             */
/* *DO NOT* deploy apps with credentials visible in code.                                      */
    
        
//      let host = "my.server.com"
//      let db   = "my_database"
//      let auth = "xxxxxabcde12345"   // base64 -> "user:pass"
//
//      UserDefaults.standard.set(host, forKey: "fm-host")
//      UserDefaults.standard.set(db, forKey: "fm-db")
//      UserDefaults.standard.set(auth, forKey: "fm-auth")
    
    
    
    
                                /* Refreshing Tokens */

/* After setting your environment, fetch a new token in applicationWillEnterForeground() */

    
//      if let auth = UserDefaults.standard.string(forKey: "fm-auth") {
//
//          DataAPI.refreshToken(auth: auth, completion: { token, _, message in
//              guard let token = token else {
//                  print(message)
//                  return
//              }
//              print("new token: \(token)")
//          })
//      }

    
    
                                /* Deleting Tokens */

/* Delete tokens in applicationDidEnterBackground() *AND* in applicationWillTerminate(). */
    
    
//      if let token = UserDefaults.standard.string(forKey: "fm-token") {
//
//          DataAPI.deleteToken(token, completion: { code, message in
//              guard code == "0" else {
//                  print(message)
//                  return
//              }
//          })
//      }

    
    
    
                    /* Wrapping calls with validateSession() */

/* When making calls in your app, validate the token and fetch a new one if neccessary. */
    
    
//      let auth  = UserDefaults.standard.string(forKey: "fm-auth") ?? ""
//      let token = UserDefaults.standard.string(forKey: "fm-token") ?? ""
//
//      DataAPI.validateSession(token: token, completion: { success, _ in
//
//          switch success {
//          case true:
//              // do stuff with 'token'
//              self.myFunction(token: token)    
//
//          case false:
//              DataAPI.refreshToken(auth: auth, completion: { token, _, message in
//                  guard let token = token else {
//                      print(message)
//                      return
//                  }
//                  // do stuff with 'newToken'
//                  self.myFunction(token: newToken)                    
//              })
//          }
//      })
    
    
    
        
    // MARK: - validate session -> (bool, message)
    
    class func validateSession(token: String, completion: @escaping (Bool, String) -> Void) {
                
        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
                let url  = URL(string: "https://\(host)/fmi/data/vLatest/validateSession") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, resp, error in
            
            guard   let data     = data, error == nil,
                    let json     = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let messages = json["messages"] as? [[String: Any]],
                    let code     = messages[0]["code"] as? String,
                    let message  = messages[0]["message"] as? String else { return }
            
            guard code == "0" else {
                completion(false, message)
                return
            }
            
            completion(true, message)
        
        }.resume()
    }
        
    
    
    
    
    // MARK: - refresh token -> (token?, code, message)
    
    class func refreshToken(auth: String, completion: @escaping (String?, String, String) -> Void) {
                
        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
                let db   = UserDefaults.standard.string(forKey: "fm-db"),
                let url  = URL(string: "https://\(host)/fmi/data/vLatest/databases/\(db)/sessions") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Basic \(auth)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, resp, error in
            
            guard   let data     = data, error == nil,
                    let json     = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let response = json["response"] as? [String: Any],
                    let messages = json["messages"] as? [[String: Any]],
                    let code     = messages[0]["code"] as? String,
                    let message  = messages[0]["message"] as? String else { return }
            
            guard let token = response["token"] as? String else {
                completion(nil, code, message)
                return
            }
            
            UserDefaults.standard.set(token, forKey: "fm-token")
            completion(token, code, message)
            
        }.resume()
    }
    
    
    
    
    
    // MARK: - delete token -> (code, message)
    
    class func deleteToken(_ token: String, completion: @escaping (String, String) -> Void) {
            
        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
                let db   = UserDefaults.standard.string(forKey: "fm-db"),
                let url  = URL(string: "https://\(host)/fmi/data/vLatest/databases/\(db)/sessions/\(token)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { data, resp, error in
            
            guard   let data     = data, error == nil,
                    let json     = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let messages = json["messages"] as? [[String: Any]],
                    let code     = messages[0]["code"] as? String,
                    let message  = messages[0]["message"] as? String else { return }
            
            guard code == "0" else {
                completion(code, message)
                return
            }
            
            UserDefaults.standard.set(nil, forKey: "fm-token")
            completion(code, message)
            
        }.resume()
    }
    
    
    
    
        
    // MARK: - create record -> (recordId?, code, message)
    
    class func createRecord(token: String,
                            layout: String,
                            payload: [String: Any],
                            completion: @escaping (String?, String, String) -> Void ) {
        
        //  payload = ["fieldData": [
        //    "firstName": "Brian",
        //    "lastName": "Hamm",
        //    "age": 47
        //  ]]
        
        //  payload = ["fieldData": []]    <-- creates an empty record
        
        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
                let db   = UserDefaults.standard.string(forKey: "fm-db"),
                let url  = URL(string: "https://\(host)/fmi/data/vLatest/databases/\(db)/layouts/\(layout)/records"),
                let body = try? JSONSerialization.data(withJSONObject: payload) else { return }
                
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, resp, error in
            
            guard   let data     = data, error == nil,
                    let json     = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let response = json["response"] as? [String: Any],
                    let messages = json["messages"] as? [[String: Any]],
                    let code     = messages[0]["code"] as? String,
                    let message  = messages[0]["message"] as? String else { return }
            
            guard let recordId = response["recordId"] as? String else {
                completion(nil, code, message)
                return
            }
            
            completion(recordId, code, message)
            
        }.resume()
    }

    
    

    
    // MARK: - duplicate record with id -> (code, message)
    
    class func duplicateRecordWith(id: Int,
                                   token: String,
                                   layout: String,
                                   completion: @escaping (String, String) -> Void) {
        
        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
                let db   = UserDefaults.standard.string(forKey: "fm-db"),
                let url  = URL(string: "https://\(host)/fmi/data/vLatest/databases/\(db)/layouts/\(layout)/records/\(id)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, resp, error in
            
            guard   let data     = data, error == nil,
                    let json     = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let messages = json["messages"] as? [[String: Any]],
                    let code     = messages[0]["code"] as? String,
                    let message  = messages[0]["message"] as? String else { return }
            
            guard code == "0" else {
                completion(code, message)
                return
            }
            
            completion(code, message)
            
        }.resume()
    }

    
    
    
    
    // MARK: - get records -> ([records]?, code, message)
    
    class func getRecords(token: String,
                          layout: String,
                          offset: Int,
                          limit: Int,
                          completion: @escaping ([[String: Any]]?, String, String) -> Void) {
        
        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
                let db   = UserDefaults.standard.string(forKey: "fm-db"),
                let url  = URL(string: "https://\(host)/fmi/data/vLatest/databases/\(db)/layouts/\(layout)/records?_offset=\(offset)&_limit=\(limit)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, resp, error in
            
            guard   let data     = data, error == nil,
                    let json     = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let response = json["response"] as? [String: Any],
                    let messages = json["messages"] as? [[String: Any]],
                    let code     = messages[0]["code"] as? String,
                    let message  = messages[0]["message"] as? String else { return }
            
            guard let records = response["data"] as? [[String: Any]] else {
                completion(nil, code, message)
                return
            }
            
            completion(records, code, message)
            
        }.resume()
    }

    

    
    
    // MARK: - find request -> ([records]?, code, message)
    
    class func findRequest(token: String,
                           layout: String,
                           payload: [String: Any],
                           completion: @escaping ([[String: Any]]?, String, String) -> Void) {
        
        //  payload = ["query": [             payload = ["query": [
        //    ["firstName": "Brian"],           ["firstName": "Brian",
        //    ["firstName": Geoff"]             "lastName": "Hamm"]
        //  ]]                                ]]
        
        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
                let db   = UserDefaults.standard.string(forKey: "fm-db"),
                let url  = URL(string: "https://\(host)/fmi/data/vLatest/databases/\(db)/layouts/\(layout)/_find"),
                let body = try? JSONSerialization.data(withJSONObject: payload) else { return }
                
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, resp, error in
            
            guard   let data     = data, error == nil,
                    let json     = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let response = json["response"] as? [String: Any],
                    let messages = json["messages"] as? [[String: Any]],
                    let code     = messages[0]["code"] as? String,
                    let message  = messages[0]["message"] as? String else { return }
            
            guard let records = response["data"] as? [[String: Any]] else {
                completion(nil, code, message)
                return
            }
            
            completion(records, code, message)
            
        }.resume()
    }
    
    
    
    
    
    // MARK: - get record with id -> (record?, code, message)
    
    class func getRecordWith(id: Int,
                             token: String,
                             layout: String,
                             completion: @escaping ([String: Any]?, String, String) -> Void) {
        
        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
                let db   = UserDefaults.standard.string(forKey: "fm-db"),
                let url  = URL(string: "https://\(host)/fmi/data/vLatest/databases/\(db)/layouts/\(layout)/records/\(id)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, resp, error in
            
            guard   let data     = data, error == nil,
                    let json     = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let response = json["response"] as? [String: Any],
                    let messages = json["messages"] as? [[String: Any]],
                    let code     = messages[0]["code"] as? String,
                    let message  = messages[0]["message"] as? String else { return }
            
            guard let records = response["data"] as? [[String: Any]] else {
                completion(nil, code, message)
                return
            }
            
            completion(records[0], code, message)
            
        }.resume()
    }
    
    
    
    
    
    // MARK: - delete record with id -> (code, message)
    
    class func deleteRecordWith(id: Int,
                                token: String,
                                layout: String,
                                completion: @escaping (String, String) -> Void) {
        
        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
                let db   = UserDefaults.standard.string(forKey: "fm-db"),
                let url  = URL(string: "https://\(host)/fmi/data/vLatest/databases/\(db)/layouts/\(layout)/records/\(id)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, resp, error in
            
            guard   let data     = data, error == nil,
                    let json     = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let messages = json["messages"] as? [[String: Any]],
                    let code     = messages[0]["code"] as? String,
                    let message  = messages[0]["message"] as? String else { return }
            
            guard code == "0" else {
                completion(code, message)
                return
            }
            
            completion(code, message)
            
        }.resume()
    }

    
    
    
        
    // MARK: - edit record with id -> (code, message)
    
    class func editRecordWith(id: Int,
                              token: String,
                              layout: String,
                              payload: [String: Any],
                              modId: Int?,
                              completion: @escaping (String, String) -> Void) {
        
        //  payload = ["fieldData": [
        //    "firstName": "newValue",
        //    "lastName": "newValue"
        //  ]]
        
        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
                let db   = UserDefaults.standard.string(forKey: "fm-db"),
                let url  = URL(string: "https://\(host)/fmi/data/vLatest/databases/\(db)/layouts/\(layout)/records/\(id)"),
                let body = try? JSONSerialization.data(withJSONObject: payload) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, resp, error in
            
            guard   let data     = data, error == nil,
                    let json     = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let messages = json["messages"] as? [[String: Any]],
                    let code     = messages[0]["code"] as? String,
                    let message  = messages[0]["message"] as? String else { return }
        
            guard code == "0" else {
                completion(code, message)
                return
            }
            
            completion(code, message)
            
        }.resume()
    }
    
    
    
    
    
    // MARK: - set global fields -> (code, message)
    
    class func setGlobalFields(token: String,
                               payload: [String: Any],
                               completion: @escaping (String, String) -> Void) {
        
        //  payload = ["globalFields": [
        //    "fieldName": "value",
        //    "fieldName": "value"
        //  ]]
        
        guard   let host = UserDefaults.standard.string(forKey: "fm-host"),
                let db   = UserDefaults.standard.string(forKey: "fm-db"),
                let url  = URL(string: "https://\(host)/fmi/data/vLatest/databases/\(db)/globals"),
                let body = try? JSONSerialization.data(withJSONObject: payload) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, resp, error in
            
            guard   let data     = data, error == nil,
                    let json     = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let messages = json["messages"] as? [[String: Any]],
                    let code     = messages[0]["code"] as? String,
                    let message  = messages[0]["message"] as? String else { return }
            
            guard code == "0" else {
                completion(code, message)
                return
            }
            
            completion(code, message)
            
        }.resume()
    }

    
    
    
    
    /* MARK: - Error Codes
     
    400     Bad request
     
    Occurs when the server cannot process the request due to a client error.
 
    401     Unauthorized
     
    Occurs when the client is not authorized to access the API. If this error occurs when attempting to log in to a database session, then there is a problem with the specified user account or password. If this error occurs with other calls, the access token is not specified or it is not valid.
 
    403     Forbidden
     
    Occurs when the client is authorized, but the call attempts an action that is forbidden for a different reason.
 
    404     Not found
    
    Occurs if the call uses a URL with an invalid URL schema. Check the specified URL for syntax errors.

    405     Method not allowed
    
    Occurs when an incorrect HTTP method is used with a call.

    415     Unsupported media type
    
    Occurs if the required header is missing or is not correct for the request: For requests that require "Content-Type: application/json" header, occurs if the "Content-Type: application/json" header is not specified or if a different content type was specified instead of the "application/json" type. For requests that require "Content-Type: multipart/form-data" header, occurs if the "Content-Type: multipart/form-data" header is not specified or if a different content type specified instead of the "multipart/form-data" type.

    500     FileMaker Server error
    
    Includes FileMaker error messages and error codes. See FileMaker error codes in FileMaker Pro Advanced Help.

    */
    
}
