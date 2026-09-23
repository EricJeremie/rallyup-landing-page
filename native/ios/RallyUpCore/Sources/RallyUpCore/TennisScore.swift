import Foundation

public struct TennisScore: Codable, Equatable, Sendable {
    private enum CodingKeys: String, CodingKey {
        case completedSets
        case games
        case points
        case isTiebreak
        case winner
    }

    public private(set) var completedSets: [SetScore]
    public private(set) var games: [Int]
    public private(set) var points: [Int]
    public private(set) var isTiebreak: Bool
    public private(set) var winner: PlayerSide?

    public init(
        completedSets: [SetScore] = [],
        games: [Int] = [0, 0],
        points: [Int] = [0, 0],
        isTiebreak: Bool = false,
        winner: PlayerSide? = nil
    ) {
        self.completedSets = completedSets
        self.games = games
        self.points = points
        self.isTiebreak = isTiebreak
        self.winner = winner
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(completedSets, forKey: .completedSets)
        try container.encode(games, forKey: .games)
        try container.encode(points, forKey: .points)
        try container.encode(isTiebreak, forKey: .isTiebreak)
        if let winner {
            try container.encode(winner.rawValue, forKey: .winner)
        } else {
            try container.encodeNil(forKey: .winner)
        }
    }

    public var isComplete: Bool { winner != nil }

    public func games(for side: PlayerSide) -> Int {
        games[side.rawValue]
    }

    public func points(for side: PlayerSide) -> Int {
        points[side.rawValue]
    }

    public func setsWon(by side: PlayerSide) -> Int {
        completedSets.filter { $0.games(for: side) > $0.games(for: side.opponent) }.count
    }

    public func pointLabel(for side: PlayerSide) -> String {
        let own = points(for: side)
        let other = points(for: side.opponent)

        if isTiebreak { return String(own) }
        if own >= 3 && other >= 3 {
            if own == other { return "40" }
            return own > other ? "AD" : "40"
        }

        return ["0", "15", "30", "40"][min(own, 3)]
    }

    public mutating func awardPoint(to side: PlayerSide, format: MatchFormat) {
        guard winner == nil else { return }
        let index = side.rawValue
        let otherIndex = side.opponent.rawValue

        if isTiebreak {
            points[index] += 1
            if points[index] >= 7 && points[index] - points[otherIndex] >= 2 {
                finishSet(wonBy: side, format: format, tiebreak: true)
            }
            return
        }

        if points[index] >= 3 && points[otherIndex] >= 3 {
            if points[index] == 4 {
                winGame(for: side, format: format)
            } else if points[otherIndex] == 4 {
                points[otherIndex] = 3
            } else {
                points[index] = 4
            }
            return
        }

        points[index] += 1
        if points[index] >= 4 && points[index] - points[otherIndex] >= 2 {
            winGame(for: side, format: format)
        }
    }

    private mutating func winGame(for side: PlayerSide, format: MatchFormat) {
        games[side.rawValue] += 1
        points = [0, 0]

        let ownGames = games[side.rawValue]
        let otherGames = games[side.opponent.rawValue]
        if ownGames >= format.gamesToWinSet && ownGames - otherGames >= 2 {
            finishSet(wonBy: side, format: format, tiebreak: false)
        } else if games[0] == format.gamesToWinSet && games[1] == format.gamesToWinSet {
            isTiebreak = true
        }
    }

    private mutating func finishSet(wonBy side: PlayerSide, format: MatchFormat, tiebreak: Bool) {
        if tiebreak { games[side.rawValue] += 1 }
        completedSets.append(SetScore(you: games[0], opponent: games[1], tiebreak: tiebreak))
        games = [0, 0]
        points = [0, 0]
        isTiebreak = false

        if setsWon(by: side) >= format.setsToWin {
            winner = side
        }
    }
}
