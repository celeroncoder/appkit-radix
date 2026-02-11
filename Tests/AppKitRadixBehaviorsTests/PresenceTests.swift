import XCTest
@testable import AppKitRadixBehaviors

final class PresenceTests: XCTestCase {
    func testInitialState() {
        let presence = Presence(isPresent: false)
        XCTAssertFalse(presence.isPresent)
        XCTAssertFalse(presence.isMounted)
    }

    func testPresenceBecomesPresent() {
        let presence = Presence(isPresent: false)
        presence.isPresent = true
        XCTAssertTrue(presence.isMounted)
    }
}
