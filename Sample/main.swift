print("Sample Starting")

import AwsCommonRuntimeKit
import AwsCMqtt
import Foundation

func buildClient() throws -> Mqtt5Client {
    print("Building Mqtt Client")
    let elg = try EventLoopGroup()
    let resolver = try HostResolver.makeDefault(eventLoopGroup: elg)
    let clientBootstrap = try ClientBootstrap(eventLoopGroup: elg, hostResolver: resolver)
    let socketOptions = SocketOptions()
    let tlsOptions = TLSContextOptions.makeDefault()
    let tlsContext = try TLSContext(options: tlsOptions, mode: .client)
    let clientOptions = MqttClientOptions(hostName: "localhost",
                                          port: 443,
                                          bootstrap: clientBootstrap,
                                          socketOptions: socketOptions,
                                          tlsCtx: tlsContext)

    print("Returning Mqtt Client")
    return try Mqtt5Client(clientOptions: clientOptions)
}

let client = try buildClient()

// for waiting/sleep
let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)

// Wait x seconds with logging
func wait (seconds: Int) {
    print("          wait for \(seconds) seconds")
    let timeLeft = seconds - 1
    for i in (0...timeLeft).reversed() {
        _ = semaphore.wait(timeout: .now() + 1)
        print("          \(i) seconds left")
    }
}

func waitNoCountdown(seconds: Int) {
    print("          wait for \(seconds) seconds")
    _ = semaphore.wait(timeout: .now() + 1)
}

func nativeSubscribe(subscribePacket: SubscribePacket, completion: @escaping (Int, SubackPacket) -> Void) -> Int {
    print("[NATIVE CLIENT] SubscribePaket with topic '\(subscribePacket.subscriptions[0].topicFilter)' received for processing")

    // Simulate an asynchronous task.
    // This block is occuring in a background thread relative to the main thread.
    DispatchQueue.global().async {
        let nativeSemaphore: DispatchSemaphore = DispatchSemaphore(value: 0)

        print("[NATIVE CLIENT] simulating 2 second delay for receiving a suback from broker for `\(subscribePacket.subscriptions[0].topicFilter)`")
        _ = nativeSemaphore.wait(timeout: .now() + 2)

        let subackPacket: SubackPacket = SubackPacket(
            reasonCodes: [SubackReasonCode.grantedQos1],
            userProperties: [UserProperty(name: "Topic", value: "\(subscribePacket.subscriptions[0].topicFilter)")])

        print("[NATIVE CLIENT] simulating calling the swift callback with an error code and subackPacket for `\(subscribePacket.subscriptions[0].topicFilter)`")
        completion(0, subackPacket)
        // if (Bool.random()){
        //     completion(5146, subackPacket)
        // } else {
        //     completion(0, subackPacket)
        // }
    }

    return 0
}

func subscribeAsync(subscribePacket: SubscribePacket) async throws -> SubackPacket {
    print("client.subscribeAsync() entered for `\(subscribePacket.subscriptions[0].topicFilter)`")

    // withCheckedThrowingContinuation is used as a bridge between native's callback asynchrnous code and Swift's async/await model
    // This func will pause until continuation.resume() is called

    return try await withCheckedThrowingContinuation { continuation in
        print("subscribeAsync try await withCheckedThrowingContinuation for '\(subscribePacket.subscriptions[0].topicFilter)` starting")
        // The completion callback to invoke when an ack is received in native
        func subscribeCompletionCallback(errorCode: Int, subackPacket: SubackPacket) {
            print("   subscribeCompletionCallback called for `\(subackPacket.userProperties![0].value)`")
            if errorCode == 0 {
                continuation.resume(returning: subackPacket)
            } else {
                continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
            }
        }

        // Translate swift packet to native packet
        // We have a native callback for the operation
        // We have a pointer to the swift callback
        // aws_mqtt5_subscribe(nativePacket, nativeCallback)

        print("subscribeAsync nativeSubscribe within withCheckedThrowingContinuation for '\(subscribePacket.subscriptions[0].topicFilter)` starting")
        // represents the call to the native client
        let result = nativeSubscribe(
            subscribePacket: subscribePacket,
            completion: subscribeCompletionCallback)

        if result != 0 {
            continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: -1)))
        }
    }
}

func subscribe(subscribePacket: SubscribePacket) -> Task<SubackPacket, Error> {
    return Task {
        print("Subscribe Task for `\(subscribePacket.subscriptions[0].topicFilter)` executing")
        return try await subscribeAsync(subscribePacket: subscribePacket)
    }
}

