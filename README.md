# SwiftFM
SwiftFM is a service class for working with the FileMaker Data API. Swift 4.2+ and Xcode 9.4+ required.

- - -


# Overview
This `README.md` is aimed at FileMaker devs who want to integrate the v17 Data API into their iOS projects. Each function is paired with an example. Everything shown below is part of the `DataAPI.swift` file, in this repo.

- - -
 
 
# Class Vars and Lets
A `let` is a constant, in Swift.

During testing it may be easier to hardcode `baseURL` and `auth` values, but best practice is to fetch that information from elsewhere and (optionally) park it in `UserDefaults`. Do not deploy apps with tokens or credentials visible in code.

I like to fetch my environment settings from CloudKit, in `didFinishLaunching` or `didEnterForeground`. Doing it this way also provides a remote kill-switch, if necessary.
 
```swift
import UIKit
 
class ViewController: UIViewController {
 
//  let baseURL = "https://<hostName>/fmi/data/v1/databases/<databaseName>"
//  let auth    = "xxxxxxxabcdefg1234567"  // base64 "user:pass"

    let baseURL = UserDefaults.standard.string(forKey: "fm-db-path")  // better
    let auth    = UserDefaults.standard.string(forKey: "fm-auth")     //
  
    var token   = UserDefaults.standard.string(forKey: "fm-token")
    var expiry  = UserDefaults.standard.object(forKey: "fm-token-expiry") as? Date ?? Date(timeIntervalSince1970: 0)
    // ...
}
```
 
- - -
 
 
# Active Token (function)
A simple `bool` check to see if there's an existing token and whether or not it's expired. The `_` means we aren't using (don't care about) the token value right now, we only care that there /is/ one.

```swift
// swift bools return either 'true' or 'false'
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
// active token?
switch isActiveToken() {  

case true:
    print("token \(self.token) - expiry \(self.expiry)")  
    // do stuff with self.token
 
case false:
    refreshToken(for: self.auth, completion: { newToken, newExpiry, error in
    
        guard error == "0" else {
            print("refresh token sad.")  // optionally handle non-zero errors
            return
        }
        
        print("token \(newToken) - expiry \(newExpiry)")  
        // do stuff with newToken
    })
}    
```
 
 - - -
 
 
