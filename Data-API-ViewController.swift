import UIKit
 
class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
 
//  let baseURL  = UserDefaults.standard.string(forKey: "fm-db-path")   // better
//  let auth     = UserDefaults.standard.string(forKey: "fm-auth")      // better
 
    let baseURL  = URL(string: "https://<hostName>/fmi/data/v1/databases/<databaseName>")!
    let auth     = "xxxxxxxabcdefg1234567"  // base64 "user:pass"
 
    var token    = UserDefaults.standard.string(forKey: "fm-token")
    var expiry   = UserDefaults.standard.object(forKey: "fm-token-expiry") as? Date ?? Date(timeIntervalSince1970: 0) 
    
    var bands    = [Band]()    
    
    @IBOutlet weak var collectionView: UICollectionView!
    // ...
    

    struct Band {
        name: String
        bio: String
    }

    
    func isActiveToken() -> Bool {
        if let _ = self.token, self.expiry > Date() {
            return true
        } else {
            return false
        }
    }


    
    // refresh token
    func refreshToken(for auth: String, completion: @escaping (String, Date) -> Void) {
       
        guard let baseURL = URL(string: self.baseURL) else { return }
        
        let url = baseURL.appendingPathComponent("/sessions")
        let expiry = Date(timeIntervalSinceNow: 900)   // 15 minutes
       
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
       
    
    
    // "or" query
    var payload = ["query": [    
        ["bandName": "Jacob Furr"],    // or ->[[pred1],[pred2]]   and ->[[pred1, pred2]]  
        ["bandName": "Sudie"],
        ["bandName": "Pinkish Black"]
    ]]
  
    
    
    // find
    func findRequest(with token: String, layout: String, payload: [String: Any]) {
       
        guard   let body = try? JSONSerialization.data(withJSONObject: payload) else { return },
                let baseURL = URL(string: self.baseURL) else { return }
                
        let url = baseURL.appendingPathComponent("/layouts/\(layout)/_find")
       
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
            for record in records  {

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


    
    // did load
    override func viewDidLoad() {
        super.viewDidLoad()
   
        // request
        switch isActiveToken() {  
        case true:
            print("active token - expiry: \(self.expiry)")
            findRequest(with: self.token!, layout: "Bands", payload: self.payload)
 
        case false:
            refreshToken(for: auth, completion: { newToken, newExpiry in
                print("new token - expiry: \(newExpiry)")
                self.findRequest(with: newToken, layout: "Bands", payload: self.payload)
            })
        }
     
    }  // .did load

 
 
// ...
}

