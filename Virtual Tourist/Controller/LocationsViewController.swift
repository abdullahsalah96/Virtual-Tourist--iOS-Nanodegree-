//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Abdalla Elshikh on 4/26/20.
//  Copyright © 2020 Abdalla Elshikh. All rights reserved.
//

import UIKit
import MapKit

class LocationsViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureView()
    }
    
    func configureView(){
        self.mapView.delegate = self
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(addWaypoint(longGesture:)))
        self.mapView.addGestureRecognizer(gesture)
    }

}

extension LocationsViewController: MKMapViewDelegate{
    //customize pins
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
       let reuseId = "pin"
       var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
       if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.isEnabled = true
            pinView!.pinTintColor = .red
            pinView!.canShowCallout = true
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        return pinView
       }
       else {
           pinView!.annotation = annotation
       }
       return pinView
    }
        
    // This delegate method is implemented to respond to taps. as to direct to media type
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            performSegue(withIdentifier: "pinSegue", sender: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "pinSegue"{
            //prepare for the segue
        }
    }

    func displayPinOnMap(location: CLLocationCoordinate2D){
        //parse data
        //create a variable for annotations
        let lat = CLLocationDegrees(location.latitude)
        let long = CLLocationDegrees(location.longitude)
        var city = ""
        var country = ""
        // The lat and long are used to create a CLLocationCoordinates2D instance.
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
        let geoCoder = CLGeocoder()
        let location = CLLocation(latitude: lat, longitude: long)
        geoCoder.reverseGeocodeLocation(location, completionHandler:
            {
                placemarks, error -> Void in
                // Place details
                guard let placeMark = placemarks?.first else { return }
                // City
                if let loc = placeMark.subAdministrativeArea{city = loc}
                // Country
                if let loc = placeMark.country{country = loc}
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                annotation.title = "\(city), \(country)"
                // Finally we place the annotation in an array of annotations.
                self.mapView.addAnnotation(annotation)
                self.mapView.setCenter(coordinate, animated: true)
                self.mapView.reloadInputViews()
                //add it to database
        })
    }
    
    @objc func addWaypoint(longGesture: UIGestureRecognizer) {
        let touchPoint = longGesture.location(in: mapView)
        let wayCoords = mapView.convert(touchPoint, toCoordinateFrom: mapView)
//        let location = CLLocation(latitude: wayCoords.latitude, longitude: wayCoords.longitude)
        let wayAnnotation = MKPointAnnotation()
        wayAnnotation.coordinate = wayCoords
        wayAnnotation.title = "waypoint"
        //show on map
        displayPinOnMap(location: wayCoords)
    }
}
