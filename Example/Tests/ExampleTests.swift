//
//  ExampleTests.swift
//  SwiftMock
//
//  Created by Matthew Flint on 17/09/2015.
//
//

import XCTest
import SwiftMock

/// collaborator class - this one will be mocked
/// this would exist in your application target
class ExampleCollaborator {
    func voidFunction() {
        
    }
    
    func function(int: Int, _ string: String) -> String {
        return ""
    }
}

/// the class we're testing
/// this would exist in your application target
class Example {
    let collaborator: ExampleCollaborator
    
    init(_ theCollaborator: ExampleCollaborator) {
        collaborator = theCollaborator
    }
    
    func doSomething() {
        // test will fail if this call isn't made
        collaborator.voidFunction()
    }
    
    func doSomethingWithParamters(int: Int, _ string: String) -> String {
        // test will fail if this call isn't made
        return collaborator.function(int, string)
    }
}



/// the mock ExampleCollaborator
/// this would exist in your test target
class MockExampleCollaborator: ExampleCollaborator, Mock {
    let callHandler: MockCallHandler
    
    init(testCase: XCTestCase) {
        callHandler = MockCallHandlerImpl(testCase)
    }
    
    override func voidFunction() {
        callHandler.accept(nil, functionName: __FUNCTION__, args: nil)
    }
    
    override func function(int: Int, _ string: String) -> String {
        return callHandler.accept("", functionName: __FUNCTION__, args: int, string) as! String
    }
}


/// the tests
class ExampleTests: XCTestCase {
    var mockCollaborator: MockExampleCollaborator!
    var sut: Example!
    
    override func setUp() {
        super.setUp()
        
        // given
        mockCollaborator = MockExampleCollaborator(testCase: self)
        
        // when
        sut = Example(mockCollaborator)
        
        // then
        mockCollaborator.verify()
    }
    
    func testDoSomething() {
        // expect
        mockCollaborator.expect().call(mockCollaborator.voidFunction())
        
        // when
        sut.doSomething()
        
        // then
        mockCollaborator.verify()
    }
    
    func testDoSomethingWithParameters() {
        // expect
        mockCollaborator.expect().call(mockCollaborator.function(42, "frood")).andReturn("hoopy")
        
        // when
        let result = sut.doSomethingWithParamters(42, "frood")
        
        // then
        mockCollaborator.verify()
        XCTAssertEqual(result, "hoopy")
    }
}
