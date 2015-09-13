//
//  MockTests.swift
//  SwiftMock
//
//  Created by Matthew Flint on 13/09/2015.
//  Copyright © 2015 CocoaPods. All rights reserved.
//

import XCTest
import SwiftMock

// ----

protocol Target {
    func voidFunc();
}

class MockTarget: Target, Mock {
    let callHandler: MockCallHandler
    
    init(withFailer failer: MockFailer) {
        callHandler = MockCallHandler(withFailer: failer)
    }
    
    func voidFunc() {
        
    }
}

class TestFailer: MockFailer {
    var message: String?
    
    func doFail(message: String) {
        
    }
}

class MockTests: XCTestCase {
    func testExpectVoidCall_voidCallMade_verify() {
        // given
        let failer = TestFailer()
        let sut = MockTarget(withFailer: failer)
        
        // when
        sut.expect().call(sut.voidFunc())
        sut.voidFunc()
        sut.verify()
    }
    
    func testExpectVoidCall_voidCallNotMade_verify() {
        // given
        let failer = TestFailer()
        let sut = MockTarget(withFailer: failer)
        XCTAssertNil(failer.message)
        
        // when
        sut.expect().call(sut.voidFunc())
        sut.verify()
        
        // then
        XCTAssertEqual(failer.message, "'voidFunc' was not called")
    }
    
    func testDoNotExpectVoidCall_voidCallMade_failFast() {
        // given
        let failer = TestFailer()
        let sut = MockTarget(withFailer: failer)
        XCTAssertNil(failer.message)
        
        // when
        sut.voidFunc()
        
        // then
        XCTAssertEqual(failer.message, "'voidFunc' unexpected call")
    }
}
