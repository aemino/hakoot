import Vapor

struct GameParameters: Content {
    var triviaTemplate: String
}

struct GameTrivium: Content {
    var question: String
    var answer: String
}

struct GameMetadata: Content {
    var pin: String
    var token: String
}

struct GameAnswerMetadata: Content {
    var id: String
    var answer: String
    var totalFunds: Int
}
