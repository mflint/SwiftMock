//
//  MockExpectation.swift
//  SwiftMock
//
//  Created by Matthew Flint on 13/09/2015.
//
//

public protocol Mock {
    func expect() -> MockExpectation
    func reject() -> MockExpectation
    func stub() -> MockExpectation
    
    func verify()
}

public extension Mock {
    func expect() -> MockExpectation {
        return MockExpectation()
    }

    func reject() -> MockExpectation {
        return MockExpectation()
    }

    func stub() -> MockExpectation {
        return MockExpectation()
    }

    func verify() {
//        preconditionFailure("wiggle")
    }
}