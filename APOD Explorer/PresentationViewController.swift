//
//  PresentationViewController.swift
//  APOD Explorer
//
//  Created by Tanner Quesenberry on 9/29/20.
//  Copyright © 2020 Tanner Quesenberry. All rights reserved.
//

import UIKit
import WebKit

class PresentationViewController: UIViewController {

    @IBOutlet var mainView: UIView!
    var data: Astronomy!
    private var originalSubviewCount = 0
    
    let months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Information button
        let infoButton = UIButton(type: .infoLight)
        infoButton.addTarget(self, action: #selector(infoButtonTapped), for: .touchUpInside)
        let barButton = UIBarButtonItem(customView: infoButton)
        self.navigationItem.rightBarButtonItem = barButton
        
        //Needed for comparison later, only want on popup at a time
        originalSubviewCount = self.view.subviews.count
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //Set title
        let dates = data.date.components(separatedBy: "-")
        if let month = Int(dates[1]) {
            title = "\(months[month - 1]) \(dates[2]), \(dates[0])"
        }
        
        //Load image or videos
        if data.media_type == "image" {
            if let image = loadImageFromDocumentDirectory(nameOfImage: data.date + ".png") {
                let imageView = UIImageView(image: image)
                imageView.frame = mainView.bounds
                imageView.contentMode = .scaleAspectFit
                mainView.addSubview(imageView)
                
            }else {
                //Error if unable to find saved image
                let ac = UIAlertController(title: "Error:", message: "Unable to load image", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                present(ac, animated: true)
            }
        }else {
            //Load video on web
            let webView = WKWebView()
            webView.frame = mainView.bounds
            webView.contentMode = .scaleAspectFit
            mainView.addSubview(webView)
            webView.load(URLRequest(url: URL(string: data.url)!))
        }
        
    }
    
    //MARK: Nav Bar Button Functions
    
    @objc func infoButtonTapped() {
        //Text to display in popup
        var text = "\(data.title)\n\n\(data.explanation)\n\n"
        if data.copyright != "Public Domain" {
            text += "© \(data.copyright)"
        }else {
            text += data.copyright
        }

        //Only want one info popup at a time
        if abs(self.view.subviews.count - originalSubviewCount) == 0 {
            let popup = InfoPopup()
            popup.changeText(using: text)
            self.view.addSubview(popup)
        }

    }

    //MARK: Loading images
    func loadImageFromDocumentDirectory(nameOfImage : String) -> UIImage? {
        let documentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let userDomainMask = FileManager.SearchPathDomainMask.userDomainMask
        let paths = NSSearchPathForDirectoriesInDomains(documentDirectory, userDomainMask, true)
        if let dirPath = paths.first{
            let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(nameOfImage)
            let image = UIImage(contentsOfFile: imageURL.path)
            return image
        }
        return nil
    }

}
