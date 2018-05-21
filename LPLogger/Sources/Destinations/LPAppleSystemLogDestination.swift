//
//  LPAppleSystemLogDestination.swift
//  LPLogger <https://github.com/leo-lp/LPLogger>
//
//  Created by pengli on 2018/4/11.
//  Copyright © 2018年 pengli. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// A standard destination that outputs log details to the Apple System Log using NSLog instead of print
open class LPAppleSystemLogDestination: LPBaseQueuedDestination {
    
    // MARK: - Properties
   
    /// Option: whether or not to output the date the log was created (Always false for this destination)
    open override var showDate: Bool {
        get {
            return false
        }
        set {
            // ignored, NSLog adds the date, so we always want showDate to be false in this subclass
        }
    }
    
    // MARK: - Overridden Methods
    
    /// Print the log to the Apple System Log facility (using NSLog).
    ///
    /// - Parameters:
    ///     - message:   Formatted/processed message ready for output.
    open override func write(message: String) {
        NSLog("%@", message)
    }
}
