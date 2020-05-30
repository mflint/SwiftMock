//
//  Mock.swift
//
//  Created by Matthew Flint on 05/11/2018.
//  Copyright © 2018 Green Light Apps. All rights reserved.
//

import XCTest

private struct MockExpectation: CustomDebugStringConvertible {
    var callSummary: String
    var actions: [([Any?]) -> Void]
    var returnValue: Any?

    var debugDescription: String {
        return callSummary
    }
}

class MockExpectationBuilder<M, R> {
    private let theCall: (M) -> R
    private let mock: M
    private var actions = [([Any?]) -> Void]()
    private var returnValue: R?

    init(call: @escaping (M) -> R, mock: M) {
        self.theCall = call
        self.mock = mock
    }

    func returning(_ returnValue: R) {
        self.returnValue = returnValue
    }

    @discardableResult
    func doing(_ block: @escaping ([Any?]) -> Void) -> MockExpectationBuilder<M, R> {
        actions.append(block)
        return self
    }

    fileprivate func complete() {
        _ = theCall(mock)
    }

    fileprivate func build(callSummary: String) -> MockExpectation {
        return MockExpectation(callSummary: callSummary,
                               actions: actions,
                               returnValue: returnValue)
    }
}

protocol MockExpectationHandler {
    func accept(_ callSummary: String, actionArgs: [Any?]) -> Any?
}

private class MockExpectationCreator: MockExpectationHandler {
    // incomplete expectations
    private var expectationCompleters = [() -> Void]()
    var expectations = [MockExpectation]()
    var buildFunction: ((String) -> MockExpectation)?

    func builder<M, R>(for mock: M, call: @escaping (M) -> R) -> MockExpectationBuilder<M, R> {
        let builder = MockExpectationBuilder<M, R>(call: call, mock: mock)
        expectationCompleters.append(builder.complete)
        return builder
    }

    func completeExpectations() {
        for completer in expectationCompleters {
            completer()
        }
        expectationCompleters.removeAll()
    }

    func claimExpectation(_ callSummary: String) -> MockExpectation? {
        // try to complete any incomplete expectations
        completeExpectations()

        guard let index = expectations.firstIndex(where: { (expectation) -> Bool in
            expectation.callSummary == callSummary
        }) else {
            return nil
        }

        return expectations.remove(at: index)
    }

    func accept(_ callSummary: String, actionArgs: [Any?]) -> Any? {
        guard let buildFunction = buildFunction else {
            preconditionFailure()
        }

        let expectation = buildFunction(callSummary)
        expectations.append(expectation)
        return expectation.returnValue
    }
}

class MockExpectationConsumer: MockExpectationHandler {
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

class Mock<M> {
    private let expectationHandler: MockExpectationHandler?

    static func create() -> Self {
        let expectationCreator = MockExpectationCreator()
        let expectationConsumer = MockExpectationConsumer(expectationCreator: expectationCreator)

        let consumerMock = self.init(expectationHandler: expectationConsumer)

        return consumerMock
    }

    internal required init(expectationHandler: MockExpectationHandler?) {
        self.expectationHandler = expectationHandler
    }

    @discardableResult
    func expect<R>(_ theFunc: @escaping (M) -> R) -> MockExpectationBuilder<M, R> {
        guard let expectationConsumer = expectationHandler as? MockExpectationConsumer else {
            preconditionFailure("internal error")
        }

        let expectationCreator = expectationConsumer.expectationCreator
        let completerMock = type(of: self).init(expectationHandler: expectationCreator) as! M
        let expectationBuilder = expectationCreator.builder(for: completerMock, call: theFunc)
        expectationCreator.buildFunction = expectationBuilder.build
        return expectationBuilder
    }

    func verify(file: StaticString = #file, line: UInt = #line) {
        guard let expectationConsumer = expectationHandler as? MockExpectationConsumer else {
            preconditionFailure("internal error")
        }

        let expectationCreator = expectationConsumer.expectationCreator

        // try to complete any incomplete expectations
        expectationCreator.completeExpectations()

        if expectationCreator.expectations.count > 0 {
            for expectation in expectationCreator.expectations {
                let expectationDescription = String(describing: expectation)
                XCTFail("Unsatisfied expectation: \(expectationDescription)", file: file, line: line)
            }
        }

        expectationCreator.expectations.removeAll()
    }

    @discardableResult
    internal func accept(func: String = #function, args: [Any?] = []) -> Any? {
        return accept(func: `func`, checkArgs: args, actionArgs: args)
    }

    @discardableResult
    internal func accept(func: String = #function, checkArgs: [Any?], actionArgs: [Any?]) -> Any? {
        let callSummary = "\(`func`) " + summary(for: checkArgs)

        guard let expectationHandler = expectationHandler else {
            preconditionFailure()
        }

        return expectationHandler.accept(callSummary, actionArgs: actionArgs)
    }
    
    private func summary(for argument: Any) -> String {
        switch argument {
        case let string as String:
            return string
        case let array as [Any]:
            var result = "["
            for (index, item) in array.enumerated() {
                result += summary(for: item)
                if index < array.count {
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
                if index < dict.count {
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
