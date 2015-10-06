//
//  MockExpectationTests.swift
//  SwiftMock
//
//  Created by Matthew Flint on 14/09/2015.
//
//

/**
Listen up:

There are many reasons why an expectation can fail to match
*expected* arguments against *actual* arguments - which means
it's likely that these tests /could/ become fragile.

(Example: if a test expects the matcher to fail because the
argument-count is wrong, and the function name is accidentally
incorrect, the test might yield a false-positive)

So you'll find this test class has code like this:

    // when
    sut.acceptExpected(functionName: "func")
    let matchYes = sut.satisfy(mockMatcherMap, functionName: "func")
    let matchNo = sut.satisfy(mockMatcherMap, functionName: "foo")

    // then
    XCTAssertTrue(matchYes)
    XCTAssertFalse(matchNo)

The "matchYes"/"matchNo" thing makes it easy to see exactly what's
being tested, as the two calls differ only slightly.

*/

import XCTest
@testable import SwiftMock

class MockExpectationTests: XCTestCase {
    let mockMatcherMap = MockMatcherMap()
    
    func testMatcherFoundByMatcherKey_doesMatch() {
        // given
        // a matcher which matches "arg", with a matcher key "matcherKey"
        let sut = MockExpectation()
        let matcher = MockEqualsMatcher("arg")
        mockMatcherMap.addMatcher(matcher, forKey:"matcherKey")
        
        // when
        // the mock accepts the expectation with that matcherKey
        // the expectation is satisfied, with the correct arg "arg"
        sut.acceptExpected(functionName: "func", matcherKeys:"matcherKey")
        let match = sut.satisfy(mockMatcherMap, functionName: "func", args:"arg")
        
        // then
        XCTAssertTrue(match)
    }
    
    func testMatcherFoundByMatcherKey_doesNotMatch() {
        // given
        // a matcher which matches "arg", with a matcher key "matcherKey"
        let sut = MockExpectation()
        let matcher = MockEqualsMatcher("arg")
        mockMatcherMap.addMatcher(matcher, forKey:"matcherKey")
        
        // when
        // the mock accepts the expectation with that matcherKey
        // the expectation is satisfied, but with an incorrect arg "foo"
        sut.acceptExpected(functionName: "func", matcherKeys:"matcherKey")
        let match = sut.satisfy(mockMatcherMap, functionName: "func", args:"foo")
        
        // then
        // matcher fails becaue the argument was different
        XCTAssertFalse(match)
    }
    
    func testMatcherNotFoundByMatcherKey() {
        // given
        // a matcher which matches "arg", with a matcher key "matcherKey"
        let sut = MockExpectation()
        let matcher = MockEqualsMatcher("arg")
        mockMatcherMap.addMatcher(matcher, forKey:"matcherKey")
        
        // when
        // the mock accepts the expectation with a different matcherKey
        // the expectation is satisfied, with the correct arg "arg"
        sut.acceptExpected(functionName: "func", matcherKeys:"foo")
        let match = sut.satisfy(mockMatcherMap, functionName: "func", args:"arg")
        
        // then
        // match fails because the matcher could not be found
        XCTAssertFalse(match)
    }
    
    func testCallMatchesExpectation() {
        // given
        let sut = MockExpectation()
        mockMatcherMap.addMatcher(MockEqualsMatcher("arg1"), forKey:"one")
        mockMatcherMap.addMatcher(MockEqualsMatcher(2), forKey:"two")
        mockMatcherMap.addMatcher(MockEqualsMatcher(nil), forKey:"three")
        mockMatcherMap.addMatcher(MockEqualsMatcher(true), forKey:"four")
        
        // when
        sut.acceptExpected(functionName: "func", matcherKeys:"one", "two", "three", "four")
        let match = sut.satisfy(mockMatcherMap, functionName: "func", args:"arg1", 2, nil, true)
        
        // then
        XCTAssertTrue(match)
    }
    
    func testNoArgsFunctionNameDifferent() {
        // given
        let sut = MockExpectation()
        
        // when
        sut.acceptExpected(functionName: "func")
        let matchYes = sut.satisfy(mockMatcherMap, functionName: "func")
        let matchNo = sut.satisfy(mockMatcherMap, functionName: "foo")
        
        // then
        XCTAssertTrue(matchYes)
        XCTAssertFalse(matchNo)
    }
    
    func testArgsDifferentCount() {
        // given
        let sut = MockExpectation()
        mockMatcherMap.addMatcher(MockEqualsMatcher("arg1"), forKey:"key1")
        
        // when
        sut.acceptExpected(functionName: "func", matcherKeys:"key1")
        let matchYes = sut.satisfy(mockMatcherMap, functionName: "func", args:"arg1")
        let matchNo = sut.satisfy(mockMatcherMap, functionName: "func", args:"foo")
        
        // then
        XCTAssertTrue(matchYes)
        XCTAssertFalse(matchNo)
    }
    
