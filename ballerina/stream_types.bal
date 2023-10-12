import ballerina/http;

public class TopicsStream {

    private final http:Client amazonSNSClient;
    private final (isolated function(map<string>) returns http:Request|Error) & readonly generateRequest;

    private string[] topics = [];
    private string? nextToken = ();
    private boolean initialized = false;

    public isolated function init(http:Client amazonSNSClient, 
        isolated function (map<string>) returns http:Request|Error generateRequest) {
        self.amazonSNSClient = amazonSNSClient;
        self.generateRequest = generateRequest;
    }

    private isolated function fetchTopics() returns Error? {
        map<string> parameters = initiateRequest("ListTopics");
        if self.nextToken is string {
            parameters["NextToken"] = <string>self.nextToken;
        }

        http:Request request = check self.generateRequest(parameters);
        json response = check sendRequest(self.amazonSNSClient, request);

        json|error nextToken = response.ListTopicsResponse.ListTopicsResult.NextToken;
        if nextToken is json && nextToken != () {
            self.nextToken = nextToken.toString();
        } else {
            self.nextToken = ();
        }

        do {
            json[] topics = <json[]>(check response.ListTopicsResponse.ListTopicsResult.Topics);
            foreach json topic in topics {
                self.topics.push((check topic.TopicArn).toString());
            }
        } on fail error e {
            return error ResponseHandleFailedError(e.message(), e);
        }
    }

    public isolated function next() returns record {|string value;|}|Error? {
        if self.topics.length() == 0 {
            if self.initialized && self.nextToken is () {
                return ();
            }

            Error? e = self.fetchTopics();
            self.initialized = true;
            if e is error {
                return e;
            }
        }

        if self.topics.length() == 0 {
            return ();
        }
    
        return {value: self.topics.remove(0)};
    }

    public isolated function close() returns Error? {
        return ();
    }
}

public class SubscriptionsStream {

    private final http:Client amazonSNSClient;
    private final (isolated function (map<string>) returns http:Request|Error) & readonly generateRequest;
    private final string? topicArn;

    private Subscription[] subscriptions = [];
    private string? nextToken = ();
    private boolean initialized = false;

    public isolated function init(http:Client amazonSNSClient,
            isolated function (map<string>) returns http:Request|Error generateRequest,
            string? topicArn) {
        self.amazonSNSClient = amazonSNSClient;
        self.generateRequest = generateRequest;
        self.topicArn = topicArn;
    }

    private isolated function fetchSubscriptions() returns Error? {
        map<string> parameters;
        if self.topicArn is string {
            parameters = initiateRequest("ListSubscriptionsByTopic");
            parameters["TopicArn"] = <string>self.topicArn;
        } else {
            parameters = initiateRequest("ListSubscriptions");
        }

        if self.nextToken is string {
            parameters["NextToken"] = <string>self.nextToken;
        }

        http:Request request = check self.generateRequest(parameters);
        json response = check sendRequest(self.amazonSNSClient, request);

        json|error nextToken;
        if self.topicArn is string {
            nextToken = response.ListSubscriptionsByTopicResponse.ListSubscriptionsByTopicResult.NextToken;
        } else {
            nextToken = response.ListSubscriptionsResponse.ListSubscriptionsResult.NextToken;
        }

        if nextToken is json && nextToken != () {
            self.nextToken = nextToken.toString();
        } else {
            self.nextToken = ();
        }

        do {
            json[] subscriptions;
            if self.topicArn is string {
                subscriptions = <json[]>
                    (check response.ListSubscriptionsByTopicResponse.ListSubscriptionsByTopicResult.Subscriptions);
            } else {
                subscriptions = 
                    <json[]>(check response.ListSubscriptionsResponse.ListSubscriptionsResult.Subscriptions);
            }

            foreach json subscription in subscriptions {
                self.subscriptions.push({
                    subscriptionArn: (check subscription.SubscriptionArn),
                    topicArn: (check subscription.TopicArn),
                    owner: (check subscription.Owner),
                    protocol: <SubscriptionProtocol>(check subscription.Protocol),
                    endpoint: (check subscription.Endpoint)
                });
            }
        } on fail error e {
            return error ResponseHandleFailedError(e.message(), e);
        }
    }

    public isolated function next() returns record {|Subscription value;|}|Error? {
        if self.subscriptions.length() == 0 {
            if self.initialized && self.nextToken is () {
                return ();
            }

            Error? e = self.fetchSubscriptions();
            self.initialized = true;
            if e is error {
                return e;
            }
        }

        if self.subscriptions.length() == 0 {
            return ();
        }

        return {value: self.subscriptions.remove(0)};
    }

    public isolated function close() returns Error? {
        return ();
    }
}

public class PlatformApplicationsStream {

    private final http:Client amazonSNSClient;
    private final (isolated function (map<string>) returns http:Request|Error) & readonly generateRequest;

    private PlatformApplication[] platformApplications = [];
    private string? nextToken = ();
    private boolean initialized = false;

    public isolated function init(http:Client amazonSNSClient, 
        isolated function (map<string>) returns http:Request|Error generateRequest) {
        self.amazonSNSClient = amazonSNSClient;
        self.generateRequest = generateRequest;
    }

    private isolated function fetchPlatformApplications() returns Error? {
        map<string> parameters = initiateRequest("ListPlatformApplications");

        if self.nextToken is string {
            parameters["NextToken"] = <string>self.nextToken;
        }

        http:Request request = check self.generateRequest(parameters);
        json response = check sendRequest(self.amazonSNSClient, request);

        json|error nextToken = response.ListPlatformApplicationsResponse.ListPlatformApplicationsResult.NextToken;

        if nextToken is json && nextToken != () {
            self.nextToken = nextToken.toString();
        } else {
            self.nextToken = ();
        }

        do {
            json[] platformApplications = <json[]>(check response.ListPlatformApplicationsResponse
                .ListPlatformApplicationsResult.PlatformApplications);

            foreach json platformApplication in platformApplications {

                RetrievablePlatformApplicationAttributes attributes = 
                    check mapJsonToPlatformApplicationAttributes(check platformApplication.Attributes);
                PlatformApplication application = {
                    platformApplicationArn: (check platformApplication.PlatformApplicationArn),
                    ...attributes
                };
                self.platformApplications.push(application);
                
            }
        } on fail error e {
            return error ResponseHandleFailedError(e.message(), e);
        }
    }

    public isolated function next() returns record {|PlatformApplication value;|}|Error? {
        if self.platformApplications.length() == 0 {
            if self.initialized && self.nextToken is () {
                return ();
            }

            Error? e = self.fetchPlatformApplications();
            self.initialized = true;
            if e is error {
                return e;
            }
        }

        if self.platformApplications.length() == 0 {
            return ();
        }

        return {value: self.platformApplications.remove(0)};
    }

    public isolated function close() returns Error? {
        return ();
    }
}
