import Foundation

struct ImageResponse: Codable{
    let photos: responseDetails
    let stat: String
}

struct responseDetails: Codable{
    let page: Int
    let pages: Int
    let perpage: Int
    let total: String
    let photo: [PhotoResponse]
}

struct PhotoResponse: Codable{
    let id: String
    let owner: String
    let secret: String
    let server: String
    let farm: Int
    let title: String
    let ispublic: Int
    let isfriend: Int
    let isfamily: Int
    let url_m: String
    let height_m: Int
    let width_m: Int
}
