//
//
//  Created by Tapash Majumder on 8/29/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK


class LocalStorageTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testUserIdAndEmail() throws {
        let mockDateProvider = MockDateProvider()
        let localStorage = LocalStorage(dateProvider: mockDateProvider)
        let userId = "zeeUserId"
        let email = "user@example.com"
        try localStorage.save(string: userId, withKey: .userId)
        try localStorage.save(string: email, withKey: .email)
        
        XCTAssertEqual(try localStorage.string(withKey: .userId), userId)
        XCTAssertEqual(try localStorage.string(withKey: .email), email)
    }
    
    func testAttributionInfo() throws {
        let mockDateProvider = MockDateProvider()
        let localStorage = LocalStorage(dateProvider: mockDateProvider)
        let attributionInfo = IterableAttributionInfo(campaignId: 1, templateId: 2, messageId: "3")
        let currentDate = Date()
        let expiration = Calendar.current.date(byAdding: Calendar.Component.hour, value: 24, to: currentDate)!
        try! localStorage.save(codable: attributionInfo, withKey: .attributionInfo, andExpiration: expiration)
        // 23 hours, not expired, still present
        mockDateProvider.currentDate = Calendar.current.date(byAdding: Calendar.Component.hour, value: 23, to: currentDate)!
        let fromLocalStorage:IterableAttributionInfo = try localStorage.codable(withKey: .attributionInfo)!
        XCTAssert(fromLocalStorage == attributionInfo)

        mockDateProvider.currentDate = Calendar.current.date(byAdding: Calendar.Component.hour, value: 25, to: currentDate)!
        let fromLocalStorage2:IterableAttributionInfo? = try localStorage.codable(withKey: .attributionInfo)
        XCTAssertNil(fromLocalStorage2)
    }
    
    func testPayload() throws {
        let mockDateProvider = MockDateProvider()
        let localStorage = LocalStorage(dateProvider: mockDateProvider)
        let payload: [AnyHashable : Any] = [
            "email": "ilya@iterable.com",
            "device": [
                "token": "foo",
                "platform": "bar",
                "applicationName": "baz",
                "dataFields": [
                    "name": "green",
                    "localizedModel": "eggs",
                    "userInterfaceIdiom": "and",
                    "identifierForVendor": "ham",
                    "systemName": "iterable",
                    "systemVersion": "is",
                    "model": "awesome"
                ]
            ]
        ]
        let currentDate = Date()
        let expiration = Calendar.current.date(byAdding: Calendar.Component.hour, value: 24, to: currentDate)!
        try! localStorage.save(dict: payload, withKey: .payload, andExpiration: expiration)
        // 23 hours, not expired, still present
        mockDateProvider.currentDate = Calendar.current.date(byAdding: Calendar.Component.hour, value: 23, to: currentDate)!
        let fromLocalStorage:[AnyHashable : Any] = try localStorage.dict(withKey: .payload)!
        XCTAssertTrue(NSDictionary(dictionary: payload).isEqual(to: fromLocalStorage))
        
        mockDateProvider.currentDate = Calendar.current.date(byAdding: Calendar.Component.hour, value: 25, to: currentDate)!
        let fromLocalStorage2:[AnyHashable : Any]? = try localStorage.dict(withKey: .payload)
        XCTAssertNil(fromLocalStorage2)
    }
}
