//
//  MockAction.swift
//  Pods
//
//  Created by Matthew Flint on 21/09/2015.
//
//

import Foundation

public class MockAction {
    let closure: () -> Void
    
    init(_ theClosure: () -> Void) {
        closure = theClosure
    }
    
    func performAction() /*-> Any?*/ {
        closure()
    }
}