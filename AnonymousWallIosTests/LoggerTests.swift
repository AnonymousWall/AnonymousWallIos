//
//  LoggerTests.swift
//  AnonymousWallIosTests
//
//  Tests for centralized logging infrastructure
//

import Testing
@testable import AnonymousWallIos

struct LoggerTests {
    
    @Test func testLoggerCanBeInitializedWithDefaultParameters() {
        // Test that logger can be created with default subsystem and category
        let logger = Logger()
        
        // Logger should be created successfully (no crash)
        #expect(logger != nil)
    }
    
    @Test func testLoggerCanBeInitializedWithCustomCategory() {
        // Test that logger can be created with custom category
        let logger = Logger(category: "CustomCategory")
        
        // Logger should be created successfully (no crash)
        #expect(logger != nil)
    }
    
    @Test func testLoggerCanBeInitializedWithCustomSubsystemAndCategory() {
        // Test that logger can be created with custom subsystem and category
        let logger = Logger(subsystem: "com.test.app", category: "TestCategory")
        
        // Logger should be created successfully (no crash)
        #expect(logger != nil)
    }
    
    @Test func testLoggerDebugMethodDoesNotCrash() {
        // Test that debug logging works without crashing
        let logger = Logger(category: "Test")
        
        // This should not crash
        logger.debug("Test debug message")
    }
    
    @Test func testLoggerInfoMethodDoesNotCrash() {
        // Test that info logging works without crashing
        let logger = Logger(category: "Test")
        
        // This should not crash
        logger.info("Test info message")
    }
    
    @Test func testLoggerWarningMethodDoesNotCrash() {
        // Test that warning logging works without crashing
        let logger = Logger(category: "Test")
        
        // This should not crash
        logger.warning("Test warning message")
    }
    
    @Test func testLoggerErrorMethodDoesNotCrash() {
        // Test that error logging works without crashing
        let logger = Logger(category: "Test")
        
        // This should not crash
        logger.error("Test error message")
    }
    
    @Test func testLogLevelDebugHasCorrectRawValue() {
        // Test that debug level has correct emoji and text
        let level = LogLevel.debug
        #expect(level.rawValue == "🔍 DEBUG")
    }
    
    @Test func testLogLevelInfoHasCorrectRawValue() {
        // Test that info level has correct emoji and text
        let level = LogLevel.info
        #expect(level.rawValue == "ℹ️ INFO")
    }
    
    @Test func testLogLevelWarningHasCorrectRawValue() {
        // Test that warning level has correct emoji and text
        let level = LogLevel.warning
        #expect(level.rawValue == "⚠️ WARNING")
    }
    
    @Test func testLogLevelErrorHasCorrectRawValue() {
        // Test that error level has correct emoji and text
        let level = LogLevel.error
        #expect(level.rawValue == "❌ ERROR")
    }
    
    @Test func testConvenienceNetworkLoggerExists() {
        // Test that convenience logger for networking is available
        let logger = Logger.network
        
        // Logger should be accessible
        #expect(logger != nil)
        
        // Should not crash when used
        logger.info("Network test message")
    }
    
    @Test func testConvenienceAuthLoggerExists() {
        // Test that convenience logger for authentication is available
        let logger = Logger.auth
        
        // Logger should be accessible
        #expect(logger != nil)
        
        // Should not crash when used
        logger.info("Auth test message")
    }
    
    @Test func testConvenienceUILoggerExists() {
        // Test that convenience logger for UI is available
        let logger = Logger.ui
        
        // Logger should be accessible
        #expect(logger != nil)
        
        // Should not crash when used
        logger.info("UI test message")
    }
    
    @Test func testConvenienceGeneralLoggerExists() {
        // Test that convenience logger for general operations is available
        let logger = Logger.general
        
        // Logger should be accessible
        #expect(logger != nil)
        
        // Should not crash when used
        logger.info("General test message")
    }
    
    @Test func testConvenienceDataLoggerExists() {
        // Test that convenience logger for data operations is available
        let logger = Logger.data
        
        // Logger should be accessible
        #expect(logger != nil)
        
        // Should not crash when used
        logger.info("Data test message")
    }
    
    @Test func testLoggerHandlesEmptyMessages() {
        // Test that logger can handle empty messages
        let logger = Logger(category: "Test")
        
        // Should not crash with empty messages
        logger.debug("")
        logger.info("")
        logger.warning("")
        logger.error("")
    }
    
    @Test func testLoggerHandlesLongMessages() {
        // Test that logger can handle very long messages
        let logger = Logger(category: "Test")
        let longMessage = String(repeating: "A", count: 1000)
        
        // Should not crash with long messages
        logger.debug(longMessage)
        logger.info(longMessage)
        logger.warning(longMessage)
        logger.error(longMessage)
    }
    
    @Test func testLoggerHandlesSpecialCharacters() {
        // Test that logger can handle messages with special characters
        let logger = Logger(category: "Test")
        let specialMessage = "Test with emoji 😀, unicode 你好, and symbols @#$%^&*()"
        
        // Should not crash with special characters
        logger.debug(specialMessage)
        logger.info(specialMessage)
        logger.warning(specialMessage)
        logger.error(specialMessage)
    }
    
    @Test func testMultipleLoggersCanCoexist() {
        // Test that multiple logger instances can be created and used together
        let logger1 = Logger(category: "Category1")
        let logger2 = Logger(category: "Category2")
        let logger3 = Logger(category: "Category3")
        
        // All should work without interfering with each other
        logger1.info("Message from logger 1")
        logger2.warning("Message from logger 2")
        logger3.error("Message from logger 3")
    }
    
    @Test func testLoggerWorksWithDifferentLogLevelsInSequence() {
        // Test that all log levels can be used in sequence
        let logger = Logger(category: "Test")
        
        logger.debug("Debug message")
        logger.info("Info message")
        logger.warning("Warning message")
        logger.error("Error message")
        logger.debug("Another debug message")
    }
}
