//
//  LPBaseQueuedDestination.swift
//  LPLogger <https://github.com/leo-lp/LPLogger>
//
//  Created by pengli on 2018/4/11.
//  Copyright © 2018年 pengli. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import Dispatch

/// A base class destination (with a possible DispatchQueue) that doesn't actually output the log anywhere and is intended to be subclassed
open class LPBaseQueuedDestination: LPBaseDestination {
    // MARK: - Properties
    /// The dispatch queue to process the log on
    open var logQueue: DispatchQueue? = nil
    
    // MARK: - Life Cycle
    
    // MARK: - Overridden Methods
    /// Apply filters and formatters to the message before queuing it to be written by the write method.
    ///
    /// - Parameters:
    ///     - logDetails:   The log details.
    ///     - message:      Message ready to be formatted for output.
    open override func output(logDetails: LPLogDetails, message: String) {
        let outputClosure = {
            // Create mutable versions of our parameters
            var logDetails = logDetails
            var message = message
            
            self.applyFormatters(logDetails: &logDetails, message: &message)
            self.write(message: message)
        }
        
        if let logQueue = logQueue {
            logQueue.async(execute: outputClosure)
        }
        else {
            outputClosure()
        }
    }
    
    // MARK: - Methods that must be overridden in subclasses
    /// Write the log message to the destination.
    ///
    /// - Parameters:
    ///     - message:   Formatted/processed message ready for output.
    open func write(message: String) {
        // Do something with the message in an overridden version of this method
        precondition(false, "Must override this")
    }
}
