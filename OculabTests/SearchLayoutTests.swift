@testable import Oculab
import SwiftUI
import UIKit
import XCTest

final class SearchLayoutTests: XCTestCase {
    @MainActor
    func testSearchFitsSmallPhoneWidthWithQueryAndPlaceholder() async throws {
        for query in ["", "Rizky testing 2 slides"] {
            _ = try await renderSearch(width: 320, typeSize: .large, query: query)
        }
    }

    @MainActor
    func testSearchFitsStandardPhoneWidthWithQueryAndPlaceholder() async throws {
        for query in ["", "Rizky testing 2 slides"] {
            _ = try await renderSearch(width: 375, typeSize: .large, query: query)
        }
    }

    @MainActor
    func testAccessibilitySearchStacksWithoutExceedingSmallPhoneWidth() async throws {
        for query in ["", "Rizky testing 2 slides"] {
            let regularHeight = try await renderSearch(width: 320, typeSize: .large, query: query, attach: false)
            let accessibilityHeight = try await renderSearch(width: 320, typeSize: .accessibility3, query: query)
            XCTAssertGreaterThan(accessibilityHeight, regularHeight + 44,
                                 "Large accessibility text must give the search action its own row")
        }
    }

    @MainActor
    @discardableResult
    private func renderSearch(
        width: CGFloat,
        typeSize: DynamicTypeSize,
        query: String,
        attach: Bool = true
    ) async throws -> CGFloat {
        // Let SwiftUI report its fitting width before installing the host in a window.
        // A fixed SwiftUI frame here could hide the overflow this test is intended to catch.
        let content = AppSearchBar(
            searchText: .constant(query),
            placeholder: "Search patient or examination",
            onSearch: {}
        )
        .padding(24)
        .background(Color.white)
        .environment(\.dynamicTypeSize, typeSize)
        .environment(\.colorScheme, .light)
        let controller = UIHostingController(rootView: content)
        controller.safeAreaRegions = []
        let fittingSize = controller.sizeThatFits(in: CGSize(width: width, height: 10_000))
        XCTAssertTrue(fittingSize.width.isFinite && fittingSize.height.isFinite)
        XCTAssertLessThanOrEqual(fittingSize.width, width + 0.5,
                                 "Search must fit the available width without parent clipping")
        XCTAssertGreaterThanOrEqual(fittingSize.height, 44)
        XCTAssertLessThan(fittingSize.height, 1_000)

        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: width, height: fittingSize.height)
        window.rootViewController = controller
        window.isHidden = false
        defer { window.isHidden = true }
        controller.view.frame = window.bounds
        controller.view.layoutIfNeeded()
        await Task.yield()
        controller.view.layoutIfNeeded()

        // UITextField is a public UIKit control used by SwiftUI's TextField. Do not
        // depend on the names or nesting of private SwiftUI hosting views.
        let textFields = textFields(in: controller.view).filter {
            !$0.isHidden && $0.alpha > 0 && $0.bounds.width > 0 && $0.window === window
        }
        XCTAssertFalse(textFields.isEmpty, "The rendered search field must be present")
        for field in textFields {
            let frame = field.convert(field.bounds, to: controller.view)
            XCTAssertGreaterThanOrEqual(frame.minX, -0.5)
            XCTAssertLessThanOrEqual(frame.maxX, width + 0.5)
            XCTAssertGreaterThan(frame.width, 20, "The action and clear control must leave room to edit a query")
        }

        if attach {
            let sizeName = typeSize.isAccessibilitySize ? "accessibility3" : "normal"
            let queryName = query.isEmpty ? "placeholder" : "query"
            let name = "search-\(Int(width))-\(sizeName)-\(queryName)"
            let image = UIGraphicsImageRenderer(size: window.bounds.size).image { _ in
                controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
            }
            let attachment = XCTAttachment(image: image)
            attachment.name = name
            attachment.lifetime = .keepAlways
            add(attachment)
            if let png = image.pngData() {
                try png.write(to: URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("oculab-\(name).png"))
            }
        }
        return fittingSize.height
    }

    @MainActor
    private func textFields(in view: UIView) -> [UITextField] {
        (view as? UITextField).map { [$0] } ?? view.subviews.flatMap { textFields(in: $0) }
    }
}
