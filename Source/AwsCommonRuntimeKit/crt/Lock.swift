import Foundation

class ReadWriteLock {
  private var rwlock = pthread_rwlock_t()

  init() {
    pthread_rwlock_init(&rwlock, nil)
  }

  deinit {
    pthread_rwlock_destroy(&rwlock)
  }

  func read<Result>(_ closure: () throws -> Result) rethrows -> Result {
    pthread_rwlock_rdlock(&rwlock)
    defer { pthread_rwlock_unlock(&rwlock) }
    return try closure()
  }

  func write<Result>(_ closure: () throws -> Result) rethrows -> Result {
    pthread_rwlock_wrlock(&rwlock)
    defer { pthread_rwlock_unlock(&rwlock) }
    return try closure()
  }
}
