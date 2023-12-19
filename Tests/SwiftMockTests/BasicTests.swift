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
	func voidFunc()
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
	
	func voidFunc() {
		accept()
	}
}

// MARK: - the tests

final class BasicTests: XCTestCase {
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
			options: .with(descriptions: "[TestProtocol] Unsatisfied expectation: funcWithOneArg(value:) [Optional(42)]")) {
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
			options: .with(descriptions: "[TestProtocol] Unsatisfied expectation: funcWithTwoArgs(value1:value2:) [Optional(42),Optional(\"meaning of life\")")) {
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
