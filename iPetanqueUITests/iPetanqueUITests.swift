import XCTest

/// Drives the app through real matches to capture what the gameplay screen
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
        // toward the middle, as a human throw would. Some of these will be
        // no-ops if it's the AI's turn when they fire — that's fine, this
        // is meant to exercise a whole match, not just one throw.
        for i in 0..<14 {
            let dx = 0.35 + Double(i % 3) * 0.15
            let dy = 0.35 + Double((i * 7) % 4) * 0.1
            let start = field.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85))
            let end = field.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: dy))
            start.press(forDuration: 0.08, thenDragTo: end)
            sleep(2)
        }

        attach(app, "06_midMatch")

        // Keep throwing (covering an end-of-end "Continue" tap if it shows
        // up) until we either see the end-of-end summary or run out of
        // patience — this is what actually exercises the board-clearing
        // bug between ends, not just a single throw.
        var sawEndOfEnd = false
        for i in 0..<20 {
            let continueButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Continuar' OR label CONTAINS[c] 'Continue'")).firstMatch
            if continueButton.exists && continueButton.isHittable {
                sawEndOfEnd = true
                attach(app, "07_endOfEnd")
                continueButton.tap()
                sleep(1)
                attach(app, "08_newEndBoardShouldBeEmpty")
                break
            }
            let dx = 0.3 + Double(i % 4) * 0.15
            let dy = 0.3 + Double((i * 5) % 5) * 0.09
            let start = field.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85))
            let end = field.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: dy))
            start.press(forDuration: 0.08, thenDragTo: end)
            sleep(2)
        }

        attach(app, "09_final")
        XCTAssertTrue(sawEndOfEnd, "Never reached an end-of-end screen — cannot verify the board-clearing fix")
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
