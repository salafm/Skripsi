//
//  Extend.swift
//  BRT Semarang
//
//  Created by NGI-1 on 29/04/18.
//  Copyright © 2018 PT Nusantara Global Inovasi. All rights reserved.
//

import Foundation
import UIKit

protocol MyProtocol {
    func setResultOfBusinessLogic(valueSent: Bool)
    func setSelectMap(sender: UITextField, name: String)
}

extension UIViewController {
    
    func httppost(url: String, data: Dictionary<String, String>, resp: Bool , loader: Bool, handler: @escaping (Dictionary<String,Any>) -> Void){
        if loader{
            Loader.shared.startLoader()
        }
        
        let request = NSMutableURLRequest(url: NSURL(string: url)! as URL)
        let boundary = "----WebKitFormBoundary7MA4YWxkTrZu0gW"
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let body = NSMutableData()
        
        //define the data post parameter
        for (key, value) in data
        {
            body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: String.Encoding.utf8)!)
            body.append("\(value)\r\n".data(using: String.Encoding.utf8)!)
        }
        
        request.httpBody = body as Data
        
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            
            if error != nil {
                print("error=\(error!)")
                if loader {
                    Loader.shared.stopLoader()
                    self.AlertWarning()
                }
                return
            }
            
            let responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
//                        print(responseString!)
            
            DispatchQueue.main.async {
                if resp == true {
                    do{
                        let temp = try JSONSerialization.jsonObject(with: data!, options: []) as! Dictionary<String, Any>
                        Loader.shared.stopLoader()
                        handler(temp)
                    }catch{
                        print(responseString!)
                        if loader{
                            self.CustomWarning("Terjadi Kesalahan", error.localizedDescription)
                        }
                    }
                }else{
                    Loader.shared.stopLoader()
                    handler([:])
                }
            }
        }
        task.resume()
    }
    
    func httpget(url: String, resp: Bool , loader: Bool, handler: @escaping (Dictionary<String,Any>) -> Void){
        if loader{
            Loader.shared.startLoader()
        }
        
        let request = NSMutableURLRequest(url: NSURL(string: url)! as URL)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            
            if error != nil {
                print("error=\(error!)")
                if loader {
                    Loader.shared.stopLoader()
                    self.AlertWarning()
                }
                return
            }
            
            let responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
            //            print(responseString!)
            
            DispatchQueue.main.async {
                if resp == true {
                    do{
                        let temp = try JSONSerialization.jsonObject(with: data!, options: []) as! Dictionary<String, Any>
                        Loader.shared.stopLoader()
                        handler(temp)
                    }catch{
                        print(responseString!)
                        if loader{
                            self.CustomWarning("Terjadi Kesalahan", error.localizedDescription)
                        }
                    }
                }else{
                    Loader.shared.stopLoader()
                    handler([:])
                }
            }
        }
        task.resume()
    }
    
    
    func AlertWarning() {
        let alert = UIAlertController(title: "Telah terjadi error", message: "Tidak dapat tersambung ke server. Periksa koneksi internet anda", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: {_ -> Void in
            self.viewWillAppear(true)
        })
        alert.addAction(action)
        
        self.present(alert, animated: true, completion: Loader.shared.stopLoader)
    }
    
    func CustomWarning(_ titles:String, _ messages:String) {
        let alert = UIAlertController(title: titles, message: messages, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        
        self.present(alert, animated: true, completion: Loader.shared.stopLoader)
    }
    
    func getScreen() -> Resolution {
        return Resolution(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
    }
    
    func reachabilityCheck(handlerFailed: @escaping () -> Void, handlerSuccess: @escaping () -> Void, onClickHandler: @escaping () -> Void) {
        if !ReachabilityHelper.isInternetAvailable() {
            handlerFailed()
            let alert = UIAlertController(title: "No Internet", message: "Please connect to Internet", preferredStyle: .alert)
            let okButton = UIAlertAction(title: "Ok", style: .default, handler: { (button) in
                alert.dismiss(animated: true, completion: nil)
                onClickHandler()
            })
            alert.addAction(okButton)
            present(alert, animated: true, completion: nil)
        }else{
            handlerSuccess()
            onClickHandler()
        }
    }
}

class MyButton: UIButton {
    var action: (() -> Void)?
    
    func whenButtonIsClicked(action: @escaping () -> Void) {
        self.action = action
        self.addTarget(self, action: #selector(MyButton.clicked), for: .touchUpInside)
    }
    
    @objc func clicked() {
        action?()
    }
}

extension UIButton {
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        isHighlighted = true
        super.touchesBegan(touches, with: event)
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isHighlighted = false
        super.touchesEnded(touches, with: event)
    }
    
    override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isHighlighted = false
        super.touchesCancelled(touches, with: event)
    }
    
}

extension UIView {
    
    func makeShadow(){
        self.layer.masksToBounds = false
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.3
        self.layer.shadowOffset = CGSize(width: -1, height: 1)
        self.layer.shadowRadius = 1
    }
    
    func makeShadowGrey(_ isCorner: Bool){
        self.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25).cgColor
        self.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        self.layer.shadowOpacity = 1.0
        self.layer.shadowRadius = 0.0
        self.layer.masksToBounds = false
        if isCorner {
            self.layer.cornerRadius = 4.0
        }
    }
}

extension String {
    func date(format: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        //        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        let date = dateFormatter.date(from: self)
        return date
    }
}

extension UIImage{
    
    func resizeImage(targetSize: CGSize) -> UIImage {
        let size = self.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}

class TextField: UITextField {
    let padding = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
    
    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override open func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
}

class Resolution {
    var width : CGFloat
    var height : CGFloat
    var widthRatio : CGFloat
    var heightRatio : CGFloat
    
    init(){
        self.width = CGFloat()
        self.height = CGFloat()
        self.widthRatio = CGFloat()
        self.heightRatio = CGFloat()
    }
    
    init(width: CGFloat, height: CGFloat){
        self.width = width
        self.height = height
        self.widthRatio = self.width/375
        self.heightRatio = self.height/667
    }
    
    func isIphoneX() -> Bool{
        if width == 375 && height == 812 {
            return true
        }else{
            return false
        }
    }
}
