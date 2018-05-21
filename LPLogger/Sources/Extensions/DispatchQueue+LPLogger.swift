//
//  DispatchQueue+LPLogger.swift
//  LPLogger <https://github.com/leo-lp/LPLogger>
//
//  Created by pengli on 2018/4/11.
//  Copyright © 2018年 pengli. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import Dispatch

/// Extensions to the DispatchQueue class
extension DispatchQueue {
    
    /// Extract the current dispatch queue's label name
    public static var currentQueueLabel: String? {
        return String(validatingUTF8: __dispatch_queue_get_label(nil))
    }
}

