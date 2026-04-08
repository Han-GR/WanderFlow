import Foundation

enum Debounce {
    static func schedule(task: inout Task<Void, Never>?, delayNanoseconds: UInt64, action: @escaping @MainActor () -> Void) {
        task?.cancel()
        task = Task { @MainActor in
            try? await Task.sleep(nanoseconds: delayNanoseconds)
            if Task.isCancelled { return }
            action()
        }
    }
}

