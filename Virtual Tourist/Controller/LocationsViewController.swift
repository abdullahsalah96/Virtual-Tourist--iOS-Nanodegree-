//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Abdalla Elshikh on 4/26/20.
//  Copyright © 2020 Abdalla Elshikh. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class LocationsViewController: UIViewController {
    
    var dataController: DataController = DataController.shared
    var pins: [Pin] = []
    var fetchRequest:NSFetchRequest<Pin>!
    var photoResponses: [PhotoResponse] = []
    var selectedPin: Pin!
    let numOfImagesToDsiplay = 100

    @IBOutlet weak var mapView: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureView()
        configureFetchRequest()
        initializeMapView()
    }
    
    func configureFetchRequest(){
        //create fetch request
        //sort descriptor and attach it
        let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: false)
        fetchRequest = Pin.fetchRequest()
        fetchRequest.sortDescriptors = [sortDescriptor]
        if let result = try? dataController.viewContext.fetch(fetchRequest){
            //if there are saved pins, load them
            pins = result
            //initialize current pin to first one in results
            if result.count > 0{
                selectedPin = pins[0]
            }
            //reload map
        }
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
        let long = (view.annotation?.coordinate.longitude)!
        let lat = (view.annotation?.coordinate.latitude)!
        getLocation(long: long, lat: lat, completion: {
            location in
            //set it as current pin
            self.selectedPin.latitude = lat
            self.selectedPin.longitude = long
            if let loc = location{
                self.selectedPin.location = loc
            }
            if control == view.rightCalloutAccessoryView {
                self.performSegue(withIdentifier: "pinSegue", sender: nil)
            }
        })
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? PhotoAlbumViewController{
            vc.pin = selectedPin
            //get images
            FlickerAPI.getImagesResponse(long: selectedPin.longitude, lat: selectedPin.latitude, page: 1, perPage: numOfImagesToDsiplay, completionHandler: {
                (responses, error) in
                //check if responses not nill set them in collection view class
                if let responses = responses{
                    vc.photoResponses = responses
                    vc.collectionView.reloadData()
                }
            })
        }
    }
    
    func initializeMapView(){
        //display saved pins
        if pins.count > 0{
            for index in 0...(pins.count-1) {
                let pin = pins[index]
                self.displayPinOnMap(long: pin.longitude, lat: pin.latitude, location: pin.location ?? "")
            }
        }
    }
    
    @objc func addWaypoint(longGesture: UIGestureRecognizer) {
        //pin is placed
        let touchPoint = longGesture.location(in: mapView)
        let wayCoords = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let wayAnnotation = MKPointAnnotation()
        wayAnnotation.coordinate = wayCoords
        wayAnnotation.title = "waypoint"
        getLocation(long: wayCoords.longitude, lat: wayCoords.latitude, completion: {
            (location) in
            if let loc = location{
                //display it on map
                self.displayPinOnMap(long: wayCoords.longitude, lat: wayCoords.latitude, location: loc)
                //save it in memory
                self.savePin(long: wayCoords.longitude, lat: wayCoords.latitude, location: loc)
            }
        })
    }

    func displayPinOnMap(long:Double, lat: Double, location:String){
        //parse data
        //create a variable for annotations
        // The lat and long are used to create a CLLocationCoordinates2D instance.
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = location
        self.mapView.addAnnotation(annotation)
        self.mapView.setCenter(coordinate, animated: true)
        self.mapView.reloadInputViews()
    }
    
    func getLocation(long: Double, lat: Double, completion: @escaping (String?)->Void){
        var location = ""
        let geoCoder = CLGeocoder()
        let waypoint = CLLocation(latitude: lat, longitude: long)
        geoCoder.reverseGeocodeLocation(waypoint, completionHandler:
             {
                (placemarks, error) -> Void in
                // Place details
                guard let placeMark = placemarks?.first else {
                    return
                }
                // Country
                if let loc = placeMark.subAdministrativeArea{
                    location = loc
                }
                if let loc = placeMark.country{
                    if location == ""{
                        location = loc
                    }else{
                        location += ", \(loc)"
                    }
                }
                DispatchQueue.main.async {
                    completion(location)
                }
         })
    }
    
    func savePin(long: Double, lat: Double, location: String){
        //get city and country and save
        let pin = Pin(context: dataController.viewContext)
        pin.longitude = long
        pin.latitude = lat
        pin.location = location
        pin.createdAt = Date()
        pins.insert(pin, at: 0)
        do{
            try dataController.viewContext.save()
        }catch{
            fatalError(error.localizedDescription)
        }
    }
}
