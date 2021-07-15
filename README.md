# SwiftMock

![](https://img.shields.io/badge/maintained-yes-green.svg)
![](https://img.shields.io/github/license/mflint/SwiftMock.svg)
![](https://img.shields.io/badge/platform-ios%20|%20osx%20|%20watchos%20|%20tvos-green.svg)
![](https://img.shields.io/badge/swift_version-5.2-green.svg)

_SwiftMock_ is a mocking framework for Swift 5.2.

## Notes on the history of this repo

* September 2015: first version of this framework
* November 2016: Marked the project as "unmaintained", with a comment "just write fakes instead"
* November 2018: Rewrote this for Swift 4.2, with much simpler code
* May 2020: Minor changes

I spent a while using fakes (test-doubles which implement a prototol and simply set various `methodWasCalled` flags), but this doesn't scale well. It's easy to forget to make assertions, especially if a new function is added to a protocol long after the protocol's fake was written. I've since migrated a lot of code to using this new Mock, and it's _amazing_ how many defects I've found. Mocks FTW!

## Versioning

_SwiftMock_ versions track the major/minor version of Swift itself, so you can easily find a tag for a version of SwiftMock which works with your version of Swift.

## Limitations

* Developers need to be aware of the difference between calls which should be mocked, and those which shouldn't (ie, simple stubs)
  * if the function in the collabotor class _performs an operation_ (starting a network request, logging-out a user, starting a timer), then it's good for mocking
  * if the function returns a value which your system-under-test uses to make a decision, and that decision is asserted elsewhere in your test code, _and_ the function doesn't have any side-effects, then that function is _not_ a suitable candidate for mocking
* No built-in support for stubbing calls. (This is calls which return a given value, but their use isn't asserted by the mock object)
* You may sometimes need to customise the arguments which are passed into the ```accept``` call
* Not all test-failure scenarios can report exactly where the failure occurred
* It's possible for calls to get confused if a mock has two functions with the same name and similar arguments - but that seems unlikely to me. (Example: ```object.function(42)``` and ```object.function("42")```)

The decision whether to "mock or stub" depends on what the function does. As an example, these two functions have similar method signatures:

* `func isButtonEnabled() -> Bool`
* `func saveValuesToKeychain() -> Bool`

Both have no arguments, and both return a Bool - but they are very different:

* `isButtonEnabled()` returns a boolean based on some internal logic. Your system-under-test will probably take that boolean value and use it to do something else, like calling `self.button.setEnabled(enabled)` - so your test would probably assert the state of the button is correct, and there's no need to check that `isButtonEnabled()` is called. _We care that the outcome is correct, not how the system-under-test decided to do the correct thing._ This doesn't need to be mocked.
* `saveValuesToKeychain()`  is a command; our system-under-test is asking the mocked collaborator to do some useful work. In this case, we _really do care_ that the function is called, so it should be mocked.

## Usage

The examples below assume we're mocking this protocol:

```swift
protocol Frood {
    func voidFunction(value: Int)
    func functionReturningString() -> String
    func performAction(value: String, completion: @escaping () -> Void)
}
```

In your test target you'll need to create a ```MockFrood``` which extends ```Mock``` with a generic type parameter ```Frood```. It must also adopt the ```Frood``` protocol.

```swift
class MockFrood: Mock<Frood>, Frood {
    func voidFunction(value: Int) {
        accept(args: [value])
    }

    func functionReturningString() -> String {
        return accept() as! String
    }

    func performAction(value: String, completion: @escaping () -> Void) {
        accept(checkArgs: [value], actionArgs: [completion])
    }
}
```

Then create the mock in your test class, using `MockFrood.create()`. A test class would typically look something like this:

```swift
class MyTests: XCTestCase {
    private let mockFrood = MockFrood.create()
    
    private func verify(file: StaticString = #file,
                        line: UInt = #line) {
        mockFrood.verify(file: file, line: line)
    }
    
    func test_something() {
        // given
        let thing = MyThing(frood: mockFrood)
        
        // expect
        mockFrood.expect { f in f.voidFunction(value: 42) }
        
        // when
        thing.hoopy()
        
        // then
        verify()
    }
```

This gives you the following behaviour:

* `verify()` will fail the test if `voidFunction()` wasn't called exactly once with the value `42`
* the mock will fast-fail the test if any other (unexpected) function is called on the mock

The original version of _SwiftMock_ had explicit matcher classes for various types; this newer version simply converts each argument to a `String`, and matches on those `String` arguments. You can often simply `accept` the arguments themseves, but sometimes you'll want to be more specific about what you pass into the `accept` function.

I'd probably put the mock objects in a separate group in the test part of my project.

### Currently-supported syntax

_SwiftMock_ syntax requires the expected call in a block; this might look weird at first, but means that we have a readable way of setting expectations, and we know the return value _before_ the expectation is set.

```swift
// expect a call on a void function
mockObject.expect { o in o.voidFunction(42) }
...
mockObject.verify()
```

```swift
// expect a call on a function which returns a String value
// this uses the $0 _shorthand argument name_, if you prefer that style
mockObject.expect { $0.functionReturningString() }.returning("dent")
...
mockObject.verify()
```

```swift
// expect a call on a function which returns a String value, and also call a block
mockObject.expect { o in
        o.functionReturningString()
    }.doing { actionArgs in
        print("frood")
    }.returning("dent")
...
mockObject.verify()
```

Mocks are strict. This means they will reject _any_ unexpected call. If this annoys you, then perhaps you should be stubbing those calls instead of mocking?


## Various ways to call the "accept" function when writing your Mock object

```swift
// simplest use-case - mocking a function which takes no arguments and
// returns no value

class Mock<Protocol>, Protocol {
    func myFunc() {
        accept()
    }
}
```

```swift
// mocking a function which returns a value
// this uses a force-cast, but in test code I guess we can live with it

class Mock<Protocol>, Protocol {
    func myFunc() -> String {
        return accept() as! String
    }
}
```

```swift
// mocking a function which takes some arguments which must match the
// expected values. SwiftMock will convert each argument to a String
// and match them all

class Mock<Protocol>, Protocol {
    func myFunc(personName: String, yearOfBirth: Int) {
        accept(args: [personName, yearOfBirth])
    }
}
```

```swift
// mocking a function which takes parameter with a custom type

struct Employee {
    let personID: UUID
    let personName: String
    let roles: [Role]
}

class Mock<Protocol>, Protocol {
    func myFunc(employee: Employee) {
        // calling `accept(args: [employee])` here will not work well - so
        // you should pass the important (identifying) parts of the struct
		// instead
        accept(args: [employee.personID, employee.personName])
    }
}
```

```swift
// specifying the function name explicitly
// SwiftMock's accept call has a func parameter with a default value of
// #func. This works most of the time, but you may wish to override it

class Mock<Protocol>, Protocol {
    func myFunc(value: Int) {
        accept(func: "functionName", args: [value])
    }
}
```

```swift
// you can set expectations that a property is set by using `didSet`
// in your Mock object

protocol ProtocolWithProperty: AnyObject {
    var value: Int { get set }
}

class MockObject: Mock<ProtocolWithProperty>, ProtocolWithProperty {
    var value: Int = 0 {
        didSet {
            accept(args: [value])
        }
    }
}

// usage in the test class

class ExampleTests: XCTestCase {
    let mock = MockObject.create()
    
    func test_withProperty() {
        // expect
        mock.expect { $0.value = 42 }
        
        // when
        ...
        
        // then
        mock.verify()
    }
}
```

```swift
// arguments which are unknown - example: a completion block which should be captured

// here, the "url" argument is known by the test (and we expect it to be correct),
// but the "completion" block argument must be captured by the test. So "checkArgs"
// are used to check the function was called with the expected parameters, while
// "actionArgs" are ignored by the matching code, and passed into any "doing" block

class Mock<Protocol>, Protocol {
    func getWebContent(url: URL, completion: (Data) -> Void) -> RequestState {
        return accept(checkArgs: [url], actionArgs:[completion]) as! RequestState
    }
}


// usage in the test class

var capturedCompletionBlock: ((Data) -> Void)?

myMock.expect { m in
        m.getWebContent(url: expectedURL, completion: { data in })
    }.doing { actionArgs in
        capturedCompletionBlock = actionArgs[0] as? (Data) -> Void
    }.returning(.requesting)


// then later, call that captured block to simulate an incoming response
capturedCompletionBlock?(response)
```

## Installation

The code is all in one file - so the easiest way to use _SwiftMock_ is to simply copy `Mock.swift` into your project.

## Feedback

Issues and pull-requests most welcome.

## Author

Matthew Flint, m@tthew.org

## License

_SwiftMock_ is available under the MIT license. See the LICENSE file for more info.
