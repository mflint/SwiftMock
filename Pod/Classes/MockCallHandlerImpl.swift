//
//  MockCallHandlerImpl.swift
//  SwiftMock
//
//  Created by Matthew Flint on 13/09/2015.
//
//

import Foundation

public class MockCallHandlerImpl: MockCallHandler {
    // failures are routed through this object
    let failer: MockFailer
    
    // this is the expectation which is currently being configured (if any)
    var expectation: MockExpectation?
    
    // this is the collection of expectations
    var expectations = [MockExpectation]()
    
    init() {
        failer = MockFailerImpl()
    }
    
    public init(withFailer theFailer: MockFailer) {
        failer = theFailer
    }
    
    public func expect() -> MockExpectation {
        let newExpectation = MockExpectation()
        
        if expectationsComplete() {
            // make new expectation, and store it
            expectation = newExpectation
            
            // and add to the array
            expectations.append(newExpectation)
        }
        
        // this return value will never be nil, but it might be useless. But returning a useless object is better than forcing tests to constantly unwrap. The test should fail anyway.
        return newExpectation
    }
    
    func expectationsComplete() -> Bool {
        var expectationsComplete = true
        
        // check that any previous expectation is complete, before starting the next
        if let currentExpectation = expectation {
            if !currentExpectation.isComplete() {
                failer.doFail("Previous expectation was started but not completed")
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
    
    public func verify() {
        if expectationsComplete() && expectations.count > 0 {
            let functionName = expectations[0].functionName!
            failer.doFail("Expected call to '\(functionName)' not received")
        }
        //        preconditionFailure("fail")
    }
    
    public func accept(returnValue: Any?, functionName: String, args: AnyObject?...) -> Any? {
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

            if matchedExpectationIndex != nil {
                // it was expected, so remove it
                expectations.removeAtIndex(matchedExpectationIndex!)
            } else {
                // whoopsie, unexpected
                failer.doFail("Unexpected call to '\(functionName)' received")
            }
        }
        
        return returnValue
    }
}