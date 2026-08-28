import CoreGraphics
import XCTest
@testable import WorkspaceShelf

final class PanelPositionCalculatorTests: XCTestCase {
    func testCentersPanelAtTopOfVisibleFrame() {
        let frame = CGRect(x: 100, y: 50, width: 1_200, height: 800)
        let size = CGSize(width: 780, height: 500)

        let origin = PanelPositionCalculator.origin(
            visibleFrame: frame,
            panelSize: size
        )

        XCTAssertEqual(origin.x, 310)
        XCTAssertEqual(origin.y, 342)
    }

    func testClampsOversizedPanelInsideVisibleFrame() {
        let frame = CGRect(x: 0, y: 0, width: 500, height: 300)
        let size = CGSize(width: 780, height: 500)

        let origin = PanelPositionCalculator.origin(
            visibleFrame: frame,
            panelSize: size
        )

        XCTAssertEqual(origin, .zero)
    }
}

