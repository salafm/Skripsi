//
//  Loader.swift
//  BRT Semarang
//
//  Created by NGI-1 on 20/07/18.
//  Copyright © 2018 PT Nusantara Global Inovasi. All rights reserved.
//

import Foundation
import UIKit
import NVActivityIndicatorView

public class Loader{
    
    var overlayView = UIView()
    var activityIndicator = NVActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    
    class var shared: Loader {
        struct Static {
            static let instance: Loader = Loader()
        }
        
        return Static.instance
    }
    
    public func startLoader() {
        if  let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let window = appDelegate.window {
            overlayView.frame = UIScreen.main.bounds
            overlayView.backgroundColor = UIColor(hue: 0/360, saturation: 0/100, brightness: 0/100, alpha: 0.4)
            
            activityIndicator.center = overlayView.center
            activityIndicator.color = #colorLiteral(red: 1, green: 0.6374356151, blue: 0, alpha: 1)
            activityIndicator.type = .ballScaleMultiple
            
            overlayView.addSubview(activityIndicator)
            window.addSubview(overlayView)
            
            self.overlayView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapBackground)))
            
            activityIndicator.startAnimating()
        }
    }
    
    public func stopLoader() {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.overlayView.removeFromSuperview()
        }
    }
    
    @objc func tapBackground(){
        self.stopLoader()
    }
}
