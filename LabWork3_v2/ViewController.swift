//
//  ViewController.swift
//  LabWork3_v2
//
//  Created by Mai Dao on 10/20/16.
//  Copyright © 2016 Mai Dao. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, UITextFieldDelegate, CLLocationManagerDelegate, MKMapViewDelegate{

    @IBOutlet weak var myMapView: MKMapView!
    @IBOutlet weak var addressTextField: UITextField!
    @IBOutlet weak var distanceValue: UILabel!
    @IBOutlet weak var zoomSlider: UISlider!
    @IBOutlet weak var travelRadius: UILabel!
    @IBOutlet weak var currentLocationLabel: UILabel!
    @IBOutlet weak var geoFeatureSwitch: UISwitch!
   // @IBOutlet weak var switchLabel: UILabel!
    
    
    let geocoder = CLGeocoder()
    let locationManager = CLLocationManager()
    var totalDistance: Double = 0.0
    var startLocation: CLLocation!
    var currentLocation: CLLocation!
    
    var overlay: MKOverlay?
    var direction: MKDirections?
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        myMapView.delegate = self
        addressTextField.delegate = self
        locationManager.delegate = self
        
        addThumbImageForSlider()
        
        let status = CLLocationManager.authorizationStatus()
        if (status == .notDetermined) {
            locationManager.requestWhenInUseAuthorization()
        } else if (status == .authorizedWhenInUse) {
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
            self.myMapView.showsUserLocation = true
            
        } else {
            print("Not allowed to access current location") }
        
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool { print("textFieldShouldBeginEditing")
        textField.backgroundColor = UIColor.lightGray
        return true
    }
    func textFieldDidBeginEditing(_ textField: UITextField) { print("textFieldDidBeginEditing")
    }
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool { print("textFieldShouldEndEditing")
        textField.backgroundColor = UIColor.white
        return true
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        print("textFieldDidEndEditing") }
    
    
    func textFieldShouldReturn(_ addressTextField: UITextField) -> Bool {
        
        if overlay != nil {
            self.myMapView.remove(overlay!)
        }
        
        addressTextField.resignFirstResponder()
        print("textField resignFirstResponder")
        if let text = addressTextField.text
        {
            fowardGeocodding(WithAddress: text)
            
        }
        return true
    }
    
    func fowardGeocodding(WithAddress:String)
    {
        geocoder.geocodeAddressString(WithAddress, completionHandler: { placemarks, error in
            if (error == nil)
            {
             //   print("haha")
                if let placemark = placemarks?.first
                {
             //       print("haha2")
                    
                    let coordinateRegion = MKCoordinateRegionMakeWithDistance((placemark.location?.coordinate)!, 1000, 1000)
                    self.myMapView.setRegion(coordinateRegion, animated: true)
                    
                    let toPlace = MKPlacemark(placemark: placemark)
                    self.routePath(fromPlace: MKPlacemark(coordinate: self.currentLocation!.coordinate, addressDictionary: nil), toLocation: toPlace)
                }
                
            }
        })
    }
    
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
    {
        if (status == .authorizedWhenInUse)
        {
            locationManager.startUpdatingLocation()
        }
        else
        {
            print("Not allowed to access current location")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        if geoFeatureSwitch.isOn == true
        {
            if startLocation == nil
            {
                startLocation = locations.first!
            }
            else{
                currentLocation = locations.last!
                let distance = startLocation.distance(from: currentLocation)
                startLocation = currentLocation
                totalDistance += distance
                distanceValue.text = "Distance: \(String(totalDistance.rounded(.up))) meters"
                
                var route = [startLocation.coordinate, currentLocation.coordinate]
                let polyline = MKPolyline(coordinates: &route, count: route.count)
                myMapView.add(polyline)
                
//                routePath(fromPlace: MKPlacemark(coordinate: self.startLocation!.coordinate, addressDictionary: nil), toLocation: MKPlacemark(coordinate: self.currentLocation!.coordinate, addressDictionary: nil))
               
            }
            
            let spanX = 0.008
            let spanY = 0.008
            let newRegion = MKCoordinateRegion(center: myMapView.userLocation.coordinate, span: MKCoordinateSpanMake(spanX, spanY))
            myMapView.setRegion(newRegion, animated: true)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if newHeading.headingAccuracy > 0
        {
            var degree = newHeading.trueHeading
            var radian = degree / 180.0 * 3.14
            var transform = CGAffineTransform.identity
            transform = CGAffineTransform(rotationAngle: CGFloat(radian))
            locationManager.stopUpdatingHeading()
            self.myMapView.transform = transform
        }
    }
    
    
    
    
    @IBAction func changeMapScale(_ sender: AnyObject)
    {
        let zoom = Double(zoomSlider.value)
        print(zoom)
        let delta = zoom / 69.0
        var currentRegion = self.myMapView.region
        currentRegion.span = MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
        self.myMapView.region = currentRegion
        
        travelRadius.text = "\(Int(round(zoom))) m"
        
        let (long, lat) = (currentRegion.center.longitude, currentRegion.center.latitude )
        currentLocationLabel.text = "Current location: \(long), \(lat)"
    }
    
    func addThumbImageForSlider()
    {
        zoomSlider.setThumbImage(UIImage(named: "thumb.png"), for: .normal)
        zoomSlider.setThumbImage(UIImage(named: "thumbHightLight.png"), for: .highlighted)
    }
    @IBAction func switchChangedValue(_ sender: AnyObject) {
        if sender.isOn == true
        {
            UIView.animate(withDuration: 0.5, animations: {
                self.addressTextField.alpha = 0
                self.distanceValue.alpha = 0.7
                }, completion:
                { _ in print("addressTextField is now hidden") })
            
        } else if sender.isOn == false
        {
            UIView.animate(withDuration: 0.5, animations: {
                self.addressTextField.alpha = 1
                self.distanceValue.alpha = 0
                }, completion:
                { _ in print("addressTextField is now displayed") })
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let lineRenderer = MKPolylineRenderer(overlay: overlay)
        lineRenderer.strokeColor = UIColor.blue
        lineRenderer.lineWidth = 5.0
        return lineRenderer
    }
    
   
    func routePath(fromPlace: MKPlacemark, toLocation: MKPlacemark) {
        let request = MKDirectionsRequest()
        let fromMapItem = MKMapItem(placemark: fromPlace)
        request.source = fromMapItem
        let toMapItem = MKMapItem(placemark: toLocation)
        request.destination = toMapItem
        self.direction = MKDirections (request: request)
        self.direction!.calculate {
            (response, error) in
            if (error == nil)
            {
                self.showRoute(response: response!)
            }
        }
    }
    
    func showRoute(response: MKDirectionsResponse) {
        for route in response.routes {
            self.overlay = route.polyline
            self.myMapView.add(overlay!)
            for step in route.steps {
                print(step.instructions)
            }
        }
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?)
    {
        if geoFeatureSwitch.isOn == false
        {
            if motion == .motionShake
            {
                let previousText = String(describing:distanceValue.text!)
                distanceValue.text = "Reset tracking..."
                distanceValue.textColor = UIColor.red
                
                Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                    self.distanceValue.text = previousText
                    self.distanceValue.textColor = UIColor.black
                }
                
                totalDistance = 0.0
                myMapView.removeOverlays(overlay as! [MKOverlay])
              
              //  self.myMapView.remove(overlay!)
                print ("overlay is removed")
            }
            else
            {
                print ("The device is not shaken")
            }
        }
        
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    


}

