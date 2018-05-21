//
//  LPBaseDestination.swift
//  LPLogger <https://github.com/leo-lp/LPLogger>
//
//  Created by pengli on 2018/4/11.
//  Copyright © 2018年 pengli. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// A base class destination that doesn't actually output the log anywhere and is intended to be subclassed
open class LPBaseDestination: LPDestinationProtocol {
    
    // MARK: - Properties
    
    /// Logger that owns the destination object
    open var owner: LPLogger?
    
    /// Identifier for the destination (should be unique)
    open var identifier: String
    
    /// Log level for this destination
    open var outputLevel: LPLogger.Level = .debug
    
    /// Flag whether or not we've logged the app details to this destination
    open var haveLoggedAppDetails: Bool = false
    
    /// Array of log formatters to apply to messages before they're output
    open var formatters: [LPLogFormatterProtocol]? = nil
    
    /// Option: whether or not to output the function name that generated the log
    open var showFunctionName: Bool = true
    
    /// Option: whether or not to output the thread's name the log was created on
    open var showThreadName: Bool = false
    
    /// Option: whether or not to output the fileName that generated the log
    open var showFileName: Bool = true
    
    /// Option: whether or not to output the line number where the log was generated
    open var showLineNumber: Bool = true
    
    /// Option: whether or not to output the log level of the log
    open var showLevel: Bool = true
    
    /// Option: whether or not to output the date the log was created
    open var showDate: Bool = true
    
    // MARK: - Life Cycle
    public init(owner: LPLogger? = nil, identifier: String = "") {
        self.owner = owner
        self.identifier = identifier
    }
    
    // MARK: - Methods to Process Log Details
    
    /// Process the log details.
    ///
    /// - Parameters:
    ///     - logDetails:   Structure with all of the details for the log to process.
    open func process(logDetails: LPLogDetails) {
        guard let owner = owner else { return }
        
        var extendedDetails: String = ""
        
        if showDate {
            extendedDetails += "\(owner.dateFormatter.string(from: logDetails.date)) "
        }
        
        if showLevel {
            extendedDetails += "[\(logDetails.level.description)] "
        }
        
        if showThreadName {
            if Thread.isMainThread {
                extendedDetails += "[main] "
            }
            else {
                if let threadName = Thread.current.name, !threadName.isEmpty {
                    extendedDetails += "[\(threadName)] "
                }
                else if let queueName = DispatchQueue.currentQueueLabel, !queueName.isEmpty {
                    extendedDetails += "[\(queueName)] "
                }
                else {
                    extendedDetails += String(format: "[%p] ", Thread.current)
                }
            }
        }
        
        if showFileName {
            extendedDetails += "[\((logDetails.fileName as NSString).lastPathComponent)\((showLineNumber ? ":" + String(logDetails.lineNumber) : ""))] "
        }
        else if showLineNumber {
            extendedDetails += "[\(logDetails.lineNumber)] "
        }
        
        if showFunctionName {
            extendedDetails += "\(logDetails.functionName) "
        }
        
        output(logDetails: logDetails, message: "\(extendedDetails)> \(logDetails.message)")
    }
    
    /// Process the log details (internal use, same as process(logDetails:) but omits function/file/line info).
    ///
    /// - Parameters:
    ///     - logDetails:   Structure with all of the details for the log to process.
    open func processInternal(logDetails: LPLogDetails) {
        guard let owner = owner else { return }
        
        var extendedDetails: String = ""
        
        if showDate {
            extendedDetails += "\(owner.dateFormatter.string(from: logDetails.date)) "
        }
        
        if showLevel {
            extendedDetails += "[\(logDetails.level)] "
        }
        
        output(logDetails: logDetails, message: "\(extendedDetails)> \(logDetails.message)")
    }
    
    // MARK: - Misc methods
    
    /// Check if the destination's log level is equal to or lower than the specified level.
    ///
    /// - Parameters:
    ///     - level: The log level to check.
    ///
    /// - Returns:
    ///     - true:     Log destination is at the log level specified or lower.
    ///     - false:    Log destination is at a higher log level.
    open func isEnabledFor(level: LPLogger.Level) -> Bool {
        return level >= self.outputLevel
    }
    
    // MARK: - Methods that must be overridden in subclasses
    
    /// Output the log to the destination.
    ///
    /// - Parameters:
    ///     - logDetails:   The log details.
    ///     - message:   Formatted/processed message ready for output.
    open func output(logDetails: LPLogDetails, message: String) {
        // Do something with the text in an overridden version of this method
        precondition(false, "Must override this")
    }
}
