//
//  MockEqualsMatcherTests.swift
//  SwiftMock
//
//  Created by Matthew Flint on 22/09/2015.
//
//

import XCTest
@testable import SwiftMock

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
        doTestOptionalArgTypeMatches("string")
        doTestOptionalArgTypeMatches(2)
        doTestOptionalArgTypeMatches(2.0)
        
        let array: [Any] = [2, "string"]
        doTestOptionalArgTypeMatches(array)
    }
    
    func doTestArgTypeMatches(arg: Any) {
        // given
        let sut = MockEqualsMatcher(arg)
        
        // when
        let match = sut.match(arg)
        
        // then
        XCTAssertTrue(match, "\(arg)")
    }
    
    func doTestOptionalArgTypeMatches(arg: Any?) {
        // given
        let sut = MockEqualsMatcher(arg)
        
        // when
        let match = sut.match(arg)
        
        // then
        XCTAssertTrue(match, "\(arg)")
    }

    func testMatcherExtension_match() {
        // given
        let classWillMatch = DifferentClassForMatching()
        let sut = MockEqualsMatcher(classWillMatch)
        
        // when
        let match = sut.match(classWillMatch)
        
        // then
        XCTAssertTrue(match)
    }
    
    func testMatcherExtension_noMatch() {
        // given
        let classWillNotMatch = AnotherDifferentClassForMatching()
        let sut = MockEqualsMatcher(classWillNotMatch)
        
        // when
        let match = sut.match(classWillNotMatch)
        
        // then
        XCTAssertFalse(match)
    }
}
