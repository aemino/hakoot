import Foundation
import Vapor

// Inefficient but sufficient for basic usage.
private func pow(_ x: Int, _ y: Int) -> Int {
    var result = 1

    for _ in 0..<y {
        result *= x
    }

    return result
}

extension WebSocket {
    func send<T: Codable>(json data: T) throws {
        let encoder = JSONEncoder()
        return try send(String(data: encoder.encode(data), encoding: .utf8)!)
    }
}

class GamePlayer {
    let id: String
    let token: String
    let displayName: String
    var ws: WebSocket?

    var isConnected: Bool {
        get {
            return ws == nil ? false : true
        }
    }

    var funds: Int

    init(id: String, token: String, displayName: String) {
        self.id = id
        self.token = token
        self.displayName = displayName
        self.ws = nil
        self.funds = 0
    }

    func asContent() -> Player {
        return Player(id: id, displayName: displayName, funds: funds)
    }
}

class GameAnswer {
    let id: String
    let answer: String
    var bets: [String: Int]

    init(id: String, answer: String) {
        self.id = id
        self.answer = answer
        self.bets = [:]
    }

    func asContent() -> GameAnswerMetadata {
        return GameAnswerMetadata(id: id, answer: answer,
            totalFunds:bets.values.reduce(0, +))
    }
}

// Types:
//  0 :: GameIdentify
//  1 :: GamePlayerReady | GameHostReady
//  2 :: GamePlayerJoin
//  3 :: GamePlayerLeave
//  4 :: GameStart
//  5 :: GameRoundStart
//  6 :: GameSuggestAnswer
//  7 :: GameAnswerUpdate
//  8 :: GameMakeBet
//  9 :: [unimpl] GameRescindBet
// 10 :: GameRoundEnd
// 11 :: GameEnd

enum PacketType: Int, Codable {
    case identify = 0
    case ready = 1
    case playerJoin = 2
    case playerLeave = 3
    case gameStart = 4
    case roundStart = 5
    case suggestAnswer = 6
    case answerUpdate = 7
    case makeBet = 8
    case rescindBet = 9 // unimplemented
    case roundEnd = 10
    case gameEnd = 11
}

struct GamePreliminaryPacket: Content {
    let type: PacketType
}

struct GamePacket<T: PacketData>: Content {
    let type: PacketType
    let data: T

    init(_ data: T) {
        self.type = T.type
        self.data = data
    }
}

protocol PacketData: Content {
    static var type: PacketType { get }
}

struct GameIdentify: PacketData {
    static let type: PacketType = .identify
    let token: String
}

struct GamePlayerReady: PacketData {
    static let type: PacketType = .ready
    let me: Player
}

struct GameHostReady: PacketData {
    static let type: PacketType = .ready
    let players: [Player]
}

struct GamePlayerJoin: PacketData {
    static let type: PacketType = .playerJoin
    let player: Player
}

struct GamePlayerLeave: PacketData {
    static let type: PacketType = .playerLeave
    let player: Player
}

struct GameStart: PacketData {
    static let type: PacketType = .gameStart
}

struct GameRoundStart: PacketData {
    static let type: PacketType = .roundStart
    let question: String
    let funds: [String: Int]
    let durationSeconds: Int
}

struct GameSuggestAnswer: PacketData {
    static let type: PacketType = .suggestAnswer
    let answer: String
}

struct GameAnswerUpdate: PacketData {
    static let type: PacketType = .answerUpdate
    let answer: GameAnswerMetadata
}

struct GameMakeBet: PacketData {
    static let type: PacketType = .makeBet
    let id: String
    let amount: Int
}

struct GameRoundEnd: PacketData {
    static let type: PacketType = .roundEnd
    let answer: String
    let funds: [String: Int]
    let intermissionSeconds: Int
}

struct GameEnd: PacketData {
    static let type: PacketType = .gameEnd
}

