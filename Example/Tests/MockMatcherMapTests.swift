//
//  MockMatcherMapTests.swift
//  SwiftMock
//
//  Created by Matthew Flint on 27/09/2015.
//
//

import XCTest

@testable import SwiftMock

class MockMatcherMapTests: XCTestCase {
    
    func testMatcherMap() {
        // given
        let sut = MockMatcherMap()
        
        // when
        let stringMatcher = MockMatcher { (actual) -> Bool in
            return true
        }
        sut.addMatcher(stringMatcher, forKey:"string")
        
        // then
        XCTAssert(stringMatcher === sut.getMatcher("string"))
        
        // when
        let intMatcher = MockMatcher { (actual) -> Bool in
            return true
        }
        sut.addMatcher(intMatcher, forKey:42)
        
        XCTAssert(intMatcher === sut.getMatcher(42))
    }
}
