import XCTest
@testable import Oculab

final class TestHostIsolationTests: XCTestCase {
    func testUnitTestSchemeExplicitlySelectsAnInertHostScene() {
        #if DEBUG
        XCTAssertTrue(AppLaunchMode.usesUnitTestScene(), "Generate the project before testing so the test action supplies its host flag")
        XCTAssertTrue(AppLaunchMode.usesUnitTestScene(environment: ["OCULAB_UNIT_TESTING": "1"]))
        #else
        XCTAssertFalse(AppLaunchMode.usesUnitTestScene(environment: ["OCULAB_UNIT_TESTING": "1"]))
        #endif
        XCTAssertFalse(AppLaunchMode.usesUnitTestScene(environment: [:]), "Normal launches must use the application scene")
        XCTAssertFalse(AppLaunchMode.usesUnitTestScene(environment: ["OCULAB_UNIT_TESTING": "0"]))
    }
}
