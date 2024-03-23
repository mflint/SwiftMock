//
//  Mock.swift
//
//  Created by Matthew Flint on 15/07/2021.
//  Copyright © 2018-2021 Green Light Apps. All rights reserved.
//
//  https://github.com/mflint/SwiftMock
//

import XCTest
@testable import SwiftMock

// MARK: - the protocol to mock

private protocol TestProtocol {
	func returnsBool() -> Bool
	func returnsOptionalString() -> String?
	func funcWithOneOptionalArg(value: Int?)
	func funcWithOneArg(value: Int)
	func funcWithTwoArgs(value1: Int, value2: String)
	func funcWithArrayOfDicts(values: [[String:Int]])
	func funcWithActionArgs(value1: Int, value2: String)
	func funcWithArgAndReturnValue(value: String) -> Int
	func funcWhichThrowsWithArgAndReturnValue(value: String) throws -> Int
	func funcWhichThrows() throws -> String
	func voidFunc()

	func asyncVoidFunc() async
	func asyncFuncWithArg(value: String) async -> Int
	func asyncFuncReturnsString() async -> String
	func asyncFuncWithActionArgs(value1: Int, value2: String) async
	func asyncThrowingFunc(value: String) async throws -> Int
}

// MARK: - the mock to test

private class TestMock: Mock<TestProtocol>, TestProtocol {
	func returnsBool() -> Bool {
		accept() as! Bool
	}
	
	func returnsOptionalString() -> String? {
		accept() as? String
	}
	
	func funcWithOneOptionalArg(value: Int?) {
		accept(args: [value])
	}
	
	func funcWithOneArg(value: Int) {
		accept(args: [value])
	}
	
	func funcWithTwoArgs(value1: Int, value2: String) {
		accept(args: [value1, value2])
	}
	
	func funcWithArrayOfDicts(values: [[String : Int]]) {
		accept(args: values)
	}
	
	func funcWithActionArgs(value1: Int, value2: String) {
		accept(checkArgs: [], actionArgs: [value1, value2])
	}
	
	func funcWithArgAndReturnValue(value: String) -> Int {
		accept(args: [value]) as! Int
	}

	func funcWhichThrowsWithArgAndReturnValue(value: String) throws -> Int {
		try throwingAccept(args: [value]) as! Int
	}

	func funcWhichThrows() throws -> String {
		try throwingAccept() as! String
	}

	func voidFunc() {
		accept()
	}

	func asyncVoidFunc() async {
		await accept()
	}

	func asyncFuncWithArg(value: String) async -> Int {
		await accept(args: [value]) as! Int
	}

	func asyncFuncReturnsString() async -> String {
		return await accept() as! String
	}

	func asyncFuncWithActionArgs(value1: Int, value2: String) async {
		await accept(checkArgs: [], actionArgs: [value1, value2])
	}

	func asyncThrowingFunc(value: String) async throws -> Int {
		return try await throwingAccept(args: [value]) as! Int
	}
}

// MARK: - the tests

final class BasicTests: XCTestCase {
	private enum Error: Swift.Error {
		case vogons
	}

	func testVerify_noExpectations_doesNotFail() {
		// given
		let mock = TestMock.create()
		
		// when
		mock.verify()
		
		// then
		// no failure
	}
	
	func testExpectationSatisFied_doesNotFail() {
		// given
		let mock = TestMock.create()
		mock.expect { $0.voidFunc() }
		mock.voidFunc()
		
		// when
		mock.verify()
		
		// then
		// no failure
	}
	
	func testUnexpectedCall_failsFast() {
		// given
		let mock = TestMock.create()
		
		// expect
		XCTExpectFailure(
			options: .with(descriptions: "[TestProtocol] Unexpected call: voidFunc()")) {
			// when
			mock.voidFunc()
		}
	}
	
	func testReturnValue() {
		// given
		let mock = TestMock.create()
		mock
			.expect { $0.returnsOptionalString() }
			.returning("fnord")
		
		// when
		let returnValue = mock.returnsOptionalString()
		
		// then
		XCTAssertEqual(returnValue, "fnord")
	}

	func testFuncWhichCanThrowButReturnsValue() throws {
		// given
		let mock = TestMock.create()
		mock
			.expect { try $0.funcWhichThrows() }
			.returning("fnord")

		// when
		let returnValue = try mock.funcWhichThrows()

		// then
		XCTAssertEqual(returnValue, "fnord")
	}

	func testFuncWhichThrowsError() {
		// given
		let mock = TestMock.create()
		mock
			.expect { try $0.funcWhichThrows() }
			.throwing(Error.vogons)

		// when
		XCTAssertThrowsError(try mock.funcWhichThrows())
	}

