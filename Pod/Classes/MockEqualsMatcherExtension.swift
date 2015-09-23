//
//  MockEqualsMatcherExtension.swift
//  Pods
//
//  Created by Matthew Flint on 22/09/2015.
//
//

import Foundation

public protocol MockEqualsMatcherExtension {
    func match(item1: Any?, _ item2: Any?) -> Bool
}