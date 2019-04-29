import Vapor

struct Player: Content {
    var id: String
    var displayName: String
    var funds: Int
}
