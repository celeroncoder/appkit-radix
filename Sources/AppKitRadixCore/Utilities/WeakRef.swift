import Foundation

public final class WeakRef<T: AnyObject> {
    public private(set) weak var value: T?

    public init(_ value: T) {
        self.value = value
    }
}
