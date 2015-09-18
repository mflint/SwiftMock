//
//  MockFailer.swift
//  SwiftMock
//
//  Created by Matthew Flint on 13/09/2015.
//
//

/*
This protocol is for things that can perform the "failure" assertions, either because verification failed, or because of a fail-fast condition.
It only exists to help us test, because Swift tests cannot currently catch the various assertions or failures, such as "preconditionFailure"
*/

import Foundation

public protocol MockFailer {
    func doFail(message: String, file: String, line: UInt)
}