# Refresh Token (function)
Refresh an expired token. The `@escaping` marker allows the `token`, `expiry`, and error `code` types to be used later (they're permitted to "escape" or outlive the function). That's typical for async calls in Swift.

```swift
// returns -> (token, expiry, error code)
func refreshToken(for auth: String, completion: @escaping (String, Date, String) -> Void) {
    
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
                let code      = messages[0]["code"] as? String,
                let message   = messages[0]["message"] as? String else { return }
        
        guard let token = response["token"] as? String else {
            print(message)  // optionally pass message to UIAlertController
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
// refresh token
refreshToken(for: self.auth, completion: { newToken, newExpiry, error in

    guard error == "0" else { 
        print("refresh token sad.")  // optionally handle non-zero errors
        return 
    }

    print("token \(newToken) - expiry \(newExpiry)")
    // do stuff with newToken
})
```

- - - 

 
# Get Records (function)
Returns an array of records with an offset of 1. This could be refactored to include an `offset` parameter if you'll be doing a lot of recursive calls/paginating records.
```swift
// returns -> ([records], error code)
func getRecords(token: String, layout: String, limit: Int, completion: @escaping ([[String: Any]], String) -> Void) {
    
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
                let code      = messages[0]["code"] as? String,
                let message   = messages[0]["message"] as? String else { return }
        
        guard let records = response["data"] as? [[String: Any]] else {
            print(message)  // optionally pass message to UIAlertController
            return
        }
        
        completion(records, code)
        
    }.resume()
}
```

### Example
```swift
// get first 20 records
getRecords(token: self.token, layout: myLayout, limit: 20, completion: { records, error in

    guard error == "0" else { 
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


# Find Request (function)
Note the difference in payload between an "or" request vs. an "and" request. You can set your payload from the UI, or hardcode a query (like this). Then pass your payload as a parameter.

```swift
// returns -> ([records], error code)
func findRequest(token: String, layout: String, payload: [String: Any], completion: @escaping ([[String: Any]], String) -> Void) {
    
    //  myPayload = ["query": [           myPayload = ["query": [
    //      ["firstName": "Brian"],           "firstName": "Brian",
    //      ["firstName": "Geoff"]            "lastName": "Hamm"
    //  ]]                                ]]
    
    guard   let path = UserDefaults.standard.string(forKey: "fm-db-path"),
            let baseURL = URL(string: path),
            let body = try? JSONSerialization.data(withJSONObject: myPayload) else { return }
    
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
                let code      = messages[0]["code"] as? String,
                let message   = messages[0]["message"] as? String else { return }
        
        guard let records = response["data"] as? [[String: Any]] else {
            print(message)  // optionally pass message to UIAlertController
            return
        }
        
        completion(records, code)
        
    }.resume()
}
```

### Example
```swift
// find request
findRequest(token: self.token, layout: myLayout, payload: myPayload, completion: { records, error in

    guard error == "0" else { 
        print("find request sad.")  // optionally handle non-zero errors
        return 
    }
    
    // array!
    for record in records {
        // deserialize with Codable, append object array, refresh UI
    }
}
```

- - -


# Get Record (function)
Fetch a record with `recID`.
```swift
// returns -> (record, error code)
func getRecordWith(id: Int, token: String, layout: String, completion: @escaping ([String: Any], String) -> Void) {
    
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
                let code      = messages[0]["code"] as? String,
                let message   = messages[0]["message"] as? String else { return }
        
        guard let records = response["data"] as? [[String: Any]] else {
            print(message)  // optionally pass message to UIAlertController
            return
        }
        
        completion(records[0], code)
        
    }.resume()
}
```
 
### Example
```swift
// get record
getRecordWith(id: recID, token: self.token, layout: myLayout, completion: { record, error in

    guard error == "0" else { 
        print("get record sad.")  // optionally handle non-zero errors
        return 
    }
    
    // record!
    // deserialize with Codable, refresh UI
}
```

- - -


# Delete Record (function)
Delete record with `recID`. Only an error code is returned with this function.
```swift
// returns -> (error code)
func deleteRecordWith(id: Int, token: String, layout: String, completion: @escaping (String) -> Void) {
    
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
                        
        completion(code)
        
    }.resume()
}
```

### Example
```swift
// delete record
deleteRecordWith(id: recID, token: self.token, layout: myLayout, completion: { error in
    
    guard error == "0" else { 
        print("delete record sad.")  // optionally handle non-zero errors
        return 
    }
    
    // deleted!
    // remove object from local array, refresh UI
}
```

- - -


# Edit Record (function)
Edit record with `recID`. Only pass values for the fields you want to modify. Optionally, you may include the `modID` (from your last fetch), to check that the server record isn't newer than the one you're editing. Passing an outdated `modID` will cause an edit request to fail. /Not/ including a `modID` will post the request.

Only an error code is returned with this function. The v17 Data API does not currently pass back a modified record object for you to use. Because of this, you may wish to refetch the record and update the view.
```swift
// returns -> (error code)
func editRecordWith(id: Int, token: String, layout: String, payload: [String: Any], modID: Int?, completion: @escaping (String) -> Void) {
    
    //  myPayload = ["fieldData": [
    //      "firstName": "newValue",
    //      "lastName": "newValue"
    //  ]]
    
    guard   let path = UserDefaults.standard.string(forKey: "fm-db-path"),
            let baseURL = URL(string: path),
            let body = try? JSONSerialization.data(withJSONObject: myPayload) else { return }
    
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
                                
        completion(code)
        
    }.resume()
}
```

### Example
```swift
// edit record
editRecordWith(id: recID, token: self.token, layout: myLayout, playload: myPayload, completion: { error in

    guard error == "0" else {
        print("edit record sad.")  // optionally handle non-zero errors
        return
    }
    
    // edited!
    // refetch record using recID, referesh UI
}
```

- - -
