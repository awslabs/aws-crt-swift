print("Sample Starting")

import AwsCommonRuntimeKit
import Combine
import Foundation

public class MqttClient {
    public func start(){
        // cals into native aws_mqtt5_client_start() which return success/failure
    }

    public func stop(disconnectPacket: DisconnectPacket? = nil) {
        // cals into native aws_mqtt5_client_stop() with optional disconnect packet. returns success/failure
    }

    public func publish(publishPacket: PublishPacket) {
        // calls into native aws_mqtt5_client_publish(). returns success/failure
    }

    public func subscribe(subscribePacket: SubscribePacket?) {
        // calls into native aws_mqtt5_client_subscribe(). returns success/failure
    }

    public func unsubscribe(unsubscribePacket: UnsubscribePacket) {
        // calls into native aws_mqtt5_client_unsubscribe(). returns success/failure
    }

    public func getStats() -> ClientOperationStatistics {
        // cals into native aws_mqtt5_client_get_stats
        return ClientOperationStatistics(
            incompleteOperationCount: 0,
            incompleteOperationSize: 0,
            unackedOperationCount: 0,
            unackedOperationSize: 0)
    }

    // This should be unecessary in Swift as all request response clients and service clients will be mqtt5 in swift.
    // public func newConnection() {
    // }

    public

    public init (clientOptions: MqttClientOptions) {
        // calls into native aws_mqtt5_client_new() which returns a pointer to the native client or nil
    }
    /*

    Native mqtt functions not exposed directly in swift client
    aws_mqtt5_client_acquire()
    aws_mqtt5_client_release()

    */
}

// for waiting/sleep
let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)

// Wait x seconds with logging
func wait (seconds: Int) {
    print("wait for \(seconds) seconds")
    let timeLeft = seconds - 1
    for i in (0...timeLeft).reversed() {
        _ = semaphore.wait(timeout: .now() + 1)
        print("\(i) seconds left")
    }
}

func waitNoCountdown(seconds: Int) {
    print("wait for \(seconds) seconds")
    _ = semaphore.wait(timeout: .now() + 1)
}

func nativeSubscribe(subscribePacket: SubscribePacket, completion: @escaping (Int, SubackPacket) -> Void) {
    print("native client simulating Subscribe packet received")

    // Simulate an asynchronous task.
    // This block is occuring in a background thread relative to the main thread.
    DispatchQueue.global().async {
        let nativeSemaphore: DispatchSemaphore = DispatchSemaphore(value: 0)

        print("native client simulating 2 second for sending a subscribe and receiving a suback")
        _ = nativeSemaphore.wait(timeout: .now() + 2)

        let subackPacket: SubackPacket = SubackPacket(reasonCodes: [SubackReasonCode.grantedQos1])

        print("native client simulating calling the swift callback with an error code and subackPacket")

        if (Bool.random()){
            completion(5146, subackPacket)
        } else {
            completion(0, subackPacket)
        }
    }
}

func subscribeFuture(subscribePacket: SubscribePacket) -> Future<SubackPacket, CommonRunTimeError> {
    print("client.subscribeFuture() entered")

    // Return the future that will be completed upon callback completion by native client
    return Future { promise in

        // Convert swift->native and call the native subscribe along with swift callback
        // native subscribe can fail and return AWS_OP_ERR. In this case, the future should complete with error
        nativeSubscribe(
            subscribePacket: subscribePacket,
            completion: { errorCode, subackPacket in
            if (errorCode > 0){
                promise(.failure(CommonRunTimeError.crtError(CRTError(code: errorCode))))
            } else {
                promise(.success(subackPacket))
            }

        })
    }
}

func subscribeAsync(subscribePacket: SubscribePacket) async throws -> SubackPacket {
    print("client.subscribeAsync() entered")

    return try await withCheckedThrowingContinuation { continuation in
        func subscribeCompletionCallback(errorCode: Int, subackPacket: SubackPacket) {
            print("   subscribeCompletionCallback called")
            if errorCode == 0 {
                continuation.resume(returning: subackPacket)
            } else {
                continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
            }
        }

        nativeSubscribe(
        subscribePacket: subscribePacket,
        completion: subscribeCompletionCallback)
    }
}

func subscribeAsyncHandled(subscribePacket: SubscribePacket, completion: ((SubackPacket) -> Void)? = nil) {
    print("client.subscribeAsyncHandled() entered")
    Task{
        do {
            let subackPacket: SubackPacket = try await subscribeAsync(
                subscribePacket: subscribePacket)
            completion?(subackPacket)
        } catch {
            print("     Error encountered: \(error)")
        }
    }
}

func processSuback(subackPacket: SubackPacket) {
    print("     Processing suback")
    print("     Suback reasonCode: \(subackPacket.reasonCodes[0])")
}

func runSubscribeFuture() -> AnyCancellable {
    print("runPublish called")
    let subscribePacket: SubscribePacket = SubscribePacket(
        topicFilter: "hello/world",
        qos: QoS.atLeastOnce)

    let subscribeFuture = subscribeFuture(subscribePacket: subscribePacket)

    print("subscribe to future with sink")

    let cancellable = subscribeFuture
        .sink(
            receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        print("Finished without error")
                    case .failure(let error):
                        print("Finished with Error: \(error)")
                }
        },
            receiveValue: { value in
                processSuback(subackPacket: value)
        })

    return cancellable
}

func runSubscribeAsync() {
    let subscribePacket: SubscribePacket = SubscribePacket(
        topicFilter: "hello/world",
        qos: QoS.atLeastOnce)



    Task {
        do {
            let subackPacket: SubackPacket = try await subscribeAsync(
                subscribePacket: subscribePacket)
            processSuback(subackPacket: subackPacket)
        } catch {
            print("     Error encountered: \(error)")
        }
    }

    waitNoCountdown(seconds: 1)

    Task {
        do {
            let subackPacket: SubackPacket = try await subscribeAsync(
                subscribePacket: subscribePacket)
            processSuback(subackPacket: subackPacket)
        } catch {
            print("     Error encountered: \(error)")
        }
    }

    waitNoCountdown(seconds: 1)

    Task {
        do {
            let subackPacket: SubackPacket = try await subscribeAsync(
                subscribePacket: subscribePacket)
            processSuback(subackPacket: subackPacket)
        } catch {
            print("     Error encountered: \(error)")
        }
    }
}

func runSubscribeAsyncHandled() {
    let subscribePacket: SubscribePacket = SubscribePacket(
        topicFilter: "hello/world",
        qos: QoS.atLeastOnce)

    subscribeAsyncHandled(subscribePacket: subscribePacket)

    waitNoCountdown(seconds: 1)

    subscribeAsyncHandled(subscribePacket: subscribePacket)

    waitNoCountdown(seconds: 1)

    subscribeAsyncHandled(subscribePacket: subscribePacket, completion: processSuback)
}

// let cancellable: AnyCancellable = runSubscribeFuture()
runSubscribeAsync()
// runSubscribeAsyncHandled()

// Wait for the future to complete or until a timeout (e.g., 5 seconds)
wait(seconds: 10)

print("Sample Ending")