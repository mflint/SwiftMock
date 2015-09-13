
public protocol ReplaceMe {
    func expect() -> MockExpectation
    func reject() -> MockExpectation
    func stub() -> MockExpectation
    
    func verify()
}