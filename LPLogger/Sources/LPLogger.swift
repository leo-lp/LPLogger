//
//  LPLogger.swift
//  LPLogger <https://github.com/leo-lp/LPLogger>
//
//  Created by pengli on 2018/4/11.
//  Copyright © 2018年 pengli. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#if os(macOS)
import AppKit
#elseif os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#endif

// MARK: - LPLogger

/// The main logging class
open class LPLogger {
    /// The default LPLogger object
    open static var shared: LPLogger = { return LPLogger() }()
    
    // MARK: - Properties
    
    /// The log level of this logger, any logs received at this level or higher will be output to the destinations
    open var outputLevel: Level = .debug {
        didSet {
            for index in 0 ..< destinations.count {
                destinations[index].outputLevel = outputLevel
            }
        }
    }
    
    /// Array of log formatters to apply to messages before they're output
    open var formatters: [LPLogFormatterProtocol]? = nil
    
    /// The default dispatch queue used for logging
    open class var logQueue: DispatchQueue {
        return DispatchQueue(label: LPLogger.Constants.logQueueIdentifier, attributes: [])
    }
    
    /// The date formatter object to use when displaying the dates of log messages
    open lazy var dateFormatter: DateFormatter = {
        let defaultDateFormatter = DateFormatter()
        defaultDateFormatter.locale = Locale(identifier: "en")
        defaultDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss" //.SSS
        return defaultDateFormatter
    }()
    
    /// Array containing all of the destinations for this logger
    open var destinations: [LPDestinationProtocol] = []
    
    // MARK: - Log destination methods
    /// Get the destination with the specified identifier.
    ///
    /// - Parameters:
    ///     - identifier:   Identifier of the destination to return.
    ///
    /// - Returns:  The destination with the specified identifier, if one exists, nil otherwise.
    open func destination(withIdentifier identifier: String) -> LPDestinationProtocol? {
        for destination in destinations {
            if destination.identifier == identifier {
                return destination
            }
        }
        return nil
    }
    
    /// Add a new destination to the logger.
    ///
    /// - Parameters:
    ///     - destination:   The destination to add.
    ///
    /// - Returns:
    ///     - true:     Log destination was added successfully.
    ///     - false:    Failed to add the destination.
    @discardableResult open func add(destination: LPDestinationProtocol) -> Bool {
        var destination = destination
        
        let existingDestination: LPDestinationProtocol? = self.destination(withIdentifier: destination.identifier)
        if existingDestination != nil {
            return false
        }
        
        if let previousOwner = destination.owner {
            previousOwner.remove(destination: destination)
        }
        
        destination.owner = self
        destinations.append(destination)
        return true
    }
    
    /// Remove the destination from the logger.
    ///
    /// - Parameters:
    ///     - destination:   The destination to remove.
    ///
    /// - Returns:
    ///     - true:     Log destination was removed successfully.
    ///     - false:    Failed to remove the destination.
    @discardableResult open func remove(destination: LPDestinationProtocol) -> Bool {
        guard destination.owner === self else { return false }
        
        let existingDestination: LPDestinationProtocol? = self.destination(withIdentifier: destination.identifier)
        guard existingDestination != nil else { return false }
        
        // Make our parameter mutable
        var destination = destination
        destination.owner = nil
        
        destinations = destinations.filter({$0.owner != nil})
        return true
    }
    
    /// Remove the destination with the specified identifier from the logger.
    ///
    /// - Parameters:
    ///     - identifier:   The identifier of the destination to remove.
    ///
    /// - Returns:
    ///     - true:     Log destination was removed successfully.
    ///     - false:    Failed to remove the destination.
    @discardableResult open func remove(destinationWithIdentifier identifier: String) -> Bool {
        guard let destination = destination(withIdentifier: identifier) else { return false }
        return remove(destination: destination)
    }
    
    // MARK: - Misc methods
    /// Check if the logger's log level is equal to or lower than the specified level.
    ///
    /// - Parameters:
    ///     - level: The log level to check.
    ///
    /// - Returns:
    ///     - true:     Logger is at the log level specified or lower.
    ///     - false:    Logger is at a higher log levelss.
    open func isEnabledFor(level: LPLogger.Level) -> Bool {
        return level >= self.outputLevel
    }
    
    // MARK: - Private methods
    
