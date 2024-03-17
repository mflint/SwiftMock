//
//  Mock.swift
//
//  https://github.com/mflint/SwiftMock
//

import XCTest

/// The state of an expectation.
private enum ClaimState {
	/// The expectation exists, but doesn't yet have a `callSummary` which
	/// describes the expected function call.
	case awaitingCallSummary

	/// The expectation exists, but doesn't yet have a `callSummary` which
	/// describes the expected function call.
	case awaitingAsyncCallSummary

	/// The expectation could not be created for some reason. Example: multiple
	/// calls to mocked functions inside the `expect` block.
	case invalid

	/// The expectation has a `callSummary`, and hasn't yet been claimed.
	case unclaimed(callSummary: String)

	/// The expectation has been claimed.
	case claimed(callSummary: String)
}

/// A protocol for expectations which erases the generic types so we can
/// store it in a collection.
private protocol AnyExpectation {
	/// A set of actions to perform if the expected call is made.
	var actions: [([Any?]) -> Void] { get }

	/// A value that should be returned from the mock function call.
	var outcome: CallOutcome<Any, Error>? { get }

	/// The state of this expectation.
	var state: ClaimState { get }

	/// For async functions, we use this XCTestExpectation to give time for
	/// mock expectation to be fulfilled before verifying.
	var testExpectation: XCTestExpectation? { get }

	/// This function makes the `callSummary` string, by calling the captured
	/// `callBlock`. The `callSummary` is used for matching expected calls
	/// against actual calls, and contains the expected function name and
	/// important arguments that should be matched.
	func makeCallSummary()

	/// This function makes the `callSummary` string, by calling the captured
	/// `callBlock`. The `callSummary` is used for matching expected calls
	/// against actual calls, and contains the expected function name and
	/// important arguments that should be matched.
	func asyncMakeCallSummary() async

	/// Test this expectation to see if its expected call matches the given
	/// `callSummary`.
	/// - Parameter callSummary: The `callSummary` string being handled by the
	/// mock.
	/// - Returns: Bool indicating whether the expectation has been claimed.
	func claim(_ callSummary: String) -> Bool

	/// Test this expectation to see if its expected call matches the given
	/// `callSummary`.
	/// - Parameter callSummary: The `callSummary` string being handled by the
	/// mock.
	/// - Returns: Bool indicating whether the expectation has been claimed.
	func asyncClaim(_ callSummary: String) async -> Bool
}

/// This is the object passed back to the test, so the test can return a value
/// from the mocked async function.
public class AsyncSuccessOutcome {
	fileprivate let value: Any
	var continuation: CheckedContinuation<Any, Never>?

	init(value: Any) {
		self.value = value
	}

	public func fulfill() {
		self.continuation?.resume(returning: self.value)
	}
}

/// This object is passed back to the unit test, so the test can throw an
/// Error from the mocked async function.
public class AsyncFailureOutcome {
	fileprivate let error: Error
	var continuation: CheckedContinuation<Never, Error>?

	init(error: Error) {
		self.error = error
	}

	public func fulfill() {
		self.continuation?.resume(throwing: self.error)
	}
}

/// `CallOutcome` is the result of a mocked function.
public enum CallOutcome<Success, Failure> where Failure : Error {
	/// A success, storing a `Success` value.
	case success(Success)

	/// A success, storing a `Success` value.
	case asyncSuccess(AsyncSuccessOutcome)

	/// A failure, storing a `Failure` value.
	case failure(Failure)

	/// A failure, storing a `Failure` value.
	case asyncFailure(AsyncFailureOutcome)
}

/// `MockSyncExpectation` is the expectation for a synchronous function.
// Implementation note: ideally, this would be a protocol which only exposes
// synchronous `returning` and `throwing` functions to the test... but the
// compiler doesn't like it.
public class MockSyncExpectation<M, R> {
	fileprivate let expectation: MockExpectation<M, R>

	init(mockName: String, callBlock: @escaping (M) throws -> R, mockInit: @escaping (String, MockExpectationHandler) -> Mock<M>) {
		self.expectation = MockExpectation(mockName: mockName,
										   callBlock: callBlock,
										   mockInit: mockInit)
	}

	init(mockName: String, callBlock: @escaping (M) async throws -> R, mockInit: @escaping (String, MockExpectationHandler) -> Mock<M>) {
		self.expectation = MockExpectation(mockName: mockName,
										   callBlock: callBlock,
										   mockInit: mockInit)
	}

	/// Adds a return value to the expectation.
	/// - Parameter returnValue: value to return.
	func returning(_ returnValue: R) {
		self.expectation.returning(returnValue)
	}

