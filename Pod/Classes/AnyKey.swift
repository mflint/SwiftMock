//
//  AnyKey.swift
//  Pods
//
//  author: jckarter
//  https://devforums.apple.com/message/1045616#1045616
//
//

import Foundation

struct AnyKey: Hashable {
    private let underlying: Any
    private let hashValueFunc: () -> Int
    private let equalityFunc: (Any) -> Bool
    
    init<T: Hashable>(_ key: T) {
        underlying = key
        // Capture the key's hashability and equatability using closures.
        // The Key shares the hash of the underlying value.
        hashValueFunc = { key.hashValue }
        
        // The Key is equal to a Key of the same underlying type,
        // whose underlying value is "==" to ours.
        equalityFunc = {
            if let other = $0 as? T {
                return key == other
            }
            return false
        }
    }
    
    var hashValue: Int { return hashValueFunc() }
}

func ==(x: AnyKey, y: AnyKey) -> Bool {
    return x.equalityFunc(y.underlying)
}
