
import Observation
import Synchronization

internal func withObservationTrackingOnce<R>(_ apply: () -> R, willSet: @escaping @Sendable () -> Void) -> R {
    let hasObserved: Atomic<Bool> = Atomic(false)
    return withObservationTracking(apply) {
        let (exchanged, _) = hasObserved.compareExchange(expected: false, desired: true, ordering: .relaxed)
        if exchanged {
            willSet()
        }
    }
}