	func testMultipleExpectationsInExpectationBlock() {
		// given
		let mock = TestMock.create()
		mock.expect {
			$0.voidFunc()
			$0.funcWithOneArg(value: 42)
		}
		
		// expect
		XCTExpectFailure(
			options:
				.with(descriptions:
						"Too many expectations in `.expect { }`"
				)) {
			// when
			mock.verify()
		}
	}
	
	func testVerifyButExpectationsNotSatisfied() {
		// given
		let mock = TestMock.create()
		mock.expect { $0.voidFunc() }
		
		// expect
		XCTExpectFailure(
			options: .with(descriptions: "[TestProtocol] Unsatisfied expectation: voidFunc()")) {
			// when
			mock.verify()
		}
	}
	
	func testUnsatisfiedExpectation_verifyAgain_doesNotFail() {
		// given
		let mock = TestMock.create()
		mock.expect {
			$0.voidFunc()
		}
		
		XCTExpectFailure(
			options: .with(descriptions: "[TestProtocol] Unsatisfied expectation: voidFunc()")) {
			// when
			mock.verify()
		}

		// when
		mock.verify()

		// then
		// no failure
	}
	
	func testExpectWithNoExpectation_doesNotCrash() {
		// given
		let mock = TestMock.create()
		mock.expect { _ in }
		
		// when
		mock.verify()
	}
	
	// MARK: - call summary
	
	func testExpectFuncWithOneArg_callSummaryCorrect() {
		// given
		let mock = TestMock.create()
		mock.expect { $0.funcWithOneArg(value: 42) }
		
		// expect
		XCTExpectFailure(
			options: .with(descriptions: "[TestProtocol] Unsatisfied expectation: funcWithOneArg(value:) [42]")) {
			// when
			mock.verify()
		}
	}
	
	func testExpectFuncWithOneOptionalArg_callSummaryCorrect() {
		// given
		let mock = TestMock.create()
		mock.expect { $0.funcWithOneOptionalArg(value: nil) }
		
		// expect
		XCTExpectFailure(
			options: .with(descriptions: "[TestProtocol] Unsatisfied expectation: funcWithOneOptionalArg(value:) [nil]")) {
			// when
			mock.verify()
		}
	}
	
	func testExpectFuncWithTwoArgs_callSummaryCorrect() {
		// given
		let mock = TestMock.create()
		mock.expect { $0.funcWithTwoArgs(value1: 42, value2: "meaning of life") }
		
		// expect
		XCTExpectFailure(
			options: .with(descriptions: "[TestProtocol] Unsatisfied expectation: funcWithTwoArgs(value1:value2:) [42,meaning of life]")) {
			// when
			mock.verify()
		}
	}
	
	func testExpectFuncWithArrayOfDictArgument_callSummaryCorrect() {
		// given
		let mock = TestMock.create()
		mock.expect { $0.funcWithArrayOfDicts(values: [
			[
				"one": 1,
				"two": 2
			],
			[
				"three": 3,
				"four": 4
			],
		]) }
		
		// expect
		XCTExpectFailure(
			options: .with(descriptions: "[TestProtocol] Unsatisfied expectation: funcWithArrayOfDicts(values:) [[one:1,two:2],[four:4,three:3]]")) {
			// when
			mock.verify()
		}
	}
	
	// MARK: - doing
	
	func testActionArgsNotChecked() {
		// given
		let mock = TestMock.create()
		
		var capturedInt: Int?
		var capturedString: String?
		
		mock
			.expect { $0.funcWithActionArgs(value1: 42, value2: "Slartibartfast") }
			.doing { actionArgs in
				capturedInt = actionArgs[0] as? Int
				capturedString = actionArgs[1] as? String
			}
		
		// when
		mock.funcWithActionArgs(value1: 1, value2: "hi")
		
		// then
		mock.verify()
		XCTAssertEqual(capturedInt, 1)
		XCTAssertEqual(capturedString, "hi")
	}
	
	func testArgsAreCheckedAndPassedToActions() {
		// given
		let mock = TestMock.create()
		
		var capturedInt: Int?
		var capturedString: String?
		
		mock
			.expect { $0.funcWithTwoArgs(value1: 42, value2: "Slartibartfast") }
			.doing { actionArgs in
				capturedInt = actionArgs[0] as? Int
				capturedString = actionArgs[1] as? String
			}
		
		// when
		mock.funcWithTwoArgs(value1: 42, value2: "Slartibartfast")
		
		// then
		mock.verify()
		XCTAssertEqual(capturedInt, 42)
		XCTAssertEqual(capturedString, "Slartibartfast")
	}
	
