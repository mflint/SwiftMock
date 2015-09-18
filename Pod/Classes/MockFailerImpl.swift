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

class MockFailerImpl: MockFailer {
    func doFail(message: String, file: String, line: UInt) {
        // warning: not tested
        preconditionFailure(message)
    }
}
