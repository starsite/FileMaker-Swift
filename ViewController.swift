import UIKit
 
class ViewController: UIViewController {
 
//  let baseURL = UserDefaults.standard.string(forKey: "fm-db-path")   // better
//  let auth    = UserDefaults.standard.string(forKey: "fm-auth")      // better
 
    let baseURL = URL(string: "https://<hostName>/fmi/data/v1/databases/<databaseName>")!
    let auth    = "xxxxxxxabcdefg1234567"  // base64 "user:pass"
 
    var token   = UserDefaults.standard.string(forKey: "fm-token")
    var expiry  = UserDefaults.standard.object(forKey: "fm-token-expiry") as? Date ?? Date(timeIntervalSince1970: 0) 
    // ...
    


    // active token?
    func isActiveToken() -> Bool {
        if let _ = self.token, self.expiry > Date() {
            return true
        } else {
            return false
        }
    }


    
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
       
    
    
    // "or" query
    var payload = ["query": [   // or ->[[pred1],[pred2]]   and ->[[pred1, pred2]]
        ["bandName": "Daniel Markham"],
        ["bandName": "Sudie"]
    ]]
  
    
    
    // find request
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


    
    // did load
    override func viewDidLoad() {
        super.viewDidLoad()
   
        // request
        switch isActiveToken() {  
        case true:
            print("with active token - expiry: \(self.expiry)")
            findRequest(with: self.token!, layout: "Bands", payload: self.payload)
 
        case false:
            refreshToken(for: auth, completion: { newToken, newExpiry in
                print("with new token")
                self.findRequest(with: newToken, layout: "Bands", payload: self.payload)
            })
        }
     
    }  // .did load

 
 
// ...
}

