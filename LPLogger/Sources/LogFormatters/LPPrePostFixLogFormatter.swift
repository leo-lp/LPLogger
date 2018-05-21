//
//  LPPrePostFixLogFormatter.swift
//  LPLogger <https://github.com/leo-lp/LPLogger>
//
//  Created by pengli on 2018/4/11.
//  Copyright © 2018年 pengli. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#if os(macOS)
import AppKit
#elseif os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#endif

// MARK: - LPPrePostFixLogFormatter
/// A log formatter that will optionally add a prefix, and/or postfix string to a message
open class LPPrePostFixLogFormatter: LPLogFormatterProtocol {
    
    /// Internal cache of the prefix strings for each log level
    internal var prefixStrings: [LPLogger.Level: String] = [:]
    
    /// Internal cache of the postfix strings codes for each log level
    internal var postfixStrings: [LPLogger.Level: String] = [:]
    
    public init() { }
    
    /// Set the prefix/postfix strings for a specific log level.
    ///
    /// - Parameters:
    ///     - prefix:   A string to prepend to log messages.
    ///     - postfix:  A string to postpend to log messages.
    ///     - level:    The log level.
    open func apply(prefix: String? = nil, postfix: String? = nil, to level: LPLogger.Level? = nil) {
        guard let level = level else {
            guard prefix != nil || postfix != nil else { clearFormatting(); return }
            
            // No level specified, so, apply to all levels
            for level in LPLogger.Level.all {
                self.apply(prefix: prefix, postfix: postfix, to: level)
            }
            return
        }
        
        if let prefix = prefix {
            prefixStrings[level] = prefix
        }
        else {
            prefixStrings.removeValue(forKey: level)
        }
        
        if let postfix = postfix {
            postfixStrings[level] = postfix
        }
        else {
            postfixStrings.removeValue(forKey: level)
        }
    }
    
    /// Clear all previously set colours. (Sets each log level back to default)
    open func clearFormatting() {
        prefixStrings = [:]
        postfixStrings = [:]
    }
    
    // MARK: - LPLogFormatterProtocol
    /// Apply some additional formatting to the message if appropriate.
    ///
    /// - Parameters:
    ///     - logDetails:   The log details.
    ///     - message:      Formatted/processed message ready for output.
    ///
    /// - Returns:  message with the additional formatting
    @discardableResult
    open func format(logDetails: inout LPLogDetails, message: inout String) -> String {
        message = "\(prefixStrings[logDetails.level] ?? "")\(message)\(postfixStrings[logDetails.level] ?? "")"
        return message
    }
}
