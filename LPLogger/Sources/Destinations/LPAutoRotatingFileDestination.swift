//
//  LPAutoRotatingFileDestination.swift
//  LPLogger <https://github.com/leo-lp/LPLogger>
//
//  Created by pengli on 2018/5/14.
//  Copyright © 2018年 pengli. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// A destination that outputs log details to files in a log folder, with auto-rotate options (by size or by time)
open class LPAutoRotatingFileDestination: LPFileDestination {
    // MARK: - Constants
    public static let autoRotatingFileDefaultMaxFileSize: UInt64 = 1_048_576
    public static let autoRotatingFileDefaultMaxTimeInterval: TimeInterval = 600
    
    // MARK: - Properties
    /// Option: desired maximum size of a log file, if 0, no maximum (log files may exceed this, it's a guideline only)
    open var targetMaxFileSize: UInt64 = autoRotatingFileDefaultMaxFileSize {
        didSet {
            if targetMaxFileSize < 1 {
                targetMaxFileSize = .max
            }
        }
    }
    
    /// Option: desired maximum time in seconds stored in a log file, if 0, no maximum (log files may exceed this, it's a guideline only)
    open var targetMaxTimeInterval: TimeInterval = autoRotatingFileDefaultMaxTimeInterval {
        didSet {
            if targetMaxTimeInterval < 1 {
                targetMaxTimeInterval = 0
            }
        }
    }
    
    /// Option: the desired number of archived log files to keep (number of log files may exceed this, it's a guideline only)
    open var targetMaxLogFiles: UInt8 = 10 {
        didSet {
            cleanUpLogFiles()
        }
    }
    
    /// Option: the URL of the folder to store archived log files (defaults to the same folder as the initial log file)
    open var archiveFolderURL: URL? = nil {
        didSet {
            guard let archiveFolderURL = archiveFolderURL else { return }
            try? FileManager.default.createDirectory(at: archiveFolderURL, withIntermediateDirectories: true)
        }
    }
    
    /// Option: an optional closure to execute whenever the log is auto rotated
    open var autoRotationCompletion: ((_ success: Bool) -> Void)? = nil
    
    /// A custom date formatter object to use as the suffix of archived log files
    internal var _customArchiveSuffixDateFormatter: DateFormatter? = nil
    /// The date formatter object to use as the suffix of archived log files
    open var archiveSuffixDateFormatter: DateFormatter! {
        get {
            guard _customArchiveSuffixDateFormatter == nil else { return _customArchiveSuffixDateFormatter }
            struct Statics {
                static var archiveSuffixDateFormatter: DateFormatter = {
                    let defaultArchiveSuffixDateFormatter = DateFormatter()
                    defaultArchiveSuffixDateFormatter.locale = NSLocale.current
                    defaultArchiveSuffixDateFormatter.dateFormat = "_yyyy-MM-dd_HHmmss"
                    return defaultArchiveSuffixDateFormatter
                }()
            }
            
            return Statics.archiveSuffixDateFormatter
        }
        set {
            _customArchiveSuffixDateFormatter = newValue
        }
    }
    
    /// Size of the current log file
    internal var currentLogFileSize: UInt64 = 0
    
    /// Start time of the current log file
    internal var currentLogStartTimeInterval: TimeInterval = 0
    
    /// The base file name of the log file
    internal var baseFileName: String = "LPLogger"
    
    /// The extension of the log file name
    internal var fileExtension: String = "log"
    
    // MARK: - Class Properties
    /// A default folder for storing archived logs if one isn't supplied
    open class var defaultLogFolderURL: URL {
        #if os(OSX)
        let defaultLogFolderURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("log")
        try? FileManager.default.createDirectory(at: defaultLogFolderURL, withIntermediateDirectories: true)
        return defaultLogFolderURL
        #elseif os(iOS) || os(tvOS) || os(watchOS)
        let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let defaultLogFolderURL = urls[urls.endIndex - 1].appendingPathComponent("log")
        try? FileManager.default.createDirectory(at: defaultLogFolderURL, withIntermediateDirectories: true)
        return defaultLogFolderURL
        #endif
    }
    
