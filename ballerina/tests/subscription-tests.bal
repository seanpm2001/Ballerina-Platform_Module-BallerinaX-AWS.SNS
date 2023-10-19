// Copyright (c) 2023 WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/test;

string topic = "";
string fakeTopic = "";

@test:BeforeGroups {value: ["subscribe", "subscribex"]}
function beforeSubscribeTests() returns error? {
    topic = check amazonSNSClient->createTopic(testRunId + "SubscribeTopic");
    fakeTopic = check amazonSNSClient->createTopic(testRunId + "FakeSubscribeTopic");
    _ = check amazonSNSClient->deleteTopic(fakeTopic);
}

   
@test:Config {
    groups: ["subscribe"]
}
function subscribeWithoutReturnArnTest() returns error? {
    string subsriptionArn = check amazonSNSClient->subscribe(topic, testEmail, EMAIL);
    test:assertEquals(subsriptionArn, "pending confirmation");
}

@test:Config {
    groups: ["subscribe"]
}
function subscribeWithReturnArnTest() returns error? {
    string subsriptionArn = 
        check amazonSNSClient->subscribe(topic, testEmail, EMAIL, returnSubscriptionArn = true);
    test:assertTrue(isArn(subsriptionArn), "Returned value is not an ARN.");
}

@test:Config {
    groups: ["subscribe"]
}
function subscribeHttpTest() returns error? {
    string subsriptionArn =
        check amazonSNSClient->subscribe(topic, testHttp, HTTP, returnSubscriptionArn = true);
    test:assertTrue(isArn(subsriptionArn), "Returned value is not an ARN.");
}

@test:Config {
    groups: ["subscribe"]
}
function subscribeHttpsTest() returns error? {
    string subsriptionArn =
        check amazonSNSClient->subscribe(topic, testHttps, HTTPS, returnSubscriptionArn = true);
    test:assertTrue(isArn(subsriptionArn), "Returned value is not an ARN.");
}

@test:Config {
    groups: ["subscribe"]
}
function subscribeEmailTest() returns error? {
    string subsriptionArn =
        check amazonSNSClient->subscribe(topic, testEmail, EMAIL, returnSubscriptionArn = true);
    test:assertTrue(isArn(subsriptionArn), "Returned value is not an ARN.");
}

@test:Config {
    groups: ["subscribe"]
}
function subscribeEmailJsonTest() returns error? {
    string subsriptionArn =
        check amazonSNSClient->subscribe(topic, testEmail, EMAIL_JSON, returnSubscriptionArn = true);
    test:assertTrue(isArn(subsriptionArn), "Returned value is not an ARN.");
}

@test:Config {
    groups: ["subscribe"]
}
function subscribeSmsTest()returns error? {
    string subsriptionArn =
        check amazonSNSClient->subscribe(topic, "+94771952226", SMS, returnSubscriptionArn = true);
    test:assertTrue(isArn(subsriptionArn), "Returned value is not an ARN.");
}

// TODO: Enable test case for SQS
// @test:Config {
//     groups: ["subscribex"]
// }
// function subscribeSqsTest() returns error? {
//     string subsriptionArn =
//         check amazonSNSClient->subscribe(topic, testSqs, SQS, returnSubscriptionArn = true);
//     test:assertTrue(subsriptionArn.matches(arnRegex), "Returned value is not an ARN.");
// }

@test:Config {
    groups: ["subscribe"]
}
function subscribeApplicationTest() returns error? {
    string subsriptionArn =
        check amazonSNSClient->subscribe(topic, testApplication, APPLICATION, returnSubscriptionArn = true);
    test:assertTrue(isArn(subsriptionArn), "Returned value is not an ARN.");
}

// TODO: Enable test case for Lambda
// @test:Config {
//     groups: ["subscribex"]
// }
// function subscribeLambdaTest() returns error? {
//     string subsriptionArn =
//         check amazonSNSClient->subscribe(topic, testLambda, LAMBDA, returnSubscriptionArn = true);
//     test:assertTrue(subsriptionArn.matches(arnRegex), "Returned value is not an ARN.");
// }

// TODO: Enable test case for Firehose
// @test:Config {
//     groups: ["subscribex"]
// }
// function subscribeFirehoseTest() returns error? {
//     string subsriptionArn =
//         check amazonSNSClient->subscribe(topic, testFirehose, FIREHOSE, returnSubscriptionArn = true);
//     test:assertTrue(subsriptionArn.matches(arnRegex), "Returned value is not an ARN.");
// }

