//
//  Logger.swift
//  SyWord
//
//  Created by Wayne Mock on 1/25/19.
//  Copyright © 2020 Syzygy Softwerks LLC. All rights reserved.
//

import Foundation

//------------------------------------------------------------------------------
/// Outputs a debug log message.
func LogDebug(_ object: Any, _ logMessage: String, functionName: String = #function) {
	Logger.shared.debug(object, logMessage, functionName: functionName)
}

//------------------------------------------------------------------------------
/// Outputs an error log message.
func LogError(_ object: Any, _ logMessage: String, functionName: String = #function) {
	Logger.shared.error(object, logMessage, functionName: functionName)
}

//------------------------------------------------------------------------------
/// Outputs an info log message.
func LogInfo(_ object: Any, _ logMessage: String, functionName: String = #function) {
	Logger.shared.info(object, logMessage, functionName: functionName)
}

//------------------------------------------------------------------------------
/// Outputs a verbose log message.
func LogVerbose(_ object: Any, _ logMessage: String, functionName: String = #function) {
	Logger.shared.verbose(object, logMessage, functionName: functionName)
}

//------------------------------------------------------------------------------

class Logger {

	static let shared = Logger()
	static private var formatter: DateFormatter?

	//--------------------------------------------------------------------------

	private init() {
	}

	//--------------------------------------------------------------------------

	func debug(_ object: Any, _ logMessage: String, functionName: String = #function) {
		out("[DEBUG] \(type(of: object)).\(functionName): \(logMessage)")
	}

	//--------------------------------------------------------------------------

	func error(_ object: Any, _ logMessage: String, functionName: String = #function) {
		out("[ERROR] \(type(of: object)).\(functionName): \(logMessage)")
	}

	//--------------------------------------------------------------------------

	func info(_ object: Any, _ logMessage: String, functionName: String = #function) {
		out("[INFO] \(type(of: object)).\(functionName): \(logMessage)")
	}

	//--------------------------------------------------------------------------

	func verbose(_ object: Any, _ logMessage: String, functionName: String = #function) {
		out("[VERBOSE] \(type(of: object)).\(functionName): \(logMessage)")
	}

	//--------------------------------------------------------------------------

	private func out(_ msg: String) {
		print("\(timestamp()) [SyWords] \(msg)")
	}

	//--------------------------------------------------------------------------

	private func timestamp() -> String {
		if Logger.formatter == nil {
			Logger.formatter = DateFormatter()
			Logger.formatter?.dateFormat = "yyyy-MM-dd' 'HH:mm:ss.SSS"
		}

		return Logger.formatter!.string(from: Date())
	}
}