	/// Primes this mocked function to throw an error.
	/// - Parameter error: error to throw.
	func throwing(_ error: Error) {
		self.expectation.throwing(error)
	}

	/// Adds a closure action which will be performed if the expected call is
	/// made.
	/// - Parameter block: action block
	@discardableResult
	func doing(_ block: @escaping ([Any?]) -> Void) -> Self {
		self.expectation.doing(block)
		return self
	}
}

/// `MockAsyncExpectation` is the expectation for a synchronous function.
// Implementation note: ideally, this would be a protocol which only exposes
// asynchronous `returning` and `throwing` functions to the test... but the
// compiler doesn't like it.
public class MockAsyncExpectation<M, R> {
	fileprivate let expectation: MockExpectation<M, R>

	init(mockName: String, callBlock: @escaping (M) throws -> R, mockInit: @escaping (String, MockExpectationHandler) -> Mock<M>) {
		self.expectation = MockExpectation(mockName: mockName,
										   callBlock: callBlock,
										   mockInit: mockInit)
	}

	init(mockName: String, callBlock: @escaping (M) async throws -> R, mockInit: @escaping (String, MockExpectationHandler) -> Mock<M>) {
		self.expectation = MockExpectation(mockName: mockName,
										   callBlock: callBlock,
										   mockInit: mockInit)
	}

	/// Adds an async return value to the expectation.
	/// - Parameter returnValue: value to return asynchronously.
	func asyncReturning(_ returnValue: R) -> AsyncSuccessOutcome {
		self.expectation.asyncReturning(returnValue)
	}

	/// Primes this mocked function to asynchronously throw an error.
	/// - Parameter error: error to throw asynchronously.
	func asyncThrowing(_ error: Error) -> AsyncFailureOutcome {
		self.expectation.asyncThrowing(error)
	}

	/// Adds a closure action which will be performed if the expected call is
	/// made.
	/// - Parameter block: action block
	@discardableResult
	func doing(_ block: @escaping ([Any?]) -> Void) -> Self {
		self.expectation.doing(block)
		return self
	}
}

/// A single expectated call on a mock; created when a test calls
/// `mock.expect`.
private class MockExpectation<M, R>: MockExpectationHandler, AnyExpectation {
	/// The name of the mock (not the name of the expecation)
	private let mockName: String

	/// This is the block that contains the expected call:
	/// `mock.expect { $0.myFunc() }`
	private let callBlock: ((M) throws -> R)?

	/// This is the block that contains the expected call:
	/// `mock.expect { $0.myFunc() }`
	private let asyncCallBlock: ((M) async throws -> R)?

	/// A function that can create a new instance of the mock, with a
	/// different expectation handler.
	///
	/// The first instance of the mock has a handler for consuming expectations.
	/// When `.expect()` is called, a new mock object is created with a handler
	/// for creating expectations.
	private let mockInit: (String, MockExpectationHandler) -> Mock<M>

	/// A set of actions to perform if the expected call is made.
	fileprivate var actions = [([Any?]) -> Void]()

	/// A value that should be returned from the mock function call.
	fileprivate var outcome: CallOutcome<Any, Error>?

	/// The state of this expectation.
	fileprivate var state: ClaimState = .invalid

	/// For async functions, we use this XCTestExpectation to give time for
	/// mock expectation to be fulfilled before verifying.
	fileprivate var testExpectation: XCTestExpectation?

	init(mockName: String, callBlock: @escaping (M) throws -> R, mockInit: @escaping (String, MockExpectationHandler) -> Mock<M>) {
		self.mockName = mockName
		self.callBlock = callBlock
		self.asyncCallBlock = nil
		self.state = .awaitingCallSummary
		self.mockInit = mockInit
	}

	init(mockName: String, callBlock: @escaping (M) async throws -> R, mockInit: @escaping (String, MockExpectationHandler) -> Mock<M>) {
		self.mockName = mockName
		self.callBlock = nil
		self.asyncCallBlock = callBlock
		self.state = .awaitingAsyncCallSummary
		self.mockInit = mockInit
		self.testExpectation = XCTestExpectation()
	}

	/// Adds a return value to the expectation.
	/// - Parameter returnValue: value to return.
	public func returning(_ returnValue: R) {
		self.outcome = .success(returnValue)
	}

	/// Adds an async return value to the expectation.
	/// - Parameter returnValue: value to return asynchronously.
	public func asyncReturning(_ returnValue: R) -> AsyncSuccessOutcome {
		let outcome = AsyncSuccessOutcome(value: returnValue)
		self.outcome = .asyncSuccess(outcome)
		return outcome
	}

