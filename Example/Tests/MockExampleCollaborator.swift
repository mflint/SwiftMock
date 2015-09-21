//
//  MockExampleCollaborator.swift
//  SwiftMock
//
//  Created by Matthew Flint on 20/09/2015.
//
//

import Foundation
import XCTest
import SwiftMock
@testable import SwiftMock_Example

/// the mock ExampleCollaborator
/// this would exist in your test target
class MockExampleCollaborator: ExampleCollaborator, Mock {
    let callHandler: MockCallHandler
    
    init(testCase: XCTestCase) {
        callHandler = MockCallHandlerImpl(testCase)
    }
    
    override func voidFunction() {
        callHandler.accept(nil, functionName: __FUNCTION__, args: nil)
    }
    
    override func function(int: Int, _ string: String) -> String {
        return callHandler.accept("", functionName: __FUNCTION__, args: int, string) as! String
    }
	
	override func stringDictFunction(dict: Dictionary<String, String>) -> String {
		return callHandler.accept("", functionName: __FUNCTION__, args: dict) as! String
	}
}
