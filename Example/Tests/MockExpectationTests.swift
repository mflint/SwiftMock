//
//  MockExpectationTests.swift
//  SwiftMock
//
//  Created by Matthew Flint on 14/09/2015.
//
//

import XCTest
import SwiftMock

class MockExpectationTests: XCTestCase {

    func testCallMatchesExpectation() {
        // given
        let sut = MockExpectation()
        
        // when
        sut.acceptExpected(functionName: "func", args:"arg1", 2, nil, true)
        let match = sut.satisfy(functionName: "func", args:"arg1", 2, nil, true)
        
        // then
        XCTAssertTrue(match)
    }
    
    func testFunctionNameDifferent() {
        // given
        let sut = MockExpectation()
        
        // when
        sut.acceptExpected(functionName: "func", args:"arg1", 2, true)
        let match = sut.satisfy(functionName: "banana", args:"arg1", 2, true)
        
        // then
        XCTAssertFalse(match)
    }
    
    func testArgsDifferentCount() {
        // given
        let sut = MockExpectation()
        
        // when
        sut.acceptExpected(functionName: "func", args:"arg1", 2, true)
        let match = sut.satisfy(functionName: "func", args:"arg1", 2)
        
        // then
        XCTAssertFalse(match)
    }
    
    func testArgsDifferent_expectNilReceivedNotNil() {
        // given
        let sut = MockExpectation()
        
        // when
        sut.acceptExpected(functionName: "func", args:"arg1", nil, true)
        let match = sut.satisfy(functionName: "func", args:"arg1", 3, true)
        
        // then
        XCTAssertFalse(match)
    }
    
    func testArgsDifferent_expectNotNilReceivedNil() {
        // given
        let sut = MockExpectation()
        
        // when
        sut.acceptExpected(functionName: "func", args:"arg1", 3, true)
        let match = sut.satisfy(functionName: "func", args:"arg1", nil, true)
        
        // then
        XCTAssertFalse(match)
    }
    
    func testArgsDifferentTypes_notNil() {
        // given
        let sut = MockExpectation()
        
        // when
        sut.acceptExpected(functionName: "func", args:"arg1", 2, true)
        let match = sut.satisfy(functionName: "func", args:"arg1", "bob", true)
        
        // then
        XCTAssertFalse(match)
    }
    
    func testArgsDifferent_notNil() {
        // given
        let sut = MockExpectation()
        
        // when
        sut.acceptExpected(functionName: "func", args:"arg1", 2, true)
        let match = sut.satisfy(functionName: "func", args:"arg1", 3, true)
        
        // then
        XCTAssertFalse(match)
    }
    
    func testArgTypes() {
        doTestArgTypeMatches(true)
        doTestArgTypeMatches("string")
        doTestArgTypeMatches(2)
        doTestArgTypeMatches(2.0)
        
        let array: [Any] = [2, "string"]
        doTestArgTypeMatches(array)
    }
    
    func testOptionalArgTypes() {
        doTestOptionalArgTypeMatches(nil)
        doTestOptionalArgTypeMatches(true)
        doTestOptionalArgTypeMatches(true)
        doTestOptionalArgTypeMatches("string")
        doTestOptionalArgTypeMatches(2)
        doTestOptionalArgTypeMatches(2.0)
        
        let array: [Any] = [2, "string"]
        doTestOptionalArgTypeMatches(array)
    }
    
    func doTestArgTypeMatches(arg: Any) {
        // given
        let sut = MockExpectation()
        
        // when
        sut.acceptExpected(functionName: "func", args:arg)
        let match = sut.satisfy(functionName: "func", args:arg)
        
        // then
        XCTAssertTrue(match, "\(arg)")
    }
    
    func doTestOptionalArgTypeMatches(arg: Any?) {
        // given
        let sut = MockExpectation()
        
        // when
        sut.acceptExpected(functionName: "func", args:arg)
        let match = sut.satisfy(functionName: "func", args:arg)
        
        // then
        XCTAssertTrue(match, "\(arg)")
    }
    
    func testCall() {
        // given
        let sut = MockExpectation()
        
        // when
        let actionable = sut.call(13)
        
        // then
        XCTAssertNotNil(actionable)
    }
    
    func testCallAndReturn() {
        // given
        let sut = MockExpectation()
        
        // when
        sut.acceptExpected(functionName: "func")
        let actionable1 = sut.call(13)
        let actionable2 = actionable1.andReturn(42)
        let satisfied = sut.satisfy(functionName: "func")
        let returnedValue = sut.returnValue as! Int
        
        // then
        XCTAssertNotNil(actionable1)
        XCTAssertNotNil(actionable2)
        XCTAssertTrue(actionable1 === actionable2)
        XCTAssertTrue(satisfied)
        XCTAssertEqual(42, returnedValue)
    }
    
}
