import Foundation

extension Pin{
    public override func awakeFromInsert() {
        self.createdAt = Date()
    }
}
