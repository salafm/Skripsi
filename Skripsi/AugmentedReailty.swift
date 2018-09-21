//
//  AugmentedReailty.swift
//  BRT Semarang
//
//  Created by NGI-1 on 15/08/18.
//  Copyright © 2018 PT Nusantara Global Inovasi. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import HDAugmentedReality

class AugmentedReality: UIViewController, ARDataSource, CLLocationManagerDelegate{
    var locationManager = CLLocationManager()
    
    public var annotations: [ARAnnotation] = []
    
    override func viewDidLoad(){
        super.viewDidLoad()
        getAnnotations()
        
        self.locationManager.delegate = self
    }

    @objc func checkConnection(){
        self.locationManager.startUpdatingLocation()
        self.reachabilityCheck(handlerFailed: {() -> Void in
            self.CustomWarning("Error", "Tidak terjangkau koneksi internet")
        } , handlerSuccess: {() -> Void in
            
        }, onClickHandler: {() -> Void in
            
        })
    }
    
    /// Creates random annotations around predefined center point and presents ARViewController modally
    public func showARViewController(){
        // Check if device has hardware needed for augmented reality
        if let error = ARViewController.isAllHardwareAvailable(), !Platform.isSimulator
        {
            let message = error.userInfo["description"] as? String
            let alertView = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alertView.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            
            self.present(alertView, animated: true, completion: nil)
            return
        }
        
        // Create random annotations around center point
        //FIXME: set your initial position here, this is used to generate random POIs
        let dummyAnnotations = self.annotations
        
        // ARViewController
        let arViewController = ARViewController()
        
        //===== Presenter - handles visual presentation of annotations
        let presenter = arViewController.presenter!
        // Vertical offset by distance
        presenter.distanceOffsetMode = .manual
        presenter.distanceOffsetMultiplier = 0.1   // Pixels per meter
        presenter.distanceOffsetMinThreshold = 500 // Doesn't raise annotations that are nearer than this
        
        // Filtering for performance
        presenter.maxDistance = 1000               // Don't show annotations if they are farther than this
        presenter.maxVisibleAnnotations = 100      // Max number of annotations on the screen
        
        // Stacking
        presenter.presenterTransform = ARPresenterStackTransform()
        
        //===== Tracking manager - handles location tracking, heading, pitch, calculations etc.
        // Location precision
        let trackingManager = arViewController.trackingManager
        trackingManager.userDistanceFilter = 15
        trackingManager.reloadDistanceFilter = 50
        
        //===== ARViewController
        // Ui
        arViewController.dataSource = self
        arViewController.uiOptions.closeButtonEnabled = true
        
        // Interface orientation
        arViewController.interfaceOrientationMask = .portrait
        
        // Failure handling
        arViewController.onDidFailToFindLocation =
            {
                [weak self, weak arViewController] elapsedSeconds, acquiredLocationBefore in
                
                self?.handleLocationFailure(elapsedSeconds: elapsedSeconds, acquiredLocationBefore: acquiredLocationBefore, arViewController: arViewController)
        }
        
        // Setting annotations
        arViewController.setAnnotations(dummyAnnotations)
        
        // Presenting controller
        self.present(arViewController, animated: true, completion: nil)
    }
    
    /// This method is called by ARViewController, make sure to set dataSource property.
    func ar(_ arViewController: ARViewController, viewForAnnotation: ARAnnotation) -> ARAnnotationView
    {
        // Annotation views should be lightweight views, try to avoid xibs and autolayout all together.
        let annotationView = TestAnnotationView()
        annotationView.frame = CGRect(x: 0,y: 0,width: 150,height: 50)
        return annotationView;
    }
    
    func getAnnotations(){
        let url = "https://brtsemarang.com/v2/mobile/shelterjson"
        self.httpget(url: url, resp: true, loader: false, handler: ({result -> Void in
            for loc in result["location"]! as! [Dictionary<String,Any>] {
                let title = loc["nama_selter"] as? String ?? "Tidak diketahui"
                let latitude = Double(loc["latitude"] as? String ?? "0")
                let longitude = Double(loc["longitude"] as? String ?? "0")
                let location = self.getLocation(Latitude: latitude!, Longitude: longitude!)
                
                if let annotation = ARAnnotation(identifier: nil, title: title, location: location) {
                    self.annotations.append(annotation)
                    print(annotation)
                }
            }
        }))
    }
    
    func getLocation(Latitude: Double,Longitude: Double) -> CLLocation {
        let lat = Latitude
        let lon = Longitude
        
        return CLLocation(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon), altitude: 1, horizontalAccuracy: 1, verticalAccuracy: 1, course: 0, speed: 0, timestamp: Date())
    }
    
    
    @IBAction func buttonTap(_ sender: AnyObject) {
        showARViewController()
    }
    
    func handleLocationFailure(elapsedSeconds: TimeInterval, acquiredLocationBefore: Bool, arViewController: ARViewController?){
        guard let arViewController = arViewController else { return }
        guard !Platform.isSimulator else { return }
        NSLog("Failed to find location after: \(elapsedSeconds) seconds, acquiredLocationBefore: \(acquiredLocationBefore)")
        
        // Example of handling location failure
        if elapsedSeconds >= 20 && !acquiredLocationBefore
        {
            // Stopped bcs we don't want multiple alerts
            arViewController.trackingManager.stopTracking()
            
            let alert = UIAlertController(title: "Problems", message: "Cannot find location, use Wi-Fi if possible!", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Close", style: .cancel)
            {
                (action) in
                
                self.dismiss(animated: true, completion: nil)
            }
            alert.addAction(okAction)
            
            self.presentedViewController?.present(alert, animated: true, completion: nil)
        }
    }
}
