//
//  LPFileDestination.swift
//  LPLogger <https://github.com/leo-lp/LPLogger>
//
//  Created by pengli on 2018/5/14.
//  Copyright © 2018年 pengli. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
import Dispatch

// MARK: - FileDestination
/// A standard destination that outputs log details to a file
open class LPFileDestination: LPBaseQueuedDestination {
    // MARK: - Properties
    /// Logger that owns the destination object
    open override var owner: LPLogger? {
        didSet {
            if owner != nil {
                openFile()
            }
            else {
                closeFile()
            }
        }
    }
    
    /// FileURL of the file to log to
    open var writeToFileURL: URL? = nil {
        didSet {
            openFile()
        }
    }
    
    /// File handle for the log file
    internal var logFileHandle: FileHandle? = nil
    
    /// Option: whether or not to append to the log file if it already exists
    internal var shouldAppend: Bool
    
    /// Option: if appending to the log file, the string to output at the start to mark where the append took place
    internal var appendMarker: String?
    
    /// Option: Attributes to use when creating a new file
    internal var fileAttributes: [FileAttributeKey: Any]? = nil
    
    // MARK: - Life Cycle
    public init(owner: LPLogger? = nil, writeToFile: Any, identifier: String = "", shouldAppend: Bool = false, appendMarker: String? = "-- ** ** ** --", attributes: [FileAttributeKey: Any]? = nil) {
        self.shouldAppend = shouldAppend
        self.appendMarker = appendMarker
        self.fileAttributes = attributes
        
        if writeToFile is NSString {
            writeToFileURL = URL(fileURLWithPath: writeToFile as! String)
        }
        else if let writeToFile = writeToFile as? URL, writeToFile.isFileURL {
            writeToFileURL = writeToFile
        }
        else {
            writeToFileURL = nil
        }
        
        super.init(owner: owner, identifier: identifier)
        
        if owner != nil {
            openFile()
        }
    }
    
    deinit {
        // close file stream if open
        closeFile()
    }
    
    // MARK: - File Handling Methods
    /// Open the log file for writing.
    private func openFile() {
        guard let owner = owner else { return }
        
        if logFileHandle != nil {
            closeFile()
        }
        
        guard let writeToFileURL = writeToFileURL else { return }
        
        let fileManager: FileManager = FileManager.default
        let fileExists: Bool = fileManager.fileExists(atPath: writeToFileURL.path)
        
        do {
            var basePath = writeToFileURL.path
            let lastPath = writeToFileURL.lastPathComponent
            if let range = basePath.range(of: lastPath, options: .backwards) {
                basePath.removeSubrange(range)
                
                if !fileManager.fileExists(atPath: basePath) {
                    try fileManager.createDirectory(atPath: basePath,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
                }
            }
            
            if !shouldAppend || !fileExists {
                fileManager.createFile(atPath: writeToFileURL.path, contents: nil, attributes: fileAttributes)
            }
            
            logFileHandle = try FileHandle(forWritingTo: writeToFileURL)
            if fileExists && shouldAppend {
                logFileHandle?.seekToEndOfFile()
                
                if let appendMarker = appendMarker,
                    let encodedData = "\(appendMarker)\n".data(using: .utf8) {
                    
                    self.logFileHandle?.write(encodedData)
                }
            }
        }
        catch {
            owner._logln("Attempt to open log file for \(fileExists && shouldAppend ? "appending" : "writing") failed: \(error.localizedDescription)", level: .error, source: self)
            logFileHandle = nil
            return
        }
        
        owner.logAppDetails(selectedDestination: self)
        
        let logDetails = LPLogDetails(level: .info, date: Date(), message: "LPLogger " + (fileExists && shouldAppend ? "appending" : "writing") + " log to: " + writeToFileURL.absoluteString, functionName: "", fileName: "", lineNumber: 0)
        owner._logln(logDetails.message, level: logDetails.level, source: self)
        if owner.destination(withIdentifier: identifier) == nil {
            processInternal(logDetails: logDetails)
        }
    }
    
    /// Close the log file.
    private func closeFile() {
        logFileHandle?.synchronizeFile()
        logFileHandle?.closeFile()
        logFileHandle = nil
    }
    
    /// Force any buffered data to be written to the file.
    ///
    /// - Parameters:
    ///     - closure:  An optional closure to execute after the file has been rotated.
    open func flush(closure: (() -> Void)? = nil) {
        if let logQueue = logQueue {
            logQueue.async {
                self.logFileHandle?.synchronizeFile()
                closure?()
            }
        }
        else {
            logFileHandle?.synchronizeFile()
            closure?()
        }
    }
    
    /// Rotate the log file, storing the existing log file in the specified location.
    ///
    /// - Parameters:
    ///     - archiveToFile:    FileURL or path (as String) to where the existing log file should be rotated to.
    ///     - closure:          An optional closure to execute after the file has been rotated.
    ///
    /// - Returns:
    ///     - true:     Log file rotated successfully.
    ///     - false:    Error rotating the log file.
    @discardableResult open func rotateFile(to archiveToFile: Any, closure: ((_ success: Bool) -> Void)? = nil) -> Bool {
        var archiveToFileURL: URL? = nil
        
        if archiveToFile is NSString {
            archiveToFileURL = URL(fileURLWithPath: archiveToFile as! String)
        }
        else if let archiveToFile = archiveToFile as? URL, archiveToFile.isFileURL {
            archiveToFileURL = archiveToFile
        }
        else {
            closure?(false)
            return false
        }
        
        if let archiveToFileURL = archiveToFileURL,
            let writeToFileURL = writeToFileURL {
            
            let fileManager: FileManager = FileManager.default
            guard !fileManager.fileExists(atPath: archiveToFileURL.path) else { closure?(false); return false }
            
            closeFile()
            haveLoggedAppDetails = false
            
            do {
                try fileManager.moveItem(atPath: writeToFileURL.path, toPath: archiveToFileURL.path)
            }
            catch let error as NSError {
                openFile()
                owner?._logln("Unable to rotate file \(writeToFileURL.path) to \(archiveToFileURL.path): \(error.localizedDescription)", level: .error, source: self)
                closure?(false)
                return false
            }
            
            do {
                if let identifierData: Data = identifier.data(using: .utf8) {
                    try archiveToFileURL.setExtendedAttribute(data: identifierData, forName: LPLogger.Constants.extendedAttributeArchivedLogIdentifierKey)
                }
                if let timestampData: Data = "\(Date().timeIntervalSince1970)".data(using: .utf8) {
                    try archiveToFileURL.setExtendedAttribute(data: timestampData, forName: LPLogger.Constants.extendedAttributeArchivedLogTimestampKey)
                }
            }
            catch let error as NSError {
                owner?._logln("Unable to set extended file attributes on file \(archiveToFileURL.path): \(error.localizedDescription)", level: .error, source: self)
            }
            
            owner?._logln("Rotated file \(writeToFileURL.path) to \(archiveToFileURL.path)", level: .info, source: self)
            openFile()
            closure?(true)
            return true
        }
        
        closure?(false)
        return false
    }
    
    // MARK: - Overridden Methods
    /// Write the log to the log file.
    ///
    /// - Parameters:
    ///     - message:   Formatted/processed message ready for output.
    open override func write(message: String) {
        if let encodedData = "\(message)\n".data(using: String.Encoding.utf8) {
            self.logFileHandle?.write(encodedData)
        }
    }
}
