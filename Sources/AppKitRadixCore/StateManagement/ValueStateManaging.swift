import Combine

public protocol ValueStateManaging: AnyObject {
    associatedtype Value: Hashable
    var value: Value? { get }
    var valuePublisher: AnyPublisher<Value?, Never> { get }
    var defaultValue: Value? { get set }
    func setValue(_ value: Value?)
    var onValueChange: ((Value?) -> Void)? { get set }
}
