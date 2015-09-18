//
//  MockCallHandler.swift
//  SwiftMock
//
//  Created by Matthew Flint on 13/09/2015.
//
//

/*
MockCallHandler is the thing who maintains the list of expectations, stubs and rejects
*/

import Foundation

public protocol MockCallHandler {
    func expect(file: String, _ line: UInt) -> MockExpectation
    func reject() -> MockExpectation
    func stub() -> MockExpectation
    
    func verify(file: String, _ line: UInt)
    
    /// check an optional value with a block
//    func checkOptional<T>(block: (value: T?) -> Bool) -> T?
    
    /// handles an incoming `function` call with the given `args` arguments. `expectationReturnValue` is the value returned while expectations are being set, so will probably be unused
    func accept(expectationReturnValue: Any?, functionName: String, args: Any?...) -> Any?
}
