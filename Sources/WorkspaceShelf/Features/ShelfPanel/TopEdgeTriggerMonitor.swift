import AppKit

@MainActor
final class TopEdgeTriggerMonitor {
    private let trigger: @MainActor () -> Void
    private let isPanelVisible: @MainActor () -> Bool
    private var locationTimer: Timer?
    private var dwellTimer: Timer?
    private var lastTriggerDate = Date.distantPast
    private var hasTriggeredInCurrentZone = false

    // Kept tight enough that reaching for the menu bar clock or a status
    // item on either side doesn't clip the zone.
    private let horizontalHalfWidth: CGFloat = 95
    private let verticalDepth: CGFloat = 22
    private let dwellDuration: TimeInterval = 0.35
    private let cooldownDuration: TimeInterval = 0.8

    init(
        isPanelVisible: @escaping @MainActor () -> Bool,
        trigger: @escaping @MainActor () -> Void
    ) {
        self.isPanelVisible = isPanelVisible
        self.trigger = trigger
    }

    func start() {
        guard locationTimer == nil else { return }

        // NSEvent global mouseMoved delivery can be inconsistent for accessory
        // menu-bar apps. Polling the public mouse location avoids accessibility
        // and Input Monitoring permissions while keeping this tiny task cheap.
        locationTimer = Timer.scheduledTimer(
            withTimeInterval: 1.0 / 12.0,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.evaluateMouseLocation()
            }
        }
        locationTimer?.tolerance = 0.02
        evaluateMouseLocation()
    }

    func stop() {
        locationTimer?.invalidate()
        locationTimer = nil
        dwellTimer?.invalidate()
        dwellTimer = nil
    }

    private func evaluateMouseLocation() {
        let point = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(point) }) else {
            resetZoneState()
            return
        }

        let isInTriggerZone = TopEdgeTriggerZone.contains(
            point: point,
            screenFrame: screen.frame,
            horizontalHalfWidth: horizontalHalfWidth,
            verticalDepth: verticalDepth
        )

        guard isInTriggerZone, !isPanelVisible() else {
            resetZoneState()
            return
        }
        guard Date().timeIntervalSince(lastTriggerDate) >= cooldownDuration else {
            return
        }
        guard !hasTriggeredInCurrentZone else { return }
        guard dwellTimer == nil else { return }

        dwellTimer = Timer.scheduledTimer(
            withTimeInterval: dwellDuration,
            repeats: false
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.dwellTimer = nil
                guard self.isMouseInTriggerZone(), !self.isPanelVisible() else {
                    return
                }
                self.lastTriggerDate = Date()
                self.hasTriggeredInCurrentZone = true
                self.trigger()
            }
        }
    }

    private func isMouseInTriggerZone() -> Bool {
        let point = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(point) }) else {
            return false
        }
        return TopEdgeTriggerZone.contains(
            point: point,
            screenFrame: screen.frame,
            horizontalHalfWidth: horizontalHalfWidth,
            verticalDepth: verticalDepth
        )
    }

    private func resetZoneState() {
        dwellTimer?.invalidate()
        dwellTimer = nil
        hasTriggeredInCurrentZone = false
    }
}

enum TopEdgeTriggerZone {
    static func contains(
        point: CGPoint,
        screenFrame: CGRect,
        horizontalHalfWidth: CGFloat,
        verticalDepth: CGFloat
    ) -> Bool {
        abs(point.x - screenFrame.midX) <= horizontalHalfWidth
            && point.y >= screenFrame.maxY - verticalDepth
    }
}
