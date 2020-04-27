//
//  FlickerAPI.swift
//  Virtual Tourist
//
//  Created by Abdalla Elshikh on 4/27/20.
//  Copyright © 2020 Abdalla Elshikh. All rights reserved.
//

import Foundation
import UIKit

class FlickerAPI {
        
    enum Endpoints{
        case searchImages(long: Double, lat: Double, perPage: Int, contentType: Int)
        static let apiKey = "192f95443a4cb57e5996a1e7207b5735"
        static let baseURL = "https://api.flickr.com/services/rest/?&method=flickr.photos.search"
        var StringValue: String{
            switch self {
            case .searchImages(let long, let lat, let perPage, let contentType):
                return Endpoints.baseURL + "&api_key=\(Endpoints.apiKey)" + "&lat=\(lat)" + "&lon=\(long)" + "&radius=20" + "&per_page=\(perPage)" + "&content_type=\(contentType)" + "&format=json&nojsoncallback=1&extras=url_m"
            }
        }
        var url: URL{
            return URL(string: StringValue)!
        }
    }
    
    class func getImagesResponse(long: Double, lat: Double, perPage: Int, completionHandler: @escaping ([PhotoResponse]?,Error?) -> Void){
        
        var request = URLRequest(url: Endpoints.searchImages(long: long, lat: lat, perPage: perPage, contentType: 1).url)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request, completionHandler: {(data,response,error) in
            guard let data = data else{
                //cannot fetch response, throw server error
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
                return
            }
            do{
                //try fetching response
                let response = try JSONDecoder().decode(ImageResponse.self, from: data)
                DispatchQueue.main.async {
                    completionHandler(response.photos.photo, nil)
                }
            }catch{
                //unable to parse response, throw credentials error
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
            }
        })
        task.resume()
    }

    class func getImageAt(index: Int,  response: [PhotoResponse], completionHandler: @escaping (UIImage?,Error?) -> Void){
        let imgURL = URL(string: response[index].url_m)
        let q = DispatchQueue.global(qos: .userInteractive)
        q.async {
            //download image on background
            do{
                let imgData = try Data(contentsOf: imgURL!)
                DispatchQueue.main.async {
                    completionHandler(UIImage(data: imgData), nil)
                }
            }catch{
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
            }
        }
    }
    
//    class func getImages(long: Double, lat: Double, perPage: Int, completionHandler: @escaping ([UIImage]?,Error?) -> Void){
//        var imgs:[UIImage] = []
//        getImagesResponse(long: long, lat: lat, perPage: perPage, completionHandler: {
//            (responses,error) in
//            guard let responses = responses else{
//                completionHandler(nil, error)
//                return
//            }
//            // download images in background
//            let q = DispatchQueue.global(qos: .userInteractive)
//            q.async {
//                for response in responses{
//                    let url = URL(string: response.url_m)
//                    do{
//                        let imgData = try Data(contentsOf: url!)
//                        let img = UIImage(data: imgData)
//                        imgs.append(img!)
//                    }catch{
//                        DispatchQueue.main.async {
//                            completionHandler(nil, error)
//                        }
//                        return
//                    }
//                }
//                DispatchQueue.main.async {
//                    completionHandler(imgs, nil)
//                }
//            }
//        })
//    }
//}
}

