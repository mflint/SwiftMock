//
//  MockMatcherMap.swift
//  Pods
//
//  Created by Matthew Flint on 27/09/2015.
//
//

import Foundation

/**
Ideally this would be a Dictionary, mapping keys to MockMatcher objects.
Unfortunately, the keys can be anything - but a Dictionary's keys must
adopt Hashable.

So it's a pair of arrays - one for keys, t'other for values. We don't
expect to store many key-value pairs here.
*/

class MockMatcherMap {
    var keys = [Any]()
    var values = [MockMatcher]()
    
    func addMatcher(matcher: MockMatcher, forKey key:Any) {
        // TODO: check for key clash
        keys.append(key)
        values.append(matcher)
    }
    
    func getMatcher(key:Any) -> MockMatcher? {
        for index in 0..<keys.count {
            let anyMatcher = MockEqualsMatcher(key)
            if anyMatcher.match(keys[index]) {
                return values[index]
            }
        }
        
        return nil
    }
}