	/// Primes this mocked function to throw an error.
	/// - Parameter error: error to throw.
	public func throwing(_ error: Error) {
		self.outcome = .failure(error)
	}

	/// Primes this mocked function to asynchronously throw an error.
	/// - Parameter error: error to throw asynchronously.
	public func asyncThrowing(_ error: Error) -> AsyncFailureOutcome {
		let outcome = AsyncFailureOutcome(error: error)
		self.outcome = .asyncFailure(outcome)
		return outcome
	}

	/// Adds a closure action which will be performed if the expected call is
	/// made.
	/// - Parameter block: action block
	public func doing(_ block: @escaping ([Any?]) -> Void) {
		actions.append(block)
	}
	
	/// Adds the expected function call to this expectation.
	/// - Parameters:
	///   - callSummary: A unique string which describes the call - including
	///   function name and important parameters.
	///   - actionArgs: An array of arguments that should be provided to any
	///   action block. These arguments will not be matched on, in the
	///   expectation.
	///   - file: Calling file.
	///   - line: Calling line.
	/// - Returns: Optional return value.
	public func accept(_ callSummary: String, actionArgs: [Any?], file: StaticString, line: UInt) -> Any? {
		switch self.state {
		case .awaitingCallSummary, .awaitingAsyncCallSummary:
			self.state = .unclaimed(callSummary: callSummary)
		case .invalid:
			break
		case .unclaimed:
			XCTFail("[\(self.mockName)]: Too many expectations in `.expect { }`", file: file, line: line)
			self.state = .invalid
		case .claimed:
			break
		}

		switch self.outcome {
		case nil:
			return nil
		case .success(let returnValue):
			return returnValue
		case .asyncSuccess(let outcome):
			// we're _setting_ the expectations, so should return the value
			// immediately
			return outcome.value
		case .failure, .asyncFailure:
			XCTFail("[\(self.mockName)]: Non-throwing function cannot throw errors", file: file, line: line)
			return nil
		}
	}

	/// Adds the expected function call to this expectation.
	/// - Parameters:
	///   - callSummary: A unique string which describes the call - including
	///   function name and important parameters.
	///   - actionArgs: An array of arguments that should be provided to any
	///   action block. These arguments will not be matched on, in the
	///   expectation.
	///   - file: Calling file.
	///   - line: Calling line.
	/// - Returns: Optional return value.
	public func asyncAccept(_ callSummary: String, actionArgs: [Any?], file: StaticString, line: UInt) async -> Any? {
		return self.accept(callSummary, actionArgs: actionArgs, file: file, line: line)
	}

	/// Adds the expected throwing function call to this expectation.
	/// - Parameters:
	///   - callSummary: A unique string which describes the call - including
	///   function name and important parameters.
	///   - actionArgs: An array of arguments that should be provided to any
	///   action block. These arguments will not be matched on, in the
	///   expectation.
	///   - file: Calling file.
	///   - line: Calling line.
	/// - Returns: Optional return value.
	public func throwingAccept(_ callSummary: String, actionArgs: [Any?], file: StaticString, line: UInt) throws -> Any? {
		switch self.state {
		case .awaitingCallSummary, .awaitingAsyncCallSummary:
			self.state = .unclaimed(callSummary: callSummary)
		case .invalid:
			break
		case .unclaimed:
			XCTFail("[\(self.mockName)]: Too many expectations in `.expect { }`", file: file, line: line)
			self.state = .invalid
		case .claimed:
			break
		}

		switch self.outcome {
		case nil:
			return nil
		case .success(let returnValue):
			return returnValue
		case .asyncSuccess(let outcome):
			// we're _setting_ the expectations, so should return the value
			// immediately
			return outcome.value
		case .failure(let error):
			throw error
		case .asyncFailure(let outcome):
			// we're _setting_ the expectations, so should throw the error
			// immediately
			throw outcome.error
		}
	}

	func asyncThrowingAccept(_ callSummary: String, actionArgs: [Any?], file: StaticString, line: UInt) async throws -> Any? {
		return try throwingAccept(callSummary, actionArgs: actionArgs, file: file, line: line)
	}

	/// This function makes the `callSummary` string, by calling the captured
	/// `callBlock`. The `callSummary` is used for matching expected calls
	/// against actual calls, and contains the expected function name and
	/// important arguments that should be matched.
	fileprivate func makeCallSummary() {
		// this function can only get the `callSummary` for synchronous
		// callblocks
		guard case ClaimState.awaitingCallSummary = self.state,
		self.callBlock != nil else {
			return
		}

		// make an instance of the `M` mock which contains this
		// expectation
		let completionMock = self.mockInit(self.mockName, self) as! M
		_ = try? self.callBlock?(completionMock)

		// if there's still no `callSummary`, then there are no mock function
		// calls in the sync `callBlock`...
		if case ClaimState.awaitingCallSummary = self.state {
			self.state = .invalid
		}
	}

