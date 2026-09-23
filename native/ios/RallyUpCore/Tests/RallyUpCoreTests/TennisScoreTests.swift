import XCTest
@testable import RallyUpCore

final class TennisScoreTests: XCTestCase {
    func testRegularGameNeedsFourPointsAndTwoPointLead() {
        var score = TennisScore()
        for _ in 0..<3 { score.awardPoint(to: .you, format: .bestOfThree) }
        for _ in 0..<3 { score.awardPoint(to: .opponent, format: .bestOfThree) }

        XCTAssertEqual(score.pointLabel(for: .you), "40")
        score.awardPoint(to: .you, format: .bestOfThree)
        XCTAssertEqual(score.pointLabel(for: .you), "AD")
        score.awardPoint(to: .opponent, format: .bestOfThree)
        XCTAssertEqual(score.pointLabel(for: .you), "40")
        XCTAssertEqual(score.games(for: .you), 0)
    }

    func testAdvantagePointWinsGameAndResetsPoints() {
        var score = TennisScore()
        for _ in 0..<3 { score.awardPoint(to: .you, format: .bestOfThree) }
        for _ in 0..<3 { score.awardPoint(to: .opponent, format: .bestOfThree) }
        score.awardPoint(to: .you, format: .bestOfThree)
        score.awardPoint(to: .you, format: .bestOfThree)

        XCTAssertEqual(score.games(for: .you), 1)
        XCTAssertEqual(score.points(for: .you), 0)
        XCTAssertEqual(score.points(for: .opponent), 0)
    }

    func testSixAllStartsTiebreakAndTiebreakCompletesSet() {
        var score = TennisScore()
        for _ in 0..<6 {
            awardGame(to: .you, score: &score)
            awardGame(to: .opponent, score: &score)
        }
        XCTAssertTrue(score.isTiebreak)

        for _ in 0..<6 {
            score.awardPoint(to: .you, format: .bestOfThree)
            score.awardPoint(to: .opponent, format: .bestOfThree)
        }
        score.awardPoint(to: .you, format: .bestOfThree)
        score.awardPoint(to: .you, format: .bestOfThree)

        XCTAssertEqual(score.completedSets.map(\.you), [7])
        XCTAssertEqual(score.completedSets.map(\.opponent), [6])
        XCTAssertFalse(score.isTiebreak)
        XCTAssertEqual(score.games, [0, 0])
    }

    func testBestOfThreeFinishesAfterTwoSets() {
        var score = TennisScore()
        for _ in 0..<6 { awardGame(to: .you, score: &score) }
        for _ in 0..<6 { awardGame(to: .you, score: &score) }

        XCTAssertEqual(score.winner, .you)
        XCTAssertEqual(score.completedSets.map(\.you), [6, 6])
        let previousScore = score
        score.awardPoint(to: .opponent, format: .bestOfThree)
        XCTAssertEqual(score, previousScore)
    }

    func testProSetUsesEightGamesAndTiebreakAtEightAll() {
        var score = TennisScore()
        for _ in 0..<8 {
            awardGame(to: .you, score: &score, format: .proSet)
            awardGame(to: .opponent, score: &score, format: .proSet)
        }
        XCTAssertTrue(score.isTiebreak)

        for _ in 0..<7 { score.awardPoint(to: .opponent, format: .proSet) }
        XCTAssertEqual(score.winner, .opponent)
        XCTAssertEqual(score.completedSets.first?.you, 8)
        XCTAssertEqual(score.completedSets.first?.opponent, 9)
        XCTAssertTrue(score.completedSets.first?.tiebreak == true)
    }

    func testScoreEncodingPreservesExplicitNullWinner() throws {
        let score = TennisScore()
        let data = try JSONEncoder().encode(score)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertTrue(object.keys.contains("completedSets"))
        XCTAssertTrue(object["winner"] is NSNull)
        XCTAssertEqual(try JSONDecoder().decode(TennisScore.self, from: data), score)
    }

    private func awardGame(to side: PlayerSide, score: inout TennisScore, format: MatchFormat = .bestOfThree) {
        for _ in 0..<4 { score.awardPoint(to: side, format: format) }
    }
}
