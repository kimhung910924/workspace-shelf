import CoreGraphics
import XCTest
@testable import WorkspaceShelf

final class TopEdgeTriggerZoneTests: XCTestCase {
    private let screen = CGRect(x: 0, y: 0, width: 1_200, height: 800)

    func testContainsTheTopCenterZone() {
        XCTAssertTrue(
            TopEdgeTriggerZone.contains(
                point: CGPoint(x: 600, y: 780),
                screenFrame: screen,
                horizontalHalfWidth: 150,
                verticalDepth: 36
            )
        )
    }

    func testRejectsPointsOutsideTheNotchZone() {
        XCTAssertFalse(
            TopEdgeTriggerZone.contains(
                point: CGPoint(x: 760, y: 780),
                screenFrame: screen,
                horizontalHalfWidth: 150,
                verticalDepth: 36
            )
        )
        XCTAssertFalse(
            TopEdgeTriggerZone.contains(
                point: CGPoint(x: 600, y: 740),
                screenFrame: screen,
                horizontalHalfWidth: 150,
                verticalDepth: 36
            )
        )
    }
}
