import XCTest
@testable import RallyUpCore

final class MatchConfigurationTests: XCTestCase {
    func testDoublesMatchKeepsBothTeamsAndTheirNames() {
        let eric = player("Eric Rotaquio")
        let miguel = player("Miguel Santos")
        let jamie = player("Jamie Cruz")
        let alex = player("Alex Reyes")
        let court = TennisCourt(
            name: "BGC Tennis Club",
            address: "Taguig",
            surface: "Hard",
            setting: "Outdoor",
            latitude: 14.55,
            longitude: 121.04
        )
        let match = MatchRecord(
            participants: [
                MatchParticipant(playerID: eric.id, displayName: eric.displayName, side: .you),
                MatchParticipant(playerID: miguel.id, displayName: miguel.displayName, side: .you),
                MatchParticipant(playerID: jamie.id, displayName: jamie.displayName, side: .opponent),
                MatchParticipant(playerID: alex.id, displayName: alex.displayName, side: .opponent),
            ],
            scheduledAt: .now,
            court: court,
            matchType: .doubles
        )

        XCTAssertEqual(match.participants(on: .you).count, 2)
        XCTAssertEqual(match.participants(on: .opponent).count, 2)
        XCTAssertEqual(match.teamName(on: .you), "Eric Rotaquio & Miguel Santos")
        XCTAssertEqual(match.teamName(on: .opponent), "Jamie Cruz & Alex Reyes")
    }

    func testFormatSummaryExplainsSetsAndGames() {
        XCTAssertTrue(MatchFormat.bestOfThree.summary.contains("2 sets"))
        XCTAssertTrue(MatchFormat.oneSet.summary.contains("6 games"))
        XCTAssertTrue(MatchFormat.proSet.summary.contains("8 games"))
    }

    private func player(_ name: String) -> PlayerProfile {
        PlayerProfile(
            displayName: name,
            initials: String(name.split(separator: " ").compactMap(\.first)),
            skillLevel: .intermediate
        )
    }
}
