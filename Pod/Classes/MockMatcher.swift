//
//  MockMatcher.swift
//  Pods
//
//  Created by Matthew Flint on 23/09/2015.
//
//

import Foundation

public class MockMatcher {
    let matcherBlock: (actual: Any?) -> Bool
    
    init(theMatcherBlock: (actual: Any?) -> Bool) {
        matcherBlock = theMatcherBlock
    }
    
    func match(actual: Any?) -> Bool {
        return matcherBlock(actual: actual)
    }
}
