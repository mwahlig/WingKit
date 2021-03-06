//
//  Client+UploadTargetTest.swift
//  WingKitTests
//
//  Created by Matt Wahlig on 9/27/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

@testable import WingKit
import XCTest

class Client_UploadTargetTest: WingKitTestCase {

    var testObject: Client!
    
    override func setUp() {
        super.setUp()

        testObject = Client()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCreateUploadTargetWhenSuccessful() {

        testObject.token = "token"

        let sessionId = UUID().uuidString
        let patientId = UUID().uuidString

        let expectedTargetId = UUID().uuidString
        let expectedTargetKey = "target-key"
        let expectedTargetBucket = "target-bucket"

        let completionCallbackExpectation = expectation(description: "wait for callback")
        let sendRequestExpectation = expectation(description: "wait for send request to be called")

        mockNetwork.sendRequestStub = { request, completion in

            do {
                let urlRequest = try request.asURLRequest()
                let expectedEndpoint = UploadTargetEndpoint.create(patientId: patientId, sessionId: sessionId)

                XCTAssertEqual(urlRequest.url?.absoluteString,
                               self.testObject.baseURLPath + expectedEndpoint.path)
                XCTAssertEqual(urlRequest.httpMethod, expectedEndpoint.method.rawValue)
            } catch {
                XCTFail()
            }

            completion([
                UploadTarget.Keys.id: expectedTargetId,
                UploadTarget.Keys.key: expectedTargetKey,
                UploadTarget.Keys.bucket: expectedTargetBucket
                ], nil)

            sendRequestExpectation.fulfill()
        }

        testObject.createUploadTarget(forTestSessionId: sessionId, patientId: patientId) { target, error in

            guard let target = target else {
                XCTFail()
                return
            }

            XCTAssertEqual(target.id, expectedTargetId)
            XCTAssertEqual(target.key, expectedTargetKey)
            XCTAssertEqual(target.bucket, expectedTargetBucket)

            completionCallbackExpectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testCreateUploadTargetWhenDecodingFails() {

        testObject.token = "token"

        let sessionId = UUID().uuidString
        let patientId = UUID().uuidString

        let expectedTargetKey = "target-key"
        let expectedTargetBucket = "target-bucket"

        let completionCallbackExpectation = expectation(description: "wait for callback")
        let sendRequestExpectation = expectation(description: "wait for send request to be called")

        mockNetwork.sendRequestStub = { request, completion in

            completion([
                UploadTarget.Keys.key: expectedTargetKey,
                UploadTarget.Keys.bucket: expectedTargetBucket
                ], nil)

            sendRequestExpectation.fulfill()
        }

        testObject.createUploadTarget(forTestSessionId: sessionId, patientId: patientId) { target, error in

            XCTAssertNil(target)

            guard let error = error else {
                XCTFail()
                return
            }

            switch error {
            case WingKit.DecodingError.decodingFailed: completionCallbackExpectation.fulfill()
            default: XCTFail("Received unexpected error: \(error)")
            }
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testCreateUploadTargetWhenResponseIsInvalid() {

        let sessionId = UUID().uuidString
        let patientId = UUID().uuidString

        let completionCallbackExpectation = expectation(description: "wait for callback")
        let sendRequestExpectation = expectation(description: "wait for send request to be called")

        testObject.token = "token"

        mockNetwork.sendRequestStub = { request, completion in

            completion(nil, nil)

            sendRequestExpectation.fulfill()
        }

        testObject.createUploadTarget(forTestSessionId: sessionId, patientId: patientId) { target, error in

            XCTAssertNil(target)

            guard let error = error else {
                XCTFail()
                return
            }

            switch error {
            case NetworkError.invalidResponse: completionCallbackExpectation.fulfill()
            default: XCTFail("Received unexpected error: \(error)")
            }
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testCreateUploadTargetWhenServerRespondsWithError() {

        let sessionId = UUID().uuidString
        let patientId = UUID().uuidString
        let expectedStatusCode = 400

        let completionCallbackExpectation = expectation(description: "wait for callback")
        let sendRequestExpectation = expectation(description: "wait for send request to be called")

        testObject.token = "token"

        mockNetwork.sendRequestStub = { request, completion in

            completion(nil, NetworkError.unacceptableStatusCode(code: expectedStatusCode))

            sendRequestExpectation.fulfill()
        }

        testObject.createUploadTarget(forTestSessionId: sessionId, patientId: patientId) { target, error in

            XCTAssertNil(target)

            guard let error = error else {
                XCTFail()
                return
            }

            switch error {
            case NetworkError.unacceptableStatusCode(let code):
                if code == expectedStatusCode {
                    completionCallbackExpectation.fulfill()
                } else {
                    XCTFail("Received unexpected status code: \(code)")
                }
            default: XCTFail("Received unexpected error: \(error)")
            }
        }

        waitForExpectations(timeout: 1, handler: nil)
    }
}
