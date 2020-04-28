//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Abdalla Elshikh on 4/26/20.
//  Copyright © 2020 Abdalla Elshikh. All rights reserved.
import UIKit
import CoreData

class PhotoAlbumViewController: UIViewController, NSFetchedResultsControllerDelegate{

    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    var dataController = DataController.shared
    var photoResponses: [PhotoResponse] = []
    var fetchResultsController: NSFetchedResultsController<Photo>!
    var isDataSaved: Bool = false
    var isNewCollectionPressed: Bool = false
    var pin: Pin!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureFetchResultsController()
        configureCollectionView()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchResultsController = nil
    }
    
    func configureFetchResultsController(){
        //create fetch request
        //sort descriptor, predicate and attach them to fetch results controller
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: false)
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.predicate = predicate
        fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchResultsController.delegate = self
        do{
            try fetchResultsController.performFetch() // fetch results
        }catch{
            fatalError("Failed to load data from memory")
        }
        //if number of fetched results >0 then we have data saved else download it
        let results = fetchResultsController.fetchedObjects!
        if results.count > 0 {
            isDataSaved = true
            self.newCollectionButton.isEnabled = true
        }else{
            isDataSaved = false
            self.newCollectionButton.isEnabled = false
        }
    }
    
    func configureCollectionView(){
        //configure UI
        collectionView.delegate = self
        collectionView.dataSource = self
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        let width = UIScreen.main.bounds.width
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: width / 4, height: width / 5)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        collectionView!.collectionViewLayout = layout
    }
    
    
    func loadPhoto(indexPath: IndexPath)->Photo?{
        //get photo object at index
        return fetchResultsController.object(at: indexPath)
    }
    
    func savePhoto(image: UIImage){
        //save photo object to memory
        let photo = Photo(context: dataController.viewContext)
        photo.photo = image.pngData()
        photo.pin = pin
        do{
            try dataController.viewContext.save()
        }catch{
            fatalError(error.localizedDescription)
        }
    }
    
    func deletePhoto(indexPath: IndexPath){
        //delete photo from memoyr
        let photo = fetchResultsController.object(at: indexPath)
        dataController.viewContext.delete(photo)
        do{
            try dataController.viewContext.save()
        }catch{
            fatalError(error.localizedDescription)
        }
        configureFetchResultsController()
    }
    
    @IBAction func newCollectionPressed(_ sender:Any){
        //fetch new set of images
        //get random page number
        self.newCollectionButton.isEnabled = false
        let page = FlickerAPI.getRandomPage()
        FlickerAPI.getImagesResponse(long: pin.longitude, lat: pin.latitude, page:page, perPage: self.photoResponses.count, completionHandler: {
            (responses, error) in
            /*check if responses not nill set them in collection view class, delete existing images and
             save new images
            */
            if let responses = responses{
                self.photoResponses = responses
                self.isDataSaved = false
                self.isNewCollectionPressed = true
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            }
        })
    }
    
}

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource{
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if isDataSaved{
            return fetchResultsController.sections!.count
        }else{
            return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isDataSaved{
            return fetchResultsController.sections![section].numberOfObjects
        }else{
            return self.photoResponses.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //delete image
        collectionView.deleteItems(at: [indexPath])
        deletePhoto(indexPath: indexPath)
        //reload table
        DispatchQueue.main.async {
            collectionView.reloadData()
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        //populate cells
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! ImageCell
        //check if there are images load them if not then download images
        if isDataSaved{
            self.newCollectionButton.isEnabled = true
            //populate cells with them
            let pic = loadPhoto(indexPath: indexPath)
            let imgData = pic!.photo
            let img = UIImage(data: imgData!)
            cell.imageView.image = img
        }else{
            cell.imageView.image = UIImage(named: "placeholder")
            downloadImagesAndReload(indexPath: indexPath, cell: cell)
        }
        return cell
    }
    
    func downloadImagesAndReload(indexPath: IndexPath, cell: ImageCell){
        //download them
        FlickerAPI.getImageAt(index: indexPath.row, response: self.photoResponses, completionHandler: {
            (img, error) in
            if let img = img {
                cell.imageView.image = img
                //save it to memory
                self.savePhoto(image: img)
                //check if it's new collection then delete next image in memory
                if(indexPath.row < self.fetchResultsController.fetchedObjects!.count - 1){
                    //if it's not last photo
                    if(self.isNewCollectionPressed){
                        let newIndex = IndexPath(row: indexPath.row + 1, section: indexPath.section)
                        self.deletePhoto(indexPath: newIndex)
                    }
                }
                else{
                    //last photo need to change boolean
                    self.isNewCollectionPressed = false
                    self.isDataSaved = true
                    self.configureFetchResultsController() //reload fetch results controller
                    self.collectionView.reloadData()
                }
            }
        })
    }
}
