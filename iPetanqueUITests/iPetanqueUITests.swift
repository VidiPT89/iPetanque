import XCTest

/// Drives the app through a real match to capture what the gameplay screen
/// actually looks like — screenshots taken here are attached to the test
/// result (`.keepAlways`) so they can be pulled out of the .xcresult bundle
/// afterwards, since simulated taps via external tools (osascript/cliclick)
/// don't reach the Simulator in this environment.
final class iPetanqueUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testGameplayFlowScreenshots() throws {
        let app = XCUIApplication()
        app.launch()

        attach(app, "01_launch")

        // Splash auto-dismisses after ~2.8s.
        let newGameButton = app.buttons["menu.newGame"]
        XCTAssertTrue(newGameButton.waitForExistence(timeout: 6), "Main menu did not appear")
        attach(app, "02_menu")

        newGameButton.tap()
        let singlesCard = app.buttons["newGame.mode.singles"]
        XCTAssertTrue(singlesCard.waitForExistence(timeout: 3), "New game screen did not appear")
        attach(app, "03_newGame")

        let startButton = app.buttons["newGame.start"]
        XCTAssertTrue(startButton.exists)
        startButton.tap()

        let field = app.otherElements["game.field"]
        XCTAssertTrue(field.waitForExistence(timeout: 3), "Game field did not appear")
        attach(app, "04_coinToss")

        // Coin toss (1.4s) + possible AI thinking delay before the field is
        // interactive.
        sleep(3)
        attach(app, "05_throwCochonnet")

        // Drag from near the bottom of the field (the throwing circle) up
        // toward the middle, as a human throw of the cochonnet would.
        let start = field.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85))
        let end = field.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45))
        start.press(forDuration: 0.1, thenDragTo: end)

        sleep(2)
        attach(app, "06_afterCochonnetThrow")

        sleep(3)
        attach(app, "07_afterFirstAITurnOrBall")

        // One more human throw attempt if it's still a throwing phase.
        let start2 = field.coordinate(withNormalizedOffset: CGVector(dx: 0.45, dy: 0.85))
        let end2 = field.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start2.press(forDuration: 0.1, thenDragTo: end2)

        sleep(3)
        attach(app, "08_afterSecondThrow")
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
