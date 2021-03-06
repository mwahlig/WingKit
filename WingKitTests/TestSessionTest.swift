//
//  TestSessionTest.swift
//  WingKitTests
//
//  Created by Matt Wahlig on 9/22/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

@testable import WingKit
import XCTest

class TestSessionTest: WingKitTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testIsDecodableFromJSON() {

        let expectedId = UUID().uuidString
        let expectedPatientId = UUID().uuidString
        let expectedStartedAt = Date()
        let expectedEndedAt = Date().addingTimeInterval(30)
        let expectedLungFunctionZone = LungFunctionZone.yellowZone
        let expectedRespiratoryState = RespiratoryState.greenZone
        let expectedReferenceMetric = ReferenceMetric.fev1
        let expectedLatitude = 3.0
        let expectedLongitude = 4.0
        let expectedAltitude = 5.0
        let expectedFloor = 6.0

        let expectedBestTestJSON = Test.sampleJSON()

        let json: JSON = [
            TestSession.Keys.id: expectedId,
            TestSession.Keys.patientId: expectedPatientId,
            TestSession.Keys.startedAt: expectedStartedAt.iso8601,
            TestSession.Keys.endedAt: expectedEndedAt.iso8601,
            TestSession.Keys.lungFunctionZone: expectedLungFunctionZone.rawValue,
            TestSession.Keys.respiratoryState: expectedRespiratoryState.rawValue,
            TestSession.Keys.referenceMetric: expectedReferenceMetric.rawValue,
            TestSession.Keys.metadata: [
                TestSession.Keys.latitude: expectedLatitude,
                TestSession.Keys.longitude: expectedLongitude,
                TestSession.Keys.altitude: expectedAltitude,
                TestSession.Keys.floor: expectedFloor
            ],
            TestSession.Keys.bestTest: expectedBestTestJSON,
            TestSession.Keys.tests: [
                expectedBestTestJSON,
                Test.sampleJSON()
            ]
        ]

        let decoder = WingKit.JSONDecoder()
        var testSession: TestSession?

        do {
            testSession = try decoder.decode(TestSession.self, from: json)
        } catch {
            XCTFail()
            return
        }

        guard let testObject = testSession else {
            XCTFail()
            return
        }

        XCTAssertEqual(testObject.id, expectedId)
        XCTAssertEqual(testObject.patientId, expectedPatientId)
        XCTAssertEqual(testObject.startedAt.timeIntervalSinceReferenceDate, expectedStartedAt.timeIntervalSinceReferenceDate, accuracy: 0.02)
        XCTAssertEqual(testObject.endedAt!.timeIntervalSinceReferenceDate, expectedEndedAt.timeIntervalSinceReferenceDate, accuracy: 0.02)
        XCTAssertEqual(testObject.lungFunctionZone, expectedLungFunctionZone)
        XCTAssertEqual(testObject.respiratoryState, expectedRespiratoryState)
        XCTAssertEqual(testObject.referenceMetric, expectedReferenceMetric)
        XCTAssertEqual(testObject.latitude, expectedLatitude)
        XCTAssertEqual(testObject.longitude, expectedLongitude)
        XCTAssertEqual(testObject.altitude, expectedAltitude)
        XCTAssertEqual(testObject.floor, expectedFloor)
        XCTAssertNotNil(testObject.bestTest)
        XCTAssertEqual(testObject.tests.count, 2)
    }

    func testBestTestChoiceStringValues() {
        XCTAssertEqual(BestTestChoice.reproducible.rawValue, "reproducible")
        XCTAssertEqual(BestTestChoice.highestReference.rawValue, "highest reference")
    }

    func testBestTestChoiceStringToEnum() {
        XCTAssertEqual(BestTestChoice(rawValue: "reproducible"), BestTestChoice.reproducible)
        XCTAssertEqual(BestTestChoice(rawValue: "highest reference"), BestTestChoice.highestReference)
        XCTAssertEqual(BestTestChoice(rawValue: "stark"), nil)
    }

    func testLungFunctionZoneStringValues() {
        XCTAssertEqual(LungFunctionZone.greenZone.rawValue, "green zone")
        XCTAssertEqual(LungFunctionZone.yellowZone.rawValue, "yellow zone")
        XCTAssertEqual(LungFunctionZone.redZone.rawValue, "red zone")
    }

    func testLungFunctionZoneStringToEnum() {
        XCTAssertEqual(LungFunctionZone(rawValue: "green zone"), LungFunctionZone.greenZone)
        XCTAssertEqual(LungFunctionZone(rawValue: "yellow zone"), LungFunctionZone.yellowZone)
        XCTAssertEqual(LungFunctionZone(rawValue: "red zone"), LungFunctionZone.redZone)
        XCTAssertEqual(LungFunctionZone(rawValue: "stark"), nil)
    }

    func testRespiratoryStateStringValues() {
        XCTAssertEqual(RespiratoryState.greenZone.rawValue, "green zone")
        XCTAssertEqual(RespiratoryState.yellowZone.rawValue, "yellow zone")
        XCTAssertEqual(RespiratoryState.redZone.rawValue, "red zone")
        XCTAssertEqual(RespiratoryState.criticalZone.rawValue, "critical zone")
    }

    func testRespiratoryStateStringToEnum() {
        XCTAssertEqual(RespiratoryState(rawValue: "green zone"), RespiratoryState.greenZone)
        XCTAssertEqual(RespiratoryState(rawValue: "yellow zone"), RespiratoryState.yellowZone)
        XCTAssertEqual(RespiratoryState(rawValue: "red zone"), RespiratoryState.redZone)
        XCTAssertEqual(RespiratoryState(rawValue: "critical zone"), RespiratoryState.criticalZone)
        XCTAssertEqual(RespiratoryState(rawValue: "stark"), nil)
    }

    func testReferenceMetricStringValues() {
        XCTAssertEqual(ReferenceMetric.pef.rawValue, "PEF")
        XCTAssertEqual(ReferenceMetric.fev1.rawValue, "FEV1")
    }

    func testReferenceMetricStringToEnum() {
        XCTAssertEqual(ReferenceMetric(rawValue: "PEF"), ReferenceMetric.pef)
        XCTAssertEqual(ReferenceMetric(rawValue: "FEV1"), ReferenceMetric.fev1)
    }

    func testReferenceMetricUnit() {
        XCTAssertEqual(ReferenceMetric.pef.unit, "L/min")
        XCTAssertEqual(ReferenceMetric.fev1.unit, "L")
    }

    func testReferenceMetricFormattedString() {
        XCTAssertEqual(ReferenceMetric.pef.formattedString(forValue: 3.5135, includeUnit: true), "211 L/min")
        XCTAssertEqual(ReferenceMetric.fev1.formattedString(forValue: 3.5182, includeUnit: true), "3.52 L")
    }
}
