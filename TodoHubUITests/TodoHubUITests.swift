//
//  TodoHubUITests.swift
//  TodoHubUITests
//
//  Copyright (c) 2025 Martin Woodward
//  Licensed under MIT License
//

import XCTest

final class TodoHubUITests: XCTestCase {
    
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    func testLoginScreenAppears() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Verify login screen elements
        XCTAssertTrue(app.staticTexts["TodoHub"].exists)
        XCTAssertTrue(app.buttons["Sign in with GitHub"].exists)
    }
}
