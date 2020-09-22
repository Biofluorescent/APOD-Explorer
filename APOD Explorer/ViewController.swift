//
//  ViewController.swift
//  APOD Explorer
//
//  Created by Tanner Quesenberry on 9/6/20.
//  Copyright © 2020 Tanner Quesenberry. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import WebKit
import CoreData

class ViewController: UIViewController, UITextViewDelegate {
    
    let baseAPI = "https://api.nasa.gov/planetary/apod?api_key=DEMO_KEY"
    let session = URLSession.shared
    let months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    
    @IBOutlet var explanationView: UITextView!
    @IBOutlet var mediaView: UIView!
    @IBOutlet var dateField: UITextField!
    @IBOutlet var saveButton: UIButton!
    
    //Create date picker
    let datePicker = UIDatePicker()
    var currentStar: AstronomyJSON?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "APOD"
        initializeDatePickerInput(for: dateField)
        
        saveButton.layer.borderWidth = 1
        saveButton.layer.borderColor = UIColor.white.cgColor
        saveButton.layer.cornerRadius = 10

        //Attributed string needed to change placeholder text color
        dateField.attributedPlaceholder = NSAttributedString(string: "Select a date", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        dateField.layer.borderColor = UIColor.white.cgColor
        dateField.layer.borderWidth = 1
        dateField.layer.cornerRadius = 10
        dateField.tintColor = .clear

        //TO-DO: When loading a date, check if date is saved. If not show save button to save to favorites. Remove when tapped
        //navigationItem.leftBarButtonItem = .none
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        DispatchQueue.global().async {
            self.makeRequest(withDate: formatter.string(from: Date()))
        }
    }
    
    //MARK: UI Functionality
    
