//
//  MockFailure.swift
//  SwiftMock
//
//  Created by Matthew Flint on 13/09/2015.
//
//

import Foundation

public enum MockFailure: ErrorType {
    case UnexpectedCall(reason: String)
    case ExpectationNotSatisfied(reason: String)
}