@test:Config {
    groups: ["subscribe"]
}
function subscribeToNonExistantTopicTest() returns error? {
    string|Error subsriptionArn = 
        amazonSNSClient->subscribe(fakeTopic, testApplication, APPLICATION, returnSubscriptionArn = true);
    
    test:assertTrue(subsriptionArn is OperationError, "Expected error.");
    test:assertEquals((<OperationError>subsriptionArn).message(), "Topic does not exist");
}

@test:Config {
    groups: ["subscribe"]
}
function subscribeWithInvalidEndpointTest() returns error? {
    string|Error subsriptionArn =
        amazonSNSClient->subscribe(topic, "this is not an email", EMAIL, returnSubscriptionArn = true);
    test:assertTrue(subsriptionArn is OperationError, "Expected error.");
    test:assertEquals((<OperationError>subsriptionArn).message(), "Invalid parameter: Email address");
}

@test:Config {
    groups: ["subscribe"]
}
function subscribeWithInvalidArnTest() returns error? {
    string|Error subsriptionArn =
        amazonSNSClient->subscribe(topic, topic, APPLICATION, returnSubscriptionArn = true);
    test:assertTrue(subsriptionArn is OperationError, "Expected error.");
    test:assertTrue((<OperationError>subsriptionArn).message().startsWith("Invalid parameter: Application endpoint arn invalid:arn"));
}

@test:Config {
    groups: ["subscribe"]
}
function subscribeWithAttributesTest() returns error? {
    string topic = check amazonSNSClient->createTopic(testRunId + "SubscribeTopic2");
    SubscriptionAttributes attributes = {
        deliveryPolicy: {healthyRetryPolicy: {numRetries: 3, minDelayTarget: 5, maxDelayTarget: 10}},
        filterPolicy: {store:["example_corp"]},
        filterPolicyScope: MESSAGE_BODY,
        //TODO: test redrive policy and subscription role ARN
        rawMessageDelivery: true
    };
    string subsriptionArn =
        check amazonSNSClient->subscribe(topic, testHttp, HTTP, attributes, true);
    test:assertTrue(isArn(subsriptionArn), "Returned value is not an ARN.");
}

@test:Config {
    groups: ["subscribe"]
}
function subscribeWithInvalidAttributeTest() returns error? {
    SubscriptionAttributes attributes = {
        deliveryPolicy: {healthyRetryPolicy: {numRetries: 3, minDelayTarget: 5, maxDelayTarget: 10}},
        filterPolicy: {store: ["example_corp"]},
        filterPolicyScope: MESSAGE_BODY,
        rawMessageDelivery: true
    };
    string|Error subsriptionArn =
        amazonSNSClient->subscribe(topic, testEmail, EMAIL, attributes, true);
    test:assertTrue(subsriptionArn is Error, "Expected error.");
    test:assertEquals((<OperationError>subsriptionArn).message(), "Invalid parameter: Attributes Reason: Delivery protocol [email] does not support raw message delivery.");
}

@test:Config {
    groups: ["subscribe"],
    enable: true
}
function confirmSubscriptionTest() returns error? {
    string topic = check amazonSNSClient->createTopic(testRunId + "SubscribeTopic3");
    _ = check amazonSNSClient->subscribe(topic, testEmail, EMAIL);
    string token = "2336412f37fb687f5d51e6e2425c464cefc60320762a6170a49b5c54805f379c1314d96e0fe2abc55dbe9c22429da22590a9aef52aae003208e2a189ff30944b79be41796e4f3cb374e9a7b32eb63744c0fbc2ebad8140c2a9fa83177525f79c8ac94b2555b44c8a87d5ca4ef8445514da6a76ba572b6b0b324a552df6d9ef528012b069c3989ebcec4dc7d66209e660";
    string subsriptionArn = check amazonSNSClient->confirmSubscription(topic, token);
    test:assertTrue(isArn(subsriptionArn), "Returned value is not an ARN.");
}

