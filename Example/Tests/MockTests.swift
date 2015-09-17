//
//  MockTests.swift
//  SwiftMock
//
//  Created by Matthew Flint on 13/09/2015.
//

import XCTest
import SwiftMock

class TestMockCallHandler: MockCallHandler {
    var failer: MockFailer {
        // just make it compile - this won't be called by the test
        return (nil as MockFailer?)!
    }
    
    var expectCalled = false
    var stubCalled = false
    var rejectCalled = false
    var verifyCalled = false
//    var checkOptionalCalled = false
    
    let mockExpectation: MockExpectation
    let testCase: XCTestCase
    
    init(withMockExpectation expectation: MockExpectation, withTestCase theTestCase: XCTestCase) {
        mockExpectation = expectation
        testCase = theTestCase
    }
    
    func expect() -> MockExpectation {
        expectCalled = true
        return mockExpectation
    }
    
    func stub() -> MockExpectation {
        stubCalled = true
        return mockExpectation
    }
    
    func reject() -> MockExpectation {
        rejectCalled = true
        return mockExpectation
    }
    
    func verify() {
        verifyCalled = true
    }
    
//    func checkOptional<T>(block: (value: T?) -> Bool) -> T? {
//        checkOptionalCalled = true
//        block(3)
//        return nil
//    }
    
    func accept(returnValue: Any?, functionName: String, args: Any?...) -> Any? {
        return nil
    }
    
    
}

class TestMockImplementation: Mock {
    var callHandler: MockCallHandler
    
    init(withCallHandler handler: MockCallHandler) {
        callHandler = handler
    }
}

// ----

class MockTests: XCTestCase {
    func testExpect() {
        // given
        let mockExpectation = MockExpectation()
        let handler = TestMockCallHandler(withMockExpectation: mockExpectation, withTestCase:self)
        let sut = TestMockImplementation(withCallHandler: handler)
        
        XCTAssertFalse(handler.expectCalled)
        
        // when
        let result = sut.expect()
        
        // when
        XCTAssertTrue(result === mockExpectation)
        XCTAssertTrue(handler.expectCalled)
    }
    
    func testStub() {
        // given
        let mockExpectation = MockExpectation()
        let handler = TestMockCallHandler(withMockExpectation: mockExpectation, withTestCase:self)
        let sut = TestMockImplementation(withCallHandler: handler)
        
        XCTAssertFalse(handler.stubCalled)
        
        // when
        let result = sut.stub()
        
        // when
        XCTAssertTrue(result === mockExpectation)
        XCTAssertTrue(handler.stubCalled)
    }
    
    func testReject() {
        // given
        let mockExpectation = MockExpectation()
        let handler = TestMockCallHandler(withMockExpectation: mockExpectation, withTestCase:self)
        let sut = TestMockImplementation(withCallHandler: handler)
        
        XCTAssertFalse(handler.rejectCalled)
        
        // when
        let result = sut.reject()
        
        // when
        XCTAssertTrue(result === mockExpectation)
        XCTAssertTrue(handler.rejectCalled)
    }
    
    func testVerify() {
        // given
        let mockExpectation = MockExpectation()
        let handler = TestMockCallHandler(withMockExpectation: mockExpectation, withTestCase:self)
        let sut = TestMockImplementation(withCallHandler: handler)
        
        XCTAssertFalse(handler.verifyCalled)
        
        // when
        sut.verify()
        
        // when
        XCTAssertTrue(handler.verifyCalled)
    }
    
//    func testCheckOptional() {
//        // given
//        let mockExpectation = MockExpectation()
//        let handler = TestMockCallHandler(withMockExpectation: mockExpectation, withTestCase:self)
//        let sut = TestMockImplementation(withCallHandler: handler)
//        
//        var checkBlockCalled = false
//        let checkBlock = { (value: Any?) -> Bool in
//            checkBlockCalled = true
//            return true
//        }
//        
//        // when
//        sut.expect()
//        sut.checkOptional(checkBlock)
//        
//        // then
//        XCTAssertTrue(handler.checkOptionalCalled)
//        
//        
//        // given
//        XCTAssertFalse(checkBlockCalled)
//        
//        // when
//        let result = handler.checkOptionalBlock(3)
//        
//        // then
//        XCTAssertTrue(result)
//        XCTAssertTrue(checkBlockCalled)
//    }
}
