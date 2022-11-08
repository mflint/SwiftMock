//
//  Mock.swift
//
//  Created by Matthew Flint on 05/11/2018.
//  Copyright © 2018-2021 Green Light Apps. All rights reserved.
//
//  https://github.com/mflint/SwiftMock
//

import XCTest

private struct MockExpectation: CustomDebugStringConvertible {
	var callSummary: String
	var actions: [([Any?]) -> Void]
	var returnValue: Any?
	
	init(callSummary: String,
		  actions: [([Any?]) -> Void],
		  returnValue: Any?) {
		self.callSummary = callSummary
		self.actions = actions
		self.returnValue = returnValue
	}
	
	var debugDescription: String {
		return callSummary
	}
}

public final class MockExpectationBuilder<M, R>: MockExpectationHandler {
	private let callBlock: (M) -> R
	private let mockInit: (MockExpectationHandler) -> Mock<M>
	private var actions = [([Any?]) -> Void]()
	private var returnValue: R?
	private var callSummary: String?
	private var multipleExpectations = false
	
	init(callBlock: @escaping (M) -> R, mockInit: @escaping (MockExpectationHandler) -> Mock<M>) {
		self.callBlock = callBlock
		self.mockInit = mockInit
	}
	
	public func returning(_ returnValue: R) {
		self.returnValue = returnValue
	}
	
	@discardableResult
	public func doing(_ block: @escaping ([Any?]) -> Void) -> MockExpectationBuilder<M, R> {
		actions.append(block)
		return self
	}
	
	public func accept(_ callSummary: String, actionArgs: [Any?]) -> Any? {
		if self.callSummary != nil {
			self.multipleExpectations = true
			XCTFail("Too many expectations in `.expect { }`")
		}
		
		self.callSummary = callSummary
		return self.returnValue
	}
	
	fileprivate func build() -> MockExpectation? {
		let completionMock = self.mockInit(self) as! M
		_ = self.callBlock(completionMock)
		
		// check that an expectation was set by the callBlock
		guard let callSummary = self.callSummary else {
			return nil
		}
		
		if self.multipleExpectations {
			// tried to set multiple expectations in one `.expect { }` block, which
			// is not permitted - so don't expect anything
			return nil
		}
		
		return MockExpectation(callSummary: callSummary,
							   actions: actions,
							   returnValue: returnValue)
	}
}

public protocol MockExpectationHandler {
	func accept(_ callSummary: String, actionArgs: [Any?]) -> Any?
}

private class MockExpectationCreator {
	var expectations = [MockExpectation]()
	private var expectationBuilderFunctions = [() -> MockExpectation?]()
	
	func builder<M, R>(callBlock: @escaping (M) -> R, mockInit: @escaping (MockExpectationHandler) -> Mock<M>) -> MockExpectationBuilder<M, R> {
		let builder = MockExpectationBuilder(callBlock: callBlock, mockInit: mockInit)
		self.expectationBuilderFunctions.append(builder.build)
		return builder
	}
	
	func buildExpectations() {
		self.expectations.append(contentsOf: self.expectationBuilderFunctions.compactMap { $0() })
		self.expectationBuilderFunctions.removeAll()
	}
	
	func claimExpectation(_ callSummary: String) -> MockExpectation? {
		// build any unbuild expectations
		self.buildExpectations()
		
		guard let index = expectations.firstIndex(where: { (expectation) -> Bool in
			expectation.callSummary == callSummary
		}) else {
			return nil
		}
		
		return expectations.remove(at: index)
	}
}

private class MockExpectationConsumer: MockExpectationHandler {
	fileprivate let expectationCreator: MockExpectationCreator
	
	fileprivate init(expectationCreator: MockExpectationCreator) {
		self.expectationCreator = expectationCreator
	}
	
	func accept(_ callSummary: String, actionArgs: [Any?]) -> Any? {
		guard let foundExpectation = expectationCreator.claimExpectation(callSummary) else {
			XCTFail("Unexpected call: \(callSummary)")
			return nil
		}
		
		for action in foundExpectation.actions {
			action(actionArgs)
		}
		
		return foundExpectation.returnValue
	}
}

open class Mock<M> {
	private let expectationHandler: MockExpectationHandler
	
	public static func create() -> Self {
		let expectationCreator = MockExpectationCreator()
		let expectationConsumer = MockExpectationConsumer(expectationCreator: expectationCreator)
		
		let consumerMock = self.init(expectationHandler: expectationConsumer)
		
		return consumerMock
	}
	
	public required init(expectationHandler: MockExpectationHandler) {
		self.expectationHandler = expectationHandler
	}
	
	@discardableResult
	public func expect<R>(_ callBlock: @escaping (M) -> R) -> MockExpectationBuilder<M, R> {
		guard let expectationCreator = (expectationHandler as? MockExpectationConsumer)?.expectationCreator else {
			preconditionFailure("internal error")
		}
		
		return expectationCreator.builder(callBlock: callBlock, mockInit: type(of: self).init)
	}
	
	public func verify(file: StaticString = #file, line: UInt = #line) {
		guard let expectationConsumer = expectationHandler as? MockExpectationConsumer else {
			preconditionFailure("internal error")
		}
		
		let expectationCreator = expectationConsumer.expectationCreator
		
		// build any unbuild expectations
		expectationCreator.buildExpectations()
		
		if expectationCreator.expectations.count > 0 {
			for expectation in expectationCreator.expectations {
				let expectationDescription = String(describing: expectation)
				XCTFail("Unsatisfied expectation: \(expectationDescription)", file: file, line: line)
			}
		}
		
		// remove all expectations, so they don't fail again
		// later in the test
		expectationCreator.expectations.removeAll()
	}
	
	@discardableResult
	public func accept(func: String = #function, args: [Any?] = []) -> Any? {
		return accept(func: `func`, checkArgs: args, actionArgs: args)
	}
	
	@discardableResult
	public func accept(func: String = #function, checkArgs: [Any?], actionArgs: [Any?]) -> Any? {
		var callSummary = "\(`func`)"
		if checkArgs.count > 0 {
			callSummary += " " + summary(for: checkArgs)
		}
		
		return expectationHandler.accept(callSummary, actionArgs: actionArgs)
	}
	
	private func summary(for argument: Any) -> String {
		switch argument {
		// TODO: unwrap optionals?
		case let array as [Any]:
			var result = "["
			for (index, item) in array.enumerated() {
				result += summary(for: item)
				if index < array.count-1 {
					result += ","
				}
			}
			result += "]"
			return result
		case let dict as [String: Any]:
			var result = "["
			for (index, key) in dict.keys.sorted().enumerated() {
				if let value = dict[key] {
					result += "\(summary(for: key)):\(summary(for:value))"
				}
				if index < dict.count-1 {
					result += ","
				}
			}
			result += "]"
			return result
		default:
			return String(describing: argument)
		}
	}
}
