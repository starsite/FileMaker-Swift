# SwiftFM

SwiftFM is a Swift wrapper for working with the FileMaker Data API. Swift 4 or later required.

---

### 🚨 FileMaker v19

I just got my hands on the v19 Data API (I'm not FBA). Looking at it right now and will update the repo as needed.

---

### Overview

This `README.md` is aimed at FileMaker devs who want to integrate the Data API into their Xcode projects. Each function is paired with an example. Everything shown below is part of the `DataAPI.swift` class, in this repo.

* [`isActiveToken()`](#active-token-function)
* [`refreshToken(for:)`](#refresh-token-function)
* [`deleteToken(_:)`](#delete-token-function)
* [`createRecord(token:layout:payload:)`](#create-record-function)
* [`duplicateRecordWith(id:token:layout)`](#duplicate-record-with-id-function) » v18 or later
* [`getRecords(token:layout:offset:limit:)`](#get-records-function)
* [`findRequest(token:layout:payload:)`](#find-request-function)
* [`deleteRecordWith(id:token:layout:)`](#delete-record-with-id-function)
* [`editRecordWith(id:token:layout:payload:modId:)`](#edit-record-with-id-function)
* [`setGlobalFields(token:payload:)`](#set-global-fields-function) » v18 or later

---

### Environment

A `let` is a constant, in Swift.

During testing it may be easier to hardcode `path` and `auth` values, but best practice is to fetch that information from elsewhere and (optionally) park it in `UserDefaults`. Do not deploy apps with tokens or credentials visible in code.

I like to fetch my environment settings from CloudKit, in `application(_:didFinishLaunchingWithOptions)` or `applicationWillEnterForeground(_:)`. Doing it this way also provides an optional remote kill-switch.

```swift
import UIKit
 
class ViewController: UIViewController {
 
//  let path   = "https://<hostName>/fmi/data/v1/databases/<databaseName>"
//  let auth   = "xxxxxxxabcdefg1234567"  // base64 "user:pass"

    let path   = UserDefaults.standard.string(forKey: "fm-db-path")  // better
    let auth   = UserDefaults.standard.string(forKey: "fm-auth")     //
 
    var token  = UserDefaults.standard.string(forKey: "fm-token")
    var expiry = UserDefaults.standard.object(forKey: "fm-token-expiry") as? Date ?? Date(timeIntervalSince1970: 0)
    // ...
}
```

---


### Active Token (function)
A simple `bool` check to see if there's an existing token and whether or not it's expired. The `_` means we aren't using (don't care about) the token value right now, we only care that there /is/ one.

```swift
// swift bools return 'true' or 'false'
func isActiveToken() -> Bool {
        
    if let _ = self.token, self.expiry > Date() {
        return true
    } else {
        return false
    }
}
```

### Example

```swift
switch isActiveToken() {  

case true:
    print("token \(self.token) - expiry \(self.expiry)")  
    // do stuff with self.token
 
case false:
    refreshToken(for: self.auth, completion: { token, expiry, code in
    
        guard let token = token, let expiry = expiry else {
            print("refresh token sad.")  // optionally handle non-zero errors
            return
        }
        
        print("token \(token) - expiry \(expiry)")  
        // do stuff with updated token
    })
}    
```

---


### Refresh Token (function)

Returns an optional token and expiry. The `@escaping` marker allows the `token?`, `expiry?`, and error `code` types to be used later (they're permitted to "escape" or outlive the function). That's typical for async calls in Swift.

```swift
// returns -> (token?, expiry?, error code)
func refreshToken(for auth: String, completion: @escaping (String?, Date?, String) -> Void) {
    
    guard   let path = UserDefaults.standard.string(forKey: "fm-db-path"),
            let baseURL = URL(string: path) else { return }
    
    let url = baseURL.appendingPathComponent("/sessions")
    let expiry = Date(timeIntervalSinceNow: 900)   // 15 minutes
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Basic \(auth)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    URLSession.shared.dataTask(with: request) { data, _, error in
        
        guard   let data     = data, error == nil,
                let json     = try? JSONSerialization.jsonObject(with: data) as! [String: Any],
                let response = json["response"] as? [String: Any],
                let messages = json["messages"] as? [[String: Any]],
                let code     = messages[0]["code"] as? String,
                let message  = messages[0]["message"] as? String else { return }
        
        guard let token = response["token"] as? String else {
            print(message)  // optionally pass message to UIAlertController
            completion(nil, nil, code)
            return
        }
        
        UserDefaults.standard.set(token, forKey: "fm-token")
        UserDefaults.standard.set(expiry, forKey: "fm-token-expiry")
        
        completion(token, expiry, code)
        
    }.resume()
}
```

### Example

```swift
refreshToken(for: self.auth, completion: { token, expiry, code in

    guard let token = token, let expiry = expiry else { 
        print("refresh token sad.")  // optionally handle non-zero errors
        return 
    }

    print("token \(token) - expiry \(expiry)")
    // do stuff with updated token
})
```

---


### Delete Token (function)

End a user session. Only an error `code` is returned with this function. For iOS apps, you might elect to call this in `applicationDidEnterBackground(_:)`. There is reportedly a 500-session limit in FMS 18, so this may be useful for larger deployments. If you don't delete a session token, it will expire 15 minutes after the last API call.
```swift
// returns -> (code)
func deleteToken(_ token: String, completion: @escaping (String) -> Void) {

    guard   let path = UserDefaults.standard.string(forKey: "fm-db-path"),
            let baseURL = URL(string: path) else { return }

    let url = baseURL.appendingPathComponent("/sessions/\(token)")

    var request = URLRequest(url: url)
    request.httpMethod = "DELETE"

    URLSession.shared.dataTask(with: request) { data, _, error in

        guard   let data     = data, error == nil,
                let json     = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let messages = json["messages"] as? [[String: Any]],
                let code     = messages[0]["code"] as? String,
                let message  = messages[0]["message"] as? String else { return }

        guard code == "0" else {
            print(message)
            completion(code)
            return
        }
        
        UserDefaults.standard.set(nil, forKey: "fm-token")
        UserDefaults.standard.set(0, forKey: "fm-token-expiry")
        
        completion(code)

    }.resume()
}
```

### Example

```swift
deleteToken(self.token, completion: { code in

    guard code == "0" else {
        print("delete token sad.")  // optionally handle non-zero errors
        return
    }
    
    // logged out!
})
```

---


### Create Record (function)

Creates a new record with a payload. Pass an empty `fieldData` object to create an empty record.

```swift
// returns -> (recordId?, code)
func createRecord(token: String, layout: String, payload: [String: Any], completion: @escaping (String?, String) -> Void ) {
             
    //  payload = ["fieldData": [
    //    "firstName": "Brian",
    //    "lastName": "Hamm",
    //    "age": 47
    //  ]]
    
    guard   let path = UserDefaults.standard.string(forKey: "fm-db-path"),
            let baseURL = URL(string: path),
            let body = try? JSONSerialization.data(withJSONObject: payload) else { return }

    let url = baseURL.appendingPathComponent("/layouts/\(layout)/records")
        
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = body

    URLSession.shared.dataTask(with: request) { data, _, error in
            
        guard   let data     = data, error == nil,
                let json     = try? JSONSerialization.jsonObject(with: data) as! [String: Any],
                let response = json["response"] as? [String: Any],
                let messages = json["messages"] as? [[String: Any]],
                let code     = messages[0]["code"] as? String,
                let message  = messages[0]["message"] as? String else { return }
                                               
        guard let recordId = response["recordId"] as? String else {
            print(message)
            completion(nil, code)
            return
        }
  
        completion(recordId, code)
            
    }.resume()
}
```

### Example

```swift
createRecord(token: self.token, layout: myLayout, payload: myPayload, completion: { recordId, code in

    guard let recordId = recordId else { 
        print("create record sad.")  // optionally handle non-zero errors
        return 
    }
    
    // record!
    print("new recordId: \(recordId)")
}
```

---


### Duplicate Record With ID (function)

Data API v18 or later. Only an error `code` is returned with this function. Note: this function is very similar to `getRecordWith(id:)`. Both require the `recordId`. The primary difference is `getRecordWith(id:)` is a GET, and `duplicateRecordWith(id:)` is a POST.

```swift
// returns -> (code)
func duplicateRecordWith(id: Int, token: String, layout: String, completion: @escaping (String) -> Void) {
    
    guard   let path = UserDefaults.standard.string(forKey: "fm-db-path"),
            let baseURL = URL(string: path) else { return }
    
    let url = baseURL.appendingPathComponent("/layouts/\(layout)/records/\(id)")
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    URLSession.shared.dataTask(with: request) { data, _, error in
        
        guard   let data     = data, error == nil,
                let json     = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let messages = json["messages"] as? [[String: Any]],
                let code     = messages[0]["code"] as? String,
                let message  = messages[0]["message"] as? String else { return }
        
        guard code == "0" else {
            print(message)
            completion(code)
            return
        }
        
        completion(code)
        
    }.resume()
}
```

### Example

```swift
duplicateRecordWith(id: recordId, token: self.token, layout: myLayout, completion: { code in

    guard code == "0" else { 
        print("duplicate record sad.")  // optionally handle non-zero errors
        return 
    }
    
    // new duplicate record!
}
```

---


### Get Records (function)

Returns an optional array of records with an offset and limit.

```swift
// returns -> ([records]?, code)
func getRecords(token: String, layout: String, offset: Int, limit: Int, completion: @escaping ([[String: Any]]?, String) -> Void) {
    
    guard   let path = UserDefaults.standard.string(forKey: "fm-db-path"),
            let baseURL = URL(string: path) else { return }
    
    let url = baseURL.appendingPathComponent("/layouts/\(layout)/records?_offset=\(offset)&_limit=\(limit)")
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    URLSession.shared.dataTask(with: request) { data, _, error in
        
        guard   let data     = data, error == nil,
                let json     = try? JSONSerialization.jsonObject(with: data) as! [String: Any],
                let response = json["response"] as? [String: Any],
                let messages = json["messages"] as? [[String: Any]],
                let code     = messages[0]["code"] as? String,
                let message  = messages[0]["message"] as? String else { return }
        
        guard let records = response["data"] as? [[String: Any]] else {
            print(message)  // optionally pass message to UIAlertController
            completion(nil, code)
            return
        }
        
        completion(records, code)
        
    }.resume()
}
```

### Example

```swift
// get the first 20 records
getRecords(token: self.token, layout: myLayout, offset: 1, limit: 20, completion: { records, code in

    guard let records = records else { 
        print("get records sad.")  // optionally handle non-zero errors
        return 
    }
    
    // array!
    for record in records {
        // deserialize with Codable, append object array, refresh UI
    }
}
```

- - -


### Find Request (function)

Returns an optional array of records. Note the difference in payload between an "or" request vs. an "and" request. You can set your payload from the UI, or hardcode a query (like this). Then pass your payload as a parameter.

```swift
// returns -> ([records]?, error code)
func findRequest(token: String, layout: String, payload: [String: Any], completion: @escaping ([[String: Any]]?, String) -> Void) {
    
    //  payload = ["query": [           payload = ["query": [
    //    ["firstName": "Brian"],         ["firstName": "Brian",
    //    ["firstName": "Geoff"]          "lastName": "Hamm"]
    //  ]]                              ]]
    
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
        
        guard   let data     = data, error == nil,
                let json     = try? JSONSerialization.jsonObject(with: data) as! [String: Any],
                let response = json["response"] as? [String: Any],
                let messages = json["messages"] as? [[String: Any]],
                let code     = messages[0]["code"] as? String,
                let message  = messages[0]["message"] as? String else { return }
        
        guard let records = response["data"] as? [[String: Any]] else {
            print(message)  // optionally pass message to UIAlertController
            completion(nil, code)
            return
        }
        
        completion(records, code)
        
    }.resume()
}
```

### Example

```swift
findRequest(token: self.token, layout: myLayout, payload: myPayload, completion: { records, code in

    guard let records = records else { 
        print("find request sad.")  // optionally handle non-zero errors
        return 
    }
    
    // array!
    for record in records {
        // deserialize with Codable, append object array, refresh UI
    }
}
```

---


### Get Record With ID (function)
Get a single record with `recordId`. Returns an optional record.
```swift
// returns -> (record?, code)
func getRecordWith(id: Int, token: String, layout: String, completion: @escaping ([String: Any]?, String) -> Void) {
    
    guard   let path = UserDefaults.standard.string(forKey: "fm-db-path"),
            let baseURL = URL(string: path) else { return }
    
    let url = baseURL.appendingPathComponent("/layouts/\(layout)/records/\(id)")
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    URLSession.shared.dataTask(with: request) { data, _, error in
        
        guard   let data     = data, error == nil,
                let json     = try? JSONSerialization.jsonObject(with: data) as! [String: Any],
                let response = json["response"] as? [String: Any],
                let messages = json["messages"] as? [[String: Any]],
                let code     = messages[0]["code"] as? String,
                let message  = messages[0]["message"] as? String else { return }
        
        guard let records = response["data"] as? [[String: Any]] else {
            print(message)  // optionally pass message to UIAlertController
            completion(nil, code)
            return
        }
        
        completion(records[0], code)
        
    }.resume()
}
```

### Example

```swift
getRecordWith(id: recordId, token: self.token, layout: myLayout, completion: { record, code in

    guard let record = record else { 
        print("get record sad.")  // optionally handle non-zero errors
        return 
    }
    
    // record!
    // deserialize with Codable, refresh UI
}
```

- - -


### Delete Record With ID (function)
Delete record with `recordId`. Only an error code is returned with this function.
```swift
// returns -> (code)
func deleteRecordWith(id: Int, token: String, layout: String, completion: @escaping (String) -> Void) {
    
    guard   let path = UserDefaults.standard.string(forKey: "fm-db-path"),
            let baseURL = URL(string: path) else { return }
    
    let url = baseURL.appendingPathComponent("/layouts/\(layout)/records/\(id)")
    
    var request = URLRequest(url: url)
    request.httpMethod = "DELETE"
    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    URLSession.shared.dataTask(with: request) { data, _, error in
        
        guard   let data     = data, error == nil,
                let json     = try? JSONSerialization.jsonObject(with: data) as! [String: Any],
                let messages = json["messages"] as? [[String: Any]],
                let code     = messages[0]["code"] as? String,
                let message  = messages[0]["message"] as? String else { return }
                
        guard code == "0" else {
            print(message)
            completion(code)
            return
        }
                        
        completion(code)
        
    }.resume()
}
```

### Example

```swift
deleteRecordWith(id: recordId, token: self.token, layout: myLayout, completion: { code in
    
    guard code == "0" else { 
        print("delete record sad.")  // optionally handle non-zero errors
        return 
    }
    
    // deleted!
    // remove object from local array, refresh UI
}
```

- - -


### Edit Record With ID (function)

Edit record with `recordId`. Pass values for the fields you want to modify. Optionally, you can include the `modId` from a previous fetch, to ensure the server record isn't newer than the one you're editing. If you pass `modId`, a record will be edited only when the `modId` matches.

Only an error code is returned with this function. The Data API does not currently pass back a modified record object for you to use. Because of this, you may want to refetch the record afterward.

```swift
// returns -> (code)
func editRecordWith(id: Int, token: String, layout: String, payload: [String: Any], modId: Int?, completion: @escaping (String) -> Void) {
    
    //  payload = ["fieldData": [
    //    "firstName": "newValue",
    //    "lastName": "newValue"
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
        
        guard   let data     = data, error == nil,
                let json     = try? JSONSerialization.jsonObject(with: data) as! [String: Any],
                let messages = json["messages"] as? [[String: Any]],
                let code     = messages[0]["code"] as? String,
                let message  = messages[0]["message"] as? String else { return }
                
        guard code == "0" else {
            print(message)
            completion(code)
            return
        }
                                
        completion(code)
        
    }.resume()
}
```

### Example

```swift
editRecordWith(id: recordId, token: self.token, layout: myLayout, payload: myPayload, modId: nil, completion: { code in

    guard code == "0" else {
        print("edit record sad.")  // optionally handle non-zero errors
        return
    }
    
    // edited!
    // refetch record using recordId, referesh UI
}
```

---


### Set Global Fields (function)

Data API v18 or later. Only an error `code` is returned with this function. Note: this function is very similar to `editRecordWith(id:)`. Both accept a simple set of key-value pairs, and they're both PATCH methods. The main difference is the payload key and the `/globals` endpoint.

```swift
// set global fields -> (code)
func setGlobalFields(token: String, payload: [String: Any], completion: @escaping (String) -> Void) {
    
    //  payload = ["globalFields": [
    //    "fieldName": "value",
    //    "fieldName": "value"
    //  ]]
    
    guard   let path = UserDefaults.standard.string(forKey: "fm-db-path"),
            let baseURL = URL(string: path),
            let body = try? JSONSerialization.data(withJSONObject: payload) else { return }
    
    let url = baseURL.appendingPathComponent("/globals")
    
    var request = URLRequest(url: url)
    request.httpMethod = "PATCH"
    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = body
    
    URLSession.shared.dataTask(with: request) { data, _, error in
        
        guard   let data     = data, error == nil,
                let json     = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let messages = json["messages"] as? [[String: Any]],
                let code     = messages[0]["code"] as? String,
                let message  = messages[0]["message"] as? String else { return }
        
        guard code == "0" else {
            print(message)
            completion(code)
            return
        }
        
        completion(code)
        
    }.resume()
}
```

### Example

```swift
setGlobalFields(token: self.token, payload: myPayload, completion: { code in

    guard code == "0" else {
        print("set globals sad.")  // optionally handle non-zero errors
        return
    }
    
    // globals set!
}
```
