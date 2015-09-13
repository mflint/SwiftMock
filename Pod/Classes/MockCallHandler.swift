//
//  MockCallHandler.swift
//  SwiftMock
//
//  Created by Matthew Flint on 13/09/2015.
//
//

import Foundation

public protocol MockFailer {
    func doFail(message: String)
}

class DefaultMockFailer: MockFailer {
    func doFail(message: String) {
        preconditionFailure(message)
    }
}

public class MockCallHandler {
    let failer: MockFailer
    
    init() {
        failer = DefaultMockFailer()
    }
    
    // test only
    public init(withFailer theFailer: MockFailer) {
        failer = theFailer
    }
    
}