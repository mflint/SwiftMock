//
//  MockEqualsMatcherTests.swift
//  SwiftMock
//
//  Created by Matthew Flint on 22/09/2015.
//
//

import XCTest
import SwiftMock

// this one will match OK
class DifferentClassForMatching {
    
}

// this will not match
class AnotherDifferentClassForMatching {
    
}

extension MockEqualsMatcherImpl: MockEqualsMatcherExtension {
    public func match(item1: Any?, _ item2: Any?) -> Bool {
        switch item1 {
        case is DifferentClassForMatching:
            return true
        default:
            return false
        }
    }
}

class MockEqualsMatcherTests: XCTestCase {
    
    func testArgTypes() {
        doTestArgTypeMatches(true)
        doTestArgTypeMatches("string")
        doTestArgTypeMatches(2)
        doTestArgTypeMatches(2.0)
        
        let array: [Any] = [2, "string"]
        doTestArgTypeMatches(array)
        
        let dict = [2: "two", "three": 3]
        doTestArgTypeMatches(dict)
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

    func testMatcherExtension_match() {
        // given
        let sut = MockExpectation()
        let classWillMatch = DifferentClassForMatching()
        
        // when
        sut.acceptExpected(functionName: "func1", args:classWillMatch)
        let match1 = sut.satisfy(functionName: "func1", args:classWillMatch)
        
        // then
        XCTAssertTrue(match1)
    }
    
    func testMatcherExtension_noMatch() {
        // given
        let sut = MockExpectation()
        let classWillNotMatch = AnotherDifferentClassForMatching()
        
        // when
        sut.acceptExpected(functionName: "func2", args:classWillNotMatch)
        let match2 = sut.satisfy(functionName: "func2", args:classWillNotMatch)
        
        // then
        XCTAssertFalse(match2)
    }
}
