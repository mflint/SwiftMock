//
//  Mock.swift
//  SwiftMock
//
//  Created by Matthew Flint on 13/09/2015.
//
//

/*
This protocol, and its extension, acts as a proxy to the real workhorse, MockCallHandler. It's here to reduce the amount of boiler-plate code when creating mock objects
*/

public protocol Mock {
    var callHandler: MockCallHandler { get }
    
    func expect(file: String, _ line: UInt) -> MockExpectation
    func stub() -> MockExpectation
    func reject() -> MockExpectation
    
    func verify(file: String, _ line: UInt)
    
    /// check an optional value with a block
//    func checkOptional<T>(block: (value: T?) -> Bool) -> T?
}

public extension Mock {
    func expect(file: String = __FILE__, _ line: UInt = __LINE__) -> MockExpectation {
        return callHandler.expect(file, line)
    }
    
    func stub() -> MockExpectation {
        return callHandler.stub()
    }

    func reject() -> MockExpectation {
        return callHandler.reject()
    }

    func verify(file: String = __FILE__, _ line: UInt = __LINE__) {
        callHandler.verify(file, line)
    }
    
//    func checkString(block: (value: String) -> Bool) -> String {
//        return nil
//    }
}