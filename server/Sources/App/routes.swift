import Vapor

/// Register your application's routes here.
public func routes(_ router: Router, _ services: inout Services) throws {
    router.get { req -> Future<Response> in
        let dirs = try req.make(DirectoryConfig.self)
        return try req.streamFile(at: dirs.workDir + "Public/index.html")
    }

    let api = router.grouped("api")

    let gameController = GameController()
    api.group("games") { games in
        games.get(String.parameter, use: gameController.get)
        games.post(use: gameController.create)
    }

    let wss = NIOWebSocketServer.default()
    wss.get("ws", "games", String.parameter, use: gameController.client)

    services.register(wss, as: WebSocketServer.self)
}
