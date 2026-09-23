import Foundation

public enum MatchType: String, Codable, CaseIterable, Identifiable, Sendable {
    case singles
    case doubles

    public var id: String { rawValue }
    public var title: String { rawValue.capitalized }
}

public enum MatchFormat: String, Codable, CaseIterable, Identifiable, Sendable {
    case bestOfThree
    case oneSet
    case proSet

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .bestOfThree: "Best of 3"
        case .oneSet: "One set"
        case .proSet: "Pro set"
        }
    }

    public var summary: String {
        switch self {
        case .oneSet: "One set to 6 games; win by 2. Tiebreak at 6–6."
        case .bestOfThree: "First to 2 sets; each set to 6 games. Tiebreak at 6–6."
        case .proSet: "One set to 8 games; win by 2. Tiebreak at 8–8."
        }
    }

    public var setsToWin: Int {
        switch self {
        case .bestOfThree: 2
        case .oneSet, .proSet: 1
        }
    }

    public var gamesToWinSet: Int {
        self == .proSet ? 8 : 6
    }
}

public enum PlayerSide: Int, Codable, CaseIterable, Identifiable, Sendable {
    case you
    case opponent

    public var id: Int { rawValue }

    public var opponent: PlayerSide {
        self == .you ? .opponent : .you
    }
}

public struct SetScore: Codable, Equatable, Sendable, Identifiable {
    public let id: UUID
    public let you: Int
    public let opponent: Int
    public let tiebreak: Bool

    public init(id: UUID = UUID(), you: Int, opponent: Int, tiebreak: Bool = false) {
        self.id = id
        self.you = you
        self.opponent = opponent
        self.tiebreak = tiebreak
    }

    public func games(for side: PlayerSide) -> Int {
        side == .you ? you : opponent
    }
}