	/// This function makes the `callSummary` string, by calling the captured
	/// `callBlock` or `asyncCallBlock`. The `callSummary` is used for matching
	/// expected calls against actual calls, and contains the expected function
	/// name and important arguments that should be matched.
	fileprivate func asyncMakeCallSummary() async {
		// make an instance of the `M` mock which contains this
		// expectation
		let completionMock = self.mockInit(self.mockName, self) as! M

		if case ClaimState.awaitingCallSummary = self.state,
		   let callBlock {
			// try to get a `callSummary` using the sync callBlock
			_ = try? callBlock(completionMock)

			// if the `callSummary` could not be set, then there's nothing
			// more we can do...
			if case ClaimState.awaitingCallSummary = self.state {
				self.state = .invalid
			}
		}

		if case ClaimState.awaitingAsyncCallSummary = self.state,
		   let asyncCallBlock {
			// try to get a `callSummary` using the async callBlock
			_ = try? await asyncCallBlock(completionMock)

			// if the `callSummary` could not be set, then there's nothing
			// more we can do...
			if case ClaimState.awaitingAsyncCallSummary = self.state {
				self.state = .invalid
			}
		}
	}

	/// Test this expectation to see if its expected call matches the given
	/// `callSummary`.
	/// - Parameter callSummary: The `callSummary` string being handled by the
	/// mock.
	/// - Returns: Bool indicating whether the expectation has been claimed.
	fileprivate func claim(_ callSummary: String) -> Bool {
		// make sure the `callSummary` has been made
		self.makeCallSummary()

		// can only claim this expectation if it's unclaimed
		guard case ClaimState.unclaimed(let expectationCallSummary) = self.state else {
			return false
		}

		if callSummary == expectationCallSummary {
			self.state = .claimed(callSummary: callSummary)
			return true
		}

		return false
	}

	/// Test this expectation to see if its expected call matches the given
	/// `callSummary`.
	/// - Parameter callSummary: The `callSummary` string being handled by the
	/// mock.
	/// - Returns: Bool indicating whether the expectation has been claimed.
	fileprivate func asyncClaim(_ callSummary: String) async -> Bool {
		// make sure the `callSummary` has been made
		await self.asyncMakeCallSummary()

		// can only claim this expectation if it's unclaimed
		guard case ClaimState.unclaimed(let expectationCallSummary) = self.state else {
			return false
		}

		if callSummary == expectationCallSummary {
			self.state = .claimed(callSummary: callSummary)
			return true
		}

		return false
	}
}

extension MockExpectation: CustomDebugStringConvertible {
	public var debugDescription: String {
		switch self.state {
		case .awaitingCallSummary, .awaitingAsyncCallSummary, .invalid:
			return "<unknown>"
		case let .unclaimed(callSummary), let .claimed(callSummary):
			return callSummary
		}
	}
}

/// A protocol for the two types that can accept a mocked function call.
/// * `MockExpectation` builds expectations that the text expects
/// * `MockExpectationConsumer` consumes those expecations when the
/// system-under-test is being exercised
public protocol MockExpectationHandler {
	func accept(_ callSummary: String, actionArgs: [Any?], file: StaticString, line: UInt) -> Any?
	func asyncAccept(_ callSummary: String, actionArgs: [Any?], file: StaticString, line: UInt) async -> Any?
	func throwingAccept(_ callSummary: String, actionArgs: [Any?], file: StaticString, line: UInt) throws -> Any?
	func asyncThrowingAccept(_ callSummary: String, actionArgs: [Any?], file: StaticString, line: UInt) async throws -> Any?
}

/// Maintains a list of expectations on a mock object.
private class MockExpectationCreator<M> {
	/// a collection of built expecations
	var expectations = [AnyExpectation]()
	/// the name of the mock object
	private let mockName: String

	init(mockName: String) {
		self.mockName = mockName
	}
	
	/// Creates a new expectation, which the test can use to configure an
	/// expected function call, its return value and any actions to perform.
	/// - Parameters:
	///   - callBlock: the closure which defines the expected function call
	///   - mockInit:
	/// - Returns: expectation
	func expectation<R>(callBlock: @escaping (M) throws -> R, mockInit: @escaping (String, MockExpectationHandler) -> Mock<M>) -> MockSyncExpectation<M, R> {
		// create the expectation
		let expectation = MockSyncExpectation(mockName: self.mockName, callBlock: callBlock, mockInit: mockInit)
		self.expectations.append(expectation.expectation)
		return expectation
	}