@test:Config {
    groups: ["subscribe"],
    enable: true
}
function confirmSubscriptionWithInvalidTokenTest() returns error? {
    string topic = check amazonSNSClient->createTopic(testRunId + "SubscribeTopic4");
    _ = check amazonSNSClient->subscribe(topic, testEmail, EMAIL);
    string token = "2336412f37fb687fd51e6e2425c464cefc6029303415bf22f632d6c1109584e3a0c5a9cb81735ec0ba6302001ae62e84c830f41c6cae9c7eeea0532b02990b572d9105532fe2ee1e97e3e06eb4b7931171f38d544f59f1077fe3dba807e1b570e992ebd62fef0677d928fafd61cf2a3b91e511bf54e99ae3270528fbd38b10709758e4c1d77ff77bbc7d460ef177618";
    string|error subsriptionArn = amazonSNSClient->confirmSubscription(topic, token);
    test:assertTrue(subsriptionArn is OperationError, "Expected error.");
    test:assertEquals((<OperationError>subsriptionArn).message(), "Invalid token");
}

@test:Config {
    groups: ["subscribe"]
}
function listSubscriptionsTest() returns error? {
    string topic = check amazonSNSClient->createTopic(testRunId + "SubscribeTopic6");
    string subscriptionArn = 
        check amazonSNSClient->subscribe(topic, testPhoneNumber, SMS);

    stream<Subscription, Error?> subscriptionsStream = amazonSNSClient->listSubscriptions();
    Subscription[] subscriptions = check from Subscription subscription in subscriptionsStream
        select subscription;

    string[] subscriptionArns = from Subscription subscription in subscriptions
        select subscription.subscriptionArn;

    // Validate newly created subscription
    Subscription[] retrievedSubscription = from Subscription subscription in subscriptions
        where subscription.subscriptionArn == subscriptionArn
        limit 1
        select subscription;
    test:assertEquals(retrievedSubscription.length(), 1, "Subscription not found in the list.");
    test:assertEquals(retrievedSubscription[0].endpoint, testPhoneNumber);
    test:assertEquals(retrievedSubscription[0].protocol, SMS);
    test:assertEquals(retrievedSubscription[0].topicArn, topic);
    test:assertEquals(retrievedSubscription[0].owner.length(), 12);

    test:assertTrue(subscriptions.length() > 100, "There should be over 100 subscriptions.");

    // Ensure there are no duplicates
    foreach string subscriptionArn1 in subscriptionArns {
        if (subscriptionArn1 == "PendingConfirmation") {
            continue;
        }

        test:assertEquals(subscriptionArns.indexOf(subscriptionArn1), subscriptionArns.lastIndexOf(subscriptionArn1),
            "Subscription " + subscriptionArn1 + " duplicated in the list.");
    }
}

@test:Config {
    groups: ["subscribe"]
}
function listSubscriptionsByTopicTest() returns error? {
    string topic = check amazonSNSClient->createTopic(testRunId + "SubscribeTopic7");
    string subscriptionArn = check amazonSNSClient->subscribe(topic, testPhoneNumber, SMS);
    _ = check amazonSNSClient->subscribe(topic, testHttp, HTTP);
    _ = check amazonSNSClient->subscribe(topic, testHttps, HTTPS);
    _ = check amazonSNSClient->subscribe(topic, testEmail, EMAIL);

    stream<Subscription, Error?> subscriptionsStream = amazonSNSClient->listSubscriptions(topic);
    Subscription[] subscriptions = check from Subscription subscription in subscriptionsStream
        order by subscription.protocol
        select subscription;

    test:assertEquals(subscriptions.length(), 4);

    test:assertEquals(subscriptions[0].subscriptionArn, "PendingConfirmation");
    test:assertEquals(subscriptions[0].endpoint, testEmail);
    test:assertEquals(subscriptions[0].protocol, EMAIL);
    test:assertEquals(subscriptions[0].topicArn, topic);
    test:assertEquals(subscriptions[0].owner.length(), 12);

    test:assertEquals(subscriptions[1].subscriptionArn, "PendingConfirmation");
    test:assertEquals(subscriptions[1].endpoint, testHttp);
    test:assertEquals(subscriptions[1].protocol, HTTP);
    test:assertEquals(subscriptions[1].topicArn, topic);
    test:assertEquals(subscriptions[1].owner.length(), 12);

    test:assertEquals(subscriptions[2].subscriptionArn, "PendingConfirmation");
    test:assertEquals(subscriptions[2].endpoint, testHttps);
    test:assertEquals(subscriptions[2].protocol, HTTPS);
    test:assertEquals(subscriptions[2].topicArn, topic);
    test:assertEquals(subscriptions[2].owner.length(), 12);

    test:assertEquals(subscriptions[3].subscriptionArn, subscriptionArn);
    test:assertEquals(subscriptions[3].endpoint, testPhoneNumber);
    test:assertEquals(subscriptions[3].protocol, SMS);
    test:assertEquals(subscriptions[3].topicArn, topic);
    test:assertEquals(subscriptions[3].owner.length(), 12);
}

