import Foundation
import Combine

public final class ComponentContext: ObservableObject {
    public let id: String

    @Published public var isDisabled: Bool = false

    private var stateStore: [String: Any] = [:]
    private var publishers: [String: Any] = [:]

    public init(id: String) {
        self.id = id
    }

    public func state<T>(for key: String, default defaultValue: T) -> T {
        (stateStore[key] as? T) ?? defaultValue
    }

    public func setState<T>(_ value: T, for key: String) {
        stateStore[key] = value
        if let subject = publishers[key] as? CurrentValueSubject<T, Never> {
            subject.send(value)
        }
    }

    public func publisher<T>(for key: String, default defaultValue: T) -> AnyPublisher<T, Never> {
        if let existing = publishers[key] as? CurrentValueSubject<T, Never> {
            return existing.eraseToAnyPublisher()
        }
        let subject = CurrentValueSubject<T, Never>(state(for: key, default: defaultValue))
        publishers[key] = subject
        return subject.eraseToAnyPublisher()
    }
}
