//
//  Logger.swift
//  Sydoku
//
//  Created by Wayne Mock on 1/25/19.
//  Copyright © 2020 Syzygy Softwerks LLC. All rights reserved.
//

import Foundation
import os.log

/// Thread-safe logger that uses Swift's unified logging system.
///
/// Usage:
/// ```swift
/// private let logger = AppLogger(category: "MyClass")
///
/// logger.debug(self, "Debug message")
/// logger.info(self, "Info message")
/// logger.error(self, "Error message")
/// ```
struct AppLogger: Sendable {
	private let logger: Logger
	
	/// Creates a new logger instance.
	///
	/// - Parameters:
	///   - subsystem: The subsystem identifier (defaults to app bundle ID)
	///   - category: A category for organizing logs (typically the class/file name)
	init(subsystem: String = "com.syzygy.sydoku", category: String) {
		self.logger = Logger(subsystem: subsystem, category: category)
	}
	
	/// Logs a debug message.
	func debug(_ object: Any, _ message: String, functionName: String = #function) {
		let typeName = String(describing: type(of: object))
		logger.debug("\(typeName).\(functionName): \(message)")
	}
	
	/// Logs an info message.
	func info(_ object: Any, _ message: String, functionName: String = #function) {
		let typeName = String(describing: type(of: object))
		logger.info("\(typeName).\(functionName): \(message)")
	}
	
	/// Logs a warning message.
	func warning(_ object: Any, _ message: String, functionName: String = #function) {
		let typeName = String(describing: type(of: object))
		logger.warning("\(typeName).\(functionName): \(message)")
	}
	
	/// Logs an error message.
	func error(_ object: Any, _ message: String, functionName: String = #function) {
		let typeName = String(describing: type(of: object))
		logger.error("\(typeName).\(functionName): \(message)")
	}
	
	/// Logs a verbose/trace message.
	func verbose(_ object: Any, _ message: String, functionName: String = #function) {
		let typeName = String(describing: type(of: object))
		logger.debug("\(typeName).\(functionName): \(message)")
	}
}