	/// Creates a new expectation, which the test can use to configure an
	/// expected function call, its return value and any actions to perform.
	/// - Parameters:
	///   - callBlock: the closure which defines the expected function call
	///   - mockInit:
	/// - Returns: expectation
	func expectation<R>(callBlock: @escaping (M) async throws -> R, mockInit: @escaping (String, MockExpectationHandler) -> Mock<M>) -> MockAsyncExpectation<M, R> {
		// create the expectation
		let expectation = MockAsyncExpectation(mockName: self.mockName, callBlock: callBlock, mockInit: mockInit)
		self.expectations.append(expectation.expectation)
		return expectation
	}

	/// This creates the `callSummary` string for every expectation. We call
	/// this when the system-under-test needs to verify expectations.
	func makeCallSummaries() {
		for expectation in expectations {
			expectation.makeCallSummary()
		}
	}

	/// This creates the `callSummary` string for every expectation. We call
	/// this when the system-under-test needs to verify expectations.
	func asyncMakeCallSummaries() async {
		for expectation in expectations {
			await expectation.asyncMakeCallSummary()
		}
	}

	/// Used by the expectation consumer to claim an expectation.
	/// - Parameter callSummary: Identifies the expecation being claimed.
	/// - Returns: An expectation, or `nil` if the call was unexpected.
	func claimExpectation(_ callSummary: String) -> AnyExpectation? {
		for expectation in expectations {
			if expectation.claim(callSummary) {
				return expectation
			}
		}

		return nil
	}

	/// Used by the expectation consumer to claim an expectation.
	/// - Parameter callSummary: Identifies the expecation being claimed.
	/// - Returns: An expectation, or `nil` if the call was unexpected.
	func asyncClaimExpectation(_ callSummary: String) async -> AnyExpectation? {
		for expectation in expectations {
			if await expectation.asyncClaim(callSummary) {
				return expectation
			}
		}

		return nil
	}
}

/// This is a call handler which consumes expectation. When the
/// system-under-test calls functions on the mock, this
/// `MockExpectationConsumer` checks that the call was expected, and
/// performs any actions associated with the expectation.
private class MockExpectationConsumer<M>: MockExpectationHandler {
	private let mockName: String
	fileprivate let expectationCreator: MockExpectationCreator<M>

	fileprivate init(mockName: String, expectationCreator: MockExpectationCreator<M>) {
		self.mockName = mockName
		self.expectationCreator = expectationCreator
	}
	
	private func claim(_ callSummary: String, actionArgs: [Any?], file: StaticString, line: UInt) -> AnyExpectation? {
		// try to find an expectation which matches the given `callSummary`
		guard let foundExpectation = expectationCreator.claimExpectation(callSummary) else {
			XCTFail("[\(self.mockName)] Unexpected call: \(callSummary)", file: file, line: line)
			return nil
		}

		// perform actions for this expecatation
		for action in foundExpectation.actions {
			action(actionArgs)
		}

		return foundExpectation
	}

	private func asyncClaim(_ callSummary: String, actionArgs: [Any?], file: StaticString, line: UInt) async -> AnyExpectation? {
		// try to find an expectation which matches the given `callSummary`
		guard let foundExpectation = await expectationCreator.asyncClaimExpectation(callSummary) else {
			XCTFail("[\(self.mockName)] Unexpected call: \(callSummary)", file: file, line: line)
			return nil
		}

		// perform actions for this expecatation
		for action in foundExpectation.actions {
			action(actionArgs)
		}

		foundExpectation.testExpectation?.fulfill()

		return foundExpectation
	}

	func accept(_ callSummary: String, actionArgs: [Any?], file: StaticString, line: UInt) -> Any? {
		// try to find the expectation, and peform actios
		guard let foundExpectation = self.claim(callSummary, actionArgs: actionArgs, file: file, line: line) else {
			return nil
		}

		// and return the return value to the caller
		switch foundExpectation.outcome {
		case nil:
			return nil
		case .success(let returnValue):
			return returnValue
		case .asyncSuccess:
			XCTFail("[\(self.mockName)]: Non-async function cannot return async values", file: file, line: line)
			return nil
		case .failure, .asyncFailure:
			XCTFail("[\(self.mockName)]: Non-throwing function cannot throw errors", file: file, line: line)
			return nil
		}
	}

