# SwiftMock

[![CI Status](http://img.shields.io/travis/mflint/SwiftMock.svg?style=flat)](https://travis-ci.org/mflint/SwiftMock)
[![Version](https://img.shields.io/cocoapods/v/SwiftMock.svg?style=flat)](http://cocoapods.org/pods/SwiftMock)
[![License](https://img.shields.io/cocoapods/l/SwiftMock.svg?style=flat)](http://cocoapods.org/pods/SwiftMock)
[![Platform](https://img.shields.io/cocoapods/p/SwiftMock.svg?style=flat)](http://cocoapods.org/pods/SwiftMock)

*SwiftMock* is a first attempt at a mocking/stubbing framework for Swift 2.0. It's at an early stage of development, but may be usable.

I'm posting it publicly to get some feedback on its API, as used in your tests.

**Note: This is a Swift 2.0 project, so requires Xcode 7.0 to build.**

## Limitations

* There's some boiler-plate code needed to create mocks. See ```MockExampleCollaborator``` for an example, and the *Usage* section below
* No support (yet) for stubbing, explicitly rejecting calls, call counts or nice mocks
* No support (yet) for "any value" matchers
* Not all failure scenarios can report exactly where the failure occurred

## Usage

There's an example test file called ```ExampleTests.swift```. Look there for some tests that can be run. This tests a class ```Example``` against a mocked collaborator ```ExampleCollaborator```.

The examples below assume we're mocking this protocol:

```
protocol Frood {
    func voidFunction(value: Int)
    func function() -> String
    func anotherFunction(value: String)
}
```

In your test code, you'll need to create a ```MockFrood```, which extends ```Frood``` and adopts ```Mock```. The mock creates a ```MockCallHandler```, and forwards all calls to it:

```
public class MockFrood: Frood, Mock {
    let callHandler: MockCallHandler
    
    init(testCase: XCTestCase) {
        callHandler = MockCallHandlerImpl(testCase)
    }
    
    override func voidFunction(int: Int) {
        // the first argument is the value returned by the mock
        // while setting expectations. In this case, we can use nil
        // as it returns Void
        callHandler.accept(nil, functionName: __FUNCTION__, args: int)
    }
    
    override func function() -> String {
        // here, the return type is String, so the first argument
        // is a String. Any String will do.
        return callHandler.accept("", functionName: __FUNCTION__, args: nil) as! String
    }

    override func anotherFunction(value: String) {
        callHandler.accept(nil, functionName: __FUNCTION__, args: value)
    }
}
```

Out of the box, *SwiftMock* can match the following types:

* String / String?
* Int / Int?
* Double / Double?
* Array / Array?
* Dictionary / Dictionary?
* *raise an issue if I'm missing any common types*

Given that Swift doesn't have reflection, *SwiftMock* can't magically match your custom types, so you'd need to make an extension for ```MockMatcher``` which adopts ```MockMatcherExtension```:

```
extension MockMatcher: MockMatcherExtension {
    public func match(item1: Any?, _ item2: Any?) -> Bool {
        switch item1 {
        case let first as MyCustomType:
            if let second = item2 as? MyCustomType {
                // custom matching code here //
                return true
            }
        default:
            return false
        }
    }
}
```

I'd probably put the mock objects and custom matcher code in a separate group in the test part of my project.

### Currently-supported syntax

```
// expect a call on a void function
mockObject.expect().call(mockObject.voidFunction(42))
...
mockObject.verify()
```

```
// expect a call on a function which returns a String value
mockObject.expect().call(mockObject.function()).andReturn("dent")
...
mockObject.verify()
```

```
// expect a call on a function which returns a String value, and also call a closure
mockObject.expect().call(mockObject.function()).andReturn("dent").andDo({
    print("frood")
})
...
mockObject.verify()
```

```
// expect a call on a function, use a closure to return a String value
mockObject.expect().call(mockObject.function()).andReturnValue({ () in
    return "dent"
})
...
mockObject.verify()
```

### Future stuff

```
// expect a call with any String parameter
mockObject.expect().call(mockObject.anotherFunction(mockObject.anyString()))
...
mockObject.verify()
```

```
// expect a call with any String parameter, and capture it using a block
mockObject.expect().call(mockObject.anotherFunction(mockObject.anyString())).andCapture{ (parameters: Dictionary) in
    // parameters dictionary contains the function parameters
})
...
mockObject.verify()
```

```
// stub a call
mockObject.stub().call(mockObject.function()).andReturn("dent")
```

```
// reject a call
mockObject.reject().call(mockObject.function())
```

Mocks are currently strict, but with nice mocks we could also support the newer "verify expectations after mocking" style:

```
// prod the system under test
systemUnderTest.prod()

// then verify that a function was called
mockObject.verify().call(mockObject.function())
```

... but I don't suppose we'd be able to feed return values back into the system. Hmm...

## Requirements

* Xcode 7
* XCTest

## Installation

SwiftMock is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile against your test target:

```ruby
pod "SwiftMock"
```

## Feedback

Issues and pull-requests most welcome - especially feedback on any Bad Swift you might find :-)

## Author

Matthew Flint, m@tthew.org

## License

*SwiftMock* is available under the MIT license. See the LICENSE file for more info.
