import XCTest
@testable import AppKitRadixCore

final class PrimitiveViewTests: XCTestCase {
    func testInitialization() {
        let view = PrimitiveView(frame: .zero)
        XCTAssertFalse(view.translatesAutoresizingMaskIntoConstraints)
        XCTAssertNil(view.componentContext)
    }

    func testDefaultAccessibilityRole() {
        let view = PrimitiveView(frame: .zero)
        XCTAssertEqual(view.primitiveAccessibilityRole, .unknown)
    }
}

final class ComponentContextTests: XCTestCase {
    func testStateStorage() {
        let context = ComponentContext(id: "test")
        context.setState("hello", for: "greeting")
        XCTAssertEqual(context.state(for: "greeting", default: ""), "hello")
    }

    func testDefaultState() {
        let context = ComponentContext(id: "test")
        XCTAssertEqual(context.state(for: "missing", default: 42), 42)
    }
}
