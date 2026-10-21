import SwiftUI
import XCTest
@testable import Oculab

final class CameraNavigationTests: XCTestCase {
    private func detail(slideId: String) -> ExaminationDetailData {
        ExaminationDetailData(examinationId: "examination-a", pic: "pic-a", slideId: slideId,
                              examinationGoal: "SCREENING", type: "SP", dpjp: "dpjp-a")
    }

    @MainActor
    func testRecordVideoNavigatesWithoutRequestingPermissionOrAwaitingCaptureStartup() async {
        let originalPath = Router.shared.path
        let originalRoute = Router.shared.currentRoute
        defer { Router.shared.path = originalPath; Router.shared.currentRoute = originalRoute }
        let capture = CameraNavigationSpy()
        capture.previewURL = URL(fileURLWithPath: "/tmp/oculab-navigation-old-preview.mov")
        let examination = ExamDataPresenter(interactor: ExamInteractor(networkService: MockNetworkService()))
        examination.examDetailData = detail(slideId: "SLIDE-ORIGINAL")

        // The entry action itself is synchronous. Hardware startup belongs to the destination's task.
        examination.newVideoRecord(capturePresenter: capture)
        examination.examDetailData = detail(slideId: "SLIDE-CHANGED-AFTER-TAP")
        XCTAssertEqual(capture.preparationCount, 1)
        XCTAssertEqual(capture.permissionChecks, 0)
        XCTAssertNil(capture.previewURL)

        let navigated = expectation(description: "Record-video route enqueued immediately")
        DispatchQueue.main.async {
            XCTAssertEqual(Router.shared.currentRoute, .videoRecord(slideId: "SLIDE-ORIGINAL"),
                           "Navigation must use the slide captured at the tap, before any async scheduling")
            XCTAssertEqual(Router.shared.path.count, originalPath.count + 1)
            XCTAssertEqual(capture.permissionChecks, 0, "The navigation action must never initialize capture hardware")
            navigated.fulfill()
        }
        await fulfillment(of: [navigated], timeout: 5)
    }
}

@MainActor
private final class CameraNavigationSpy: VideoRecordPresenter {
    var preparationCount = 0
    var permissionChecks = 0
    override func prepareForNewSession() {
        preparationCount += 1
        super.prepareForNewSession()
    }
    override func checkPermission() async { permissionChecks += 1 }
}
