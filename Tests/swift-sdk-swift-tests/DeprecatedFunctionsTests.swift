//
//  DeprecatedFunctionsTests.swift
//  swift-sdk-swift-tests
//
//  Created by Jay Kim on 10/8/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class DeprecatedFunctionsTests: XCTestCase {
    private var apiKey = "123123123"
    private var email = "user@example.com"
    
    func testDeprecatedTrackInAppOpen() {
//        let message = IterableInAppMessage(messageId: "message1",
//                                           campaignId: "",
//                                           trigger: IterableInAppTrigger(dict: [.ITBL_IN_APP_TRIGGER_TYPE: "never"]),
//                                           createdAt: nil,
//                                           expiresAt: nil,
//                                           content: getEmptyInAppContent(),
//                                           saveToInbox: true,
//                                           inboxMetadata: nil,
//                                           customPayload: nil)
//
//        let expectation1 = expectation(description: "track in app open (DEPRECATED VERSION)")
//
//        let networkSession = MockNetworkSession(statusCode: 200)
//        IterableAPI.initializeForTesting(apiKey: apiKey, networkSession: networkSession)
//        IterableAPI.email = email
//
//        networkSession.callback = { _, _, _ in
//            TestUtils.validate(request: networkSession.request!,
//                               requestType: .post,
//                               apiEndPoint: .ITBL_ENDPOINT_API,
//                               path: .ITBL_PATH_TRACK_INAPP_OPEN,
//                               queryParams: [])
//
//            TestUtils.validateHeader(networkSession.request!, self.apiKey)
//
//            let body = networkSession.getRequestBody() as! [String: Any]
//
        // validation breaks here
//            TestUtils.validateDeprecatedMessageContext(messageId: message.messageId,
//                                                       email: self.email,
//                                                       saveToInbox: message.saveToInbox,
//                                                       silentInbox: message.silentInbox,
//                                                       inBody: body)
//
//            TestUtils.validateDeviceInfo(inBody: body)
//
//            expectation1.fulfill()
//        }
//
//        IterableAPI.track(inAppOpen: message.messageId)
//        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testDeprecatedTrackInAppClick() {}
    
    func testDeprecatedTrackInAppClose() {}
    
    func testDeprecatedTrackInAppConsume() {}
    
    private func getEmptyInAppContent() -> IterableHtmlInAppContent {
        return IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: "")
    }
}
