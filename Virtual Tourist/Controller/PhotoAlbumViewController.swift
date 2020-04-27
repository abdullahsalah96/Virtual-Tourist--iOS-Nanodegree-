//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Abdalla Elshikh on 4/26/20.
//  Copyright © 2020 Abdalla Elshikh. All rights reserved.
//

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
    
    func initCollectionView(){
//        FlickerAPI.getImages(long: pin.longitude, lat: pin.latitude, perPage: 2, completionHandler: {
//            (responses,error) in
//            if let responses = responses{
//                self.images = responses
//                print(responses.count)
//                print("reloading collection view")
//                self.collectionView.reloadData()
//            }
//        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("Latitude: \(pin.latitude)")
        print("Longitude: \(pin.longitude)")
        print("Location: \(pin.location!)")
        initCollectionView()
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
            //if there are saved pins, load them
//            photos = result
//            print(photos.count)
            //reload map
        }
    }
    
    func configureView(){
        //configure UI
    }
    
    @IBAction func newCollectionPressed(_ sender: Any) {
        //fetch new set of images
        self.collectionView.reloadData()
    }
    
}

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.photoResponses.count //how many cells
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath)
        //delete image
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
        return cell
    }
}
