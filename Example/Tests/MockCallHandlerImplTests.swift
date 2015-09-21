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
    var file: String?
    var line: UInt?
    
    func doFail(message: String, file: String, line: UInt) {
        self.message = message
        self.file = file
        self.line = line
    }
}

class MockCallHandlerImplTests: XCTestCase {
    var failer: TestFailer!
    var sut: MockCallHandlerImpl!
    
    override func setUp() {
        failer = TestFailer()
        sut = MockCallHandlerImpl(failer)
    }

    func testExpectCall_callMade_verify() {
        // given
        XCTAssertNil(failer.message)
        XCTAssertNil(failer.file)
        XCTAssertNil(failer.line)

        // when
        sut.expect("ignored", 1)
        let expectationReturnValue = sut.accept(42, functionName: "selector", args: "arg1", "arg2", 3)
        sut.accept(42, functionName: "selector", args: "arg1", "arg2", 3)
        
        // then
        XCTAssertEqual(42, expectationReturnValue as? Int)
        XCTAssertNil(failer.message)
        XCTAssertNil(failer.file)
        XCTAssertNil(failer.line)
        
        
        // when
        sut.verify("thefile", 1234)
        
        // then
        XCTAssertNil(failer.message)
        XCTAssertNil(failer.file)
        XCTAssertNil(failer.line)
    }
    
    func testExpectCall_callNotMade_verify() {
        // given
        XCTAssertNil(failer.message)
        XCTAssertNil(failer.file)
        XCTAssertNil(failer.line)
        
        // when
        sut.expect("ignored", 1)
        let expectationReturnValue = sut.accept(42, functionName: "selector", args: "arg1", "arg2", 3)
        
        // then
        XCTAssertEqual(42, expectationReturnValue as? Int)
        XCTAssertNil(failer.message)
        XCTAssertNil(failer.file)
        XCTAssertNil(failer.line)
        
        
        // when
        sut.verify("thefile", 1234)
        
        // then
        XCTAssertEqual(failer.message, "Expected call to 'selector' not received")
        XCTAssertEqual(failer.file, "thefile")
        XCTAssertEqual(failer.line, 1234)
    }

    func testDoNotExpectCall_callMade_failFast() {
        // given
        XCTAssertNil(failer.message)
        XCTAssertNil(failer.file)
        XCTAssertNil(failer.line)
        
        // when
        sut.accept(42, functionName: "selector", args: "arg1", "arg2", 3)
        
        // then
        XCTAssertEqual(failer.message, "Unexpected call to 'selector' received")
        XCTAssertEqual(failer.file, "")
        XCTAssertEqual(failer.line, 0)
    }
    
    func testIncompleteExpectationThenAnotherExpectation() {
        // given
        XCTAssertNil(failer.message)
        XCTAssertNil(failer.file)
        XCTAssertNil(failer.line)
        
        // when
        sut.expect("ignored", 1)
        
        // then
        XCTAssertNil(failer.message)
        XCTAssertNil(failer.file)
        XCTAssertNil(failer.line)
        
        
        // when
        sut.expect("thefile", 1234)

        // then
        XCTAssertEqual(failer.message, "Previous expectation was started but not completed")
        XCTAssertEqual(failer.file, "thefile")
        XCTAssertEqual(failer.line, 1234)
    }
    
    func testIncompleteExpectationThenVerify() {
        // given
        XCTAssertNil(failer.message)
        XCTAssertNil(failer.file)
        XCTAssertNil(failer.line)
        
        // when
        sut.expect("ignored", 1)
        
        // then
        XCTAssertNil(failer.message)
        XCTAssertNil(failer.file)
        XCTAssertNil(failer.line)

        
        // when
        sut.verify("thefile", 1234)
        
        // then
        XCTAssertEqual(failer.message, "Previous expectation was started but not completed")
        XCTAssertEqual(failer.file, "thefile")
        XCTAssertEqual(failer.line, 1234)
    }
    
