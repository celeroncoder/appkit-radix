import Combine

public enum CheckedState: Hashable, Sendable {
    case checked
    case unchecked
    case indeterminate
}

public protocol CheckedStateManaging: AnyObject {
    var checkedState: CheckedState { get }
    var checkedPublisher: AnyPublisher<CheckedState, Never> { get }
    var defaultChecked: CheckedState { get set }
    func setChecked(_ state: CheckedState)
    var onCheckedChange: ((CheckedState) -> Void)? { get set }
}