	func asyncAccept(_ callSummary: String, actionArgs: [Any?], file: StaticString, line: UInt) async -> Any? {
		// try to find the expectation, and peform actios
		guard let foundExpectation = await self.asyncClaim(callSummary, actionArgs: actionArgs, file: file, line: line) else {
			return nil
		}

		// and return the return value to the caller
		switch foundExpectation.outcome {
		case nil:
			return nil
		case .success(let returnValue):
			return returnValue
		case .asyncSuccess(let outcome):
			return await withCheckedContinuation { continuation in
				outcome.continuation = continuation
			}
		case .failure, .asyncFailure:
			XCTFail("[\(self.mockName)]: Non-throwing function cannot throw errors", file: file, line: line)
			return nil
		}
	}

	func throwingAccept(_ callSummary: String, actionArgs: [Any?], file: StaticString, line: UInt) throws -> Any? {
		// try to find the expectation, and peform actios
		guard let foundExpectation = self.claim(callSummary, actionArgs: actionArgs, file: file, line: line) else {
			return nil
		}

		// and return the return value to the caller
		switch foundExpectation.outcome {
		case nil:
			return nil
		case .success(let returnValue):
			return returnValue
		case .asyncSuccess:
			XCTFail("[\(self.mockName)]: Non-async function cannot return async values", file: file, line: line)
			return nil
		case .failure(let error):
			throw error
		case .asyncFailure:
			XCTFail("[\(self.mockName)]: Non-async function cannot asynchronously throw errors", file: file, line: line)
			return nil
		}
	}

	func asyncThrowingAccept(_ callSummary: String, actionArgs: [Any?], file: StaticString, line: UInt) async throws -> Any? {
		// try to find the expectation, and peform actios
		guard let foundExpectation = await self.asyncClaim(callSummary, actionArgs: actionArgs, file: file, line: line) else {
			return nil
		}

		// and return the return value to the caller
		switch foundExpectation.outcome {
		case nil:
			return nil
		case .success(let returnValue):
			return returnValue
		case .asyncSuccess(let outcome):
			return await withCheckedContinuation { continuation in
				outcome.continuation = continuation
			}
		case .failure(let error):
			throw error
		case .asyncFailure(let outcome):
			try await withCheckedThrowingContinuation { continuation in
				outcome.continuation = continuation
			}
		}
	}
}

/// The base class for a Mock object.
open class Mock<M> {
	private let name: String
	private let expectationHandler: MockExpectationHandler
	
	/// Creates a mock object with the given name. If `name` is not provided,
	/// then a name of the mocked protocol (`M`) will be used.
	/// - Parameter name: Mock name.
	/// - Returns: A mock object for the `M` protocol.
	public static func create(mockName name: String? = nil) -> Self {
		let mockName = name ?? String(describing: M.self)
		let expectationCreator = MockExpectationCreator<M>(mockName: mockName)
			let expectationConsumer = MockExpectationConsumer(mockName: mockName, expectationCreator: expectationCreator)

		let consumerMock = self.init(name: mockName, expectationHandler: expectationConsumer)

		return consumerMock
	}
	
	public required init(name: String, expectationHandler: MockExpectationHandler) {
		self.name = name
		self.expectationHandler = expectationHandler
	}
	
	/// Creates an expectation for a function call.
	/// - Parameter callBlock: A block containing the expected function call.
	/// - Returns: An expectation which may contain a call outcome and actions.
	@discardableResult
	public func expect<R>(_ callBlock: @escaping (M) throws -> R) -> MockSyncExpectation<M, R> {
		guard let expectationCreator = (expectationHandler as? MockExpectationConsumer<M>)?.expectationCreator else {
			preconditionFailure("internal error")
		}
		
		return expectationCreator.expectation(callBlock: callBlock, mockInit: type(of: self).init)
	}

	/// Creates an expectation for a function call.
	/// - Parameter callBlock: A block containing the expected function call.
	/// - Returns: An expectation which may contain a call outcome and actions.
	@discardableResult
	public func expect<R>(_ callBlock: @escaping (M) async throws -> R) -> MockAsyncExpectation<M, R> {
		guard let expectationCreator = (expectationHandler as? MockExpectationConsumer<M>)?.expectationCreator else {
			preconditionFailure("internal error")
		}

		return expectationCreator.expectation(callBlock: callBlock, mockInit: type(of: self).init)
	}

