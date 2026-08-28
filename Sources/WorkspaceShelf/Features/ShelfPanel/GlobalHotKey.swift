import Carbon
import Foundation

@MainActor
final class GlobalHotKey {
    enum RegistrationError: LocalizedError {
        case handlerInstallation(OSStatus)
        case registration(OSStatus)

        var errorDescription: String? {
            switch self {
            case .handlerInstallation(let status):
                "단축키 이벤트 처리기를 만들지 못했습니다. 코드: \(status)"
            case .registration(let status):
                "Option + Space 단축키를 등록하지 못했습니다. 다른 앱에서 사용 중일 수 있습니다. 코드: \(status)"
            }
        }
    }

    private static let signature: OSType = 0x57534846 // WSHF
    private static let identifier: UInt32 = 1

    private var hotKeyReference: EventHotKeyRef?
    private var eventHandlerReference: EventHandlerRef?
    private let action: @MainActor () -> Void

    init(action: @escaping @MainActor () -> Void) {
        self.action = action
    }

    func register() throws {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else {
                    return OSStatus(eventNotHandledErr)
                }

                var hotKeyID = EventHotKeyID()
                let parameterStatus = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                guard parameterStatus == noErr,
                      hotKeyID.signature == GlobalHotKey.signature,
                      hotKeyID.id == GlobalHotKey.identifier else {
                    return OSStatus(eventNotHandledErr)
                }

                let manager = Unmanaged<GlobalHotKey>
                    .fromOpaque(userData)
                    .takeUnretainedValue()
                MainActor.assumeIsolated {
                    manager.action()
                }
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerReference
        )

        guard handlerStatus == noErr else {
            throw RegistrationError.handlerInstallation(handlerStatus)
        }

        let hotKeyID = EventHotKeyID(
            signature: Self.signature,
            id: Self.identifier
        )
        let registrationStatus = RegisterEventHotKey(
            UInt32(kVK_Space),
            UInt32(optionKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyReference
        )
        guard registrationStatus == noErr else {
            invalidate()
            throw RegistrationError.registration(registrationStatus)
        }
    }

    func invalidate() {
        if let hotKeyReference {
            UnregisterEventHotKey(hotKeyReference)
            self.hotKeyReference = nil
        }
        if let eventHandlerReference {
            RemoveEventHandler(eventHandlerReference)
            self.eventHandlerReference = nil
        }
    }
}
