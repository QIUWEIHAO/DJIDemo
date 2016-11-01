//
//  LogHelper.swift
//  DJISDKSwiftDemo
//
//  Created by DJI on 11/20/15.
//  Copyright © 2015 DJI. All rights reserved.
//

import Foundation
import DJISDK


public func logDebug<T>(object: T?, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
    let logText = convertToString(object)
    DJIRemoteLogger.logWithLevel(.Debug, file: file.stringValue, function: function.stringValue, line: line, string: logText)
}

public func logInfo<T>(object: T?, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
    let logText = convertToString(object)
    DJIRemoteLogger.logWithLevel(.Info, file: file.stringValue, function: function.stringValue, line: line, string: logText)
}

public func logWarn<T>(object: T?, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
    let logText = convertToString(object)
    DJIRemoteLogger.logWithLevel(.Warn, file: file.stringValue, function: function.stringValue, line: line, string: logText)
}

public func logVerbose<T>(object: T?, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
    let logText = convertToString(object)
    DJIRemoteLogger.logWithLevel(.Verbose, file: file.stringValue, function: function.stringValue, line: line, string: logText)
}

public  func logError<T>(object: T?, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
    let logText = convertToString(object)
    DJIRemoteLogger.logWithLevel(.Error, file: file.stringValue, function: function.stringValue, line: line, string: logText)
}

func convertToString<T>(objectOpt: T?) -> String
{
    if let object = objectOpt
    {
        switch object
        {
        case let error as NSError:
            let localizedDesc = error.localizedDescription
            if !localizedDesc.isEmpty { return "\(error.domain) : \(error.code) : \(localizedDesc)" }
            return "<<\(error.localizedDescription)>> --- ORIGINAL ERROR: \(error)"
        case let nsobject as NSObject:
            if nsobject.respondsToSelector(#selector(NSObject.debugDescription as () -> String)) {
                return nsobject.debugDescription
            }
            else
            {
                return nsobject.description
            }
        default:
            return "\(object)"
        }
    }
    else
    {
        return "nil"
    }
    
}