//
//  MockCallHandlerImplTests.swift
//  SwiftMock
//
//  Created by Matthew Flint on 13/09/2015.
//

import XCTest
import SwiftMock

// ----

protocol Target {
    func voidFunc();
}

class TestFailer: MockFailer {
    var message: String?
    
    func doFail(theMessage: String) {
        message = theMessage;
    }
}

class MockCallHandlerImplTests: XCTestCase {
    func testExpectCall_callMade_verify() {
        // given
        let failer = TestFailer()
        XCTAssertNil(failer.message)
        let sut: MockCallHandler
        sut = MockCallHandlerImpl(withFailer: failer)
        
        // when
        sut.expect()
        let expectationReturnValue = sut.accept(42, functionName: "selector", args: "arg1", "arg2", 3)
        let replayReturnValue = sut.accept(42, functionName: "selector", args: "arg1", "arg2", 3)
        
        // then
        XCTAssertEqual(42, expectationReturnValue as? Int)
        XCTAssertEqual(42, replayReturnValue as? Int)
        
        
        // when
        sut.verify()
        
        // then
        XCTAssertNil(failer.message)
    }
    
    func testExpectCall_callNotMade_verify() {
        // given
        let failer = TestFailer()
        XCTAssertNil(failer.message)
        let sut: MockCallHandler
        sut = MockCallHandlerImpl(withFailer: failer)
        
        // when
        sut.expect()
        let expectationReturnValue = sut.accept(42, functionName: "selector", args: "arg1", "arg2", 3)
        
        // then
        XCTAssertEqual(42, expectationReturnValue as? Int)
        
        
        // when
        sut.verify()
        
        // then
        XCTAssertEqual(failer.message, "Expected call to 'selector' not received")
    }

    func testDoNotExpectCall_callMade_failFast() {
        // given
        let failer = TestFailer()
        XCTAssertNil(failer.message)
        let sut: MockCallHandler
        sut = MockCallHandlerImpl(withFailer: failer)
        
        // when
        sut.accept(42, functionName: "selector", args: "arg1", "arg2", 3)
        
        // then
        XCTAssertEqual(failer.message, "Unexpected call to 'selector' received")
    }
    
    func testIncompleteExpectationThenAnotherExpectation() {
        // given
        let failer = TestFailer()
        XCTAssertNil(failer.message)
        let sut: MockCallHandler
        sut = MockCallHandlerImpl(withFailer: failer)
        
        // when
        sut.expect()
        sut.expect()

        // then
        XCTAssertEqual(failer.message, "Previous expectation was started but not completed")
    }
    
    func testIncompleteExpectationThenVerify() {
        // given
        let failer = TestFailer()
        XCTAssertNil(failer.message)
        let sut: MockCallHandler
        sut = MockCallHandlerImpl(withFailer: failer)
        
        // when
        sut.expect()
        sut.verify()
        
        // then
        XCTAssertEqual(failer.message, "Previous expectation was started but not completed")
    }
    
    func testExpectCall_differentFunctionCalled_failFast() {
        // given
        let failer = TestFailer()
        XCTAssertNil(failer.message)
        let sut: MockCallHandler
        sut = MockCallHandlerImpl(withFailer: failer)
        
        // when
        sut.expect()
        sut.accept(42, functionName: "selector", args: "arg1", "arg2", 3)
        sut.accept(42, functionName: "differentSelector", args: "arg1", "arg2", 3)
        
        // then
        XCTAssertEqual(failer.message, "Unexpected call to 'differentSelector' received")
    }
    
    func testExpectCall_sameFunctionCalledWithDifferentArgs_failFast() {
        // given
        let failer = TestFailer()
        XCTAssertNil(failer.message)
        let sut: MockCallHandler
        sut = MockCallHandlerImpl(withFailer: failer)
        
        // when
        sut.expect()
        sut.accept(42, functionName: "selector", args: "arg1", "arg2", 3)
        sut.accept(42, functionName: "selector", args: "arg1", "banana", 3)
        
        // then
        XCTAssertEqual(failer.message, "Unexpected call to 'selector' received")
    }
    
    func testReminders() {
        XCTFail("TODO: expectation without method call, then stub() - incomplete expectation")
        XCTFail("TODO: expectation without method call, then reject() - incomplete expectation")
    }
}
