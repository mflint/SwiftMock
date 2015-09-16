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
    
    func testArgsDifferent_notNil() {
        // given
        let sut = MockExpectation()
        
        // when
        sut.acceptExpected(functionName: "func", args:"arg1", 2, true)
        let match = sut.satisfy(functionName: "func", args:"arg1", 3, true)
        
        // then
        XCTAssertFalse(match)
    }
    
}
