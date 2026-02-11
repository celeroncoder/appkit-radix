import Foundation
import Combine

public final class Presence: ObservableObject {
    @Published public var isPresent: Bool
    @Published public private(set) var isMounted: Bool

    public var forceMount: Bool = false
    public var exitDuration: TimeInterval = 0

    private var cancellables = Set<AnyCancellable>()
    private var exitWorkItem: DispatchWorkItem?

    public init(isPresent: Bool = false) {
        self.isPresent = isPresent
        self.isMounted = isPresent

        $isPresent
            .removeDuplicates()
            .sink { [weak self] present in self?.handleChange(present) }
            .store(in: &cancellables)
    }

    private func handleChange(_ present: Bool) {
        exitWorkItem?.cancel()

        if present {
            isMounted = true
        } else if forceMount {
            // Keep mounted
        } else if exitDuration > 0 {
            let item = DispatchWorkItem { [weak self] in self?.isMounted = false }
            exitWorkItem = item
            DispatchQueue.main.asyncAfter(deadline: .now() + exitDuration, execute: item)
        } else {
            isMounted = false
        }
    }
}
