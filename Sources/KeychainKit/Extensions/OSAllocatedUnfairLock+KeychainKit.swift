
internal import os.lock

extension OSAllocatedUnfairLock where State == Void {

    internal borrowing func withLock<Failure, Result>(throwing: Failure.Type = Failure.self, perform body: @Sendable () throws(Failure) -> Result) throws(Failure) -> Result where Result: Sendable {
        self.lock()

        defer { self.unlock() }

        return try body()
    }
}
