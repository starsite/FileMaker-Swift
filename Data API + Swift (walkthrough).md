### Data API + Swift (walkthrough)
This walkthrough shows how to check status for an existing token, how to refresh expired tokens, and to make sure you're passing active tokens in your requests, where possible. Fetching a new session token for every request is lazy. Don't be that guy. 🙃
 - - -
 
#### Class Vars And Lets
A `let` is a constant, in Swift.

For testing the Data API, you can hardcode `baseURL` and `auth` as below, but best practice is to keep sensitive info (api keys, etc.) outside of `Bundle.main`. It's safer to fetch that information from elsewhere and save to `UserDefaults`. For my apps, I fetch all "environment" settings from CloudKit, on launch. Doing it that way also provides a remote access kill-switch, if necessary.
 
```swift
import UIKit
 
class ViewController: UIViewController {
 
//  let baseURL = UserDefaults.standard.string(forKey: "fm-db-path")   // better
//  let auth    = UserDefaults.standard.string(forKey: "fm-auth")      // better
 
    let baseURL = URL(string: "https: //<hostName>/fmi/data/v1/databases/<databaseName>")!
    let auth    = "xxxxxxxabcdefg1234567"  // base64 "user:pass"
 
    var token   = UserDefaults.standard.string(forKey: "fm-token")
    var expiry  = UserDefaults.standard.object(forKey: "fm-token-expiry") as? Date ?? Date(timeIntervalSince1970: 0)
 
    // ... (cont'd)
```
 
 - - -
 
#### Active Token?
A simple Bool check to see if there's an existing token in `UserDefaults`, and whether or not it's expired. The `_` means we aren't using/don't care about the token value right now, we only care that there /is/ one.

```swift
    // active token?
    func isActiveToken() -> Bool {
        if let _ = self.token, self.expiry > Date() {
            return true
        } else {
            return false
        }
    }
```
 
 - - -

#### Refresh Token
Refresh an expired token. The @escaping marker allows the `token` and `expiry` types to be passed sometime later (they're permitted to "escape" or "outlive" the function). Typical for async calls in Swift. We'll fire this later, in `viewDidLoad()`

```swift
    // refresh token
    func refreshToken(for auth: String, completion: @escaping (String, Date) -> Void) {
       
        let url = baseURL.appendingPathComponent("/sessions")
        let expiry = Date(timeIntervalSinceNow: 900)   // 15 minutes
       
        // request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Basic \(auth)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
       
        // task
        URLSession.shared.dataTask(with: request) { data, _, error in
           
            guard   let data  = data, error == nil,
                    let json  = try? JSONSerialization.jsonObject(with: data) as! [String: Any],
                    let resp  = json["response"] as? [String: Any],
                    let token = resp["token"] as? String
            else {
                    print("refresh token sad")
                    return
            }
           
            // prefs
            self.token  = token
            self.expiry = expiry
           
            completion(token, expiry)   // out^
           
        }.resume()
    }
```
 
 - - -
 
#### Find Request
This example shows an "or" request. Set the payload from a `UITextField` (or hardcode a query, like this) and pass it as a parameter.

```swift
    // query
    var payload = ["query": [   // or ->[[p1],[p2]]   and ->[[p1,p2]]
        ["bandName": "Daniel Markham"],
        ["bandName": "Sudie"]
    ]]
 
 
    /// data api find request
    func findRequest(with token: String, layout: String, payload: [String: Any]) {
       
        let url = baseURL.appendingPathComponent("/layouts/\(layout)/_find")
 
        // serialize             
        guard let body = try? JSONSerialization.data(withJSONObject: payload) else { return }
       
        // request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
       
        // task
        URLSession.shared.dataTask(with: request) { data, _, error in
           
            guard   let data = data, error == nil,
                    let json = try? JSONSerialization.jsonObject(with: data) as! [String: Any]
            else {
                    print("api request sad")
                    return
            }
           
            print("\n\(json)")   // disco!
           
        }.resume()
    }
```
 
 - - -
 
#### `viewDidLoad` With Query
Here we check for an active token (self.token) and give it to our find request. If the token is missing or expired, we fetch a new one and pass `newToken` instead.
 
If you're new to Swift, `viewDidLoad()` is called only when stepping *into* a view. It is *not* called when navigating backward/down the stack. If you need to call a function every time the user enters a view, that's done in `viewWillAppear()` or `viewDidAppear()`.

```swift
    // did load
    override func viewDidLoad() {
        super.viewDidLoad()
   
        // apiRequest
        switch isActiveToken() {   
        case true:
            print("with active token - expiry: \(self.expiry)")
            findRequest(with: self.token!, layout: "Bands", payload: self.payload)
 
        case false:
            refreshToken(for: auth, completion: { newToken, newExpiry in    // async
                print("with new token")
                self.findRequest(with: newToken, layout: "Bands", payload: self.payload)
            })
        }
        // ....
 
    }  // .did load
```
 
