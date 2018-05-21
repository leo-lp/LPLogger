//
//  LPDestinationProtocol.swift
//  LPLogger <https://github.com/leo-lp/LPLogger>
//
//  Created by pengli on 2018/4/11.
//  Copyright © 2018年 pengli. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

/// Protocol for destination classes to conform to
public protocol LPDestinationProtocol {
    // MARK: - Properties
    /// Logger that owns the destination object
    var owner: LPLogger? {get set}
    
    /// Identifier for the destination (should be unique)
    var identifier: String {get set}
    
    /// Log level for this destination
    var outputLevel: LPLogger.Level {get set}
    
    /// Flag whether or not we've logged the app details to this destination
    var haveLoggedAppDetails: Bool { get set }
    
    /// Array of log formatters to apply to messages before they're output
    var formatters: [LPLogFormatterProtocol]? { get set }
    
    // MARK: - Methods
    /// Process the log details.
    ///
    /// - Parameters:
    ///     - logDetails:   Structure with all of the details for the log to process.
    func process(logDetails: LPLogDetails)
    
    /// Process the log details (internal use, same as processLogDetails but omits function/file/line info).
    ///
    /// - Parameters:
    ///     - logDetails:   Structure with all of the details for the log to process.
    func processInternal(logDetails: LPLogDetails)
    
    /// Check if the destination's log level is equal to or lower than the specified level.
    ///
    /// - Parameters:
    ///     - level: The log level to check.
    ///
    /// - Returns:
    ///     - true:     Log destination is at the log level specified or lower.
    ///     - false:    Log destination is at a higher log level.
    func isEnabledFor(level: LPLogger.Level) -> Bool
    
    /// Apply formatters.
    ///
    /// - Parameters:
    ///     - logDetails:   The log details.
    ///     - message:      Formatted/processed message ready for output.
    func applyFormatters(logDetails: inout LPLogDetails, message: inout String)
}

extension LPDestinationProtocol {
    
    /// Iterate over all of the log formatters in this destination, or the logger if none set for the destination.
    ///
    /// - Parameters:
    ///     - logDetails:   The log details.
    ///     - message:      Formatted/processed message ready for output.
    public func applyFormatters(logDetails: inout LPLogDetails, message: inout String) {
        guard let formatters = self.formatters ?? self.owner?.formatters, formatters.count > 0 else { return }
        
        for formatter in formatters {
            formatter.format(logDetails: &logDetails, message: &message)
        }
    }
}