    /// Log a message if the logger's log level is equal to or lower than the specified level.
    ///
    /// - Parameters:
    ///     - message:   Message to log.
    ///     - level:     Specified log level.
    ///     - source:    The destination calling this method
    internal func _logln(_ message: String, level: Level = .debug, source sourceDestination: LPDestinationProtocol? = nil) {
        let logDetails: LPLogDetails = LPLogDetails(level: level, date: Date(), message: message, functionName: "", fileName: "", lineNumber: 0)
        for destination in self.destinations {
            if level >= .error && sourceDestination?.identifier == destination.identifier { continue }
            if (destination.isEnabledFor(level: level)) {
                destination.processInternal(logDetails: logDetails)
            }
        }
    }
}

// Implement Comparable for LPLogger.Level
public func < (lhs: LPLogger.Level, rhs: LPLogger.Level) -> Bool {
    return lhs.rawValue < rhs.rawValue
}

// MARK: -
// MARK: - output

extension LPLogger {
    /// Log something at the Verbose log level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    open func verbose(_ message: Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(.verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber, message: message)
    }
    
    /// Log something at the Debug log level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    open func debug(_ message: Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(.debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, message: message)
    }
    
    /// Log something at the Info log level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    open func info(_ message: Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(.info, functionName: functionName, fileName: fileName, lineNumber: lineNumber, message: message)
    }
    
    /// Log something at the Warning log level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    open func warning(_ message: Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(.warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber, message: message)
    }
    
    /// Log something at the Error log level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    open func error(_ message: Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(.error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, message: message)
    }
    
    /// Log something at the Severe log level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    open func severe(_ message: Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(.severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber, message: message)
    }
    
    /// Log a message if the logger's log level is equal to or lower than the specified level.
    ///
    /// - Parameters:
    ///     - level:        Specified log level **Default:** *Debug*.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - closure:      A closure that returns the object to be logged.
    open func logln(_ level: Level = .debug, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, message: Any?) {
        logln(level, functionName: String(describing: functionName), fileName: String(describing: fileName), lineNumber: lineNumber, message: message)
    }
    
    /// Log a message if the logger's log level is equal to or lower than the specified level.
    ///
    /// - Parameters:
    ///     - level:        Specified log level **Default:** *Debug*.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - closure:      A closure that returns the object to be logged.
    open func logln(_ level: Level = .debug, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line, message: Any?) {
        let enabledDestinations = destinations.filter { $0.isEnabledFor(level: level) }
        guard enabledDestinations.count > 0 else { return }
        let logDetails = LPLogDetails(level: level, date: Date(), message: String(describing: message ?? ""), functionName: functionName, fileName: fileName, lineNumber: lineNumber)
        for destination in enabledDestinations {
            destination.process(logDetails: logDetails)
        }
    }
    
    /// Generate logs to display your app's vitals (app name, version, etc) as well as LPLogger's version and log level.
    ///
    /// - Parameters:
    ///     - selectedDestination:     A specific destination to log the vitals on, if omitted, will log to all destinations
    open func logAppDetails(selectedDestination: LPDestinationProtocol? = nil) {
        let date = Date()

        var buildString = ""
        if let infoDict = Bundle.main.infoDictionary {
            if let shortVersion = infoDict["CFBundleShortVersionString"] as? String {
                buildString = "Version: \(shortVersion) "
            }
            if let version = infoDict["CFBundleVersion"] as? String {
                buildString += "Build: \(version) "
            }
        }

        let processInfo = ProcessInfo.processInfo
        let LPLoggerVersionNumber = LPLogger.Constants.versionString

        var logDetails: [LPLogDetails] = []
        logDetails.append(LPLogDetails(level: .info, date: date, message: "\(processInfo.processName) \(buildString)PID: \(processInfo.processIdentifier)", functionName: "", fileName: "", lineNumber: 0))
        logDetails.append(LPLogDetails(level: .info, date: date, message: "LPLogger Version: \(LPLoggerVersionNumber) - Level: \(outputLevel)", functionName: "", fileName: "", lineNumber: 0))
        
        for var destination in (selectedDestination != nil ? [selectedDestination!] : destinations) where !destination.haveLoggedAppDetails {
            for logDetail in logDetails {
                guard destination.isEnabledFor(level:.info) else { continue }

                destination.haveLoggedAppDetails = true
                destination.processInternal(logDetails: logDetail)
            }
        }
    }
}
