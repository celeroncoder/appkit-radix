import Combine

public protocol OpenStateManaging: AnyObject {
    var isOpen: Bool { get }
    var isOpenPublisher: AnyPublisher<Bool, Never> { get }
    var defaultOpen: Bool { get set }
    func setOpen(_ open: Bool)
    var onOpenChange: ((Bool) -> Void)? { get set }
}
