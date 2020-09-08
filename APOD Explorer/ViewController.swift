//
//  ViewController.swift
//  APOD Explorer
//
//  Created by Tanner Quesenberry on 9/6/20.
//  Copyright © 2020 Tanner Quesenberry. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let baseAPI = "https://api.nasa.gov/planetary/apod?api_key=DEMO_KEY"
    let session = URLSession.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        title = "APOD"

        DispatchQueue.global().async {
            self.makeRequest(withDate: "2020-01-03")
        }
    }
    
    func updateUI(data: Astronomy) -> Void {
        title = data.title
    }

    func makeRequest(withDate: String) {
        let date = "&date=" + withDate
        let url = URL(string: baseAPI + date)!
        let urlRequest = URLRequest(url: url)
        
        let task = session.dataTask(with: urlRequest) { (data, response, error) in
            //Check for error
            if error != nil  || data == nil {
                print("Error")
                return
            }
            
            //Check mime
            guard let mime = response?.mimeType, mime == "application/json" else {
                print("Wrong MIME type!")
                return
            }
            
            //Check HTTP response code
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("Error with the response, unexpected status code: \(String(describing: response))")
                return
            }
            
            if let data = data {
                if let star = try? JSONDecoder().decode(Astronomy.self, from: data) {
                    DispatchQueue.main.async {
                        self.updateUI(data: star)
                    }
                    
                    print(star.title)
                    print(star.date)
                    print(star.explanation)
                }else {
                    print(String(data: data, encoding: .utf8)!)
                }
            }
        }
        
        task.resume()
    }
    
}

