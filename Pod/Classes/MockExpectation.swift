//
//  MockExpectation.swift
//  SwiftMock
//
//  Created by Matthew Flint on 13/09/2015.
//
//

import Foundation

public class MockExpectation {
    public var functionName: String?
    var args: [Any?]
    
    public init() {
        args = [Any?]()
    }
    
    public func call() {
        
    }
    
    /// record the function name and arguments during the expectation-setting phase
    public func acceptExpected(functionName theFunctionName: String, args theArgs: Any?...) -> Bool {
        // do we already have a function? if so, we can't accept this call as an expectation
        let result = functionName == nil
        if result {
            functionName = theFunctionName
            args = theArgs
        }
        return result
    }
    
    public func isComplete() -> Bool {
        return functionName != nil
    }
    
    /// offer this function, and its arguments, to the expectation to see if it matches
    public func satisfy(functionName theFunctionName: String, args theArgs: Any?...) -> Bool {
        return functionName == theFunctionName && checkArgs(theArgs)
    }
    
    func checkArgs(theArgs: [Any?]) -> Bool {
        if theArgs.count != args.count {
            return false
        }
        
        for var index=0; index<theArgs.count; index++ {
            let expected = args[index]
            let actual = theArgs[index]
            
            if expected == nil && actual != nil {
                return false
            }
            
            if expected != nil && actual == nil {
                return false
            }
            
            if expected != nil && actual != nil && expected! != actual! {
                return false
            }
        }
        
        return true
    }
}