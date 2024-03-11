# MQTT 5
# Table of Contents

* [Introduction](#introduction)
* [Getting Started with MQTT](#getting-started-with-mqtt)
    * [Connecting to AWS IoT Core](#connecting-to-aws-iot-core)
    * [How to create an MQTT Client based on desired connection method](#how-to-create-an-mqtt-client-based-on-desired-connection-method)
        * [Direct MQTT with X509-based mutual TLS](#direct-mqtt-with-x509-based-mutual-tls)
        * [Direct MQTT with Custom Authentication](#direct-mqtt-with-custom-authentication)
        * [Direct MQTT with PKCS11 Method](#direct-mqtt-with-pkcs11-method)
        * [Direct MQTT with PKCS12 Method](#direct-mqtt-with-pkcs12-method)
        * [MQTT over Websockets with Sigv4 authentication](#mqtt-over-websockets-with-sigv4-authentication)
        * [MQTT over Websockets with Cognito authentication](#mqtt-over-websockets-with-cognito-authentication)
    * [Adding an HTTP Proxy](#adding-an-http-proxy)
    * [Client Lifecycle Management](#client-lifecycle-management)
        * [Lifecycle Events](#lifecycle-events)
    * [Client Operations](#client-operations)
        * [Subscribe](#subscribe)
        * [Unsubscribe](#unsubscribe)
        * [Publish](#publish)
    * [MQTT Best Practices](#mqtt-best-practices)

## **Introduction**

This user guide is designed to act as a reference and guide for how to use MQTT5 with the Swift SDK. This guide includes code snippets for how to make an MQTT client with proper configuration, how to connect to AWS IoT Core, how to perform operations and interact with AWS IoT Core through MQTT, and some best practices for MQTT.

If you are completely new to MQTT, it is highly recommended to check out the following resources to learn more about MQTT:

* MQTT.org getting started: https://mqtt.org/getting-started/
* MQTT.org FAQ (includes list of commonly used terms): https://mqtt.org/faq/
* MQTT on AWS IoT Core documentation: https://docs.aws.amazon.com/iot/latest/developerguide/mqtt.html
* MQTT 5 standard: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html

This user guide expects some beginner level familiarity with MQTT and the terms used to describe MQTT.

### MQTT Client Notes
* The MQTT5 client attempts to reconnect on all disconnects or failed connection attempts including initial attempt.
* The set of client lifecycle events is expanded and contains more detailed information whenever possible.  All protocol data is exposed to the user.
* MQTT operations are completed with the full associated ACK packet when possible.
* New behavioral configuration options:
    * [IoT Core specific validation](link to api guide) - will validate and fail operations that break IoT Core specific restrictions
    * [IoT Core specific flow control](link to api guide) - will apply flow control to honor IoT Core specific per-connection limits and quotas
    * [Flexible queue control](link to api guide) - provides a number of options to control what happens to incomplete operations on a disconnection event
* A [new API](link to api guide) has been added to query the internal state of the client's operation queue.  This API allows the user to make more informed flow control decisions before submitting operations to the client.
* Data can not back up on the socket.  At most one frame of data is ever pending-write on the socket.
* The MQTT5 client has a single message-received callback.

### Not Supported
Not all parts of the MQTT5 spec are supported by the implementation.  We currently do not support:
* AUTH packets and the authentication fields in the CONNECT packet
* QoS 2

## **Getting Started with MQTT**

This section covers how to use MQTT in the Swift SDK. This includes how to setup an MQTT builder for making MQTT clients, how to connect to AWS IoT Core, and how to perform the operations with the MQTT client. Each section below contains code snippets showing the functionality in Swift.

## **Connecting To AWS IoT Core**
We strongly recommend using the AwsIotMqttClientConfigBuilder class to configure MQTT clients when connecting to AWS IoT Core.  The builder simplifies configuration for all authentication methods supported by AWS IoT Core.  This section shows samples for all of the authentication possibilities.

## **How to create an MQTT Client based on desired connection method**
### **Optional Keyword Arguments**
All lifecycle events and the callback for publishes received by the MQTT Client should be added to the builder on creation of the Client. A full list of accepted external parameter names can be found in the API guide.
#### **Direct MQTT with X509-based mutual TLS**
For X509 based mutual TLS, you can create a client where the certificate and private key are configured by path:

```swift
    // X.509 based certificate file
    let certFilepath: String = "<certificate file path>"
    // PKCS#1 or PKCS#8 PEM encoded private key file
    let priKeyFilepath String = "<private key file path>"

    // other builder configurations can be added using external parameter names in the builder

    // Create an MQTT Client using mqttClientBuilder
    client: MqttClient = mqttClientBuilder.mtlsFromPath(
        endpoint: "<account-specific endpoint>",
        certFilepath: certFilepath,
        priKeyFilepath: priKeyFilepath))
```

#### **Direct MQTT with Custom Authentication**
AWS IoT Core Custom Authentication allows you to use a lambda to gate access to IoT Core resources.  For this authentication method,
you must supply an additional configuration structure containing fields relevant to AWS IoT Core Custom Authentication.
If your custom authenticator does not use signing, you don't specify anything related to the token signature:

```swift
    // other builder configurations can be added using external parameter names in the builder

    client: MqttClient = mqttClientBuilder.directWithCustomAuthorizer(
        endpoint: "<account-specific endpoint>",
        authAuthorizerName: "<Name of your custom authorizer>",
        authUsername: "<Value of the username field that should be passed to the authorizer's lambda>",
        authPassword: <Binary data value of the password field to be passed to the authorizer lambda>)
```

If your custom authorizer uses signing, you must specify the three signed token properties as well. It is your responsibility to URI-encode the authUsername, authAuthorizerName, and auth_tokenKeyName parameters.

```swift
    // other builder configurations can be added using external parameter names in the builder

    client: MqttClient = mqttClientBuilder.directWithCustomAuthorizer(
        endpoint: "<account-specific endpoint>",
        authAuthorizerName: "<Name of your custom authorizer>",
        authUsername: "<Value of the username field that should be passed to the authorizer's lambda>",
        authPassword: <Binary data value of the password field to be passed to the authorizer lambda>,
        authAuthorizerSignature: "<The signature of the custom authorizer>")
```

In both cases, the builder will construct a final CONNECT packet username field value for you based on the values configured.  Do not add the token-signing fields to the value of the username that you assign within the custom authentication config structure.  Similarly, do not add any custom authentication related values to the username in the CONNECT configuration optionally attached to the client configuration. The builder will do everything for you.

#### **Direct MQTT with PKCS11 Method**

An MQTT direct connection can be made using a PKCS11 device rather than using a PEM encoded private key, the private key for mutual TLS is stored on a PKCS#11 compatible smart card or Hardware Security Module (HSM). To create an MQTT builder configured for this connection, see the following code:

```swift
    // other builder configurations can be added using external parameter names in the builder

    let pkcs11Lib: Pkcs11Lib = io.Pkcs11Lib(
        file="<Path to PKCS11 library>",
        behavior=io.Pkcs11Lib.InitializeFinalizeBehavior.STRICT)

    client: MqttClient = mqttClientBuilder.mtlsWithPkcs11(
        pkcs11Lib: pkcs11Lib,
        userPin: userPin,
        slotId: pkcs11SlotId,
        tokenLabel: pkcs11TokenLabel,
        priaveKeyLabel: pkcs11PrivateKeyLabel,
        certFilepath: pkcs11CertFilepath,
        endpoint: "<account-specific endpoint>")
```

**Note**: Currently, TLS integration with PKCS#11 is only available on Unix devices.

#### **Direct MQTT with PKCS12 Method**

An MQTT direct connection can be made using a PKCS12 file rather than using a PEM encoded private key. To create an MQTT builder configured for this connection, see the following code:

```swift
    // other builder configurations can be added using external parameter names in the builder

    client: MqttClient = mqttClientBuilder.mtlsWithPkcs12(
        pkcs12Filepath: "<PKCS12 file path>",
        pkcs12Password: "<PKCS12 password>",
        endpoint: "<account-specific endpoint>")
```

**Note**: Currently, TLS integration with PKCS#12 is only available on MacOS devices.

#### **MQTT over Websockets with Sigv4 authentication**
Sigv4-based authentication requires a credentials provider capable of sourcing valid AWS credentials. Sourced credentials
will sign the websocket upgrade request made by the client while connecting.  The default credentials provider chain supported by
the SDK is capable of resolving credentials in a variety of environments according to a chain of priorities:

```Environment -> Profile (local file system) -> STS Web Identity -> IMDS (ec2) or ECS```

If the default credentials provider chain and built-in AWS region extraction logic are sufficient, you do not need to specify
any additional configuration:

```swift
    // The signing region. e.x.: 'us-east-1'
    let signingRegion: String = "<signing region>"
    let credentialsProvider: CredentialsProvider = auth.AwsCredentialsProvider.newDefaultChain()

    // other builder configurations can be added using external parameter names in the builder

    // Create an MQTT Client using mqttClientBuilder
    client: MqttClient = mqttClientBuilder.websocketsWithDefaultAwsSigning(
        endpoint: "<account-specific endpoint>",
        region: signingRegion,
        credentialsProvider: credentialsProvider))
```

#### **MQTT over Websockets with Cognito authentication**

An MQTT websocket connection can be made using Cognito to authenticate rather than the AWS credentials located on the device or via key and certificate. Instead, Cognito can authenticate the connection using a valid Cognito identity ID. This requires a valid Cognito identity ID, which can be retrieved from a Cognito identity pool. A Cognito identity pool can be created from the AWS console.

To create an MQTT builder configured for this connection, see the following code:

```swift
    // The signing region. e.x.: 'us-east-1'
    let signingRegion: String = "<signing region>"

    // See https://docs.aws.amazon.com/general/latest/gr/cognito_identity.html for Cognito endpoints
    let cognitoEndpoint:String = "cognito-identity." + signing_region + ".amazonaws.com"
    let cognitoIdentityId: String = "<Cognito identity ID>"
    let credentialsProvider: CredentialsProvider = auth.AwsCredentialsProvider.newCognito(
        endpoint: cognitoEndpoint,
        identity: cognitoIdentityId,
        tlsCtx=io.ClientTlsContext(TlsContextOptions()))

    // other builder configurations can be added using external parameter names in the builder

    // Create an MQTT Client using mqttClientBuilder
    client: MqttClient = mqttClientBuilder.websocketsWithDefaultAwsSigning(
        endpoint: "<account-specific endpoint>",
        region: signingRegion,
        credentialsProvider: credentialsProvider))
```

**Note**: A Cognito identity ID is different from a Cognito identity pool ID and trying to connect with a Cognito identity pool ID will not work. If you are unable to connect, make sure you are passing a Cognito identity ID rather than a Cognito identity pool ID.

### **Adding an HTTP Proxy**
No matter what your connection transport or authentication method is, you may connect through an HTTP proxy
by adding the http_proxy_options keyword argument to the builder:

```swift
    httpProxyOptions: HttpProxyOptions = http.HttpProxyOptions(
        hostName: "<proxy host>",
        port: <proxy port>)

    // Create an MQTT Client using mqttClientBuilder with proxy options a an external parameter name
    client: MqttClient = mqttClientBuilder.mtlsFromPath(
        endpoint: "<account-specific endpoint>",
        certFilepath: "<certificate file path>",
        priKeyFilepath: "<private key file path>",
        httpProxyOptions: httpProxyOptions))
```

SDK Proxy support also includes support for basic authentication and TLS-to-proxy.  SDK proxy support does not include any additional
proxy authentication methods (kerberos, NTLM, etc...) nor does it include non-HTTP proxies (SOCKS5, for example).

## **Client lifecycle management**
Once created, an MQTT client's configuration is immutable.  Invoking start() on the client will put it into an active state where it
recurrently establishes a connection to the configured remote endpoint.  Reconnecting continues until you invoke stop().

```swift
    // Create an MQTT Client
    clientOptions: MqttClientOptions = MqttClientOptions(
        hostName: "<endpoint to connect to>",
        port: <port to use>,
        bootstrap: bootstrap,
        socketOptions: socketOptions,
        tlsCtx: tlsCtx)

    // Other options in client options can be set but once Client is initialized configuration is immutable
    // e.g. setting the onPublishCallbackFn to be set
    // clientOptions.onPublishCallbackFn = onPublishReceived

    client: MqttClient = MqttClient(clientOptions)

    # Use the client
    client.start();
    ...
```

Invoking stop() breaks the current connection (if any) and moves the client into an idle state.

```swift
    // Shutdown
    client.stop();

```
## **Lifecycle Events**
The MQTT client emits a set of events related to state and network status changes.

#### **AttemptingConnect**
Emitted when the client begins to make a connection attempt.

#### **ConnectionSuccess**
Emitted when a connection attempt succeeds based on receipt of an affirmative CONNACK packet from the MQTT broker.  A ConnectionSuccess event includes the MQTT broker's CONNACK packet, as well as a structure -- the NegotiatedSettings -- which contains the final values for all variable MQTT session settings (based on protocol defaults, client wishes, and server response).

#### **ConnectionFailure**
Emitted when a connection attempt fails at any point between DNS resolution and CONNACK receipt.  In addition to an error code, additional data may be present in the event based on the context.  For example, if the remote endpoint sent a CONNACK with a failing reason code, the CONNACK packet will be included in the event data.

#### **Disconnect**
Emitted when the client's network connection is shut down, either by a local action, event, or a remote close or reset.  Only emitted after a ConnectionSuccess event: a network connection that is shut down during the connecting process manifests as a ConnectionFailure event.  A Disconnect event will always include an error code.  If the Disconnect event is due to the receipt of a server-sent DISCONNECT packet, the packet will be included with the event data.

#### **Stopped**
Emitted once the client has shutdown any associated network connection and entered an idle state where it will no longer attempt to reconnect.  Only emitted after an invocation of `stop()` on the client.  A stopped client may always be started again.

## **Client Operations**
There are four basic MQTT operations you can perform with the MQTT client.

### Subscribe
The Subscribe operation takes a description of the SUBSCRIBE packet you wish to send and returns a future that resolves successfully with the corresponding SUBACK returned by the broker; the future result raises an exception if anything goes wrong before the SUBACK is received.

```swift

    // TO IMPLEMENT
    // This is the client's subscribe func
    func subscribe(subscribePacket: SubscribePacket) -> Future<SubackPacket, MQTTError> {
        return Future { promise in
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                // Asynchronous operation

            }
        }
    }

    // Create a Subscribe Packet with a topic filter and qos
    let subscribePacket = SubscribePacket(
        topicFilter: "hello/world/qos1",
        qos: QoS.atLeastOnce)

    // Subscribe using the MQTT client and process the Future
    let subscribeFuture = client.subscribe(subscribePacket: subscribePacket)
        .sink { completion in
            switch completion {
            case .finished:
                // completion block for success
                break
            case .failure(let error):
                print("Error: \(error)")
            }
        } receiveValue: { subackPacket in
            print("Suback Packet received")
        }
```

### Unsubscribe
The Unsubscribe operation takes a description of the UNSUBSCRIBE packet you wish to send and returns a future that resolves successfully with the corresponding UNSUBACK returned by the broker; the future result raises an exception if anything goes wrong before the UNSUBACK is received.

```swift
// TODO. Unsure what we return yet.
    unsubscribe_future = client.unsubscribe(unsubscribe_packet = mqtt5.UnsubscribePacket(
        topic_filters=["hello/world/qos1"]))

    unsuback = unsubscribe_future.result()
```

### Publish
The Publish operation takes a description of the PUBLISH packet you wish to send and returns a future of polymorphic value.  If the PUBLISH was a QoS 0 publish, then the future result is an empty PUBACK packet with all members set to None and is completed as soon as the packet has been written to the socket.  If the PUBLISH was a QoS 1 publish, then the future result is a PUBACK packet value and is completed as soon as the PUBACK is received from the broker.  If the operation fails for any reason before these respective completion events, the future result raises an exception.

```swift
// TODO. Unsure what we return yet.
    publish_future = client.publish(mqtt5.PublishPacket(
        topic = "hello/world/qos1",
        payload = "This is the payload of a QoS 1 publish",
        qos = mqtt5.QoS.AT_LEAST_ONCE))

    # on success, the result of publish_future will be a PubackPacket
    puback = publish_future.result()
```

### Disconnect
The `stop()` API supports a DISCONNECT packet as an optional parameter.  If supplied, the DISCONNECT packet will be sent to the server prior to closing the socket.  There is no future returned by a call to `stop()` but you may listen for the 'stopped' event on the client.

```swift
    client.stop(DisconnectPacket(
        reasonCode: DisconnectReasonCode.normalDisconnection,
        sessionExpiryIntervalSec: 3600))
```

## **MQTT5 Best Practices**

Below are some best practices for the MQTT5 client that are recommended to follow for the best development experience:

* When creating MQTT5 clients, make sure to use ClientIDs that are unique! If you connect two MQTT5 clients with the same ClientID, they will Disconnect each other! If you do not configure a ClientID, the MQTT5 server will automatically assign one.
* Use the minimum QoS you can get away with for the lowest latency and bandwidth costs. For example, if you are sending data consistently multiple times per second and do not have to have a guarantee the server got each and every publish, using QoS 0 may be ideal compared to QoS 1. Of course, this heavily depends on your use case but generally it is recommended to use the lowest QoS possible.
* If you are getting unexpected disconnects when trying to connect to AWS IoT Core, make sure to check your IoT Core Thing’s policy and permissions to make sure your device is has the permissions it needs to connect!
* For **Publish**, **Subscribe**, and **Unsubscribe**, you can check the reason codes in the returned Future to see if the operation actually succeeded.
* You MUST NOT perform blocking operations on any callback, or you will cause a deadlock. For example: in the `on_publish_received` callback, do not send a publish, and then wait for the future to complete within the callback. The Client cannot do work until your callback returns, so the thread will be stuck.