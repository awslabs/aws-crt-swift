import Foundation

class ReadWriteLock {
    private var rwlock = pthread_rwlock_t()

    init() {
        pthread_rwlock_init(&rwlock, nil)
    }

    deinit {
        pthread_rwlock_destroy(&rwlock)
    }

    func read(_ closure: () throws -> Void) rethrows {
        pthread_rwlock_rdlock(&rwlock)
        defer { pthread_rwlock_unlock(&rwlock) }
        return try closure()
    }

    func write( _ closure: () throws -> Void) rethrows {
        pthread_rwlock_wrlock(&rwlock)
        defer { pthread_rwlock_unlock(&rwlock) }
        try closure()
    }
}
