# SwiftMock

[![CI Status](http://img.shields.io/travis/mflint/SwiftMock.svg?style=flat)](https://travis-ci.org/mflint/SwiftMock)
<!---
[![Version](https://img.shields.io/cocoapods/v/SwiftMock.svg?style=flat)](http://cocoapods.org/pods/SwiftMock)
[![License](https://img.shields.io/cocoapods/l/SwiftMock.svg?style=flat)](http://cocoapods.org/pods/SwiftMock)
[![Platform](https://img.shields.io/cocoapods/p/SwiftMock.svg?style=flat)](http://cocoapods.org/pods/SwiftMock)
-->

*SwiftMock* is a first attempt at a mocking/stubbing framework for Swift 2.0. It's in the very earliest stage of development, but may be almost usable.

I'm posting it publicly to get some feedback on its API, as used in your tests.

**Note: This is a Swift 2.0 project, so requires Xcode 7.0 to build.**

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

Unfortunately, there's some boiler-plate code needed to create mocks. See ```MockExampleCollaborator``` for an example. The mock simply forwards calls onto a ```MockCallHandler```.

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

### Future stuff

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

Mocks are currently strict, but with nice mocks we could also support the newer "verify expectations after" mocking:

```
// prod the system under test
systemUnderTest.prod()

// then verify that a function was called
mockObject.verify().call(mockObject.function())
```

... but I don't suppose we'd be able to feed return values back into the system. Hmm...

## Requirements

## Installation

SwiftMock is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile against your test target:

```ruby
pod "SwiftMock"
```

```ExampleTests.swift``` should be a good starting-point.

## Author

Matthew Flint, m@tthew.org

## License

SwiftMock is available under the MIT license. See the LICENSE file for more info.
