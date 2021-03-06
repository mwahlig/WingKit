//
//  Client+TestSessionTest.swift
//  WingKitTests
//
//  Created by Matt Wahlig on 9/25/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

@testable import WingKit
import XCTest

class Client_TestSessionTest: WingKitTestCase {

    var testObject: Client!
    
    override func setUp() {
        super.setUp()

        testObject = Client()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    // MARK: - Test Session Endpoint

    func testTestSessionEndpointPaths() {

        let patientId = "patient-id"
        let sessionId = "session-id"

        XCTAssertEqual(TestSessionEndpoint.create.path, "/test-sessions")
        XCTAssertEqual(TestSessionEndpoint.retrieve(patientId: patientId, sessionId: sessionId).path,
                       "/patients/\(patientId)/test-sessions/\(sessionId)")
    }

    func testTestSessionEndpointMethods() {

        XCTAssertEqual(TestSessionEndpoint.create.method, .post)
        XCTAssertEqual(TestSessionEndpoint.retrieve(patientId: "patient-id", sessionId: "test-id").method, .get)
    }

    // MARK: - Create Test Session

    func testCreateTestSessionWhenTokenIsNil() {

        let patientData = PatientData(
            id: UUID().uuidString,
            biologicalSex: .male,
            ethnicity: .nativeAmerican,
            height: 66,
            age: 27
        )

        testObject.token = nil

        let errorExpectation = expectation(description: "wait for unauthorized error")

        testObject.createTestSession(with: patientData) { (testSession, error) in

            guard let error = error else {
                XCTFail("Expected to catch unauthorized error!")
                return
            }

            switch error {
            case ClientError.unauthorized: errorExpectation.fulfill()
            default: XCTFail()
            }
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testCreateTestSessionWhenSuccessful() {

        let patientData = PatientData(
            id: UUID().uuidString,
            biologicalSex: .male,
            ethnicity: .nativeAmerican,
            height: 66,
            age: 27
        )

        let expectedToken = UUID().uuidString
        let expectedTestSessionId = UUID().uuidString
        let expectedPatientId = UUID().uuidString
        let expectedStartedAt = Date()
        let expectedReferenceMetric = ReferenceMetric.fev1

        let expectedUploadId1 = UUID().uuidString
        let expectedUploadId2 = UUID().uuidString

        let expectedUploadKey1 = "test-wavs/testupload1.wav"
        let expectedUploadKey2 = "test-wavs/testupload2.wav"

        let expectedUploadBucket = "dev-test-uploads.mywing.io"

        let completionCallbackExpectation = expectation(description: "wait for callback")
        let sendRequestExpectation = expectation(description: "wait for send request to be called")



        testObject.token = expectedToken

        mockNetwork.sendRequestStub = { request, completion in

            do {
                let urlRequest = try request.asURLRequest()

                XCTAssertEqual(urlRequest.url?.absoluteString, self.testObject.baseURLPath + TestSessionEndpoint.create.path)
                XCTAssertEqual(urlRequest.httpMethod, TestSessionEndpoint.create.method.rawValue)
                XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Authorization"], expectedToken)

                guard let requestBody = urlRequest.httpBody,
                    let requestJSON = try? JSONSerialization.jsonObject(with: requestBody, options: []) as? JSON,
                    let patientJSON = requestJSON?["patient"] as? JSON else {
                        XCTFail()
                        return
                }

                XCTAssertEqual(patientJSON["externalId"] as? String, patientData.id)
                XCTAssertEqual(patientJSON["ethnicity"] as? String, patientData.ethnicity?.rawValue)
                XCTAssertEqual(patientJSON["biologicalSex"] as? String, patientData.biologicalSex?.rawValue)
                XCTAssertEqual(patientJSON["height"] as? Int, patientData.height)

                guard let age = patientData.age,
                    let expectedBirthdate = Calendar.current.date(byAdding: .year, value: -age, to: Date()),
                    let actualBirthdate = (patientJSON["dob"] as? String)?.dateFromISO8601 else {
                        XCTFail()
                        return
                }

                XCTAssertEqual(actualBirthdate.timeIntervalSinceReferenceDate,
                               expectedBirthdate.timeIntervalSinceReferenceDate, accuracy: 0.2)


            } catch {
                XCTFail()
            }

            completion([
                TestSession.Keys.id: expectedTestSessionId,
                TestSession.Keys.patientId: expectedPatientId,
                TestSession.Keys.startedAt: expectedStartedAt.iso8601,
                TestSession.Keys.referenceMetric: expectedReferenceMetric.rawValue,
                TestSession.Keys.uploads: [
                    [
                        UploadTarget.Keys.id: expectedUploadId1,
                        UploadTarget.Keys.key: expectedUploadKey1,
                        UploadTarget.Keys.bucket: expectedUploadBucket
                    ],
                    [
                        UploadTarget.Keys.id: expectedUploadId2,
                        UploadTarget.Keys.key: expectedUploadKey2,
                        UploadTarget.Keys.bucket: expectedUploadBucket
                    ]
                ]
                ], nil)

            sendRequestExpectation.fulfill()
        }


        testObject.createTestSession(with: patientData) { (testSession, error) in

            guard let testSession = testSession else {
                XCTFail()
                return
            }

            XCTAssertEqual(testSession.id, expectedTestSessionId)
            XCTAssertEqual(testSession.patientId, expectedPatientId)
            XCTAssertEqual(testSession.startedAt.timeIntervalSinceReferenceDate,
                           expectedStartedAt.timeIntervalSinceReferenceDate,
                           accuracy: 0.02)

            XCTAssertEqual(testSession.uploadTargets.count, 2)
            XCTAssertEqual(testSession.uploadTargets[0].id, expectedUploadId1)
            XCTAssertEqual(testSession.uploadTargets[0].key, expectedUploadKey1)
            XCTAssertEqual(testSession.uploadTargets[0].bucket, expectedUploadBucket)
            XCTAssertEqual(testSession.uploadTargets[1].id, expectedUploadId2)
            XCTAssertEqual(testSession.uploadTargets[1].key, expectedUploadKey2)
            XCTAssertEqual(testSession.uploadTargets[1].bucket, expectedUploadBucket)

            completionCallbackExpectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testCreateTestSessionWhenDecodingFails() {

        let patientData = PatientData(
            id: UUID().uuidString,
            biologicalSex: .male,
            ethnicity: .nativeAmerican,
            height: 66,
            age: 27
        )

        let expectedStartedAt = Date()

        let expectedUploadId1 = UUID().uuidString
        let expectedUploadId2 = UUID().uuidString

        let expectedUploadKey1 = "test-wavs/testupload1.wav"
        let expectedUploadKey2 = "test-wavs/testupload2.wav"

        let expectedUploadBucket = "dev-test-uploads.mywing.io"

        let completionCallbackExpectation = expectation(description: "wait for callback")
        let sendRequestExpectation = expectation(description: "wait for send request to be called")

        testObject.token = UUID().uuidString

        mockNetwork.sendRequestStub = { request, completion in

            completion([
                TestSession.Keys.startedAt: expectedStartedAt.iso8601,
                TestSession.Keys.uploads: [
                    [
                        UploadTarget.Keys.id: expectedUploadId1,
                        UploadTarget.Keys.key: expectedUploadKey1,
                        UploadTarget.Keys.bucket: expectedUploadBucket
                    ],
                    [
                        UploadTarget.Keys.id: expectedUploadId2,
                        UploadTarget.Keys.key: expectedUploadKey2,
                        UploadTarget.Keys.bucket: expectedUploadBucket
                    ]
                ]
                ], nil)

            sendRequestExpectation.fulfill()
        }


        testObject.createTestSession(with: patientData) { (testSession, error) in

            XCTAssertNil(testSession)

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

    func testCreateTestSessionWhenResponseIsInvalid() {

        let patientData = PatientData(
            id: UUID().uuidString,
            biologicalSex: .male,
            ethnicity: .nativeAmerican,
            height: 66,
            age: 27
        )

        testObject.token = UUID().uuidString

        let completionCallbackExpectation = expectation(description: "wait for callback")
        let sendRequestExpectation = expectation(description: "wait for send request to be called")

        mockNetwork.sendRequestStub = { request, completion in

            completion(nil, nil)

            sendRequestExpectation.fulfill()
        }


        testObject.createTestSession(with: patientData) { (testSession, error) in

            XCTAssertNil(testSession)

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

    func testCreateTestSessionWhenServerRespondsWithError() {

        let patientData = PatientData(
            id: UUID().uuidString,
            biologicalSex: .male,
            ethnicity: .nativeAmerican,
            height: 66,
            age: 27
        )

        testObject.token = UUID().uuidString

        let expectedStatusCode = 400
        let completionCallbackExpectation = expectation(description: "wait for callback")
        let sendRequestExpectation = expectation(description: "wait for send request to be called")

        mockNetwork.sendRequestStub = { request, completion in

            completion(nil, NetworkError.unacceptableStatusCode(code: expectedStatusCode))

            sendRequestExpectation.fulfill()
        }


        testObject.createTestSession(with: patientData) { (testSession, error) in

            XCTAssertNil(testSession)

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

    // MARK: - Retrieve Test Session

    func testRetrieveTestSessionWhenTokenIsNil() {

        testObject.token = nil

        let errorExpectation = expectation(description: "wait for error")

        testObject.retrieveTestSession(withId: UUID().uuidString,
                                       patientId: UUID().uuidString) { (testSession, error) in
            guard let error = error else {
                XCTFail()
                return
            }

            switch error {
            case ClientError.unauthorized: errorExpectation.fulfill()
            default: XCTFail()
            }
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testRetrieveTestSessionWhenSuccessful() {

        testObject.token = UUID().uuidString

        let expectedTestSessionId = UUID().uuidString
        let expectedPatientId = UUID().uuidString
        let expectedStartedAt = Date().addingTimeInterval(-700)
        let expectedEndedAt = Date()

        let expectedBestTestChoice = BestTestChoice.reproducible
        let expectedLungFunctionZone = LungFunctionZone.yellowZone
        let expectedRespiratoryState = RespiratoryState.yellowZone
        let expectedReferenceMetric = ReferenceMetric.fev1

        let expectedTestId1 = UUID().uuidString
        let expectedPef1 = 1234.0
        let expectedFev11 = 2345.0
        let expectedTestTakenAt1 = Date().addingTimeInterval(-500)
        let expectedTestStatus1 = TestStatus.complete.rawValue
        let expectedTestBreathDuration1 = 2351.0
        let expectedTestTotalVolume1 = 3591.0
        let expectedTestExhaleCurve1 = [
            [123.0, 234.0],
            [345.0, 456.0]
        ]

        let expectedTestId2 = UUID().uuidString
        let expectedPef2 = 612.0
        let expectedFev12 = 829.0
        let expectedTestTakenAt2 = Date().addingTimeInterval(-20)
        let expectedTestStatus2 = TestStatus.complete.rawValue
        let expectedTestBreathDuration2 = 4810.0
        let expectedTestTotalVolume2 = 8108.0

        let expectedUploadId1 = UUID().uuidString
        let expectedUploadId2 = UUID().uuidString

        let expectedUploadKey1 = "test-wavs/testupload1.wav"
        let expectedUploadKey2 = "test-wavs/testupload2.wav"

        let expectedUploadBucket = "dev-test-uploads.mywing.io"

        let completionCallbackExpectation = expectation(description: "wait for callback")
        let sendRequestExpectation = expectation(description: "wait for send request to be called")

        mockNetwork.sendRequestStub = { request, completion in

            do {
                let urlRequest = try request.asURLRequest()

                let expectedEndpoint = TestSessionEndpoint.retrieve(patientId: expectedPatientId,
                                                                    sessionId: expectedTestSessionId)

                XCTAssertEqual(urlRequest.url?.absoluteString, self.testObject.baseURLPath + expectedEndpoint.path)
                XCTAssertEqual(urlRequest.httpMethod, expectedEndpoint.method.rawValue)

            } catch {
                XCTFail()
            }

            completion([
                TestSession.Keys.id: expectedTestSessionId,
                TestSession.Keys.patientId: expectedPatientId,
                TestSession.Keys.startedAt: expectedStartedAt.iso8601,
                TestSession.Keys.endedAt: expectedEndedAt.iso8601,
                TestSession.Keys.bestTestChoice: expectedBestTestChoice.rawValue,
                TestSession.Keys.lungFunctionZone: expectedLungFunctionZone.rawValue,
                TestSession.Keys.respiratoryState: expectedRespiratoryState.rawValue,
                TestSession.Keys.referenceMetric: expectedReferenceMetric.rawValue,
                TestSession.Keys.bestTest: [
                    Test.Keys.id: expectedTestId1,
                    Test.Keys.breathDuration: expectedTestBreathDuration1,
                    Test.Keys.pef: expectedPef1,
                    Test.Keys.fev1: expectedFev11,
                    Test.Keys.takenAt: expectedTestTakenAt1.iso8601,
                    Test.Keys.exhaleCurve: expectedTestExhaleCurve1,
                    Test.Keys.status: expectedTestStatus1,
                    Test.Keys.totalVolume: expectedTestTotalVolume1,
                    Test.Keys.upload: expectedUploadId1
                ],
                TestSession.Keys.tests: [
                    [
                        Test.Keys.id: expectedTestId1,
                        Test.Keys.breathDuration: expectedTestBreathDuration1,
                        Test.Keys.pef: expectedPef1,
                        Test.Keys.fev1: expectedFev11,
                        Test.Keys.takenAt: expectedTestTakenAt1.iso8601,
                        Test.Keys.status: expectedTestStatus1,
                        Test.Keys.totalVolume: expectedTestTotalVolume1,
                        Test.Keys.upload: expectedUploadId1
                    ],
                    [
                        Test.Keys.id: expectedTestId2,
                        Test.Keys.breathDuration: expectedTestBreathDuration2,
                        Test.Keys.pef: expectedPef2,
                        Test.Keys.fev1: expectedFev12,
                        Test.Keys.takenAt: expectedTestTakenAt2.iso8601,
                        Test.Keys.status: expectedTestStatus2,
                        Test.Keys.totalVolume: expectedTestTotalVolume2,
                        Test.Keys.upload: expectedUploadId2
                    ],
                ],
                TestSession.Keys.uploads: [
                    [
                        UploadTarget.Keys.id: expectedUploadId1,
                        UploadTarget.Keys.key: expectedUploadKey1,
                        UploadTarget.Keys.bucket: expectedUploadBucket
                    ],
                    [
                        UploadTarget.Keys.id: expectedUploadId2,
                        UploadTarget.Keys.key: expectedUploadKey2,
                        UploadTarget.Keys.bucket: expectedUploadBucket
                    ]
                ]
                ], nil)

            sendRequestExpectation.fulfill()
        }


        testObject.retrieveTestSession(withId: expectedTestSessionId,
                                       patientId: expectedPatientId) { (testSession, error) in

            guard let testSession = testSession else {
                XCTFail()
                return
            }

            // Assert test session values

            XCTAssertEqual(testSession.id, expectedTestSessionId)
            XCTAssertEqual(testSession.patientId, expectedPatientId)
            XCTAssertEqual(testSession.startedAt.timeIntervalSinceReferenceDate,
                           expectedStartedAt.timeIntervalSinceReferenceDate,
                           accuracy: 0.02)
            XCTAssertEqual(testSession.endedAt!.timeIntervalSinceReferenceDate,
                           expectedEndedAt.timeIntervalSinceReferenceDate,
                           accuracy: 0.02)
            XCTAssertEqual(testSession.bestTestChoice, expectedBestTestChoice)
            XCTAssertEqual(testSession.lungFunctionZone, expectedLungFunctionZone)
            XCTAssertEqual(testSession.respiratoryState, expectedRespiratoryState)
            XCTAssertEqual(testSession.referenceMetric, expectedReferenceMetric)

            // Assert best test values

            guard let bestTest = testSession.bestTest else {
                XCTFail()
                return
            }

            XCTAssertEqual(bestTest.id, expectedTestId1)
            XCTAssertEqual(bestTest.breathDuration, expectedTestBreathDuration1)

            if let exhaleCurve = bestTest.exhaleCurve {
                for (index, point) in exhaleCurve.enumerated() {
                    XCTAssertEqual(point[0], expectedTestExhaleCurve1[index][0])
                    XCTAssertEqual(point[1], expectedTestExhaleCurve1[index][1])
                }
            }

            XCTAssertEqual(bestTest.fev1, expectedFev11)
            XCTAssertEqual(bestTest.pef, expectedPef1)
            XCTAssertEqual(bestTest.status.rawValue, expectedTestStatus1)
            XCTAssertEqual(bestTest.takenAt!.timeIntervalSinceReferenceDate,
                           expectedTestTakenAt1.timeIntervalSinceReferenceDate,
                           accuracy: 0.02)
            XCTAssertEqual(bestTest.totalVolume, expectedTestTotalVolume1)
            XCTAssertEqual(bestTest.uploadTargetId, expectedUploadId1)

            // Assert test values

            XCTAssertEqual(testSession.tests.count, 2)

            XCTAssertEqual(testSession.tests[0].id, expectedTestId1)
            XCTAssertEqual(testSession.tests[0].breathDuration, expectedTestBreathDuration1)

            XCTAssertEqual(testSession.tests[0].fev1, expectedFev11)
            XCTAssertEqual(testSession.tests[0].pef, expectedPef1)
            XCTAssertEqual(testSession.tests[0].status.rawValue, expectedTestStatus1)
            XCTAssertEqual(testSession.tests[0].takenAt!.timeIntervalSinceReferenceDate,
                           expectedTestTakenAt1.timeIntervalSinceReferenceDate,
                           accuracy: 0.02)
            XCTAssertEqual(testSession.tests[0].totalVolume, expectedTestTotalVolume1)
            XCTAssertEqual(testSession.tests[0].uploadTargetId, expectedUploadId1)


            XCTAssertEqual(testSession.tests[1].id, expectedTestId2)
            XCTAssertEqual(testSession.tests[1].breathDuration, expectedTestBreathDuration2)

            XCTAssertEqual(testSession.tests[1].fev1, expectedFev12)
            XCTAssertEqual(testSession.tests[1].pef, expectedPef2)
            XCTAssertEqual(testSession.tests[1].status.rawValue, expectedTestStatus2)
            XCTAssertEqual(testSession.tests[1].takenAt!.timeIntervalSinceReferenceDate,
                           expectedTestTakenAt2.timeIntervalSinceReferenceDate,
                           accuracy: 0.02)
            XCTAssertEqual(testSession.tests[1].totalVolume, expectedTestTotalVolume2)
            XCTAssertEqual(testSession.tests[1].uploadTargetId, expectedUploadId2)

            // Assert upload target values

            XCTAssertEqual(testSession.uploadTargets.count, 2)
            XCTAssertEqual(testSession.uploadTargets[0].id, expectedUploadId1)
            XCTAssertEqual(testSession.uploadTargets[0].key, expectedUploadKey1)
            XCTAssertEqual(testSession.uploadTargets[0].bucket, expectedUploadBucket)
            XCTAssertEqual(testSession.uploadTargets[1].id, expectedUploadId2)
            XCTAssertEqual(testSession.uploadTargets[1].key, expectedUploadKey2)
            XCTAssertEqual(testSession.uploadTargets[1].bucket, expectedUploadBucket)

            completionCallbackExpectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testRetrieveTestSessionWhenDecodingFails() {

        testObject.token = UUID().uuidString

        let expectedTestSessionId = UUID().uuidString
        let expectedPatientId = UUID().uuidString
        let expectedStartedAt = Date()

        let expectedUploadId1 = UUID().uuidString
        let expectedUploadId2 = UUID().uuidString

        let expectedUploadKey1 = "test-wavs/testupload1.wav"
        let expectedUploadKey2 = "test-wavs/testupload2.wav"

        let expectedUploadBucket = "dev-test-uploads.mywing.io"

        let completionCallbackExpectation = expectation(description: "wait for callback")
        let sendRequestExpectation = expectation(description: "wait for send request to be called")

        mockNetwork.sendRequestStub = { request, completion in

            completion([
                TestSession.Keys.startedAt: expectedStartedAt.iso8601,
                TestSession.Keys.uploads: [
                    [
                        UploadTarget.Keys.id: expectedUploadId1,
                        UploadTarget.Keys.key: expectedUploadKey1,
                        UploadTarget.Keys.bucket: expectedUploadBucket
                    ],
                    [
                        UploadTarget.Keys.id: expectedUploadId2,
                        UploadTarget.Keys.key: expectedUploadKey2,
                        UploadTarget.Keys.bucket: expectedUploadBucket
                    ]
                ]
                ], nil)

            sendRequestExpectation.fulfill()
        }


        testObject.retrieveTestSession(withId: expectedTestSessionId,
                                       patientId: expectedPatientId) { (testSession, error) in

            XCTAssertNil(testSession)

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

    func testRetrieveTestSessionWhenResponseIsInvalid() {

        testObject.token = UUID().uuidString

        let completionCallbackExpectation = expectation(description: "wait for callback")
        let sendRequestExpectation = expectation(description: "wait for send request to be called")

        mockNetwork.sendRequestStub = { request, completion in

            completion(nil, nil)

            sendRequestExpectation.fulfill()
        }


        testObject.retrieveTestSession(withId: UUID().uuidString,
                                       patientId: UUID().uuidString) { (testSession, error) in

            XCTAssertNil(testSession)

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

    func testRetrieveTestSessionWhenServerRespondsWithError() {

        testObject.token = UUID().uuidString

        let expectedStatusCode = 400
        let completionCallbackExpectation = expectation(description: "wait for callback")
        let sendRequestExpectation = expectation(description: "wait for send request to be called")

        mockNetwork.sendRequestStub = { request, completion in

            completion(nil, NetworkError.unacceptableStatusCode(code: expectedStatusCode))

            sendRequestExpectation.fulfill()
        }


        testObject.retrieveTestSession(withId: UUID().uuidString,
                                       patientId: UUID().uuidString) { (testSession, error) in

            XCTAssertNil(testSession)

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
