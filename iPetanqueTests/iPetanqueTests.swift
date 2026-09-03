import XCTest
@testable import iPetanque

final class iPetanqueTests: XCTestCase {
    func testGameModeBallCounts() {
        XCTAssertEqual(GameMode.singles.ballsPerPlayer, 3)
        XCTAssertEqual(GameMode.doubles.ballsPerPlayer, 3)
        XCTAssertEqual(GameMode.triples.ballsPerPlayer, 2)
    }

    func testBallDistance() {
        let ball = Ball(team: .teamA, position: CGPoint(x: 0, y: 0))
        XCTAssertEqual(ball.distance(to: CGPoint(x: 3, y: 4)), 5, accuracy: 0.0001)
    }

    func testTeamOpponent() {
        XCTAssertEqual(Team.teamA.opponent, .teamB)
        XCTAssertEqual(Team.teamB.opponent, .teamA)
    }
}
