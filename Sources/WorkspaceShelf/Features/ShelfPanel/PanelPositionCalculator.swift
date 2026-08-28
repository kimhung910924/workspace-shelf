import CoreGraphics

enum PanelPositionCalculator {
    static func origin(
        visibleFrame: CGRect,
        panelSize: CGSize,
        topGap: CGFloat = 8
    ) -> CGPoint {
        let clampedWidth = min(panelSize.width, visibleFrame.width)
        let clampedHeight = min(panelSize.height, visibleFrame.height)
        let proposedX = visibleFrame.midX - clampedWidth / 2
        let proposedY = visibleFrame.maxY - clampedHeight - topGap

        return CGPoint(
            x: min(
                max(proposedX, visibleFrame.minX),
                visibleFrame.maxX - clampedWidth
            ),
            y: min(
                max(proposedY, visibleFrame.minY),
                visibleFrame.maxY - clampedHeight
            )
        )
    }
}