    func testArgsDifferent_expectNilReceivedNotNil() {
        // given
        let sut = MockExpectation()
        mockMatcherMap.addMatcher(MockEqualsMatcher("arg1"), forKey:"key1")
        mockMatcherMap.addMatcher(MockEqualsMatcher(nil), forKey:"key2")
        mockMatcherMap.addMatcher(MockEqualsMatcher(true), forKey:"key3")
        
        // when
        sut.acceptExpected(functionName: "func", matcherKeys:"key1", "key2", "key3")
        let matchYes = sut.satisfy(mockMatcherMap, functionName: "func", args:"arg1", nil, true)
        let matchNo = sut.satisfy(mockMatcherMap, functionName: "func", args:"arg1", 2, true)
        
        // then
        XCTAssertTrue(matchYes)
        XCTAssertFalse(matchNo)
    }
    
    func testArgsDifferent_expectNotNilReceivedNil() {
        // given
        let sut = MockExpectation()
        mockMatcherMap.addMatcher(MockEqualsMatcher("arg1"), forKey:"key1")
        mockMatcherMap.addMatcher(MockEqualsMatcher(2), forKey:"key2")
        mockMatcherMap.addMatcher(MockEqualsMatcher(true), forKey:"key3")
        
        // when
        sut.acceptExpected(functionName: "func", matcherKeys:"key1", "key2", "key3")
        let matchYes = sut.satisfy(mockMatcherMap, functionName: "func", args:"arg1", 2, true)
        let matchNo = sut.satisfy(mockMatcherMap, functionName: "func", args:"arg1", nil, true)
        
        // then
        XCTAssertTrue(matchYes)
        XCTAssertFalse(matchNo)
    }
    
    func testArgsDifferentTypes_notNil() {
        // given
        let sut = MockExpectation()
        mockMatcherMap.addMatcher(MockEqualsMatcher("arg1"), forKey:"key1")
        mockMatcherMap.addMatcher(MockEqualsMatcher(2), forKey:"key2")
        mockMatcherMap.addMatcher(MockEqualsMatcher(true), forKey:"key3")
        
        // when
        sut.acceptExpected(functionName: "func", matcherKeys:"key1", "key2", "key3")
        let matchYes = sut.satisfy(mockMatcherMap, functionName: "func", args:"arg1", 2, true)
        let matchNo = sut.satisfy(mockMatcherMap, functionName: "func", args:"arg1", "foo", true)
        
        // then
        XCTAssertTrue(matchYes)
        XCTAssertFalse(matchNo)
    }
    
    func testArgsDifferent_notNil() {
        // given
        let sut = MockExpectation()
        mockMatcherMap.addMatcher(MockEqualsMatcher("arg1"), forKey:"key1")
        mockMatcherMap.addMatcher(MockEqualsMatcher(2), forKey:"key2")
        mockMatcherMap.addMatcher(MockEqualsMatcher(true), forKey:"key3")
        
        // when
        sut.acceptExpected(functionName: "func", matcherKeys:"key1", "key2", "key3")
        let matchYes = sut.satisfy(mockMatcherMap, functionName: "func", args:"arg1", 2, true)
        let matchNo = sut.satisfy(mockMatcherMap, functionName: "func", args:"arg1", 3, true)
        
        // then
        XCTAssertTrue(matchYes)
        XCTAssertFalse(matchNo)
    }
    
    func testNoMatcherKey_treatedAsALiteralExpectation_usesEqualsMatcher() {
        // given
        let sut = MockExpectation()
        // Note: no matcher with key "unknownMatcherKey", so it's treated as a
        // literal expectation and matched with a MockEqualsMatcher
        mockMatcherMap.addMatcher(MockEqualsMatcher(2), forKey:"key2")
        mockMatcherMap.addMatcher(MockEqualsMatcher(true), forKey:"key3")
        
        // when
        sut.acceptExpected(functionName: "func", matcherKeys:"unknownMatcherKey", "key2", "key3")
        let matchYes = sut.satisfy(mockMatcherMap, functionName: "func", args:"unknownMatcherKey", 2, true)
        let matchNo = sut.satisfy(mockMatcherMap, functionName: "func", args:"thisIsTotallyWrong", 3, true)
        
        // then
        XCTAssertTrue(matchYes)
        XCTAssertFalse(matchNo)
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
        let satisfied = sut.satisfy(mockMatcherMap, functionName: "func")
        let returnedValue = sut.performActions() as! Int
        
        // then
        XCTAssertNotNil(actionable1)
        XCTAssertNotNil(actionable2)
        XCTAssertTrue(actionable1 === actionable2)
        XCTAssertTrue(satisfied)
        XCTAssertEqual(42, returnedValue)
    }
    
}
