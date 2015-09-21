//
//  MockExpectation.swift
//  SwiftMock
//
//  Created by Matthew Flint on 13/09/2015.
//
//

import Foundation

public class MockExpectation {
    public var functionName: String?
    var args: [Any?]

    /// the return value for this expectation, if any
    public var returnValue: Any?
    
    public init() {
        args = [Any?]()
    }
    
    public func call<T>(value: T) -> MockActionable<T> {
        return MockActionable(value, self)
    }
    
    /// record the function name and arguments during the expectation-setting phase
    public func acceptExpected(functionName theFunctionName: String, args theArgs: Any?...) -> Bool {
        // do we already have a function? if so, we can't accept this call as an expectation
        let result = functionName == nil
        if result {
            functionName = theFunctionName
            args = theArgs
        }
        return result
    }
    
    public func isComplete() -> Bool {
        return functionName != nil
    }
    
    /// offer this function, and its arguments, to the expectation to see if it matches
    public func satisfy(functionName theFunctionName: String, args theArgs: Any?...) -> Bool {
        return functionName == theFunctionName && match(args, theArgs)
    }
    
    func match(firstAnyOptional: Any?, _ secondAnyOptional: Any?) -> Bool {
        if firstAnyOptional == nil && secondAnyOptional == nil {
            return true
        }

        if firstAnyOptional == nil || secondAnyOptional == nil {
            return false
        }
        
        let firstAny = firstAnyOptional!
        let secondAny = secondAnyOptional!
        
        // there must be a better way to match two Any? values :-/
        var result = false
        switch(firstAny) {
        case let firstArray as Array<Any?>:
            if let secondArray = secondAny as? Array<Any?> {
                result = matchArraysOfOptionals(firstArray, secondArray)
            }
        case let firstArray as Array<Any>:
            if let secondArray = secondAny as? Array<Any> {
                result = matchArrays(firstArray, secondArray)
            }
		case let firstDictionary as NSDictionary:
			if let secondDictionary = secondAny as? NSDictionary{
				result = matchDictionaries(firstDictionary, secondDictionary)
			}
        case let first as String:
            if let second = secondAny as? String {
                result = first == second
            }
        case let first as Int:
            if let second = secondAny as? Int {
                result = first == second
            }
        case let first as Double:
            if let second = secondAny as? Double {
                result = first == second
            }
        case let first as Bool:
            if let second = secondAny as? Bool {
                result = first == second
            }
        default: break
        }
        
        return result
    }
    
    func matchArraysOfOptionals(firstArray: Array<Any?>, _ secondArray: Array<Any?>) -> Bool {
        var result = true
        if firstArray.count != secondArray.count {
            result = false
        }
        
        for var index=0; index<firstArray.count && result; index++ {
            result = match(firstArray[index], secondArray[index])
        }
        
        return result
    }
    
    func matchArrays(firstArray: Array<Any>, _ secondArray: Array<Any>) -> Bool {
        var result = true
        if firstArray.count != secondArray.count {
            result = false
        }
        
        for var index=0; index<firstArray.count && result; index++ {
            result = match(firstArray[index], secondArray[index])
        }
        
        return result
    }
	
	func matchDictionaries(firstDictionary: NSDictionary,_ secondDictionary: NSDictionary) -> Bool{
		var result = true
		var firstKeys=Array<Any>()
		var secondKeys=Array<Any>()
		firstDictionary.keyEnumerator()
		firstDictionary.keyEnumerator().forEach { (e) -> () in
			firstKeys.append(e)
		}
		secondDictionary.keyEnumerator().forEach { (e) -> () in
			secondKeys.append(e)
		}
		
		if !matchArrays(firstKeys, secondKeys){
			result=false
		}
		
		for var index=0; index<firstKeys.count && result; index++ {
			let key=firstKeys[index] as! NSCopying;
			result = match(firstDictionary[key], secondDictionary[key])
		}
		return result
	}
}