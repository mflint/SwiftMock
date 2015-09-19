//
//  MockFailerImpl.swift
//  SwiftMock
//
//  Created by Matthew Flint on 13/09/2015.
//
//

/*
Concrete implementation of MockFailure. Not tested.
*/

import Foundation
import XCTest

class MockFailerImpl: MockFailer {
    let testCase: XCTestCase
    
    init(_ theTestCase: XCTestCase) {
        testCase = theTestCase
    }
    
    func doFail(message: String, file: String, line: UInt) {
        // warning: not tested
        testCase.recordFailureWithDescription(message, inFile: file, atLine: line, expected: false)
    }
}
