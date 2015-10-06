//
//  MockExpectation.swift
//  SwiftMock
//
//  Created by Matthew Flint on 13/09/2015.
//
//

import Foundation

public class MockExpectation {
    /// calls will be matched against this functionName and arguments array
    var functionName: String?
    var matcherKeys = [Any]()

    /// the actionable object holds actions for this expectation, and can perform them
    var actionPerformer: MockActionPerformer!
    
    public init() {
    }
    
    /// this call makes a MockActionable<T>, where T is the return value of the funciton being mocked. The returned object is resonsible for making and performing Actions when the expectation is satisfied. Every subsequent call to "andDo", "andReturn", etc is a separate Action.
    public func call<T: Any>(value: T) -> MockActionable<T> {
        let theActionable = MockActionable(value)
        actionPerformer = theActionable
        return theActionable
    }
    
    /// record the function name and arguments during the expectation-setting phase
    func acceptExpected(functionName theFunctionName: String, matcherKeys theMatcherKeys: Any...) -> Bool {
        // do we already have a function? if so, we can't accept this call as an expectation
        let result = functionName == nil
        if result {
            functionName = theFunctionName
            matcherKeys = theMatcherKeys
        }
        return result
    }
    
    func isComplete() -> Bool {
        return functionName != nil
    }
    
    /// offer this function, and its arguments, to the expectation to see if it matches
    func satisfy(matchers: MockMatcherMap, functionName theFunctionName: String, args: Any?...) -> Bool {
        if functionName != theFunctionName {
            return false
        }
        
        if args.count != matcherKeys.count {
            return false
        }
        
        for index in 0..<args.count {
            // this is either the key to finding a predefined matcher,
            // or it's a literal expected value
            let matcherKeyOrLiteral = matcherKeys[index]
            
            // so either get the predefined matcher, if one exists, or
            // create a new MockEqualsMatcher for that literal
            let matcher = matchers.getMatcher(matcherKeyOrLiteral) ?? MockEqualsMatcher(matcherKeyOrLiteral)
            
            // and now check the matcher against the actual arg value
            if !matcher.match(args[index]) {
                return false
            }
        }
        
        return true
    }
    
    /// perform actions, and return a value from the mock
    func performActions() -> Any? {
        if let performer = actionPerformer {
            return performer.performActions()
        }
        
        return nil
    }
}