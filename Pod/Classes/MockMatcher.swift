//
//  MockMatcher.swift
//  Pods
//
//  Created by Matthew Flint on 22/09/2015.
//
//

import Foundation

public class MockMatcher {
    func match(firstAnyOptional: Any?, _ secondAnyOptional: Any?) -> Bool {
        
        switch (firstAnyOptional, secondAnyOptional) {
        case (nil, nil): return true
        case (nil, _): return false
        case (_, nil): return false
        default: return patternMatchAnys(firstAnyOptional!, secondAnyOptional!)
        }
    }
    
    func matchArraysOfOptionals(firstArray: Array<Any?>, _ secondArray: Array<Any?>) -> Bool {
        var result = true
        if firstArray.count != secondArray.count {
            result = false
        }
        
        for var index=0; index<firstArray.count && result; index += 1 {
            result = match(firstArray[index], secondArray[index])
        }
        
        return result
    }
    
    func matchArrays(firstArray: Array<Any>, _ secondArray: Array<Any>) -> Bool {
        var result = true
        if firstArray.count != secondArray.count {
            result = false
        }
        
        for var index=0; index<firstArray.count && result; index += 1 {
            result = match(firstArray[index], secondArray[index])
        }
        
        return result
    }
    
    func matchDictionaries(firstDictionary: NSDictionary,_ secondDictionary: NSDictionary) -> Bool{
        var result = true
        var firstKeys=Array<Any>()
        var secondKeys=Array<Any>()

        firstDictionary.keyEnumerator().forEach { (e) -> () in
            firstKeys.append(e)
        }
        secondDictionary.keyEnumerator().forEach { (e) -> () in
            secondKeys.append(e)
        }
        
        if !matchArrays(firstKeys, secondKeys){
            result=false
        }
        
        for var index=0; index<firstKeys.count && result; index += 1 {
            let key=firstKeys[index] as! NSCopying;
            result = match(firstDictionary[key], secondDictionary[key])
        }
        return result
    }
    
    private func patternMatchAnys(lhs: Any, _ rhs: Any) -> Bool {
        var result = false
        
        switch (lhs, rhs) {
        case let (lhs as Array<Any?>, rhs as Array<Any?>):
            result = matchArraysOfOptionals(lhs, rhs)
        case let (lhs as Array<Any>, rhs as Array<Any>):
            result = matchArrays(lhs, rhs)
        case let (lhs as NSDictionary, rhs as NSDictionary):
            result = matchDictionaries(lhs, rhs)
        case let (lhs as String, rhs as String):
            result = lhs == rhs
        case let (lhs as Int, rhs as Int):
            result = lhs == rhs
        case let (lhs as Double, rhs as Double):
            result = lhs == rhs
        case let (lhs as Bool, rhs as Bool):
            result = lhs == rhs
        default:
            if let matcherExtension = self as? MockMatcherExtension {
                result = matcherExtension.match(lhs, rhs)
            }
        }
        
        return result
    }
}