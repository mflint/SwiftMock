//
//  MockActionable.swift
//  Pods
//
//  Created by Matthew Flint on 16/09/2015.
//
//

import Foundation

public class MockActionable<T> {
    let expectation: MockExpectation
    
    init(_ value: T, _ theExpectation: MockExpectation) {
        expectation = theExpectation
    }
    
    public func andReturn(value: T) -> MockActionable<T> {
        expectation.returnValue = value
        return self
    }
    
    public func andDo(closure: () -> Void) -> MockActionable<T> {
        let action = MockAction(closure)
        expectation.addAction(action)
        return self
    }
}
