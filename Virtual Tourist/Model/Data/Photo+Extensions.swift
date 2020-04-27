import Foundation

extension Photo{
    public override func awakeFromInsert() {
        self.createdAt = Date()
    }
}
