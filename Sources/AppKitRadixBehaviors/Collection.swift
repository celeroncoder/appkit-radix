import Foundation
import Combine

public final class PrimitiveCollection<Item: Hashable>: ObservableObject {
    @Published public private(set) var items: [Item] = []

    public init() {}

    public func register(_ item: Item) {
        guard !items.contains(item) else { return }
        items.append(item)
    }

    public func unregister(_ item: Item) {
        items.removeAll { $0 == item }
    }

    public func item(at index: Int) -> Item? {
        items.indices.contains(index) ? items[index] : nil
    }

    public func index(of item: Item) -> Int? {
        items.firstIndex(of: item)
    }
}
