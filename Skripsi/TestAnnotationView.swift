//
//  TestAnnotationView.swift
//  BRT Semarang
//
//  Created by NGI-1 on 15/08/18.
//  Copyright © 2018 PT Nusantara Global Inovasi. All rights reserved.
//

import Foundation
import UIKit
import HDAugmentedReality
import GoogleMaps
import MapKit

open class TestAnnotationView: ARAnnotationView, UIGestureRecognizerDelegate, CLLocationManagerDelegate{
    private var paths : [[(Double,Double)]] = []
    private var destination : (Double,Double) = (Double(),Double())
    private var userLocationMarker : GMSMarker!
    private var polyline : GMSPolyline!
    
    open var titleLabel: UILabel?
    open var infoButton: UIButton?
    open var arFrame: CGRect = CGRect.zero  // Just for test stacking
    override open func initialize()
    {
        super.initialize()
        self.loadUi()
    }
    
    func loadUi()
    {
        // Title label
        self.titleLabel?.removeFromSuperview()
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10)
        label.numberOfLines = 0
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor.white
        self.addSubview(label)
        self.titleLabel = label
        
        // Info button
        self.infoButton?.removeFromSuperview()
        let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
        button.isUserInteractionEnabled = false   // Whole view will be tappable, using it for appearance
        self.addSubview(button)
        self.infoButton = button
        
        // Gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(TestAnnotationView.tapGesture))
        self.addGestureRecognizer(tapGesture)
        
        // Other
        self.backgroundColor = UIColor.red.withAlphaComponent(0.5)
        self.layer.cornerRadius = 5
        
        if self.annotation != nil
        {
            self.bindUi()
        }
    }
    
    func layoutUi()
    {
        let buttonWidth: CGFloat = 40
        let buttonHeight: CGFloat = 40
        
        self.titleLabel?.frame = CGRect(x: 10, y: 0, width: self.frame.size.width - buttonWidth - 5, height: self.frame.size.height);
        self.infoButton?.frame = CGRect(x: self.frame.size.width - buttonWidth, y: self.frame.size.height/2 - buttonHeight/2, width: buttonWidth, height: buttonHeight);
    }
    
    // This method is called whenever distance/azimuth is set
    override open func bindUi()
    {
        if let annotation = self.annotation, let title = annotation.title
        {
            let distance = annotation.distanceFromUser > 1000 ? String(format: "%.1fkm", annotation.distanceFromUser / 1000) : String(format:"%.0fm", annotation.distanceFromUser)
            
            let text = String(format: "%@\nAZ: %.0f°\nDST: %@", title, annotation.azimuth, distance)
            self.titleLabel?.text = text
        }
    }
    
    open override func layoutSubviews()
    {
        super.layoutSubviews()
        self.layoutUi()
    }
    
    @objc open func tapGesture()
     {
        if let annotation = self.annotation
        {
            self.getRoute(annotation.location.coordinate, completionHandler: {(path, dest) in
                let storyBoard = UIStoryboard(name: "Main", bundle: Bundle.main)
                //let controller = storyBoard.instantiateViewController(withIdentifier: "navigation1") as? UINavigationController
                
                //set storyboard ID to your root navigationController.
                let vc = storyBoard.instantiateViewController(withIdentifier: "arview") as! ARView
                vc.sectionCoordinates = path
                vc.carLocation = dest
                
                var topVC = UIApplication.shared.keyWindow?.rootViewController
                while((topVC!.presentedViewController) != nil) {
                    topVC = topVC!.presentedViewController
                }
                topVC?.present(vc, animated: true, completion: nil)
            })
        }
    }
}

extension TestAnnotationView : GMSMapViewDelegate{
    
    //MARK:- Create marker on long press
    
    func getRoute(_ coordinate: CLLocationCoordinate2D, completionHandler : (([[(Double,Double)]], (Double,Double)) -> ())?) {
        guard let appDelegate = UIApplication.shared.delegate  as? AppDelegate else { return }
        appDelegate.locationManager.delegate = self
        
        if let userLocation = appDelegate.locationManager.location?.coordinate {
            if ReachabilityHelper.isInternetAvailable() {
                fetchRoute(source: userLocation, destination: coordinate, completionHandler: { [weak self] (polyline) in
                   
                    if let polyline = polyline as? GMSPolyline {
                        
                        // Add user location
                        let path = GMSMutablePath()
                        if let userlocation = appDelegate.locationManager.location?.coordinate {
                            path.add(userlocation)
                        }
                        
                        // add rest of the  co-ordinates
                        if let polyLinePath = polyline.path, polyLinePath.count() > 0 {
                            for i in 0..<polyLinePath.count() {
                                path.add(polyLinePath.coordinate(at: i))
                            }
                        }
                        
                        let updatedPolyline = GMSPolyline(path: path)
                        self?.polyline = updatedPolyline
                        
                        // update path and destination
                        self?.destination = (coordinate.latitude, coordinate.longitude)
                        
                        if let path = updatedPolyline.path {
                            var polylinePath : [(Double,Double)] = []
                            for i in 0..<path.count() {
                                let point = path.coordinate(at: i)
                                polylinePath.append((point.latitude,point.longitude))
                            }
                            self?.paths = []
                            self?.paths.append(polylinePath)
                        }
                        
                        completionHandler?((self?.paths)!, (self?.destination)!)
                    }
                })
            }
        }
    }
    
    private func fetchRoute(source : CLLocationCoordinate2D, destination : CLLocationCoordinate2D , completionHandler : ((Any) -> ())? ) {
        let origin = String(format: "%f,%f", source.latitude,source.longitude)
        let destination = String(format: "%f,%f", destination.latitude,destination.longitude)
        let directionsAPI = "https://maps.googleapis.com/maps/api/directions/json?"
        let apiKey = "AIzaSyBVB7lSCPno3o38ve-_ca85Law2IXdC5gI"
        let directionsUrlString = String(format: "%@&origin=%@&destination=%@&mode=walking&key=%@",directionsAPI,origin,destination,apiKey) // walking , driving
        
        if let url = URL(string: directionsUrlString) {
            
            let fetchDirection = URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                DispatchQueue.main.async {
                    if error == nil && data != nil {
                        var polyline : GMSPolyline?
                        if let dictionary = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments ) as? [String : Any] {
                            if let routesArray = dictionary?["routes"] as? [Any], !routesArray.isEmpty {
                                if let routeDict = routesArray.first as? [String : Any] , !routeDict.isEmpty {
                                    if let routeOverviewPolyline = routeDict["overview_polyline"] as? [String : Any] , !routeOverviewPolyline.isEmpty {
                                        if let points = routeOverviewPolyline["points"] as? String {
                                            if let path = GMSPath(fromEncodedPath: points) {
                                                polyline = GMSPolyline(path: path)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        if let polyline = polyline { completionHandler?(polyline) }
                    }
                }
            })
            fetchDirection.resume()
        }
    }
    
}

