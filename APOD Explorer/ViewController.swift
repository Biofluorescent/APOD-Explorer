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
    let months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    
    @IBOutlet var explanationView: UITextView!
    @IBOutlet var titleLabel: UILabel!
    
    let datePicker = UIDatePicker()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        title = "APOD"

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(searchDate))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: nil)

        //TO-DO: When loading a date, check if date is saved. If not show save button to save to favorites. Remove when tapped
        //navigationItem.leftBarButtonItem = .none
        
        DispatchQueue.global().async {
            self.makeRequest(withDate: "2020-09-08")
        }
    }
    
    func updateUI(data: Astronomy) -> Void {
        titleLabel.text = data.title
        explanationView.text = data.explanation
        
        let dates = data.date.components(separatedBy: "-")
        if let month = Int(dates[1]) {
            title = "\(months[month - 1]) \(dates[2]), \(dates[0])"
        }
    }
    
    //MARK: Search functionality
    @objc func searchDate() {
        //Create toolbar

        
    }
    
    //MARK: Request functionality
    
    func errorAlert(errorInfo: String) {
        let ac = UIAlertController(title: "Error", message: errorInfo, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        
        present(ac, animated: true)
    }
    
    func makeRequest(withDate: String) {
        let date = "&date=" + withDate
        let url = URL(string: baseAPI + date)!
        let urlRequest = URLRequest(url: url)
        
        let task = session.dataTask(with: urlRequest) { (data, response, error) in
            //Check for error
            if error != nil  || data == nil {
                print("Error")
                DispatchQueue.main.async {
                    self.errorAlert(errorInfo: "Data for the selected date is currently unavailable or unreachable. Please try another date.")
                }
                return
            }
            
            //Check mime
            guard let mime = response?.mimeType, mime == "application/json" else {
                print("Wrong MIME type!")
                DispatchQueue.main.async {
                    self.errorAlert(errorInfo: "Data was not received correctly. Please try again later.")
                }
                return
            }
            
            //Check HTTP response code
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("Error with the response, unexpected status code: \(String(describing: response))")
                DispatchQueue.main.async {
                    self.errorAlert(errorInfo: "Server unavailable or unable to process request. Please try again later or with a different date.")
                }
                return
            }
            
            //Update UI with retrieved data
            if let data = data {
                if let star = try? JSONDecoder().decode(Astronomy.self, from: data) {
                    DispatchQueue.main.async {
                        self.updateUI(data: star)
                    }
                    
                    //Debug
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

