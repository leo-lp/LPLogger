//
//  LPLogFormatterProtocol.swift
//  LPLogger <https://github.com/leo-lp/LPLogger>
//
//  Created by pengli on 2018/4/11.
//  Copyright © 2018年 pengli. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

/// Protocol for log formatter classes to conform to
public protocol LPLogFormatterProtocol {
    
    /// Apply some additional formatting to the message if appropriate.
    ///
    /// - Parameters:
    ///     - logDetails:   The log details.
    ///     - message:      Formatted/processed message ready for output.
    @discardableResult
    func format(logDetails: inout LPLogDetails, message: inout String) -> String
}

