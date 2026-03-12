//
//  NotEnoughResinsUITests.swift
//  NotEnoughResinsUITests
//
//  Created by ph0ryn on 2026/03/12.
//

import XCTest

final class NotEnoughResinsUITests: XCTestCase {
    private func makeApp(
        scenario: String? = nil,
        keychainServiceSuffix: String = UUID().uuidString,
        userDefaultsSuiteSuffix: String = UUID().uuidString
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["NOT_ENOUGH_RESINS_UI_TEST_WINDOW"] = "1"
        app.launchEnvironment["NOT_ENOUGH_RESINS_DISABLE_REFRESH"] = "1"
        app.launchEnvironment["NOT_ENOUGH_RESINS_KEYCHAIN_SERVICE_SUFFIX"] = keychainServiceSuffix
        app.launchEnvironment["NOT_ENOUGH_RESINS_USER_DEFAULTS_SUFFIX"] = userDefaultsSuiteSuffix

        if let scenario {
            app.launchEnvironment["NOT_ENOUGH_RESINS_UI_TEST_SCENARIO"] = scenario
        }

        return app
    }

    private func assertMenuBarStatusLabel(
        in app: XCUIApplication,
        equals expectedLabel: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let statusLabel = element(in: app, id: "menuBar.statusLabel")
        XCTAssertTrue(statusLabel.waitForExistence(timeout: 2), file: file, line: line)
        XCTAssertEqual(statusLabel.label, expectedLabel, file: file, line: line)
    }

    private func element(in app: XCUIApplication, id: String) -> XCUIElement {
        app.windows["NotEnoughResins Debug"].descendants(matching: .any)[id]
    }

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        let app = XCUIApplication()
        if app.state != .notRunning {
            app.terminate()
        }

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        let app = XCUIApplication()
        if app.state != .notRunning {
            app.terminate()
        }
    }

    @MainActor
    func testExample() throws {
        let app = makeApp(scenario: "needsConfiguration")
        app.launch()

        assertMenuBarStatusLabel(in: app, equals: "Set Up")
        XCTAssertTrue(app.staticTexts["Configuration Needed"].waitForExistence(timeout: 2))
        XCTAssertTrue(element(in: app, id: "content.openPreferences").exists)
        XCTAssertTrue(element(in: app, id: "content.quit").exists)
    }

    @MainActor
    func testPreferencesSavePersistsAcrossRelaunch() throws {
        let isolationSuffix = UUID().uuidString
        let app = makeApp(
            keychainServiceSuffix: isolationSuffix,
            userDefaultsSuiteSuffix: isolationSuffix
        )

        app.launch()

        XCTAssertTrue(app.staticTexts["Configuration Needed"].waitForExistence(timeout: 2))

        app.typeKey(",", modifierFlags: .command)

        let cookieEditor = app.textViews["preferences.cookieEditor"]
        XCTAssertTrue(cookieEditor.waitForExistence(timeout: 2))

        cookieEditor.click()
        cookieEditor.typeText("account_id_v2=12345; cookie_token_v2=abcdef")

        let saveButton = app.buttons["preferences.saveButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2))
        saveButton.click()

        app.terminate()
        app.launch()

        XCTAssertTrue(app.staticTexts["Configuration Ready"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testNormalScenarioShowsMenuBarAndPanelSummary() throws {
        let app = makeApp(scenario: "normal")
        app.launch()

        assertMenuBarStatusLabel(in: app, equals: "160 / 200")
        XCTAssertTrue(app.staticTexts["Daily Note Ready"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testOverflowScenarioShowsWasteStatus() throws {
        let app = makeApp(scenario: "overflow")
        app.launch()

        assertMenuBarStatusLabel(in: app, equals: "Waste 7")
        XCTAssertTrue(app.staticTexts["Overflow Detected"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testAuthErrorScenarioShowsNonNormalStatus() throws {
        let app = makeApp(scenario: "authError")
        app.launch()

        assertMenuBarStatusLabel(in: app, equals: "Auth")
        XCTAssertTrue(app.staticTexts["Authentication Failed"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testRequestErrorScenarioShowsNonNormalStatus() throws {
        let app = makeApp(scenario: "requestError")
        app.launch()

        assertMenuBarStatusLabel(in: app, equals: "Stale")
        XCTAssertTrue(app.staticTexts["Request Failed"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            makeApp().launch()
        }
    }
}
