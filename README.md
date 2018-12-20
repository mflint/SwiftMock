# SwiftMock

[![CI Status](http://img.shields.io/travis/mflint/SwiftMock.svg?style=flat)](https://travis-ci.org/mflint/SwiftMock)
[![Version](https://img.shields.io/cocoapods/v/SwiftMock.svg?style=flat)](http://cocoapods.org/pods/SwiftMock)
[![License](https://img.shields.io/cocoapods/l/SwiftMock.svg?style=flat)](http://cocoapods.org/pods/SwiftMock)
[![Platform](https://img.shields.io/cocoapods/p/SwiftMock.svg?style=flat)](http://cocoapods.org/pods/SwiftMock)

_SwiftMock_ is a mocking framework for Swift 4.2.

## Notes on the history of this repo

* September 2015: first version of this framework
* November 2016: Marked the project as "unmaintained", with a comment "just write fakes instead"
* November 2018: Rewrote this for Swift 4.2, with much simpler code

I spent a while using fakes (test-doubles which implement a prototol and simply set various `methodWasCalled` flags), but this doesn't scale well. It's easy to forget to make assertions, especially if a new function is added to a protocol long after the protocol's fake was written. I've since migrated a lot of code to using this new Mock, and it's _amazing_ how many defects I've found. Mocks FTW!

## Limitations

* Developers need to be aware of the difference between calls which should be mocked, and those which shouldn't (ie, simple stubs)
  * if the function in the collabotor class _performs an operation_ (starting a network request, logging-out a user, starting a timer), then it's good for mocking
  * if the function returns a value, which your system-under-test uses to make a decision, and that decision is asserted elsewhere in your test code, then that function is _not_ a suitable candidate for mocking
* You may sometimes need to customise the arguments which are passed into the ```accept``` call
* Not all test-failure scenarios can report exactly where the failure occurred
* It's possible for calls to get confused if a mock has two functions with the same name and similar arguments - but that seems unlikely to me. (Example: ```object.function(42)``` and ```object.function("42")```)

## Usage

The examples below assume we're mocking this protocol:

```swift
protocol Frood {
    func voidFunction(value: Int)
    func function() -> String
    func performAction(value: String, completion: @escaping () -> Void)
}
```

In your test target, you'll need to create a ```MockFrood```, which extends ```Mock``` with a specialised type ```Frood``` and also adopts ```Frood```.

```swift
public class MockFrood: Mock<Frood>, Frood {
    func voidFunction(value: Int) {
        accept(args: [value])
    }

    func function() -> String {
        return accept() as! String
    }

    func performAction(value: String, completion: @escaping () -> Void) {
        accept(checkArgs: [value], actionArgs: [completion])
    }
}
```

Then create the mock in your test class, using `MockThing.create()`. A test class would typically look something like this:

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
        mockFrood.expect { f in f.voidFunction() }
        
        // when
        thing.hoopy()
        
        // then
        verify()
    }
```

The original version of _SwiftMock_ had explicit matcher classes for various types; this newer version simply converts each argument to a `String`, and matches on those `String` arguments. You can often simply `accept` the arguments themseves, but sometimes you'll want to be more specific about what you pass into the `accept` function.

I'd probably put the mock objects in a separate group in the test part of my project.

### Currently-supported syntax

_SwiftMock_ syntax requires the expected call in a block; this might look weird at first, but means that we have a readable way of setting expectations, and we know the return value _before_ the expected function is called.

```swift
// expect a call on a void function
mockObject.expect { o in o.voidFunction(42) }
...
mockObject.verify()
```

```swift
// expect a call on a function which returns a String value
mockObject.expect { o in o.functionReturningString() }.returning("dent")
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

Mocks are strict. This means they will reject _any_ unexpected call.


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
        // calling accept(arg) here might not work well - so you can
        // select the important (identifying) parts of the struct
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
