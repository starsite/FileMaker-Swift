# SwiftFM
SwiftFM is a service class for working with the FileMaker Data API. (Swift 4.2+, Xcode 9.4+)

- - -
 
## Class Vars and Lets
A `let` is a constant, in Swift.

During testing, you can hardcode `baseURL` and `auth` values as below, but best practice is to fetch that information from elsewhere and (optionally) park it in `UserDefaults`. 

I like to fetch my environment settings from CloudKit, in `didFinishLaunching` or `didEnterForeground`. Doing it that way also provides a remote kill-switch, if necessary.
 
```swift
import UIKit
 
class ViewController: UIViewController {
 
//  let baseURL = "https://<hostName>/fmi/data/v1/databases/<databaseName>"
//  let auth    = "xxxxxxxabcdefg1234567"  // base64 "user:pass"

    let baseURL = UserDefaults.standard.string(forKey: "fm-db-path")  // better
    let auth    = UserDefaults.standard.string(forKey: "fm-auth")     //
  
    var token   = UserDefaults.standard.string(forKey: "fm-token")
    var expiry  = UserDefaults.standard.object(forKey: "fm-token-expiry") as? Date ?? Date(timeIntervalSince1970: 0)  
}
```
 
- - -
 
## Active Token? (function)
Bool check to see if there's an existing token and whether or not it's expired. The `_` means we aren't using (don't care about) the token value right now, we only care that there /is/ one.

```swift
class func isActiveToken() -> Bool {
    
    let token   = UserDefaults.standard.string(forKey: "fm-token")
    let expiry  = UserDefaults.standard.object(forKey: "fm-token-expiry") as? Date ?? Date(timeIntervalSince1970: 0)
    
    if let _ = token, expiry > Date() {
        return true
    } else {
        return false
    }
}
```

## Active Token (example)
```swift 
switch isActiveToken() {  
case true:
    print("active token - expiry \(self.expiry)")
 
case false:
    refreshToken(for: auth, completion: { newToken, newExpiry in
        print("new token - expiry \(newExpiry)")
    })
}    
```
 
 - - -
 
## Refresh Token (function)
Refresh an expired token. The `@escaping` marker allows the `token` and `expiry` types to be used later (they're permitted to "escape" or outlive the function). That's typical for async calls in Swift.

```swift
// returns -> (token, expiry, error code)
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

## Refresh Token (example)
```swift
refreshToken(for: auth, completion: { newToken, newExpiry in
    print("new token - expiry \(newExpiry)")
    // newToken and newExpiry saved to UserDefaults
})
```

- - - 
 
## Get Records (function)
```swift
// returns -> ([records], error code)
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
                let error     = messages[0]["code"] as? String else { return }
        
        guard let records = response["data"] as? [[String: Any]] else {
            print(messages)
            return
        }
        
        completion(records, error)
        
    }.resume()
}
```

## Get Records (example)
```swift
// get first 20 records
getRecords(token: myToken, layout: myLayout, limit: 20, completion: { records, error in

    guard error == "0" else { 
        print("get records sad.")
        return 
    }
    
    guard let records = records else {
        print("no records.")
        return
    }
    
    // array
    for record in records {
        // deserialize with Codable, append object array, load table or collection view
    }
}
```

- - -

## Find Request (function)
This example shows an "or" request. Note the difference in payload for an "and" request. Set the payload from a `UITextField` (or hardcode a query, like this) and pass it as a parameter.

```swift
// returns -> ([records], error code)
class func findRequest(token: String, layout: String, payload: [String: Any], completion: @escaping ([[String: Any]], String) -> Void) {
    
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

## Find Request (example)
```swift
findRequest(token: myToken, layout: myLayout, payload: myPayload, completion: { records, error in

    guard error == "0" else { 
        print("find request sad.")
        return 
    }
    
    guard let records = records else {
        print("no records found.")
        return
    }
    
    // array
    for record in records {
        // deserialize with Codable, append object array, load table or collection view
    }
}
```

- - -

## Get Record (function)
```swift
// returns -> (record, error code)
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
                let error     = messages[0]["code"] as? String else { return }
        
        guard let records = response["data"] as? [[String: Any]] else {
            print(messages)
            return
        }
        
        completion(records[0], error)
        
    }.resume()
}
```
 
## Get Record (example)
```swift
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

## Delete Record (function)
```swift
// returns -> (error code)
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
                let error     = messages[0]["code"] as? String else { return }
        
        guard error == "0" else {
            print(messages)
            return
        }
        
        completion(error)
        
    }.resume()
}
```

## Delete Record (example)
```swift
deleteRecordWith(id: recID, token: myToken, layout: myLayout, completion: { error in

    guard error == "0" else {
        print("delete record sad.")
        return
    }
    
    // remove object from local array, reload view
}
```

- - -

## Edit Record (function)
```swift
// returns -> (error code)
class func editRecordWith(id: Int, token: String, layout: String, payload: [String: Any], modID: Int?, completion: @escaping (String) -> Void) {
    
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

## Edit Record (example)
```swift
editRecordWith(id: recID, token: myToken, layout: myLayout, playload: myPayload, completion: { error in

    guard error == "0" else {
        print("edit record sad.")
        return
    }
    
    // refetch record, reload view
}
```