	/// Verifies that the expectated function calls have all been satisfied.
	/// - Parameters:
	///   - file: Calling file.
	///   - line: Calling line.
	public func verify(file: StaticString = #file, line: UInt = #line) {
		guard let expectationConsumer = expectationHandler as? MockExpectationConsumer<M> else {
			preconditionFailure("internal error")
		}
		
		let expectationCreator = expectationConsumer.expectationCreator
		
		// make sure all the `callSummary` values are built
		expectationCreator.makeCallSummaries()

		let unclaimedExpectations = expectationCreator.expectations.filter {
			switch $0.state {
			case .invalid, .claimed:
				return false
			case .awaitingCallSummary, .awaitingAsyncCallSummary, .unclaimed:
				return true
			}
		}
		
		if !unclaimedExpectations.isEmpty {
			for unclaimedExpectation in unclaimedExpectations {
				let expectationDescription = String(describing: unclaimedExpectation)
				XCTFail("[\(self.name)] Unsatisfied expectation: \(expectationDescription)", file: file, line: line)
			}
		}
		
		// remove all expectations, so they don't fail again
		// later in the test
		expectationCreator.expectations.removeAll()
	}

	/// Verifies that the expectated function calls have all been satisfied.
	/// - Parameters:
	///   - file: Calling file.
	///   - line: Calling line.
	public func verify(file: StaticString = #file, line: UInt = #line) async {
		guard let expectationConsumer = expectationHandler as? MockExpectationConsumer<M> else {
			preconditionFailure("internal error")
		}

		let expectationCreator = expectationConsumer.expectationCreator

		// make sure all the sync and async `callSummary` values are built
		expectationCreator.makeCallSummaries()
		await expectationCreator.asyncMakeCallSummaries()

		// wait for the XCTestExpectation for every async call to be fulfilled,
		// before we verify the expectations
		for expectation in expectationCreator.expectations {
			if let testExpectation = expectation.testExpectation {
				// run this in a synchronous context
				{
					_ = XCTWaiter().wait(for: [testExpectation], timeout: 0.5)
				}()
			}
		}

		let unclaimedExpectations = expectationCreator.expectations.filter {
			switch $0.state {
			case .invalid, .claimed:
				return false
			case .awaitingCallSummary, .awaitingAsyncCallSummary, .unclaimed:
				return true
			}
		}

		if !unclaimedExpectations.isEmpty {
			for unclaimedExpectation in unclaimedExpectations {
				let expectationDescription = String(describing: unclaimedExpectation)
				XCTFail("[\(self.name)] Unsatisfied expectation: \(expectationDescription)", file: file, line: line)
			}
		}

		// remove all expectations, so they don't fail again
		// later in the test
		expectationCreator.expectations.removeAll()
	}

	/// A concrete mock object should call one of the `accept()` functions
	/// whenever a call to a mocked function is made.
	/// - Parameters:
	///   - func: The name of the mocked function.
	///   - args: A collection of arguments that should be matched.
	///   - file: Calling file.
	///   - line: Calling line.
	/// - Returns: The optional return value for the mocked function.
	@discardableResult
	public func accept(func: String = #function, args: [Any?] = [], file: StaticString = #file, line: UInt = #line) -> Any? {
		return accept(func: `func`, checkArgs: args, actionArgs: args, file: file, line: line)
	}
	
	@discardableResult
	/// A concrete mock object should call one of the `accept()` functions
	/// whenever a call to a mocked function is made.
	/// - Parameters:
	///   - func: The name of the mocked function.
	///   - checkArgs: A collection of arguments that should be matched.
	///   - actionArgs: A collection of arguments that should not be matched,
	///   but may be given to any action closures associated with this call.
	///   - file: Calling file.
	///   - line: Calling line.
	/// - Returns: The optional return value for the mocked function.
	public func accept(func: String = #function, checkArgs: [Any?], actionArgs: [Any?], file: StaticString = #file, line: UInt = #line) -> Any? {
		var callSummary = "\(`func`)"
		if checkArgs.count > 0 {
			callSummary += " " + summary(for: checkArgs)
		}
		
		return expectationHandler.accept(callSummary, actionArgs: actionArgs, file: file, line: line)
	}

	/// A concrete mock object should call one of the `throwingAccept()`
	/// functions whenever a call to a mocked throwing function is made.
	/// - Parameters:
	///   - func: The name of the mocked function.
	///   - args: A collection of arguments that should be matched.
	///   - file: Calling file.
	///   - line: Calling line.
	/// - Returns: The optional return value for the mocked function.
	@discardableResult
	public func throwingAccept(func: String = #function, args: [Any?] = [], file: StaticString = #file, line: UInt = #line) throws -> Any? {
		return try throwingAccept(func: `func`, checkArgs: args, actionArgs: args, file: file, line: line)
	}

