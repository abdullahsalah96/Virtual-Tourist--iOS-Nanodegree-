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

class PhotoAlbumViewController: UIViewController {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var collectionView: UICollectionView!
    var dataController = DataController.shared
    var fetchRequest:NSFetchRequest<Photo>!
    var photoResponses: [PhotoResponse] = []
    var photos: [Photo] = []
    var images: [UIImage] = [] //to be removed and replaced by photos
    var pin: Pin!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        configureFetchRequest()
        self.activityIndicator.startAnimating()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("Latitude: \(pin.latitude)")
        print("Longitude: \(pin.longitude)")
        print("Location: \(pin.location!)")
    }
    
    func configureFetchRequest(){
        //create fetch request
        fetchRequest = Photo.fetchRequest()
        //sort descriptor and attach it
//        let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: false)
//        fetchRequest.sortDescriptors = [sortDescriptor]
        //set predicate
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        if let result = try? dataController.viewContext.fetch(fetchRequest){
//            if there are saved pins, load them
            photos = result
            print(photos.count)
//            reload collection view
        }
    }
    
    func configureView(){
        //configure UI
    }
    
    @IBAction func newCollectionPressed(_ sender:Any){
        //fetch new set of images
        //get random page number
        let page = FlickerAPI.getRandomPage()
        print("Random Page: \(page)")
        FlickerAPI.getImagesResponse(long: pin.longitude, lat: pin.latitude, page:page, perPage: self.photoResponses.count, completionHandler: {
            (responses, error) in
            //check if responses not nill set them in collection view class
            if let responses = responses{
                self.photoResponses = responses
                self.collectionView.reloadData()
            }
        })
    }
    
}

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.photoResponses.count //how many cells
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath)
        //delete image
        collectionView.deleteItems(at: [indexPath])
//        collectionView.remove
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        //populate cells
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! ImageCell
        self.activityIndicator.startAnimating()
        //download image
        FlickerAPI.getImageAt(index: indexPath.row, response: self.photoResponses, completionHandler: {
            (img, error) in
            if let img = img {
                cell.imageView.image = img
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
            }
        })
        self.activityIndicator.isHidden = true
        return cell
    }
}