@test:Config {
    groups: ["subscribe"]
}
function listSubscriptionsByTopicEmptyTest() returns error? {
    string topic = check amazonSNSClient->createTopic(testRunId + "SubscribeTopic8");

    stream<Subscription, Error?> subscriptionsStream = amazonSNSClient->listSubscriptions(topic);
    Subscription[] subscriptions = check from Subscription subscription in subscriptionsStream
        select subscription;
    test:assertEquals(subscriptions.length(), 0);
}

@test:Config {
    groups: ["subscribe"]
}
function listSubscriptionsByTopicDoesNotExist() returns error? {
    string topic = check amazonSNSClient->createTopic(testRunId + "SubscribeTopic9");
    _ = check amazonSNSClient->deleteTopic(topic);

    stream<Subscription, Error?> subscriptionsStream = amazonSNSClient->listSubscriptions(topic);
    Subscription[]|Error? e = from Subscription subscription in subscriptionsStream
        select subscription;
    test:assertTrue(e is OperationError, "Expected error.");
    test:assertEquals((<OperationError>e).message(), "Topic does not exist");
}

@test:Config {
    groups: ["subscribe"]
}
function getSubscriptionAttributesTest1() returns error? {
    string topic = check amazonSNSClient->createTopic(testRunId + "SubscribeTopic5");
    string subscription = check amazonSNSClient->subscribe(topic, testEmail, EMAIL, returnSubscriptionArn = true);

    GettableSubscriptionAttributes attributes = check amazonSNSClient->getSubscriptionAttributes(subscription);
    test:assertEquals(attributes.subscriptionArn, subscription);
    test:assertEquals(attributes.endpoint, testEmail);
    test:assertEquals(attributes.protocol, EMAIL);
    test:assertEquals(attributes.topicArn, topic);
    test:assertTrue(isArn(attributes.subscriptionPrincipal));
    test:assertEquals(attributes.confirmationWasAuthenticated, false);
    test:assertEquals(attributes.pendingConfirmation, true);
    test:assertEquals(attributes.rawMessageDelivery, false);
    test:assertEquals(attributes.owner.length(), 12);
}

@test:Config {
    groups: ["subscribe"]
}
function getSubscriptionAttributesTest2() returns error? {
    string topic = check amazonSNSClient->createTopic(testRunId + "SubscribeTopic5");

    SubscriptionAttributes setAttributes = {
        deliveryPolicy: {healthyRetryPolicy: {numRetries: 3, minDelayTarget: 5, maxDelayTarget: 10}},
        filterPolicy: {store: ["example_corp"]},
        filterPolicyScope: MESSAGE_BODY,
        //TODO: test redrive policy and subscription role ARN
        rawMessageDelivery: false
    };
    string subscription = check amazonSNSClient->subscribe(topic, testHttp, HTTP, setAttributes, true);

    GettableSubscriptionAttributes attributes = check amazonSNSClient->getSubscriptionAttributes(subscription);
    test:assertEquals(attributes.subscriptionArn, subscription);
    test:assertEquals(attributes.endpoint, testHttp);
    test:assertEquals(attributes.protocol, HTTP);
    test:assertEquals(attributes.topicArn, topic);
    test:assertTrue(isArn(attributes.subscriptionPrincipal));
    test:assertEquals(attributes.confirmationWasAuthenticated, false);
    test:assertEquals(attributes.pendingConfirmation, true);
    test:assertEquals(attributes.rawMessageDelivery, false);
    test:assertEquals(attributes.owner.length(), 12);
    test:assertTrue(attributes?.deliveryPolicy is json);
    test:assertEquals(attributes?.filterPolicy, setAttributes?.filterPolicy);
    test:assertEquals(attributes.filterPolicyScope, setAttributes.filterPolicyScope);
}

