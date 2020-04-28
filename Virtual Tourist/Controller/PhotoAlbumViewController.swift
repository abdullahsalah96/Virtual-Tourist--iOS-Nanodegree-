//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Abdalla Elshikh on 4/26/20.
//  Copyright © 2020 Abdalla Elshikh. All rights reserved.
//

//TODO:
//1- LOAD/SAVE DATA IN MEMEORY
//2- DELETE DATA
//3- MIGRATE TO USING FETCH REQUEST CONTROLLER

import UIKit
import CoreData

class PhotoAlbumViewController: UIViewController, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    var dataController = DataController.shared
    var photoResponses: [PhotoResponse] = []
    var fetchResultsController: NSFetchedResultsController<Photo>!
    var isDataSaved: Bool = false
    var pin: Pin!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureFetchResultsController()
        configureCollectionView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func configureFetchResultsController(){
        //create fetch request
        //sort descriptor, predicate and attach them to fetch results controller
        print("Latitude: \(pin.latitude)")
        print("Longitude: \(pin.longitude)")
        print("Location: \(pin.location!)")
        let fetchRequest:NSFetchRequest<Photo>!
        let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: false)
        let predicate = NSPredicate(format: "pin == %@", argumentArray: [pin])
        fetchRequest = Photo.fetchRequest()
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.predicate = predicate
        fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchResultsController.delegate = self
        do{
            try fetchResultsController.performFetch() // fetch results
        }catch{
            fatalError("Failed to load data from memory")
        }
        let results = fetchResultsController.fetchedObjects!
        if results.count > 0 {
            isDataSaved = true
            print("FETCH RESULTS Count ? : \(results.count)")
        }else{
            print("No data saved")
            isDataSaved = false
        }
        print(isDataSaved)
        self.collectionView.reloadData()
    }
    
    func configureCollectionView(){
        //configure UI
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    func savePhoto(image: UIImage){
        let photo = Photo(context: dataController.viewContext)
        photo.photo = image.pngData()
        photo.createdAt = Date()
        photo.pin = self.pin
        do{
            try dataController.viewContext.save()
            print("Saving picture")
        }catch{
            print("Can't save picture")
        }
        collectionView.reloadData()
    }
    
    @IBAction func newCollectionPressed(_ sender:Any){
        //fetch new set of images
        //get random page number
        let page = FlickerAPI.getRandomPage()
        print("Random Page: \(page)")
        FlickerAPI.getImagesResponse(long: pin.longitude, lat: pin.latitude, page:page, perPage: self.photoResponses.count, completionHandler: {
            (responses, error) in
            /*check if responses not nill set them in collection view class, delete existing images and
             save new images
            */
            if let responses = responses{
                self.photoResponses = responses
//                self.isDataSaved = false
                self.collectionView.reloadData()
                print("Found \(self.photoResponses.count) new images")
            }
        })
    }
    
}

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource{
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
//        return fetchResultsController.sections?.count > ?? 1
        if isDataSaved{
            return fetchResultsController.sections!.count
        }else{
            return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return fetchResultsController.sections?[section].numberOfObjects ?? self.photoResponses.count
        if isDataSaved{
            return fetchResultsController.sections![section].numberOfObjects
        }else{
            return self.photoResponses.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath)
        //delete image
        collectionView.deleteItems(at: [indexPath])
//        collectionView.remove
    }
    
    func loadPhoto(indexPath: IndexPath)->Photo?{
        return fetchResultsController.object(at: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        //populate cells
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! ImageCell
        //check if there are images load them if not then download images
        if isDataSaved{
            print("Loading data")
            //populate cells with them
            let pic = loadPhoto(indexPath: indexPath)
            let imgData = pic!.photo
            let img = UIImage(data: imgData!)
            cell.imageView.image = img
        }else{
            print("Downloading data")
            //download them
            FlickerAPI.getImageAt(index: indexPath.row, response: self.photoResponses, completionHandler: {
                (img, error) in
                if let img = img {
                    cell.imageView.image = img
                    //save it to memory
                    self.savePhoto(image: img)
                }
            })
        }
        return cell
    }
}