/// Explicitly request a Task on an operation
func subscribeOptionalTask(subscribePacket: SubscribePacket, getAck: Bool = false) -> Task<SubackPacket, Error>? {

    // If getAck is false, submit the operation to native with no callback
    guard getAck else {
        // Calls native subscribe() without a completion callback.
        // Immediately returns nil
        return nil
    }

    // If an ack is requested, return the Task that will
    return Task {
        return try await subscribeAsync(subscribePacket: subscribePacket)
    }
}

func processSuback(subackPacket: SubackPacket) {
    print("     =======SUBACK PACKET=======")
    print("     Processing suback")
    print("     Suback reasonCode: \(subackPacket.reasonCodes[0])")
    if let userProperties = subackPacket.userProperties {
        for property in userProperties {
            print("     \(property.name) : \(property.value)")
        }
    }
    print("     =====SUBACK PACKET END=====")
}

let subscribePacket: SubscribePacket = SubscribePacket(
    topicFilter: "hello/world",
    qos: QoS.atLeastOnce)

// // Ignore the returned Task
// _ = subscribe(subscribePacket: SubscribePacket(
//     topicFilter: "Ignore",
//     qos: QoS.atLeastOnce))

// waitNoCountdown(seconds: 1)

// let taskUnused = subscribe(subscribePacket: SubscribePacket(
//     topicFilter: "Task Unused",
//     qos: QoS.atLeastOnce))

// let task1 = subscribe(subscribePacket: SubscribePacket(
//     topicFilter: "Within",
//     qos: QoS.atLeastOnce))
// do {
//     let subackPacket = try await task1.value
//     processSuback(subackPacket: subackPacket)
// } catch {
//     print("An error was thrown \(error)")
// }

// This passes to Native the operation, we don't care about result but the async function runs to completion
// async let _ = subscribeAsync(subscribePacket: subscribePacket)

let suback = try await subscribeAsync(subscribePacket: subscribePacket)

// results in "'async' call in a function that does not support concurrency"
// needs to be contained in an async function to be used this way
// subscribeAsync(subscribePacket: subscribePacket)

// Drops out of scope immediately without passing op to native
// Task {
//     try await subscribeAsync(subscribePacket: subscribePacket)
// }

// func TestFunk() {
//     Task {
//         let result = try await subscribeAsync(subscribePacket: subscribePacket)
//         print("RESULT \(result.reasonCodes[0])")
//     }
// }
// TestFunk()

// _ = subscribe(subscribePacket: subscribePacket)

// _ = subscribe(subscribePacket: subscribePacket)

// let taskF = client.subscribe(subscribePacket: subscribePacket)
// let task =  Task { try await client.subscribeAsync(subscribePacket: subscribePacket) }

// async let ack = try subscribe(subscribePacket: subscribePacket).value
// try await client.subscribeAsync(subscribePacket: subscribePacket)

// Execute the operation from within a task block
// Task.detached {
//     let task1 = subscribe(subscribePacket: SubscribePacket(
//     topicFilter: "Within",
//     qos: QoS.atLeastOnce))
//     do {
//         let subackPacket = try await task1.value
//         processSuback(subackPacket: subackPacket)
//     } catch {
//         print("An error was thrown \(error)")
//     }
// }

// waitNoCountdown(seconds: 1)

// // Execute the operation and store the task and then complete it in a task block.
// let task2 = subscribe(subscribePacket: SubscribePacket(
//     topicFilter: "Store and task block",
//     qos: QoS.atLeastOnce))
// Task.detached {
//     do {
//         let subackPacket = try await task2.value
//         processSuback(subackPacket: subackPacket)
//     } catch {
//         print("An error was thrown \(error)")
//     }
// }

// waitNoCountdown(seconds: 1)
// let task3 = subscribe(subscribePacket: SubscribePacket(
//     topicFilter: "Store and nothing else",
//     qos: QoS.atLeastOnce))

// // Wait for the future to complete or until a timeout (e.g., 5 seconds)
// wait(seconds: 5)
// Task.detached {
//     do {
//         let subackTask3 = try await task3.value
//         processSuback(subackPacket: subackTask3)
//     } catch {
//         print("An error was thrown \(error)")
//     }
// }

// wait(seconds: 3)

print("Sample Ending")
