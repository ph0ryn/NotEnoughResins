//
//  NotEnoughResinsUITests.swift
//  NotEnoughResinsUITests
//
//  Created by ph0ryn on 2026/03/12.
//

import XCTest

final class NotEnoughResinsUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testPreferencesSavePersistsAcrossRelaunch() throws {
        let app = XCUIApplication()
        app.launchEnvironment["NOT_ENOUGH_RESINS_KEYCHAIN_SERVICE_SUFFIX"] = UUID().uuidString

        app.launch()

        XCTAssertTrue(app.staticTexts["Configuration Needed"].waitForExistence(timeout: 2))

        app.buttons["content.openPreferences"].click()

        let cookieEditor = app.textViews["preferences.cookieEditor"]
        XCTAssertTrue(cookieEditor.waitForExistence(timeout: 2))

        cookieEditor.click()
        cookieEditor.typeText("account_id_v2=12345; cookie_token_v2=abcdef")

        let saveButton = app.buttons["preferences.saveButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2))
        saveButton.click()

        XCTAssertTrue(app.staticTexts["Configuration Ready"].waitForExistence(timeout: 2))

        app.terminate()
        app.launch()

        XCTAssertTrue(app.staticTexts["Configuration Ready"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