	func testDoingAndReturn() {
		// given
		let mock = TestMock.create()
		var capturedString: String?
		
		mock
			.expect { $0.funcWithArgAndReturnValue(value: "Vogons") }
			.doing { actionArgs in
				capturedString = actionArgs[0] as? String
			}
			.returning(42)
		
		// when
		let returnValue = mock.funcWithArgAndReturnValue(value: "Vogons")
		
		// when
		mock.verify()
		XCTAssertEqual(capturedString, "Vogons")
		XCTAssertEqual(returnValue, 42)
	}
	
	// MARK: - multiple expectations for the same call
	
	func testFuncExpectedTwice_performedOnce_fails() {
		// given
		let mock = TestMock.create()
		mock.expect { $0.voidFunc() }
		mock.expect { $0.voidFunc() }
		mock.voidFunc()
		
		// expect
		XCTExpectFailure(
			options: .with(descriptions: "[TestProtocol] Unsatisfied expectation: voidFunc()")) {
			// when
			mock.verify()
		}
	}
	
	func testFuncExpectedTwice_performedThreeTimes_fails() {
		// given
		let mock = TestMock.create()
		mock.expect { $0.voidFunc() }
		mock.expect { $0.voidFunc() }
		mock.voidFunc()
		mock.voidFunc()

		// expect
		XCTExpectFailure(
			options: .with(descriptions: "Unexpected call: voidFunc()")) {
			// when
			mock.voidFunc()
		}
	}
	
	func testFuncExpectedTwice_performedTwice_pass() {
		// given
		let mock = TestMock.create()
		mock.expect { $0.voidFunc() }
		mock.expect { $0.voidFunc() }
		
		// when
		mock.voidFunc()
		mock.voidFunc()

		// when
		mock.verify()
	}

	// MARK: - Async calls

	func testAsyncVoidFunc_pass() async {
		// given
		let mock = TestMock.create()
		mock.expect { await $0.asyncVoidFunc() }

		// when
		await mock.asyncVoidFunc()

		// then
		await mock.verify()
	}

	func testAsyncVoidFunc_notCalled_verify_fail() async {
		// given
		let mock = TestMock.create()
		mock.expect { await $0.asyncVoidFunc() }

		// when
		// nothing

		// then
		XCTExpectFailure(options: .with(descriptions: "Unsatisfied expectation: asyncVoidFunc()"))
		await mock.verify()
	}

	func testAsyncVoidFunc_unexpectedCall_fail() async {
		// given
		let mock = TestMock.create()

		Task {
			// when
			XCTExpectFailure(options: .with(descriptions: "Unexpected call: asyncVoidFunc()"))
			await mock.asyncVoidFunc()
		}
	}

	func testAsyncReturnsInt() async {
		// test that we can set expectations on an async function being called

		// given
		let mock = TestMock.create()
		let future = mock.expect { await $0.asyncFuncReturnsString() }
			.asyncReturning("Beeblebrox")

		// when
		Task {
			let result = await mock.asyncFuncReturnsString()
			XCTAssertEqual(result, "Beeblebrox")
		}

		await mock.verify()

		// check that mocked async functions can return a value to the
		// system-under-test

		// when
		future.fulfill()

		// then
		// XCTAssertEqual in the Task will check the return value
	}

	func testAsyncFuncWithActions() async {
		// given
		var capturedInt: Int?
		var capturedString: String?

		let mock = TestMock.create()
		mock.expect { await $0.asyncFuncWithActionArgs(value1: 1, value2: "hi") }
			.doing { actionArgs in
				capturedInt = actionArgs[0] as? Int
				capturedString = actionArgs[1] as? String
			}

		// when
		Task {
			await mock.asyncFuncWithActionArgs(value1: 1, value2: "hi")
		}

		await mock.verify()
		XCTAssertEqual(capturedInt, 1)
		XCTAssertEqual(capturedString, "hi")
	}

	func testAsyncThrowingFunc() async {
		// test that we can set expectations on an async function being called

		// given
		let mock = TestMock.create()
		let future = mock.expect { try await $0.asyncThrowingFunc(value: "Zaphod") }
			.asyncThrowing(Error.vogons)

		// when
		Task {
			do {
				_ = try await mock.asyncThrowingFunc(value: "Zaphod")
				XCTFail("Expected error")
			} catch {
				XCTAssertEqual(error as? Error, Error.vogons)
			}
		}

		await mock.verify()

		// check that mocked async functions can return a value to the
		// system-under-test

		// when
		future.fulfill()

		// then
		// XCTAssertEqual in the Task will check the thrown error
	}

