
import os.lock

extension OSAllocatedUnfairLock {

    internal borrowing func withLock<Failure, Result>(throwing: Failure.Type = Failure.self, perform body: @Sendable (inout State) throws(Failure) -> Result) throws(Failure) -> Result where Result: Sendable {
        do {
            return try self.withLock { state in
                return try body(&state)
            }
        } catch let error as Failure {
            throw error
        } catch {
            fatalError()
        }
    }
}
