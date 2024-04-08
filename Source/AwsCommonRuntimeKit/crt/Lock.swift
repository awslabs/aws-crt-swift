import Foundation

class ReadWriteLock {
    private var rwlock = pthread_rwlock_t()

    init() {
        pthread_rwlock_init(&rwlock, nil)
    }

    deinit {
        pthread_rwlock_destroy(&rwlock)
    }

    func read(_ closure: () -> Void) {
        pthread_rwlock_rdlock(&rwlock)
        defer { pthread_rwlock_unlock(&rwlock) }
        return closure()
    }

    func write( _ closure: () -> Void) {
        pthread_rwlock_wrlock(&rwlock)
        defer { pthread_rwlock_unlock(&rwlock) }
        closure()
    }
}
