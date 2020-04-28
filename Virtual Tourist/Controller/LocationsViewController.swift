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

class LocationsViewController: UIViewController, NSFetchedResultsControllerDelegate {
    
    var dataController: DataController = DataController.shared
    var fetchResultsController: NSFetchedResultsController<Pin>!
    var photoResponses: [PhotoResponse] = []
    var selectedPin: Pin!
    let numOfImagesToDsiplay = 20

    @IBOutlet weak var mapView: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureView()
        configureFetchResultsController()
        initializeMapView()
    }
    
    func configureFetchResultsController(){
        //create fetch request
        //sort descriptor and attach it
        let fetchRequest:NSFetchRequest<Pin>!
        let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: false)
        fetchRequest = Pin.fetchRequest()
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchResultsController.delegate = self
        do{
            try fetchResultsController.performFetch()
            if fetchResultsController.fetchedObjects!.count > 0{
                selectedPin = fetchResultsController.object(at: IndexPath(item: 0, section: 0))
            }else{
                self.selectedPin = Pin(context: self.dataController.viewContext)
            }
        }catch{
            fatalError("Failed to load data from memory")
        }
    }
    
    func configureView(){
        self.mapView.delegate = self
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(addWaypoint(longGesture:)))
        self.mapView.addGestureRecognizer(gesture)
    }

}

// -------------------------------------------------------------------------
// MARK: - MAP VIEW DELEGATE AND FUNCTIONS

extension LocationsViewController: MKMapViewDelegate{
    //customize pins
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
       let reuseId = "pin"
       var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
       if pinView == nil {
        //Styling of pins
        pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        pinView?.isEnabled = true
        pinView!.pinTintColor = .red
        pinView!.canShowCallout = true
        pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
       }
       else {
           pinView!.annotation = annotation
       }
       return pinView
    }
        
    // This delegate method is implemented to respond to taps. as to direct to media type
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        //getting latitude and longitude
        let long = (view.annotation?.coordinate.longitude)!
        let lat = (view.annotation?.coordinate.latitude)!
        getLocation(long: long, lat: lat, completion: {
            //getting geographical location
            location in
            //set it as current pin
            self.selectedPin.latitude = lat
            self.selectedPin.longitude = long
            if let loc = location{
                self.selectedPin.location = loc
            }
            if control == view.rightCalloutAccessoryView {
                //moving to photo album
                self.performSegue(withIdentifier: "pinSegue", sender: nil)
            }
        })
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? PhotoAlbumViewController{
            guard selectedPin != nil else{return}
            vc.pin = selectedPin //setting photo album pin
//            vc.configureFetchResultsController() //fetch results so they are ready before loading view
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
        let pins = fetchResultsController.fetchedObjects!
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
        //The lat and long are used to create a CLLocationCoordinates2D instance.
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = location
        self.mapView.addAnnotation(annotation)
        self.mapView.setCenter(coordinate, animated: true)
        self.mapView.reloadInputViews()
    }
    
    func getLocation(long: Double, lat: Double, completion: @escaping (String?)->Void){
        //this function is used to get country and city string to be displayed on pin
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
        //get city and country and save pin to data model
        let pin = Pin(context: dataController.viewContext)
        pin.longitude = long
        pin.latitude = lat
        pin.location = location
        do{
            try dataController.viewContext.save()
            print("Saving pin")
        }catch{
            fatalError(error.localizedDescription)
            print("Error saving pin")
        }
    }
}
