print("Hello, world")

import AwsCommonRuntimeKit

let subscribePacket = SubscribePacket(
    topicFilter: "hello/world",
    qos: QoS.atLeastOnce)
