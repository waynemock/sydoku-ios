//
//  SydokuUITests.swift
//  SydokuUITests
//
//  Created by Wayne Mock on 12/14/25.
//

import XCTest

/// UI tests for the Sydoku application.
///
/// This test class contains UI-level tests that interact with the app's
/// user interface to verify functionality and performance.
final class SydokuUITests: XCTestCase {

    /// Sets up the test environment before each test method runs.
    ///
    /// Configures test settings such as failure handling and initial app state.
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    /// Tears down the test environment after each test method completes.
    ///
    /// Performs cleanup operations after test execution.
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    /// A basic example UI test that launches the application.
    ///
    /// This test serves as a template for creating more specific UI tests.
    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    /// Measures the application's launch performance.
    ///
    /// This test tracks how long it takes for the app to launch, which is
    /// useful for monitoring performance regressions over time.
    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