	func testArgsDoNotMatch_returnBestGuessValue_doesNotCrash() {
		// given
		let mock = TestMock.create()

		mock
			.expect { $0.funcWithArgAndReturnValue(value: "Vogons") }
			.returning(42)

		// when
		let result = XCTExpectFailure(
			options: .with(descriptions: "[TestProtocol] Unexpected call: funcWithArgAndReturnValue(value:) [Humans]")) {
			// when
			mock.funcWithArgAndReturnValue(value: "Humans")
		}

		// then
		XCTAssertEqual(result, 42)
	}

	func testThrowingFunction_argsDoNotMatch_returnBestGuessValue_doesNotCrash() throws {
		// given
		let mock = TestMock.create()

		mock
			.expect { try $0.funcWhichThrowsWithArgAndReturnValue(value: "Vogons") }
			.returning(42)

		// expect
		XCTExpectFailure(options: .with(descriptions: "[TestProtocol] Unexpected call: funcWhichThrowsWithArgAndReturnValue(value:) [Humans]"))

		// when
		let result = try mock.funcWhichThrowsWithArgAndReturnValue(value: "Humans")
		XCTAssertEqual(result, 42)
	}

	func testThrowingFunction_argsDoNotMatch_throwsBestGuessError_doesNotCrash() {
		// given
		let mock = TestMock.create()

		mock
			.expect { try $0.funcWhichThrowsWithArgAndReturnValue(value: "Vogons") }
			.throwing(Error.vogons)

		// expect
		XCTExpectFailure(options: .with(descriptions: "[TestProtocol] Unexpected call: funcWhichThrowsWithArgAndReturnValue(value:) [Humans]"))

		// when
		XCTAssertThrowsError(try mock.funcWhichThrowsWithArgAndReturnValue(value: "Humans"))
	}

	func testAsyncFunction_argsDoNotMatch_neverReturnsValue_doesNotCrash() async {
		// given
		let mock = TestMock.create()

		_ = mock
			.expect { await $0.asyncFuncWithArg(value: "Vogons") }
			.asyncReturning(42)

		Task {
			// expect
			XCTExpectFailure(options: .with(descriptions: "[TestProtocol] Unexpected call: asyncFuncWithArg(value:) [Humans]"))

			// when
			_ = await mock.asyncFuncWithArg(value: "Humans")
		}
	}

	func testAsyncThrowingFunction_argsDoNotMatch_neverReturnsValue_doesNotCrash() async throws {
		// given
		let mock = TestMock.create()

		_ = mock
			.expect { try await $0.asyncThrowingFunc(value: "Vogons") }
			.asyncReturning(42)

		// when
		Task {
			XCTExpectFailure(options: .with(descriptions: "[TestProtocol] Unexpected call: asyncThrowingFunc(value:) [Humans]"))

			_ = try await mock.asyncThrowingFunc(value: "Humans")
		}
	}

	func testAsyncThrowingFunction_funcDoesNotMatch_doesNotCrash() async throws {
		// given
		let mock = TestMock.create()

		_ = mock
			.expect { try await $0.asyncThrowingFunc(value: "Vogons") }
			.asyncReturning(42)

		// when
		Task {
			XCTExpectFailure(options: .with(descriptions: "[TestProtocol] Unexpected call: asyncFuncReturnsString()"))

			_ = await mock.asyncFuncReturnsString()

			XCTFail("do not expect the async function to ever return")
		}
	}

	func testAsyncThrowingFunction_argsDoNotMatch_neverThrowsError_doesNotCrash() async throws {
		// given
		let mock = TestMock.create()

		_ = mock
			.expect { try await $0.asyncThrowingFunc(value: "Vogons") }
			.asyncThrowing(Error.vogons)

		Task {
			// expect
			XCTExpectFailure(options: .with(descriptions: "[TestProtocol] Unexpected call: asyncThrowingFunc(value:) [Humans]"))

			// when
			_ = try await mock.asyncThrowingFunc(value: "Humans")
			XCTFail("expected error")
		}
	}
}

extension XCTExpectedFailure.Options {
	static func with(descriptions: String...) -> XCTExpectedFailure.Options {
		let result = XCTExpectedFailure.Options()
		result.issueMatcher = { issue in
			descriptions.filter { expectedDescription in
				issue.compactDescription.contains(expectedDescription)
			}
			.count > 0
		}
		return result
	}
}
