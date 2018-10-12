# SwiftFM
SwiftFM is a service class for Swift 4.2 to work with the FileMaker Data API. (Xcode 9.4+ required)
- - -

### Overview
This walkthrough shows how to check status for an existing token, how to refresh expired tokens, and to make sure you're passing active tokens in your requests, where possible. Fetching a new session token for every request is lazy. Don't be that guy. 🙃

The example includes a simple find request. Refer to the DataAPI.swift class to see a complete list of functions (createRecord, getRecords, editRecord, deleteRecord, etc.)
 - - -
 
### Class vars and lets
A `let` is a constant, in Swift.

During testing, you can hardcode `baseURL` and `auth` values as below, but best practice is to keep sensitive info (api keys, etc.) outside of `Bundle.main`. It's safer to fetch that information from elsewhere and save to `UserDefaults`. For my apps, I fetch all "environment" settings from CloudKit, on launch. Doing it that way also provides a remote kill-switch, if necessary.
 
```swift
import UIKit
 
class ViewController: UIViewController {
 
//  let baseURL = UserDefaults.standard.string(forKey: "fm-db-path")   // better
//  let auth    = UserDefaults.standard.string(forKey: "fm-auth")      // better
 
    let baseURL = "https://<hostName>/fmi/data/v1/databases/<databaseName>"
    let auth    = "xxxxxxxabcdefg1234567"  // base64 "user:pass"
 
    var token   = UserDefaults.standard.string(forKey: "fm-token")
    var expiry  = UserDefaults.standard.object(forKey: "fm-token-expiry") as? Date ?? Date(timeIntervalSince1970: 0)
    
    var bands   = [Band]()    
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    
    struct Band {
        name: String
        bio: String
    }
    
    // ...
```
 
 - - -
 
### Active token?
Bool check to see if there's an existing token and whether or not it's expired. The `_` means we aren't using (don't care about) the token value right now, we only care that there /is/ one.

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

### Refresh token
Refresh an expired token. The `@escaping` marker allows the `token` and `expiry` types to be passed later (they're permitted to "escape" or "outlive" the function). That's typical for async calls in Swift. We'll call this function later, in `viewDidLoad()`

```swift
    // refresh token
    func refreshToken(for auth: String, completion: @escaping (String, Date) -> Void) {
    
        guard let baseURL = URL(string: self.baseURL) else { return }
       
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
            UserDefaults.standard.set(token, forKey: "fm-token")
            UserDefaults.standard.set(expiry, forKey: "fm-token-expiry")
           
            completion(token, expiry)   // out^
           
        }.resume()
    }
```
 
 - - -
 
### Find request
This example shows an "or" request. Set your payload from a `UITextField` (or hardcode a query, like this) and pass it as a parameter.

```swift
    var payload = ["query": [   
        ["bandName": "Pinkish Black"],  // "or" query ->[[pred1],[pred2]]   "and" ->[[pred1, pred2]]
        ["bandName": "Sudie"]
        // ...
    ]]
 
 
    /// data api find request
    func findRequest(with token: String, layout: String, payload: [String: Any]) {
    
        guard   let body = try? JSONSerialization.data(withJSONObject: payload),
                let baseURL = URL(string: self.baseURL) else { return }

        let url = baseURL.appendingPathComponent("/layouts/\(layout)/_find")
        
        // request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
       
        // task
        URLSession.shared.dataTask(with: request) { data, _, error in
           
            guard   let data     = data, error == nil,
                    let json     = try? JSONSerialization.jsonObject(with: data) as! [String: Any],
                    let response = json["response"] as? [String: Any],
                    let records  = response["data"] as? [[String: Any]] else { return }
            
            // json array
            for record in records {

                guard   let fieldData = record["fieldData"] as? [String: Any],
                        let bandName  = fieldData["bandName"] as? String,
                        let bandBio   = fieldData["bandBio"] as? String else { return }
                
                // make
                let b = Band(name: bandName, bio: bandBio)                 
                self.bands.append(b)
            }
            
            // completion
            OperationQueue.main.addOperation {
                self.bands.sort { $0.bandName < $1.bandName }
                self.collectionView.reloadData()
            }
           
        }.resume()
    }
```
 
 - - -
 
### ViewDidLoad() with query
Check for an active token (`self.token`) and hand it to our find request. If the token is missing or expired, we fetch a new one and pass `newToken` instead.
 
If you're new to Swift, `viewDidLoad()` is called only when stepping *into* a view. It is *not* called when navigating backward/down the stack. If you need to call a function every time the user enters a view, that's done in `viewWillAppear()` or `viewDidAppear()`.

```swift
    override func viewDidLoad() {
        super.viewDidLoad()
   
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isPrefetchingEnabled = true
   
        // request
        switch isActiveToken() {  
        case true:
            print("active token - expiry \(self.expiry)")
            findRequest(with: token!, layout: "Bands", payload: self.payload)
 
        case false:
            refreshToken(for: auth, completion: { newToken, newExpiry in
                print("new token - expiry \(newExpiry)")
                self.findRequest(with: newToken, layout: "Bands", payload: self.payload)
            })
        }
        
 
    }  // .did load
```
 
