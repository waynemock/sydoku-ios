//
//  SydokuUITestsLaunchTests.swift
//  SydokuUITests
//
//  Created by Wayne Mock on 12/14/25.
//

import XCTest

/// UI tests for verifying the app's launch behavior across different configurations.
///
/// This test class captures screenshots and verifies the app launches successfully
/// in various UI configurations (e.g., light/dark mode, different screen sizes).
final class SydokuUITestsLaunchTests: XCTestCase {

    /// Indicates that these tests should run for each UI configuration.
    ///
    /// When `true`, the test runs multiple times with different UI settings
    /// to ensure the app launches correctly in all supported configurations.
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    /// Sets up the test environment before each test method runs.
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Tests the app launch and captures a screenshot.
    ///
    /// This test launches the app, takes a screenshot of the launch screen,
    /// and attaches it to the test results for visual verification.
    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