enum GameStatus {
    case lobby, started, round, intermission, ended
}

// TODO: Improve Game implementation
// The whole Game implementation was hastily implemented and could greatly
// benefit from some cleanup; particularly in how async functions/callbacks are
// handled.
final class Game {
    static let durationSeconds: Int = 45
    static let intermissionSeconds: Int = 5

    let pin: String
    let hostToken: String
    let trivia: [GameTrivium]
    var status: GameStatus
    var triviaIterator: IndexingIterator<[GameTrivium]>

    var hostSocket: WebSocket?
    var players: [String: GamePlayer]
    
    var suggestedAnswers: [String: GameAnswer]

    var funds: [String: Int] {
        get {
            return players.mapValues({ $0.funds })
        }
    }

    init(pin: String, hostToken: String, trivia: [GameTrivium]) {
        self.pin = pin
        self.status = .lobby
        self.hostToken = hostToken
        self.trivia = trivia
        self.triviaIterator = trivia.makeIterator()

        self.hostSocket = nil
        self.players = [:]

        self.suggestedAnswers = [:]
    }

    func addPlayer(id: String, displayName: String, token: String, on worker: Worker) {
        let player = GamePlayer(
            id: id,
            token: token,
            displayName: displayName
        )

        players[id] = player

        worker.eventLoop.scheduleTask(in: .seconds(5)) {
            if (!self.players[id]!.isConnected) {
                self.players.removeValue(forKey: id)
            }
        }
    }

    func start(on worker: Worker) {
        status = .started

        // Remove any players that failed to connect
        for (id, player) in players {
            if !player.isConnected {
                players.removeValue(forKey: id)
            }
        }

        worker.eventLoop.execute {
            let packet = GamePacket(GameStart())

            try? self.hostSocket?.send(json: packet)

            for player in self.players.values {
                try? player.ws?.send(json: packet)
            }

            self.startRound(on: worker)
        }
    }

    func startRound(on worker: Worker) {
        guard let trivium = triviaIterator.next() else {
            end(on: worker)
            return
        }

        status = .round

        worker.eventLoop.execute {
            self.suggestedAnswers.removeAll()

            for player in self.players.values {
                player.funds += 500
            }

            let packet = GamePacket(
                GameRoundStart(
                    question: trivium.question,
                    funds: self.funds,
                    durationSeconds: Game.durationSeconds
                )
            )

            try? self.hostSocket?.send(json: packet)

            for player in self.players.values {
                try? player.ws?.send(json: packet)
            }
        }

        worker.eventLoop.scheduleTask(in: .seconds(Game.durationSeconds)) {
            self.status = .intermission

            let correctAnswer = self.suggestedAnswers.values.first(where: {
                $0.answer.lowercased() == trivium.answer.lowercased()
            })

            if let answer = correctAnswer {
                for (id, bet) in answer.bets {
                    self.players[id]!.funds += (bet * 2)
                }
            }

            let packet = GamePacket(
                GameRoundEnd(
                    answer: trivium.answer,
                    funds: self.funds,
                    intermissionSeconds: Game.intermissionSeconds
                )
            )

            try? self.hostSocket?.send(json: packet)

            for player in self.players.values {
                try? player.ws?.send(json: packet)
            }

            /* worker.eventLoop.scheduleTask(in: .seconds(Game.intermissionSeconds)) {
                self.startRound(on: worker)
            }*/
        }
    }

    func suggest(_ answerString: String, from player: GamePlayer,
        on worker: Worker) {
        guard !suggestedAnswers.values.contains(where: {
            $0.answer.lowercased() == answerString.lowercased()
        }) else {
            return
        }

        let id = GameController.generateID();
        let answer = GameAnswer(id: id, answer: answerString)

        suggestedAnswers[id] = answer

        worker.eventLoop.execute {
            let packet = GamePacket(
                GameAnswerUpdate(
                    answer: answer.asContent()
                )
            )

            try? self.hostSocket?.send(json: packet)

            for player in self.players.values {
                try? player.ws?.send(json: packet)
            }
        }
    }

