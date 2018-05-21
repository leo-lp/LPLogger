//
//  LPLoggerDemo.swift
//  LPLoggerDemo
//
//  Created by pengli on 2018/5/21.
//  Copyright © 2018年 pengli. All rights reserved.
//

import Foundation
import LPLogger

/// 日志调试器
let log: LPLogger = {
    let log = LPLogger.shared
    
    /// 设置在DEBUG版本下使用print打印日志...
    #if DEBUG // 可在 “Build Settings” -> “Other Swift Flags” 下设置
    let consoleDestination = LPConsoleDestination(identifier: LPLogger.Constants.baseConsoleDestinationIdentifier)
    consoleDestination.showThreadName = true
    consoleDestination.outputLevel = .debug
    log.add(destination: consoleDestination)
    
    let emojiFormatter = LPPrePostFixLogFormatter()
    emojiFormatter.apply(prefix: "🗯🗯🗯 ", postfix: " 🗯🗯🗯", to: .verbose)
    emojiFormatter.apply(prefix: "🔹🔹🔹 ", postfix: " 🔹🔹🔹", to: .debug)
    emojiFormatter.apply(prefix: "ℹ️ℹ️ℹ️ ", postfix: " ℹ️ℹ️ℹ️", to: .info)
    emojiFormatter.apply(prefix: "⚠️⚠️⚠️ ", postfix: " ⚠️⚠️⚠️", to: .warning)
    emojiFormatter.apply(prefix: "‼️‼️‼️ ", postfix: " ‼️‼️‼️", to: .error)
    emojiFormatter.apply(prefix: "💣💣💣 ", postfix: " 💣💣💣", to: .severe)
    log.formatters = [emojiFormatter]
    #endif
    
    /// 使用文件记录日志；（只在DEBUG和ADHOC下有效）
    #if USE_FILELOGGING // 可在 “Build Settings” -> “Other Swift Flags” 下设置
    if let cacheURL = FileManager.default.urls(for: .cachesDirectory,
                                               in: .userDomainMask).last {
        // Create a file log destination
        let logPath = cacheURL.appendingPathComponent("LPLogging/logDemo  .log")
        
        let fileDestination = LPAutoRotatingFileDestination(
            writeToFile: logPath,
            identifier: LPLogger.Constants.fileDestinationIdentifier,
            shouldAppend: true,
            attributes: [.protectionKey:
                FileProtectionType.completeUntilFirstUserAuthentication])
        
        // Optionally set some configuration options
        fileDestination.outputLevel = .error
        fileDestination.showThreadName = true
        
        // Process this destination in the background
        fileDestination.logQueue = LPLogger.logQueue
        
        // Add colour (using the ANSI format) to our file log, you can see the colour when `cat`ing or `tail`ing the file in Terminal on macOS
        let colorFormatter = LPANSIColorLogFormatter()
        colorFormatter.colorize(level: .verbose, with: .colorIndex(number: 244), options: [.faint])
        colorFormatter.colorize(level: .debug, with: .black)
        colorFormatter.colorize(level: .info, with: .blue, options: [.underline])
        colorFormatter.colorize(level: .warning, with: .yellow)
        colorFormatter.colorize(level: .error, with: .red, options: [.bold])
        colorFormatter.colorize(level: .severe, with: .white, on: .red)
        
        fileDestination.formatters = [colorFormatter]
        
        // Add the destination to the logger
        log.add(destination: fileDestination)
    }
    #endif
    return log
}()
