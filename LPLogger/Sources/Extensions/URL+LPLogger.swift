//
//  URL+LPLogger.swift
//  LPLogger <https://github.com/leo-lp/LPLogger>
//
//  Created by pengli on 2018/5/14.
//  Copyright © 2018年 pengli. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

extension URL {
    
    /// Get extended attribute.
    func extendedAttribute(forName name: String) throws -> Data? {
        let data: Data? = try self.withUnsafeFileSystemRepresentation { (fileSystemPath: (UnsafePointer<Int8>?)) -> Data? in
            // Determine attribute size
            let length = getxattr(fileSystemPath, name, nil, 0, 0, 0)
            guard length >= 0 else { return nil }
            
            // Create buffer with required size
            var data = Data(count: length)
            
            // Retrieve attribute
            let result = data.withUnsafeMutableBytes {
                getxattr(fileSystemPath, name, $0, length, 0, 0)
            }
            guard result >= 0 else { throw URL.posixError(errno) }
            return data
        }
        
        return data
    }
    
    /// Set extended attribute.
    func setExtendedAttribute(data: Data, forName name: String) throws {
        try self.withUnsafeFileSystemRepresentation { fileSystemPath in
            let result = data.withUnsafeBytes {
                setxattr(fileSystemPath, name, $0, data.count, 0, 0)
            }
            guard result >= 0 else { throw URL.posixError(errno) }
        }
    }
    
    /// Remove extended attribute.
    func removeExtendedAttribute(forName name: String) throws {
        try self.withUnsafeFileSystemRepresentation { fileSystemPath in
            let result = removexattr(fileSystemPath, name, 0)
            guard result >= 0 else { throw URL.posixError(errno) }
        }
    }
    
    /// Get list of all extended attributes.
    func listExtendedAttributes() throws -> [String] {
        let list = try self.withUnsafeFileSystemRepresentation { (fileSystemPath: (UnsafePointer<Int8>?)) -> [String] in
            let length = listxattr(fileSystemPath, nil, 0, 0)
            guard length >= 0 else { throw URL.posixError(errno) }
            
            // Create buffer with required size
            var data = Data(count: length)
            
            // Retrieve attribute list
            let result = data.withUnsafeMutableBytes {
                listxattr(fileSystemPath, $0, length, 0)
            }
            guard result >= 0 else { throw URL.posixError(errno) }
            
            // Extract attribute names
            let list = data.split(separator: 0).compactMap {
                String(data: Data($0), encoding: .utf8)
            }
            return list
        }
        return list
    }
    
    /// Helper function to create an NSError from a Unix errno.
    private static func posixError(_ err: Int32) -> NSError {
        return NSError(domain: NSPOSIXErrorDomain, code: Int(err), userInfo: [NSLocalizedDescriptionKey: String(cString: strerror(err))])
    }
}