    func bet(_ amount: Int, on answer: GameAnswer, for player: GamePlayer,
        on worker: Worker) {
        guard amount > 0 && player.funds >= amount else {
            return
        }

        player.funds -= amount
        answer.bets[player.id] = (answer.bets[player.id] ?? 0) + amount

        worker.eventLoop.execute {
            let packet = GamePacket(
                GameAnswerUpdate(
                    answer: answer.asContent()
                )
            )

            try? self.hostSocket?.send(json: packet)

            for player in self.players.values {
                try? player.ws?.send(json: packet)
            }
        }
    }

    func end(on worker: Worker) {
        status = .ended

        worker.eventLoop.execute {
            let packet = GamePacket(
                GameEnd()
            )

            try? self.hostSocket?.send(json: packet)

            for player in self.players.values {
                try? player.ws?.send(json: packet)
            }
        }
    }

    func connect(_ ws: WebSocket) {
        let decoder = JSONDecoder()

        var playerID: String? = nil

        ws.onText { _, text in
            guard let prelimPacket = try? decoder
                .decode(GamePreliminaryPacket.self, from: text) else {
                ws.close()
                return
            }

            switch (prelimPacket.type) {
                case .identify:
                    guard let packet = try? decoder.decode(
                        GamePacket<GameIdentify>.self, from: text) else {
                        ws.close()
                        return
                    }

                    let data = packet.data
                    let token = data.token

                    if (token == self.hostToken) {
                        self.hostSocket = ws

                        do {
                            try ws.send(json: GamePacket(
                                GameHostReady(
                                    players: self.players.values.map({ $0.asContent() })
                                )
                            ))
                        } catch {
                            ws.close()
                        }

                        break
                    }

                    guard let player = self.players.values.first(where: {
                        $0.token == token
                    }) else {
                        ws.close()
                        return
                    }

                    player.ws = ws
                    playerID = player.id

                    do {
                        try ws.send(json: GamePacket(
                            GamePlayerReady(me: player.asContent())
                        ))
                    } catch {
                        ws.close()
                        return
                    }

                    do {
                        try self.hostSocket?.send(json: GamePacket(
                            GamePlayerJoin(player: player.asContent())
                        ))
                    } catch {}
                case .gameStart:
                    switch (self.status) {
                        case .lobby:
                            self.start(on: ws)
                        case .intermission:
                            self.startRound(on: ws)
                        default:
                            break
                    }
                case .suggestAnswer:
                    guard let packet = try? decoder.decode(
                        GamePacket<GameSuggestAnswer>.self, from: text) else {
                        ws.close()
                        return
                    }

                    guard let player = playerID != nil ? self.players[playerID!] : nil else {
                        ws.close()
                        return
                    }

                    let data = packet.data

                    self.suggest(data.answer, from: player, on: ws)
                case .makeBet:
                    guard let packet = try? decoder.decode(
                        GamePacket<GameMakeBet>.self, from: text) else {
                        ws.close()
                        return
                    }

                    guard let player = playerID != nil ? self.players[playerID!] : nil else {
                        ws.close()
                        return
                    }

                    let data = packet.data

                    guard let answer = self.suggestedAnswers[packet.data.id] else {
                        return
                    }

                    self.bet(data.amount, on: answer, for: player, on: ws)
                default:
                    ws.close()
            }
        }

        ws.onCloseCode { _ in
            playerID = nil
        }
    }
}

final class GameController {
    static let pinRange: Range<Int> = pow(10, 5)..<pow(10, 6)
    static let idRange: Range<Int> = pow(10, 3)..<pow(10, 4)
    static let tokenRange: Range<Int> = pow(10, 11)..<pow(10, 12)

