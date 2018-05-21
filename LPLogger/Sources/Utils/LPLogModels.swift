//
//  LPLogModels.swift
//  LPLogger <https://github.com/leo-lp/LPLogger>
//
//  Created by pengli on 2018/4/11.
//  Copyright © 2018年 pengli. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

// MARK: -
// MARK: - LPLogDetails

/// Data structure to hold all info about a log message, passed to destination classes
public struct LPLogDetails {
    
    /// Log level required to display this log
    public var level: LPLogger.Level
    
    /// Date this log was sent
    public var date: Date
    
    /// The log message to display
    public var message: String
    
    /// Name of the function that generated this log
    public var functionName: String
    
    /// Name of the file the function exists in
    public var fileName: String
    
    /// The line number that generated this log
    public var lineNumber: Int
    
    public init(level: LPLogger.Level,
                date: Date,
                message: String,
                functionName: String,
                fileName: String,
                lineNumber: Int) {
        self.level = level
        self.date = date
        self.message = message
        self.functionName = functionName
        self.fileName = fileName
        self.lineNumber = lineNumber
    }
}

// MARK: -
// MARK: - Data Struct / Enum

extension LPLogger {
    
    // MARK: - Constants
    public struct Constants {
        /// Prefix identifier to use for all other identifiers
        public static let baseIdentifier = "com.cerebralgardens.LPLogger"
        
        /// Identifer for the Xcode console destination
        public static let baseConsoleDestinationIdentifier = "\(baseIdentifier).logdestination.console"
        
        /// Identifier for the Apple System Log destination
        public static let systemLogDestinationIdentifier = "\(baseIdentifier).logdestination.console.nslog"
        
        /// Identifier for the file logging destination
        public static let fileDestinationIdentifier = "\(baseIdentifier).logdestination.file"
        
        /// Identifier for the default dispatch queue
        public static let logQueueIdentifier = "\(baseIdentifier).queue"
        
        /// Library version number
        public static let versionString = "6.0.2"
        
        /// Extended file attributed key to use when storing the logger's identifier on an archived log file
        public static let extendedAttributeArchivedLogIdentifierKey = "\(baseIdentifier).archived.by"
        
        /// Extended file attributed key to use when storing the time a log file was archived
        public static let extendedAttributeArchivedLogTimestampKey = "\(baseIdentifier).archived.at"
    }
    
    // MARK: - Enums
    /// Enum defining our log levels
    public enum Level: Int, Comparable, CustomStringConvertible {
        case verbose
        case debug
        case info
        case warning
        case error
        case severe
        case none
        
        public var description: String {
            switch self {
            case .verbose:
                return "Verbose"
            case .debug:
                return "Debug"
            case .info:
                return "Info"
            case .warning:
                return "Warning"
            case .error:
                return "Error"
            case .severe:
                return "Severe"
            case .none:
                return "None"
            }
        }
        
        public static let all: [Level] = [.verbose, .debug, .info, .warning, .error, .severe]
    }
}