@test:Config {
    groups: ["subscribe"]
}
function setSubscriptionAttributesTest() returns error? {
    string topic = check amazonSNSClient->createTopic(testRunId + "SubscribeTopic10");
    string subscription = check amazonSNSClient->subscribe(topic, testHttp, HTTP, returnSubscriptionArn = true);

    SubscriptionAttributes setAttributes = {
        deliveryPolicy: {healthyRetryPolicy: {numRetries: 3, minDelayTarget: 5, maxDelayTarget: 10}},
        filterPolicy: {store: ["example_corp"]},
        filterPolicyScope: MESSAGE_BODY,
        //TODO: test redrive policy and subscription role ARN
        rawMessageDelivery: true
    };
    _ = check amazonSNSClient->setSubscriptionAttributes(subscription, setAttributes);

    GettableSubscriptionAttributes attributes = check amazonSNSClient->getSubscriptionAttributes(subscription);
    test:assertEquals(attributes.subscriptionArn, subscription);
    test:assertEquals(attributes.endpoint, testHttp);
    test:assertEquals(attributes.protocol, HTTP);
    test:assertEquals(attributes.topicArn, topic);
    test:assertTrue(isArn(attributes.subscriptionPrincipal));
    test:assertEquals(attributes.confirmationWasAuthenticated, false);
    test:assertEquals(attributes.pendingConfirmation, true);
    test:assertEquals(attributes.rawMessageDelivery, true);
    test:assertEquals(attributes.owner.length(), 12);
    test:assertTrue(attributes?.deliveryPolicy is json);
    test:assertEquals(attributes?.filterPolicy, setAttributes?.filterPolicy);
    test:assertEquals(attributes.filterPolicyScope, setAttributes.filterPolicyScope);
};

@test:Config {
    groups: ["subscribe"]
}
function setSubscriptionAttributesTestNegative() returns error? {
    string topic = check amazonSNSClient->createTopic(testRunId + "SubscribeTopic10");
    string subscription = check amazonSNSClient->subscribe(topic, testPhoneNumber, SMS, returnSubscriptionArn = true);

    SubscriptionAttributes setAttributes = {
        deliveryPolicy: {healthyRetryPolicy: {numRetries: 3, minDelayTarget: 5, maxDelayTarget: 10}},
        filterPolicy: {store: ["example_corp"]},
        filterPolicyScope: MESSAGE_BODY,
        //TODO: test redrive policy and subscription role ARN
        rawMessageDelivery: true
    };
    Error? e = amazonSNSClient->setSubscriptionAttributes(subscription, setAttributes);
    
    test:assertTrue(e is OperationError, "Expected error.");
    test:assertEquals((<OperationError>e).message(), "Invalid parameter: Delivery protocol [sms] does not support raw message delivery.");
};

@test:Config {
    groups: ["subscribe"]
}
function unsubscribeTest() returns error? {
    string topic = check amazonSNSClient->createTopic(testRunId + "SubscribeTopic11");
    string subscription = check amazonSNSClient->subscribe(topic, testPhoneNumber, SMS, returnSubscriptionArn = true);
    string[] subscriptions = check from Subscription subscripion in amazonSNSClient->listSubscriptions(topic) 
                                         select subscripion.subscriptionArn;
    test:assertTrue(subscriptions.indexOf(subscription) != ());

    _ = check amazonSNSClient->unsubscribe(subscription);
    subscriptions = check from Subscription subscripion in amazonSNSClient->listSubscriptions(topic) 
                          select subscripion.subscriptionArn;
    test:assertTrue(subscriptions.indexOf(subscription) is ());
}

@test:Config {
    groups: ["subscribe"]
}
function unsubscribeWithInvalidArnTest() returns error? {
    string topic = check amazonSNSClient->createTopic(testRunId + "SubscribeTopic13");
    string subscription = check amazonSNSClient->subscribe(topic, testEmail, EMAIL); // Valid ARN is not returned

    Error? e = amazonSNSClient->unsubscribe(subscription);
    test:assertTrue(e is OperationError, "Expected error.");
    test:assertEquals((<OperationError>e).message(), "Invalid parameter: SubscriptionArn Reason: An ARN must have at least 6 elements, not 1");
}

@test:Config {
    groups: ["subscribe"]
}
function usubscribeUnauthorizedTest() returns error? {
    Error? e = amazonSNSClient->unsubscribe("arn:aws:sns:us-east-1:invalid:2023-10-11T103913903939ZSubscribeTopic12:45f03920-f890-4a2f-bd77-32f9689b8013");
    test:assertTrue(e is OperationError, "Expected error.");
    test:assertTrue((<OperationError>e).message().includes("is not authorized to perform: SNS:Unsubscribe on resource"));
}