    func testExpectCall_differentFunctionCalled_failFast() {
        // given
        XCTAssertNil(failer.message)
        XCTAssertNil(failer.file)
        XCTAssertNil(failer.line)
        
        // when
        sut.expect("ignored", 1)
        sut.accept(42, functionName: "selector", args: "arg1", "arg2", 3)
        
        // then
        XCTAssertNil(failer.message)
        XCTAssertNil(failer.file)
        XCTAssertNil(failer.line)
        
        
        // when
        sut.accept(42, functionName: "differentSelector", args: "arg1", "arg2", 3)
        
        // then
        XCTAssertEqual(failer.message, "Unexpected call to 'differentSelector' received")
        XCTAssertEqual(failer.file, "")
        XCTAssertEqual(failer.line, 0)
    }
    
    func testExpectCall_sameFunctionCalledWithDifferentArgs_failFast() {
        // given
        XCTAssertNil(failer.message)
        XCTAssertNil(failer.file)
        XCTAssertNil(failer.line)
        
        // when
        sut.expect("ignored", 1)
        sut.accept(42, functionName: "selector", args: "arg1", "arg2", 3)
        
        // then
        XCTAssertNil(failer.message)
        XCTAssertNil(failer.file)
        XCTAssertNil(failer.line)
        
        
        // when
        sut.accept(42, functionName: "selector", args: "arg1", "banana", 3)
        
        // then
        XCTAssertEqual(failer.message, "Unexpected call to 'selector' received")
        XCTAssertEqual(failer.file, "")
        XCTAssertEqual(failer.line, 0)
    }
    
    func testAndReturn() {
        // given
        XCTAssertNil(failer.message)
        XCTAssertNil(failer.file)
        XCTAssertNil(failer.line)
        
        // when
        // Note: this "0" is here to provide the return value type
        // Note: the "42" is the value returned by the mock when the expectations are being set. The tests will certainly ignore it, but it's not optional.
        sut.expect("ignored", 1).call(0).andReturn(555)
        sut.accept(42, functionName: "selector", args: "string", 12)
        
        // then
        XCTAssertNil(failer.message)
        XCTAssertNil(failer.file)
        XCTAssertNil(failer.line)
        
        // when
        // Note: this "42" is only relevant at expectation-setting time, unused at runtime
        let runtimeReturnValue = sut.accept(42, functionName: "selector", args: "string", 12) as! Int
        
        // then
        XCTAssertEqual(runtimeReturnValue, 555)
        XCTAssertNil(failer.message)
        XCTAssertNil(failer.file)
        XCTAssertNil(failer.line)
    }
    
    func testAndDo() {
        // given
        XCTAssertNil(failer.message)
        XCTAssertNil(failer.file)
        XCTAssertNil(failer.line)
        
        var closure1Called = false
        var closure2Called = false
        
        // when
        // Note: this "0" is here to provide the return value type
        sut.expect("ignored", 1).call().andDo({
            closure1Called = true
        }).andDo({
            closure2Called = true
        })
        sut.accept(nil, functionName: "selector", args: nil)
        
        // then
        XCTAssertNil(failer.message)
        XCTAssertNil(failer.file)
        XCTAssertNil(failer.line)
        XCTAssertFalse(closure1Called)
        XCTAssertFalse(closure2Called)
        
        // when
        sut.accept(nil, functionName: "selector", args: nil)
        
        // then
        XCTAssertNil(failer.message)
        XCTAssertNil(failer.file)
        XCTAssertNil(failer.line)
        XCTAssertTrue(closure1Called)
        XCTAssertTrue(closure2Called)
    }
    
//    func testReminders() {
//        XCTFail("TODO: expectation without method call, then stub() - incomplete expectation")
//        XCTFail("TODO: expectation without method call, then reject() - incomplete expectation")
//        XCTFail("TODO: if multiple expectations are unsatisfied, report them all")
//        XCTFail("TODO: check for two return values")
//    }
}
