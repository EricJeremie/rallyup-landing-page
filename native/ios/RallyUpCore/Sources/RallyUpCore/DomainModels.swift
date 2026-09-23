import Foundation

public enum SkillLevel: String, Codable, CaseIterable, Identifiable, Sendable {
    case beginner
    case intermediate
    case advanced

    public var id: String { rawValue }

    public var title: String { rawValue.capitalized }
}

public enum PlayerStrength: String, Codable, CaseIterable, Identifiable, Sendable {
    case forehand
    case backhand
    case serve
    case volley
    case footwork
    case consistency

    public var id: String { rawValue }

    public var title: String { rawValue.capitalized }

    public var detail: String {
        switch self {
        case .forehand: "A confident shot from the baseline."
        case .backhand: "A reliable one- or two-handed stroke."
        case .serve: "Power, placement, or a steady start."
        case .volley: "Comfortable closing in at the net."
        case .footwork: "Quick coverage and court movement."
        case .consistency: "Long rallies and dependable returns."
        }
    }
}

public struct PlayerProfile: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var displayName: String
    public var initials: String
    public var skillLevel: SkillLevel
    public var approximateDistanceKm: Double?
    public var homeArea: String?
    public var wins: Int
    public var losses: Int
    public var availabilitySummary: String
    public var compatibilityPercent: Int?
    public var avatarURL: String?
    public var strengths: [PlayerStrength]?
    public var racketPhotoURLs: [String]?
    public var rackets: [PlayerRacket]?

    public var racketSetup: [PlayerRacket] {
        if let rackets, !rackets.isEmpty { return Array(rackets.prefix(3)) }
        return (racketPhotoURLs ?? []).prefix(3).enumerated().map {
            PlayerRacket(name: "Racket \($0.offset + 1)", photoURL: $0.element)
        }
    }

    public init(
        id: UUID = UUID(),
        displayName: String,
        initials: String,
        skillLevel: SkillLevel,
        approximateDistanceKm: Double? = nil,
        homeArea: String? = nil,
        wins: Int = 0,
        losses: Int = 0,
        availabilitySummary: String = "Availability not set",
        compatibilityPercent: Int? = nil,
        avatarURL: String? = nil,
        strengths: [PlayerStrength]? = nil,
        racketPhotoURLs: [String]? = nil,
        rackets: [PlayerRacket]? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.initials = initials
        self.skillLevel = skillLevel
        self.approximateDistanceKm = approximateDistanceKm
        self.homeArea = homeArea
        self.wins = wins
        self.losses = losses
        self.availabilitySummary = availabilitySummary
        self.compatibilityPercent = compatibilityPercent
        self.avatarURL = avatarURL
        self.strengths = strengths.map { Array($0.prefix(PlayerStrength.allCases.count)) }
        self.racketPhotoURLs = racketPhotoURLs.map { Array($0.prefix(3)) }
        self.rackets = rackets.map { Array($0.prefix(3)) }
    }
}

public struct PlayerRacket: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var photoURL: String?

    public init(id: UUID = UUID(), name: String, photoURL: String? = nil) {
        self.id = id
        self.name = name
        self.photoURL = photoURL
    }
}

public struct TennisCourt: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var address: String
    public var surface: String
    public var setting: String
    public var latitude: Double
    public var longitude: Double

    public init(
        id: UUID = UUID(),
        name: String,
        address: String,
        surface: String,
        setting: String,
        latitude: Double,
        longitude: Double
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.surface = surface
        self.setting = setting
        self.latitude = latitude
        self.longitude = longitude
    }
}

public enum MatchStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case invited
    case inviteSent
    case scheduled
    case inProgress
    case awaitingConfirmation
    case completed
    case cancelled
    case disputed

    public var id: String { rawValue }
}

public struct MatchParticipant: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var playerID: UUID
    public var displayName: String
    public var side: PlayerSide

    public init(id: UUID = UUID(), playerID: UUID, displayName: String, side: PlayerSide) {
        self.id = id
        self.playerID = playerID
        self.displayName = displayName
        self.side = side
    }
}

public struct MatchRecord: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var participants: [MatchParticipant]
    public var scheduledAt: Date
    public var court: TennisCourt
    public var matchType: MatchType
    public var format: MatchFormat
    public var status: MatchStatus
    public var score: TennisScore
    public var resultConfirmedBy: Set<UUID>
    public var note: String?

    public init(
        id: UUID = UUID(),
        participants: [MatchParticipant],
        scheduledAt: Date,
        court: TennisCourt,
        matchType: MatchType = .singles,
        format: MatchFormat = .bestOfThree,
        status: MatchStatus = .scheduled,
        score: TennisScore = TennisScore(),
        resultConfirmedBy: Set<UUID> = [],
        note: String? = nil
    ) {
        self.id = id
        self.participants = participants
        self.scheduledAt = scheduledAt
        self.court = court
        self.matchType = matchType
        self.format = format
        self.status = status
        self.score = score
        self.resultConfirmedBy = resultConfirmedBy
        self.note = note
    }

    public func participants(on side: PlayerSide) -> [MatchParticipant] {
        participants.filter { $0.side == side }
    }

    public func teamName(on side: PlayerSide) -> String {
        participants(on: side).map(\.displayName).joined(separator: " & ")
    }
}
