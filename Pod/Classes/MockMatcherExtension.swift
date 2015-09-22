//
//  MockMatcherExtension.swift
//  Pods
//
//  Created by Matthew Flint on 22/09/2015.
//
//

import Foundation

protocol MockMatcherExtension {
    func match(item1: Any?, _item2: Any?) -> Bool
}