	@discardableResult
	/// A concrete mock object should call one of the `throwingAccept()`
	/// functions whenever a call to a mocked throwing function is made.
	/// - Parameters:
	///   - func: The name of the mocked function.
	///   - checkArgs: A collection of arguments that should be matched.
	///   - actionArgs: A collection of arguments that should not be matched,
	///   but may be given to any action closures associated with this call.
	///   - file: Calling file.
	///   - line: Calling line.
	/// - Returns: The optional return value for the mocked function.
	/// - Throws: May throw errors when the expecations are being consumed. Will not throw when expectations are being set.
	public func throwingAccept(func: String = #function, checkArgs: [Any?], actionArgs: [Any?], file: StaticString = #file, line: UInt = #line) throws -> Any? {
		var callSummary = "\(`func`)"
		if checkArgs.count > 0 {
			callSummary += " " + summary(for: checkArgs)
		}

		return try expectationHandler.throwingAccept(callSummary, actionArgs: actionArgs, file: file, line: line)
	}

	/// A concrete mock object should call one of the `accept()` functions
	/// whenever a call to a mocked function is made.
	/// - Parameters:
	///   - func: The name of the mocked function.
	///   - args: A collection of arguments that should be matched.
	///   - file: Calling file.
	///   - line: Calling line.
	/// - Returns: The optional return value for the mocked function.
	@discardableResult
	public func accept(func: String = #function, args: [Any?] = [], file: StaticString = #file, line: UInt = #line) async -> Any? {
		return await accept(func: `func`, checkArgs: args, actionArgs: args, file: file, line: line)
	}

	@discardableResult
	/// A concrete mock object should call one of the `accept()` functions
	/// whenever a call to a mocked function is made.
	/// - Parameters:
	///   - func: The name of the mocked function.
	///   - checkArgs: A collection of arguments that should be matched.
	///   - actionArgs: A collection of arguments that should not be matched,
	///   but may be given to any action closures associated with this call.
	///   - file: Calling file.
	///   - line: Calling line.
	/// - Returns: The optional return value for the mocked function.
	public func accept(func: String = #function, checkArgs: [Any?], actionArgs: [Any?], file: StaticString = #file, line: UInt = #line) async -> Any? {
		var callSummary = "\(`func`)"
		if checkArgs.count > 0 {
			callSummary += " " + summary(for: checkArgs)
		}

		return await expectationHandler.asyncAccept(callSummary, actionArgs: actionArgs, file: file, line: line)
	}

	/// A concrete mock object should call one of the `throwingAccept()`
	/// functions whenever a call to a mocked throwing function is made.
	/// - Parameters:
	///   - func: The name of the mocked function.
	///   - args: A collection of arguments that should be matched.
	///   - file: Calling file.
	///   - line: Calling line.
	/// - Returns: The optional return value for the mocked function.
	@discardableResult
	public func throwingAccept(func: String = #function, args: [Any?] = [], file: StaticString = #file, line: UInt = #line) async throws -> Any? {
		return try await throwingAccept(func: `func`, checkArgs: args, actionArgs: args, file: file, line: line)
	}

	@discardableResult
	/// A concrete mock object should call one of the `throwingAccept()`
	/// functions whenever a call to a mocked throwing function is made.
	/// - Parameters:
	///   - func: The name of the mocked function.
	///   - checkArgs: A collection of arguments that should be matched.
	///   - actionArgs: A collection of arguments that should not be matched,
	///   but may be given to any action closures associated with this call.
	///   - file: Calling file.
	///   - line: Calling line.
	/// - Returns: The optional return value for the mocked function.
	/// - Throws: May throw errors when the expecations are being consumed. Will not throw when expectations are being set.
	public func throwingAccept(func: String = #function, checkArgs: [Any?], actionArgs: [Any?], file: StaticString = #file, line: UInt = #line) async throws -> Any? {
		var callSummary = "\(`func`)"
		if checkArgs.count > 0 {
			callSummary += " " + summary(for: checkArgs)
		}

		return try await expectationHandler.asyncThrowingAccept(callSummary, actionArgs: actionArgs, file: file, line: line)
	}

	private func summary(for argument: Any) -> String {
		switch argument {
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
		case  Optional<Any>.none:
			// for nil values (Optional.none), return "nil"
			return "nil"
		case Optional<Any>.some(let value):
			// for non-nil values (Optional.some), return the unwrapped value
			return String(describing: value)
		default:
			preconditionFailure("don't expect this to happen, because we're already handling Optional.none and Optional.some")
		}
	}
}
