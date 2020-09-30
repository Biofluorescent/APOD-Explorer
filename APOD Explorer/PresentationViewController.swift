//
//  PresentationViewController.swift
//  APOD Explorer
//
//  Created by Tanner Quesenberry on 9/29/20.
//  Copyright © 2020 Tanner Quesenberry. All rights reserved.
//

import UIKit

class PresentationViewController: UIViewController {

    @IBOutlet var mainView: UIView!
    var data: Astronomy!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        title = data.date
        
        //Load image or videos
        if data.media_type == "image" {
            if let image = loadImageFromDocumentDirectory(nameOfImage: data.date + ".png") {
                let imageView = UIImageView(image: image)
                imageView.frame = mainView.bounds
                imageView.contentMode = .scaleAspectFit
                mainView.addSubview(imageView)
                
            }
        }else {
            //video
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
