print("Sample Starting")

import AwsCommonRuntimeKit
import Combine
import Foundation

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
    print("client.subscribe() entered")

    // Return the future that will be completed upon callback completion by native client
    return Future { promise in

        // Convert swift->native and call the native subscribe along with swift callback
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

func ProcessSuback(subackPacket: SubackPacket) {
    print("Processing suback")
    print("Suback reasonCode: \(subackPacket.reasonCodes[0])")
}

func runSubscribe() -> AnyCancellable {
    print("runPublish called")
    let subscribePacket: SubscribePacket = SubscribePacket(
        topicFilter: "hello/world",
        qos: QoS.atLeastOnce)

    let subscribeFuture = subscribeFuture(subscribePacket: subscribePacket)

    print("subscribe to future with sink")

    let cancellable = subscribeFuture
        .sink(receiveCompletion: {completion in
            switch completion {
                case .finished:
                    print("Finished without error")
                case .failure(let error):
                    print("Finished with Error: \(error)")
            }
        }, receiveValue: { value in
            ProcessSuback(subackPacket: value)
        })

    return cancellable
}

let cancellable: AnyCancellable = runSubscribe()

// Wait for the future to complete or until a timeout (e.g., 5 seconds)
wait(seconds: 5)

print("Sample Ending")