    // MARK: - Life Cycle
    public init(owner: LPLogger? = nil,
                writeToFile: Any,
                identifier: String = "",
                shouldAppend: Bool = false,
                appendMarker: String? = "-- ** ** ** --",
                attributes: [FileAttributeKey: Any]? = nil,
                maxFileSize: UInt64 = autoRotatingFileDefaultMaxFileSize,
                maxTimeInterval: TimeInterval = autoRotatingFileDefaultMaxTimeInterval,
                archiveSuffixDateFormatter: DateFormatter? = nil) {
        super.init(owner: owner, writeToFile: writeToFile, identifier: identifier, shouldAppend: true, appendMarker: shouldAppend ? appendMarker : nil, attributes: attributes)
        
        currentLogStartTimeInterval = Date().timeIntervalSince1970
        self.archiveSuffixDateFormatter = archiveSuffixDateFormatter
        self.shouldAppend = shouldAppend
        self.targetMaxFileSize = maxFileSize
        self.targetMaxTimeInterval = maxTimeInterval
        
        guard let writeToFileURL = writeToFileURL else { return }
        
        // Calculate some details for naming archived logs based on the current log file path/name
        fileExtension = writeToFileURL.pathExtension
        baseFileName = writeToFileURL.lastPathComponent
        if let fileExtensionRange: Range = baseFileName.range(of: ".\(fileExtension)", options: .backwards),
            fileExtensionRange.upperBound >= baseFileName.endIndex {
            baseFileName = String(baseFileName[baseFileName.startIndex ..< fileExtensionRange.lowerBound])
        }
        
        let filePath: String = writeToFileURL.path
        let logFileName: String = "\(baseFileName).\(fileExtension)"
        if let logFileNameRange: Range = filePath.range(of: logFileName, options: .backwards),
            logFileNameRange.upperBound >= filePath.endIndex {
            let archiveFolderPath: String = String(filePath[filePath.startIndex ..< logFileNameRange.lowerBound])
            archiveFolderURL = URL(fileURLWithPath: "\(archiveFolderPath)")
        }
        if archiveFolderURL == nil {
            archiveFolderURL = type(of: self).defaultLogFolderURL
        }
        
        do {
            // Initialize starting values for file size and start time so shouldRotate calculations are valid
            let fileAttributes: [FileAttributeKey: Any] = try FileManager.default.attributesOfItem(atPath: filePath)
            currentLogFileSize = fileAttributes[.size] as? UInt64 ?? 0
            currentLogStartTimeInterval = (fileAttributes[.creationDate] as? Date ?? Date()).timeIntervalSince1970
        }
        catch {
            owner?._logln("Unable to determine current file attributes of log file: \(error.localizedDescription)", level: .warning)
        }
        
        // Because we always start by appending, regardless of the shouldAppend setting, we now need to handle the cases where we don't want to append or that we have now reached the rotation threshold for our current log file
        if !shouldAppend || shouldRotate() {
            rotateFile()
        }
    }
    
    /// Scan the log folder and delete log files that are no longer relevant.
    open func cleanUpLogFiles() {
        var archivedFileURLs: [URL] = self.archivedFileURLs()
        guard archivedFileURLs.count > Int(targetMaxLogFiles) else { return }
        
        archivedFileURLs.removeFirst(Int(targetMaxLogFiles))
        
        let fileManager: FileManager = FileManager.default
        for archivedFileURL in archivedFileURLs {
            do {
                try fileManager.removeItem(at: archivedFileURL)
            }
            catch let error as NSError {
                owner?._logln("Unable to delete old archived log file \(archivedFileURL.path): \(error.localizedDescription)", level: .error)
            }
        }
    }
    
