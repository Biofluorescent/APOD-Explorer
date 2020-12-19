//
//  InfoPopup.swift
//  APOD Explorer
//
//  Created by Tanner Quesenberry on 10/1/20.
//  Copyright © 2020 Tanner Quesenberry. All rights reserved.
//

import UIKit

/// This class is used to present a view with a text box in the middle of the screen.
class InfoPopup: UIView {
    
    fileprivate let textView: UITextView = {
        let view = UITextView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isEditable = false
        view.textAlignment = .center
        view.backgroundColor = .black
        view.textColor = .white
        view.font = .systemFont(ofSize: 15)
        view.layer.cornerRadius = 24
        view.text = "This is where the description of the image should be."
        
        return view
    }()
    
    fileprivate let container: UIView = {
       let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .black
        view.layer.cornerRadius = 24
        return view
    }()
    
    
    @objc fileprivate func animateOut() {
        UIView.animate(withDuration: 0.7, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
            self.container.transform = CGAffineTransform(translationX: 0, y: -self.frame.height)
            self.alpha = 0
        }) { complete in
            self.removeFromSuperview()
        }
    }
    
    @objc fileprivate func animateIn() {
        self.container.transform = CGAffineTransform(translationX: 0, y: -self.frame.height)
        self.alpha = 0

        UIView.animate(withDuration: 0.7, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
            self.container.transform = .identity
            self.alpha = 1
        })
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(animateOut)))
        self.backgroundColor = UIColor.gray.withAlphaComponent(0.6)
        self.frame = UIScreen.main.bounds
        self.addSubview(container)
        
        container.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        container.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        container.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.7).isActive = true
        container.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.45).isActive = true
        
        container.addSubview(textView)
        textView.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: 0.95).isActive = true
        textView.heightAnchor.constraint(equalTo: container.heightAnchor, multiplier: 0.95).isActive = true
        textView.centerXAnchor.constraint(equalTo: container.centerXAnchor).isActive = true
        textView.centerYAnchor.constraint(equalTo: container.centerYAnchor).isActive = true
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func changeText(using words: String) {
        textView.text = words
    }
    
}
