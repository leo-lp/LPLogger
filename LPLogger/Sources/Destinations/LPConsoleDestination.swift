//
//  LPConsoleDestination.swift
//  LPLogger <https://github.com/leo-lp/LPLogger>
//
//  Created by pengli on 2018/4/11.
//  Copyright © 2018年 pengli. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// A standard destination that outputs log details to the console
open class LPConsoleDestination: LPBaseQueuedDestination {
    
    // MARK: - Overridden Methods
    
    /// Print the log to the console.
    ///
    /// - Parameters:
    ///     - message:   Formatted/processed message ready for output.
    open override func write(message: String) {
        print(message)
    }
}
