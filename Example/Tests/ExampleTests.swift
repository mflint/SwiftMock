//
//  ExampleTests.swift
//  SwiftMock
//
//  Created by Matthew Flint on 17/09/2015.
//
//

import XCTest
import SwiftMock
@testable import SwiftMock_Example

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
	
	func testStringDict(){
		// expect
		mockCollaborator.expect().call(mockCollaborator.stringDictFunction(["Hello":"Pong"])).andReturn("ping")
		
		// when
		let result = sut.doSomethingWithDictParameters(["Hello":"Pong"])
		
		// then
		mockCollaborator.verify()
		XCTAssertEqual(result, "ping")
		
	}
}