    static let displayNameAdjectives: [String] = [
        "crispy",
        "cheesy",
        "sweet",
        "salty",
        "toasty",
        "savory",
        "obsolete",
        "audacious",
        "ambitious",
        "altruistic",
        "meddling",
        "surprising",
        "glorified",
        "exhalted",
        "pretentious",
        "auspicious",
        "intelligent",
        "perfect",
        "clueless",
        "clumbsy",
        "terrible",
        "unqualified",
        "troubled",
    ]

    static let displayNameNouns: [String] = [
        "banana",
        "pineapple",
        "pomegranate",
        "plum",
        "grapefruit",
        "monkey",
        "zebra",
        "lion",
        "cheetah",
        "octopus",
        "squid",
        "yeti",
        "bear",
        "king",
        "queen",
        "pessimist",
        "optimist",
        "scientist",
        "artist",
        "doctor",
        "dentist",
        "musician",
        "engineer",
        "architect",
        "author",
        "guesser",
        "jester",
        "charlatan",
        "critic",
        "connoisseur",
        "entrepreneur",
        "mathematician",
        "salesperson",
        "clerk",
        "priest",
        "actor",
        "thinker",
        "proletariat",
        "bourgeoisie",
        "clerk",
    ]

    private var games: [String: Game] = [:]

    static func generateID() -> String {
        return String(Int.random(in: GameController.idRange))
    }

    static func generatePin() -> String {
        return String(Int.random(in: GameController.pinRange))
    }

    static func generateToken() -> String {
        return String(Int.random(in: GameController.tokenRange))
            .data(using: .utf8)!
            .base64EncodedString()
    }

    static func generateDisplayName() -> String {
        return [
                GameController.displayNameAdjectives.randomElement()!,
                GameController.displayNameNouns.randomElement()!,
        ].joined(separator: " ")
    }

    private func createGameTrivia(from triviaTemplate: String) throws -> [GameTrivium] {
        let triviumTemplates = triviaTemplate.components(separatedBy: "\n\n")

        return try triviumTemplates.map { triviumTemplate in
            if let range = triviumTemplate
                .range(of: #"\{\{.*\}\}"#, options: .regularExpression) {
                let answerRange =
                    triviumTemplate.index(range.lowerBound, offsetBy: 2)
                    ...
                    triviumTemplate.index(range.upperBound, offsetBy: -3)
                
                let answer = String(triviumTemplate[answerRange])
                var question = triviumTemplate
                question.replaceSubrange(
                    range, with: String(repeating: "_", count: answer.count))

                return GameTrivium(
                    question: question,
                    answer: answer
                )
            } else {
                throw Abort(.badRequest,
                    reason: "Improperly formatted trivia template.")
            }
        }
    }

    func get(_ req: Request) throws -> GameMetadata {
        let pin = try req.parameters.next(String.self)

        guard let game = self.games[pin] else {
            throw Abort(.notFound)
        }

        guard case .lobby = game.status else {
            throw Abort(.badRequest)
        }

        let id = GameController.generateID()
        let displayName = GameController.generateDisplayName()
        let token = GameController.generateToken()

        game.addPlayer(id: id, displayName: displayName, token: token, on: req)

        return GameMetadata(
            pin: game.pin, token: token)
    }

    func create(_ req: Request) throws -> Future<GameMetadata> {
        return try req.content.decode(GameParameters.self).map { params in
            let trivia = try self.createGameTrivia(from: params.triviaTemplate)

            let game = Game(
                pin: GameController.generatePin(),
                hostToken: GameController.generateToken(),
                trivia: trivia
            )

            self.games[game.pin] = game

            return GameMetadata(
                pin: game.pin, token: game.hostToken)
        }
    }

    func client(_ ws: WebSocket, _ req: Request) throws {
        let pin = try req.parameters.next(String.self)

        guard let game = self.games[pin] else {
            throw Abort(.notFound)
        }

        game.connect(ws)
    }
}
