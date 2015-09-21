//
//  MockCallHandlerImpl.swift
//  SwiftMock
//
//  Created by Matthew Flint on 13/09/2015.
//
//

import Foundation
import XCTest

public class MockCallHandlerImpl: MockCallHandler {
    // failures are routed through this object
    let failer: MockFailer
    
    // this is the expectation which is currently being configured (if any)
    var expectation: MockExpectation?
    
    // this is the collection of expectations
    var expectations = [MockExpectation]()
    
    public init(_ testCase: XCTestCase) {
        failer = MockFailerImpl(testCase)
    }
    
    public init(_ theFailer: MockFailer) {
        failer = theFailer
    }
    
    public func expect(file: String, _ line: UInt) -> MockExpectation {
        let newExpectation = MockExpectation()
        
        if expectationsComplete(file, line) {
            // make new expectation, and store it
            expectation = newExpectation
            
            // and add to the array
            expectations.append(newExpectation)
        }
        
        // this return value will never be nil, but it might be useless. But returning a useless object is better than forcing tests to constantly unwrap. The test should fail anyway.
        return newExpectation
    }
    
    func expectationsComplete(file: String, _ line: UInt) -> Bool {
        var expectationsComplete = true
        
        // check that any previous expectation is complete, before starting the next
        if let currentExpectation = expectation {
            if !currentExpectation.isComplete() {
                failer.doFail("Previous expectation was started but not completed", file: file, line: line)
                expectationsComplete = false
            }
        }

        return expectationsComplete
    }
    
    public func reject() -> MockExpectation {
        return (nil as MockExpectation?)!
    }
    
    public func stub() -> MockExpectation {
        return (nil as MockExpectation?)!
    }
    
    public func verify(file: String, _ line: UInt) {
        if expectationsComplete(file, line) && expectations.count > 0 {
            let functionName = expectations[0].functionName!
            failer.doFail("Expected call to '\(functionName)' not received", file: file, line: line)
        }
    }
    
    public func checkOptional<T>(block: (value: T?) -> Bool) -> T? {
        return nil
    }
    
    public func accept(expectationReturnValue: Any?, functionName: String, args: Any?...) -> Any? {
        var returnValue = expectationReturnValue
        var expectationRegistered = false
        
        if let currentExpectation = expectation {
            // there's an expectation in progress - is it waiting for the function details?
            expectationRegistered = currentExpectation.acceptExpected(functionName:functionName, args: args)
        }
        
        if !expectationRegistered {
            // OK, this wasn't a call to set up function expectations, so it's a real call
            var matchedExpectationIndex: Int?
            for var index=0; index<expectations.count && matchedExpectationIndex == nil; index++ {
                if expectations[index].satisfy(functionName:functionName, args: args) {
                    matchedExpectationIndex = index
                }
            }

            if let index = matchedExpectationIndex {
                // it was expected
                returnValue = expectationMatched(index)
            } else {
                // whoopsie, unexpected
                failer.doFail("Unexpected call to '\(functionName)' received", file: "", line: 0)
            }
        }
        
        return returnValue
    }
    
    func expectationMatched(index: Int) -> Any? {
        // get the expectation
        let expectation = expectations[index]
        
        // ... and remove it
        expectations.removeAtIndex(index)
        
        // perform any actions on that expectation
        return expectation.performActions()
    }
}