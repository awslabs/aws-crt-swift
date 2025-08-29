import Foundation

public class ReadWriteLock {
  private var rwlock = pthread_rwlock_t()

  public init() {
    pthread_rwlock_init(&rwlock, nil)
  }

  deinit {
    pthread_rwlock_destroy(&rwlock)
  }

  public func read<Result>(_ closure: () throws -> Result) rethrows -> Result {
    pthread_rwlock_rdlock(&rwlock)
    defer { pthread_rwlock_unlock(&rwlock) }
    return try closure()
  }

  public func write<Result>(_ closure: () throws -> Result) rethrows -> Result {
    pthread_rwlock_wrlock(&rwlock)
    defer { pthread_rwlock_unlock(&rwlock) }
    return try closure()
  }
}
