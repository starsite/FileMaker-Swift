# SwiftFM
SwiftFM is a service class for working with the FileMaker Data API. Swift 4.2+ and Xcode 9.4+ required.

- - -


# Overview
This `README.md` is aimed at FileMaker devs who want to integrate the v17 Data API into their iOS projects. Each function is paired with an example. Everything shown below is part of the `DataAPI.swift` file, in this repo.

- - -
 
 
# Class Vars and Lets
A `let` is a constant, in Swift.

During testing, you may hardcode `baseURL` and `auth` values as below, but best practice is to fetch that information from elsewhere and (optionally) park it in `UserDefaults`. Do not deploy apps with tokens or credentials visible in code.

I like to fetch my environment settings from CloudKit, in `didFinishLaunching` or `didEnterForeground`. Doing it this way also provides a remote kill-switch, if necessary. You could also fetch from Firebase, or another service.
 
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
        
    if let _ = token, expiry > Date() {
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
    print("active token - expiry \(self.expiry)")
    // do stuff
 
case false:
    refreshToken(for: auth, completion: { newToken, newExpiry in
        print("new token - expiry \(newExpiry)")
        // do stuff
    })
}    
```
 
 - - -
 
 
# Refresh Token (function)
Refresh an expired token. The `@escaping` marker allows the `token`, `expiry`, and `error` types to be used later (they're permitted to "escape" or outlive the function). That's typical for async calls in Swift.

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
                let error     = messages[0]["code"] as? String else { return }
        
        guard let token = response["token"] as? String else {
            print(messages)
            return
        }
        
        UserDefaults.standard.set(token, forKey: "fm-token")
        UserDefaults.standard.set(expiry, forKey: "fm-token-expiry")
        
        completion(token, expiry, error)
        
    }.resume()
}
```

### Example
```swift
// refresh token
refreshToken(for: auth, completion: { newToken, newExpiry in

    print("new token - expiry \(newExpiry)")
    // updated values written to UserDefaults.standard
})
```

- - - 

 
# Get Records (function)
Returns an array of records with an offset of 1. This could be refactored to include an `offset` parameter, for recursive calls/paginating records.
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
                let error     = messages[0]["code"] as? String else { return }
        
        guard let records = response["data"] as? [[String: Any]] else {
            print(messages)
            return
        }
        
        completion(records, error)
        
    }.resume()
}
```

### Example
```swift
// get first 20 records
getRecords(token: myToken, layout: myLayout, limit: 20, completion: { records, error in

    // request error
    guard error == "0" else {
        print("get records sad.")
        return 
    }
    
    // successful request, no records returned
    guard let records = records else {
        print("no records.")
        return
    }
    
    // array!
    for record in records {
        // deserialize with Codable, append object array, load table or collection view
    }
}
```

- - -


# Find Request (function)
Note the difference in payload when building an "or" request vs. an "and" request. You can set your payload from a `UITextField`, or hardcode a query (like this). Then pass the payload as a parameter.

```swift
// returns -> ([records], error code)
func findRequest(token: String, layout: String, payload: [String: Any], completion: @escaping ([[String: Any]], String) -> Void) {
    
    //  myPayload = ["query": [           myPayload = ["query": [
    //    ["firstName": "Brian"],           "firstName": "Brian",
    //    ["firstName": Geoff"]             "lastName": "Hamm"
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
                let error     = messages[0]["code"] as? String else { return }
        
        guard let records = response["data"] as? [[String: Any]] else {
            print(messages)
            return
        }
        
        completion(records, error)
        
    }.resume()
}
```

### Example
```swift
// find request
findRequest(token: myToken, layout: myLayout, payload: myPayload, completion: { records, error in

    guard error == "0" else { 
        print("find request sad.")
        return 
    }
    
    guard let records = records else {
        print("no records found.")
        return
    }
    
    // array!
    for record in records {
        // deserialize with Codable, append object array, load table or collection view
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
                let error     = messages[0]["code"] as? String else { return }
        
        guard let records = response["data"] as? [[String: Any]] else {
            print(messages)
            return
        }
        
        completion(records[0], error)
        
    }.resume()
}
```
 
### Example
```swift
// get record
getRecordWith(id: recID, token: myToken, layout: myLayout, completion: { record, error in

    guard error == "0" else { 
        print("get record sad.")
        return 
    }
    
    guard let record = record else { 
        print("no record with id.")
        return 
    }
    
    // record!
    // deserialize with Codable, load view
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
                let error     = messages[0]["code"] as? String else { return }
        
        guard error == "0" else {
            print(messages)
            return
        }
        
        completion(error)
        
    }.resume()
}
```

### Example
```swift
// delete record
deleteRecordWith(id: recID, token: myToken, layout: myLayout, completion: { error in

    guard error == "0" else {
        print("delete record sad.")
        return
    }
    
    // deleted!
    // remove object from local array, reload view
}
```

- - -


# Edit Record (function)
Edit record with `recID`. Only pass new values for the fields you want to modify. Optionally, you may include the `modID` (from your last fetch), to check that the server record isn't newer than the one you're editing. Passing an outdated `modID` will cause an edit request to fail. /Not/ including a `modID` will post the request.

Only an error code is returned with this function. The v17 Data API does not currently pass back a modified record object for you to use. Because of this, you may wish to refetch the record and update the view.
```swift
// returns -> (error code)
func editRecordWith(id: Int, token: String, layout: String, payload: [String: Any], modID: Int?, completion: @escaping (String) -> Void) {
    
    //  myPayload = ["fieldData": [
    //      "firstName": "newValue",
    //      "lastName": newValue"
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
                let error     = messages[0]["code"] as? String else { return }
        
        guard error == "0" else {
            print(messages)
            return
        }
        
        completion(error)
        
    }.resume()
}
```

### Example
```swift
// edit record
editRecordWith(id: recID, token: myToken, layout: myLayout, playload: myPayload, completion: { error in

    guard error == "0" else {
        print("edit record sad.")
        return
    }
    
    // edited!
    // refetch updated record, reload view
}
```

- - -