    /// Delete all archived log files.
    open func purgeArchivedLogFiles() {
        let fileManager: FileManager = FileManager.default
        for archivedFileURL in archivedFileURLs() {
            do {
                try fileManager.removeItem(at: archivedFileURL)
            }
            catch let error as NSError {
                owner?._logln("Unable to delete old archived log file \(archivedFileURL.path): \(error.localizedDescription)", level: .error)
            }
        }
    }
    
    /// Get the URLs of the archived log files.
    ///
    /// - Returns:      An array of file URLs pointing to previously archived log files, sorted with the most recent logs first.
    open func archivedFileURLs() -> [URL] {
        let archiveFolderURL: URL = (self.archiveFolderURL ?? type(of: self).defaultLogFolderURL)
        guard let fileURLs = try? FileManager.default.contentsOfDirectory(at: archiveFolderURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else { return [] }
        guard let identifierData: Data = identifier.data(using: .utf8) else { return [] }
        
        var archivedDetails: [(url: URL, timestamp: String)] = []
        for fileURL in fileURLs {
            guard let archivedLogIdentifierOptionalData = try? fileURL.extendedAttribute(forName: LPLogger.Constants.extendedAttributeArchivedLogIdentifierKey) else { continue }
            guard let archivedLogIdentifierData = archivedLogIdentifierOptionalData else { continue }
            guard archivedLogIdentifierData == identifierData else { continue }
            
            guard let timestampOptionalData = try? fileURL.extendedAttribute(forName: LPLogger.Constants.extendedAttributeArchivedLogTimestampKey) else { continue }
            guard let timestampData = timestampOptionalData else { continue }
            guard let timestamp = String(data: timestampData, encoding: .utf8) else { continue }
            
            archivedDetails.append((fileURL, timestamp))
        }
        
        archivedDetails.sort(by: { (lhs, rhs) -> Bool in lhs.timestamp > rhs.timestamp })
        var archivedFileURLs: [URL] = []
        for archivedDetail in archivedDetails {
            archivedFileURLs.append(archivedDetail.url)
        }
        
        return archivedFileURLs
    }
    
    /// Rotate the current log file.
    open func rotateFile() {
        var archiveFolderURL: URL = (self.archiveFolderURL ?? type(of: self).defaultLogFolderURL)
        archiveFolderURL = archiveFolderURL.appendingPathComponent("\(baseFileName)\(archiveSuffixDateFormatter.string(from: Date()))")
        archiveFolderURL = archiveFolderURL.appendingPathExtension(fileExtension)
        rotateFile(to: archiveFolderURL, closure: autoRotationCompletion)
        
        currentLogStartTimeInterval = Date().timeIntervalSince1970
        currentLogFileSize = 0
        
        cleanUpLogFiles()
    }
    
    /// Determine if the log file should be rotated.
    ///
    /// - Returns:
    ///     - true:     The log file should be rotated.
    ///     - false:    The log file doesn't have to be rotated.
    open func shouldRotate() -> Bool {
        // Do not rotate until critical setup has been completed so that we do not accidentally rotate once to the defaultLogFolderURL before determining the desired log location
        guard archiveFolderURL != nil else { return false }
        
        // File Size
        guard currentLogFileSize < targetMaxFileSize else { return true }
        
        // Time Interval, zero = never rotate
        guard targetMaxTimeInterval > 0 else { return false }
        
        // Time Interval, else check time
        guard Date().timeIntervalSince1970 - currentLogStartTimeInterval < targetMaxTimeInterval else { return true }
        
        return false
    }
    
    // MARK: - Overridden Methods
    /// Write the log to the log file.
    ///
    /// - Parameters:
    ///     - message:   Formatted/processed message ready for output.
    open override func write(message: String) {
        currentLogFileSize += UInt64(message.count)
        
        super.write(message: message)
        
        if shouldRotate() {
            rotateFile()
        }
    }
}