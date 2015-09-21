//
//  MockAction.swift
//  Pods
//
//  Created by Matthew Flint on 21/09/2015.
//
//

import Foundation

public class MockAction<T> {
    let closure: () -> T
    let returnsValue: Bool
    
    init(_ theClosure: () -> T, providesReturnValue: Bool = false) {
        closure = theClosure
        returnsValue = providesReturnValue
    }
    
    func performAction() -> Any? {
        return closure()
    }
    
    func providesReturnValue() -> Bool {
        return returnsValue
    }
}