    func initializeDatePickerInput(for field: UITextField) {
        datePicker.datePickerMode = .date
        datePicker.timeZone = TimeZone(abbreviation: "PST")
        //Starting June 16, 1996
        datePicker.minimumDate = Date(timeIntervalSince1970: 60 * 60 * 24 * 9664)
        datePicker.maximumDate = Date()
        
        //Create toolbar and customize date picker for use with textfield
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dateDonePressed))
        toolBar.setItems([doneButton], animated: true)
        
        //Assign datepicker to be the input option for the textfield
        field.inputAccessoryView = toolBar
        field.inputView = datePicker
        field.sendActions(for: .touchUpInside)
        
        field.addTarget(self, action: #selector(textFieldTapped), for: .touchUpInside)
    }
    
    @objc func dateDonePressed() {
        //Formate date chosen
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: datePicker.date)
        //Close toolbar
        self.view.endEditing(true)
        
        DispatchQueue.global().async {
            self.makeRequest(withDate: dateString)
        }
    }
    
    @objc func textFieldTapped() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    
    func updateUI(data: AstronomyJSON) -> Void {
        var info = data.explanation + "\n\n"
        
        if let copyright = data.copyright {
            info += "© \(copyright)"
        }else {
            info += "Public Domain"
        }
        //  Undecided on where to display current date
        let dates = data.date.components(separatedBy: "-")
        if let month = Int(dates[1]) {
            title = "\(months[month - 1]) \(dates[2]), \(dates[0])"
        }
        
        //title = data.title
        info = data.title + "\n\n" + info
        explanationView.text = info
        explanationView.textAlignment = .center

        DispatchQueue.global().async {
            self.fetchMedia(mediaType: data.media_type, atURL: data.url)
        }
    }
  
    //MARK: SAVE Functionality
    @IBAction func saveButtonPressed(_ sender: UIButton) {
        //Make sure there is object to save
        guard let star = currentStar else { return }
        
        //Get context
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext

        //Check if object already saved in core data
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Astronomy")
        let predicate = NSPredicate(format: "date == %@", star.date)
        request.predicate = predicate
        request.fetchLimit = 1
        
        do {
            let count = try managedContext.count(for: request)
            if count == 0 {
                //No matching object, can save
                save()
            }else {
                //Object found in core data, inform user they already saved it
                let ac = UIAlertController(title: "Already saved in favorites", message: nil, preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                present(ac, animated: true)
            }
        } catch {
            print("Could not fetch \(error), \(error.localizedDescription)")
        }

       // let generator = UINotificationFeedbackGenerator()
       // generator.notificationOccurred(.success)
        //UIDevice.vibrate()
    }
    
    func save() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        guard let star = currentStar else { return }
        
        //Needed before you can save or retrieve
        let managedContext = appDelegate.persistentContainer.viewContext
        managedContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        //Create a new managed object to be inserted into the context
        let entity = NSEntityDescription.entity(forEntityName: "Astronomy", in: managedContext)!
        let astronomy = NSManagedObject(entity: entity, insertInto: managedContext)
        
        //Set attributes
        astronomy.setValue(star.title, forKey: "title")
        astronomy.setValue(star.date, forKey: "date")
        astronomy.setValue(star.explanation, forKey: "explanation")
        astronomy.setValue(star.url, forKey: "url")
        astronomy.setValue(star.media_type, forKey: "media_type")
        
        //Save data to disk
        if let copyright = star.copyright {
            astronomy.setValue(copyright, forKey: "copyright")
        }else {
            astronomy.setValue("Public Domain", forKey: "copyright")
        }
        
        do {
            try managedContext.save()
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        
    }
    
    //MARK: Date Request functionality
    
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
                if var star = try? JSONDecoder().decode(AstronomyJSON.self, from: data) {
                    //Set the currently data, needed for data saving
                    self.currentStar = star
                    
                    //Verify url. Error in data for video on 2013-09-16
                    if !star.url.hasPrefix("https://www.") {
                        if let range = star.url.range(of: "youtube") {
                            let end = String(star.url[range.upperBound...])
                            star.url = "https://www.youtube" + end
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.updateUI(data: star)
                    }
                }else {
                    print(String(data: data, encoding: .utf8)!)
                }
            }
        }
        
        task.resume()
    }
    
    //MARK: Media request/functionality
    
    func fetchMedia(mediaType: String, atURL: String) {
        
        let mediaURL = URL(string: atURL)!

        if mediaType == "image" {
            let task = session.dataTask(with: mediaURL) { (data, reponse, error) in
                if error == nil {
                    let loadedImage = UIImage(data: data!)
                    
                    //UI Work on main thread
                    DispatchQueue.main.async {
                        for view in self.mediaView.subviews {
                            view.removeFromSuperview()
                        }
                        
                        let imageView = UIImageView(image: loadedImage)
                        //imageView.translatesAutoresizingMaskIntoConstraints = false
                        imageView.contentMode = .scaleAspectFit
                        imageView.frame = self.mediaView.bounds
                        imageView.isUserInteractionEnabled = true
                        self.mediaView.addSubview(imageView)
                    }
                    
                }
            }
            
            task.resume()
            
        }else {
            //Load youtube video in a webview
            DispatchQueue.main.async {
                for view in self.mediaView.subviews {
                    view.removeFromSuperview()
                }
                
                let webView = WKWebView()
                webView.frame = self.mediaView.bounds
                webView.contentMode = .scaleAspectFit
                self.mediaView.addSubview(webView)
                webView.load(URLRequest(url: mediaURL))
            }
            /*
            let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            //TODO: Fix path component
            let destinationURL = docsURL.appendingPathComponent("Test.mp4")
            
            //Do not download if we already have the content saved
            if FileManager().fileExists(atPath: destinationURL.path) {
                print("Already there.")
                //Play saved media
                DispatchQueue.main.async {
                    self.playVideo(from: destinationURL)
                }
            }else {
                var request = URLRequest(url: mediaURL)
                request.httpMethod = "GET"
                
                _ = session.dataTask(with: request, completionHandler:  { data, response, error in
                    if error != nil {
                        print("Error happened")
                        return
                    }
                    
                    if let response = response as? HTTPURLResponse {
                        if response.statusCode == 200 {
                            DispatchQueue.main.async {
                                if let data = data {
                                    if let _ = try? data.write(to: destinationURL, options: Data.WritingOptions.atomic) {
                                        print("Data written")
                                        DispatchQueue.main.async {
                                            self.playVideo(from: destinationURL)
                                        }
                                    }else {
                                        print("Error writing.")
                                    }
                                }
                            }
                        }
                    }
                }).resume()
                
            } //End .fileExists else block
            */
            
        }//End video media block
    }//End fetchMedia function
    
    //MARK: Future usage?
    
    //Possible future functionality if downloading videos.
    //Note: Cannot download youtube videos
    func playVideo(from file: URL) {
        let url = file
        print(url)
        let avAssest = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: avAssest)
        let player = AVPlayer(playerItem: playerItem)

        let playerViewController = AVPlayerViewController()
        playerViewController.player = player

        self.present(playerViewController, animated: true, completion: {
            player.play()
        })
    }

}

extension UIDevice {
    static func vibrate() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
}
