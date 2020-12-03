# SwiftFM

SwiftFM is a Swift wrapper for the FileMaker Data API. Xcode 11 and Swift 4 (or later) required.

This `README.md` is aimed at FileMaker devs who want to integrate the Data API into their Xcode projects. Each function is paired with a code example. Everything shown below is part of `DataAPI.swift`, in this repo.

#### If you'd like to support this project, you can:

* Contribute socially, by giving SwiftFM a ⭐️ on GitHub or telling other people about it
* Contribute financially, by helping to [sponsor ths project](https://paypal.me/starsite)
* Hire me to build an iOS app for your company 🥰
* Hire me to build an iOS app for one of your FileMaker clients (if something like this is out of reach for you)

---

### 🚨 FileMaker v19 

I've updated SwiftFM to include the new `validateSession()` method. Meaning, we no longer need to track expiry values with `isActiveToken()`. 🎉 Because Claris is using a different URL path for validations, I went ahead and refactored all `URLSession` calls to use `host` and `db` environment values. That's a better way to do it anyway.

Lastly, I moved the Data API `message` response into the completion block. So now you can access the server message in the closure, where it's more helpful.

---

### Table of Contents

#### v19
* [`validateSession(token:)`](#validate-session-function)
#### v18+
* [`duplicateRecord(id:token:layout:)`](#duplicate-record-function)
* [`setGlobalFields(token:payload:)`](#set-global-fields-function)
#### v17+
* ~`isActiveToken()`~
* [`refreshToken(auth:)`](#refresh-token-function)
* [`deleteToken(_:)`](#delete-token-function)
* [`createRecord(token:layout:payload:)`](#create-record-function)
* [`getRecords(token:layout:offset:limit:)`](#get-records-function)
* [`findRequest(token:layout:payload:)`](#find-request-function)
* [`getRecord(id:token:layout:)`](#get-record-function)
* [`deleteRecord(id:token:layout:)`](#delete-record-function)
* [`editRecord(id:token:layout:payload:modId:)`](#edit-record-function)

---

### Environment

Set your host, db, and auth values in the AppDelegate, in `applicationWillEnterForeground(_:)`. For TESTING, you can set these with string literals. For PRODUCTION, you should be fetching these values from elsewhere.

DO NOT deploy apps with credentials visible in code. 😵

```swift
class AppDelegate: UIResponder, UIApplicationDelegate {

    // ...
    
    func applicationWillEnterForeground(_ application: UIApplication) {
       
        let host = "my.server.com"
        let db   = "my_database"
        let auth = "xxxxxabcde12345"   // base64 -> "user:pass"

        UserDefaults.standard.set(host, forKey: "fm-host")
        UserDefaults.standard.set(db, forKey: "fm-db")
        UserDefaults.standard.set(auth, forKey: "fm-auth")
    }
    
    // ...
}
```

---


### Validate Session (function)
Data API v19 or later. In previous versions, we had to attempt and retry calls that failed, or set and track an expiry `Date()`. Neither of those options were great. Now we can (very) quickly validate a session token. 🎉

```swift
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
```

### Example

```swift
let auth  = UserDefaults.standard.string(forKey: "fm-auth") ?? ""
let token = UserDefaults.standard.string(forKey: "fm-token") ?? ""

DataAPI.validateSession(token: token, completion: { success, _ in

    switch success {
    case true:
        // do stuff with 'token'
        self.fetchUpdates(token: token)

    case false:
        DataAPI.refreshToken(auth: auth, completion: { newToken, _, message in
            guard let newToken = newToken else {
                print(message)
                return
            }
            
            // do stuff with 'newToken'
            self.fetchUpdates(token: newToken)
        })
    }
})
```

---


### Refresh Token (function)

Returns an optional `token`. The `@escaping` marker allows the `token?`, `code`, and `message` types to be used later (they're permitted to "escape" or outlive the function). That's typical for async calls in Swift. All of the functions in this repo use `@escaping`.

```swift
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
```

### Example

```swift
if let auth = UserDefaults.standard.string(forKey: "fm-auth") {

    DataAPI.refreshToken(auth: auth, completion: { token, _, message in
        guard let token = token else {
            print(message)
            return
        }
        
        // new token!
        print("new token: \(token)")
    })
}
```

---


### Delete Token (function)

Ends a user session. Only an error `code` and `message` are returned with this function. For iOS apps, a good place to call this would be `applicationDidEnterBackground(_:)`. The Data API has a 500-session limit, so managing tokens is extra important for large deployments. If you don't delete your session token, it ~will~ _should_ expire 15 minutes after the last API call. Probably. But you should clean up after yourself and not assume this will happen. 🙂

```swift
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
```

### Example

```swift
if let token = UserDefaults.standard.string(forKey: "fm-token") {

    DataAPI.deleteToken(token, completion: { code, message in
        guard code == "0" else {
            print(message)
            return
        }
        
        // deleted token!
    })
}
```

---


### Create Record (function)

Creates a new record with a payload. Returns an optional `recordId`.

💡 I've included an example of a Swift "trailing closure" in the code example. Trailing closures are everywhere in Swift and SwiftUI, so you should get used to seeing them, and writing them. They're pretty great. You can opt for a trailing closure _as you're writing the call_ by double-clicking the `completion:` placeholder. Or you can tab to the placeholder and hit `Return`.

```swift
// MARK: - create record -> (recordId?, code, message)

// to create a new empty record, pass an empty dict object for 'fieldData'.
// let payload = ["fieldData": []]

class func createRecord(token: String,
                        layout: String,
                        payload: [String: Any],
                        completion: @escaping (String?, String, String) -> Void ) {                       

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
```

### Example

```swift
let token  = UserDefaults.standard.string(forKey: "fm-token") ?? ""
let layout = "Customers"

let payload = ["fieldData": [
  "firstName": "Brian",
  "lastName": "Hamm",
  "email": "hello@starsite.co"
]]

// when a completion block is the final parameter, you can write it as a trailing closure. 😉
createRecord(token: token, layout: layout, payload: payload) { recordId, _, message in

    guard let recordId = recordId else { 
        print(message)
        return 
    }
    
    // new record!
    print("new recordId: \(recordId)")
}
```

---


### Duplicate Record (function)

Data API v18 or later. Only an error `code` and `message` are returned with this function. This function is very similar to `getRecord(id:)`. Both require a `recordId`. The main difference is `getRecord(id:)` is a GET, and `duplicateRecord(id:)` is a POST.

```swift
// MARK: - duplicate record -> (code, message)

class func duplicateRecord(id: Int,
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
```

### Example

```swift
let recid  = 12345
let token  = UserDefaults.standard.string(forKey: "fm-token") ?? ""
let layout = "Customers"

// another trailing closure, aren't they great?
duplicateRecord(id: recid, token: token, layout: layout) { code, message in

    guard code == "0" else { 
        print(message)
        return 
    }
    
    // duplicated record!
}
```

---


### Get Records (function)

Returns an optional array of `records` with an `offset` and `limit`.

```swift
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
```

### Example

```swift
// get first 20 records
let token  = UserDefaults.standard.string(forKey: "fm-token") ?? ""
let layout = "Customers"

// trailing closure
getRecords(token: token, layout: layout, offset: 1, limit: 20) { records, _, message in

    guard let records = records else { 
        print(message)
        return 
    }
    
    // array!
    records.forEach { record in
        // deserialize with Codable, append object array, refresh UI
    }
}
```

- - -


### Find Request (function)

Returns an optional array of `records`. Note the difference in payload between an "or" request vs. an "and" request. Set your payload from the UI, or hardcode a query. Then pass `payload` as a parameter.

```swift
// MARK: - find request -> ([records]?, code, message)

class func findRequest(token: String,
                       layout: String,
                       payload: [String: Any],
                       completion: @escaping ([[String: Any]]?, String, String) -> Void) {

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
```

### Example

```swift
let token  = UserDefaults.standard.string(forKey: "fm-token") ?? ""
let layout = "Customers"

// find customers named Brian or Geoff
payload = ["query": [
  ["firstName": "Brian"],
  ["firstName": "Geoff"]
]]

// find customers named Brian in Dallas
payload = ["query": [
  ["firstName": "Brian", "city": "Dallas"]
]]

// trailing closure
findRequest(token: token, layout: layout, payload: payload) { records, _, message in

    guard let records = records else { 
        print(message)
        return 
    }
    
    // array!
    records.forEach { record in
        // deserialize with Codable, append object array, refresh UI
    }
}
```

---


### Get Record (function)

Get a single record with `recordId`. Returns an optional `record`.

```swift
// MARK: - get record with id -> (record?, code, message)

class func getRecord(id: Int,
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
```

### Example

```swift
let recid  = 12345
let token  = UserDefaults.standard.string(forKey: "fm-token") ?? ""
let layout = "Customers"

// trailing closure
getRecord(id: recid, token: token, layout: layout) { record, _, message in

    guard let record = record else { 
        print(message)
        return 
    }
    
    // record!
    // deserialize with Codable, refresh UI
}
```

- - -


### Delete Record (function)

Delete record with `recordId`. Only an error `code` and `message` are returned with this function.

```swift
// MARK: - delete record -> (code, message)

class func deleteRecord(id: Int,
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
```

### Example

```swift
let recid  = 12345
let token  = UserDefaults.standard.string(forKey: "fm-token") ?? ""
let layout = "Customers"

// trailing closure
deleteRecord(id: recid, token: token, layout: layout) { code, message in
    
    guard code == "0" else {
        print(message)
        return 
    }
    
    // record deleted!
    // remove object from local array, refresh UI
}
```

- - -


### Edit Record (function)

Edit record with `recordId`. Pass values for the fields you want to modify. Optionally, you can include the `modId` from a previous fetch, to ensure the server record isn't newer than the one you're editing. If you pass `modId`, a record will be edited only when the `modId` matches.

Only an error `code` and `message` are returned with this function. The Data API does not pass back a modified record object for you to use. Boo 👎. You may want to refetch the record afterward with `getRecord(id:)`.

```swift
// MARK: - edit record -> (code, message)

class func editRecord(id: Int,
                      token: String,
                      layout: String,
                      payload: [String: Any],
                      modId: Int?,
                      completion: @escaping (String, String) -> Void) {

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
```

### Example

```swift
let recid  = 12345
let token  = UserDefaults.standard.string(forKey: "fm-token") ?? ""
let layout = "Customers"

payload = ["fieldData": [
  "firstName": "Brian",
  "lastName": "Hamm"
]]

// trailing closures are _especially_ great for long signatures, like this one
editRecord(id: recid, token: token, layout: layout, payload: payload, modId: nil) { code, message in

    guard code == "0" else {
        print(message)
        return
    }
    
    // edited!
    // refetch record using recordId, referesh UI
}
```

---


### Set Global Fields (function)

Data API v18 or later. Only an error `code` and `message` are returned with this function. This function is very similar to `editRecord(id:)`. Both accept a simple set of key-value pairs _and_ they're both PATCH methods. The main difference is the `globalFields` payload key and the `/globals` endpoint.

```swift
// MARK: - set global fields -> (code, message)

class func setGlobalFields(token: String,
                           payload: [String: Any],
                           completion: @escaping (String, String) -> Void) {

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
```

### Example

```swift
let token  = UserDefaults.standard.string(forKey: "fm-token") ?? ""

payload = ["globalFields": [
  "gField": "value",
  "gField": "value"
]]

// trailing closure
setGlobalFields(token: token, payload: payload) { code, message in

    guard code == "0" else {
        print(message)
        return
    }
    
    // globals set!
}
```
