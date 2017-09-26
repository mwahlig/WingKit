//
//  ClientTest.swift
//  WingKitTests
//
//  Created by Matt Wahlig on 9/25/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

@testable import WingKit
import XCTest

class ClientTest: WingKitTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testRequestCreationWithValidURL() {

        enum TestEndpoint: Endpoint {
            case test

            var method: HTTPMethod {
                return .get
            }

            var path: String {
                return "/testpath"
            }
        }

        var request: NetworkRequest?
        do {
            request = try Client.request(for: TestEndpoint.test)
        } catch {
            XCTFail()
        }

        guard let createdRequest = request else {
            XCTFail()
            return
        }

        XCTAssertEqual(createdRequest.url.absoluteString, Client.baseURLPath + TestEndpoint.test.path)
        XCTAssertEqual(createdRequest.method, TestEndpoint.test.method)
    }

    func testRequestCreationWithInvalidURL() {

        enum TestEndpoint: Endpoint {
            case test

            var method: HTTPMethod {
                return .get
            }

            var path: String {
                return ":?1/%^!invalidPath"
            }
        }

        let errorExpectation = expectation(description: "wait for error")

        var request: NetworkRequest?
        do {
            request = try Client.request(for: TestEndpoint.test)
        } catch ClientError.invalidURL {
            errorExpectation.fulfill()
        } catch {
            XCTFail("Caught unexpected error: \(error)")
        }

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertNil(request)
    }

    func testRequestCreationPopulatesDefaultHeaders() {

        enum TestEndpoint: Endpoint {
            case test

            var method: HTTPMethod {
                return .get
            }

            var path: String {
                return "/testpath"
            }
        }

        var request: NetworkRequest?
        do {
            request = try Client.request(for: TestEndpoint.test)
        } catch {
            XCTFail()
        }

        guard let createdRequest = request else {
            XCTFail()
            return
        }

        guard let headers = createdRequest.headers else {
            XCTFail()
            return
        }

        guard let acceptValue = headers["Accept"] else {
            XCTFail("Could not find Accept header value!")
            return
        }

        guard let contentTypeValue = headers["Content-Type"] else {
            XCTFail("Could not find Content-Type header value!")
            return
        }

        XCTAssertEqual(acceptValue, "application/json")
        XCTAssertEqual(contentTypeValue, "application/json")
    }

    func testRequestCreationPopulatesCustomHeaders() {

        enum TestEndpoint: Endpoint {
            case test

            var method: HTTPMethod {
                return .get
            }

            var path: String {
                return "/testpath"
            }
        }

        let expectedAcceptValue = "something different"
        let expectedContentType = "a different type"
        let expectedCustomHeaderKey = "different key"
        let expectedCustomHeaderValue = "custom value"

        var request: NetworkRequest?
        do {
            request = try Client.request(
                for: TestEndpoint.test,
                headers: [
                    "Accept": expectedAcceptValue,
                    "Content-Type": expectedContentType,
                    expectedCustomHeaderKey: expectedCustomHeaderValue
                    ]
            )
        } catch {
            XCTFail()
        }

        guard let createdRequest = request else {
            XCTFail()
            return
        }

        guard let headers = createdRequest.headers else {
            XCTFail()
            return
        }

        guard let acceptValue = headers["Accept"] else {
            XCTFail("Could not find Accept header value!")
            return
        }

        guard let contentTypeValue = headers["Content-Type"] else {
            XCTFail("Could not find Content-Type header value!")
            return
        }

        guard let customValue = headers[expectedCustomHeaderKey] else {
            XCTFail("Could not find custom key in headers")
            return
        }

        XCTAssertEqual(acceptValue, expectedAcceptValue)
        XCTAssertEqual(contentTypeValue, expectedContentType)
        XCTAssertEqual(customValue, expectedCustomHeaderValue)
    }

    func testRequestCreationPopulatesParameters() {

        enum TestEndpoint: Endpoint {
            case test

            var method: HTTPMethod {
                return .get
            }

            var path: String {
                return "/testpath"
            }
        }

        let intValueKey = "intValueKey"
        let expectedIntValue = 8

        let stringValueKey = "stringValueKey"
        let expectedStringValue = "something goes here"

        var request: NetworkRequest?
        do {
            request = try Client.request(
                for: TestEndpoint.test,
                parameters: [
                    intValueKey: expectedIntValue,
                    stringValueKey: expectedStringValue
                ])
        } catch {
            XCTFail()
        }

        guard let createdRequest = request else {
            XCTFail()
            return
        }

        guard let parameters = createdRequest.parameters else {
            XCTFail()
            return
        }

        guard let intValue = parameters[intValueKey] as? Int else {
            XCTFail("Could not find intValueKey value!")
            return
        }

        guard let stringValue = parameters[stringValueKey] as? String else {
            XCTFail("Could not find stringValueKey value!")
            return
        }

        XCTAssertEqual(intValue, expectedIntValue)
        XCTAssertEqual(stringValue, expectedStringValue)
    }
}