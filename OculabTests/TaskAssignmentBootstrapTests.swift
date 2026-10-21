import Combine
import XCTest
@testable import Oculab

final class TaskAssignmentBootstrapTests: XCTestCase {
    @MainActor
    private func fixture() -> (TaskAssignmentFlowCoordinator, BootstrapOfficerInteractor, User) {
        let interactor = BootstrapOfficerInteractor()
        let flow = TaskAssignmentFlowCoordinator(repository: TaskAssignmentRepository(interactor: interactor))
        let officer = User(id: "officer-a", name: "Default officer", role: .LAB, businessModel: .B2C)
        return (flow, interactor, officer)
    }

    @MainActor
    func testDefaultOfficerSelectionChangesOnceAndDoesNotFetchDirectly() {
        let (flow, interactor, officer) = fixture()
        var selections: [String] = []
        let observer = flow.$selectedPIC.dropFirst().sink { selections.append($0) }
        XCTAssertNil(flow.selectDefaultOfficerIfNeeded(user: officer))
        XCTAssertEqual(flow.selectedPIC, officer.id)
        XCTAssertEqual(selections, [officer.id])
        XCTAssertTrue(interactor.lookups.isEmpty)

        XCTAssertEqual(flow.selectDefaultOfficerIfNeeded(user: officer), officer.id,
                       "An unresolved unchanged selection returns work to the view-owned task")
        XCTAssertEqual(selections, [officer.id], "Returning must not republish the same selection")
        XCTAssertTrue(interactor.lookups.isEmpty, "Bootstrap selection must not start a second request")
        withExtendedLifetime(observer) {}
    }

    @MainActor
    func testInitialBootstrapSelectionObserverOwnsExactlyOneOfficerLookup() async {
        let (flow, interactor, officer) = fixture()
        var lookupTask: Task<Void, Never>?
        let observer = flow.$selectedPIC.dropFirst().sink { id in
            lookupTask?.cancel()
            lookupTask = Task { await flow.getUserById(userId: id) }
        }
        let explicitLookup = flow.selectDefaultOfficerIfNeeded(user: officer)
        if let explicitLookup {
            lookupTask?.cancel()
            lookupTask = Task { await flow.getUserById(userId: explicitLookup) }
        }
        await lookupTask?.value
        XCTAssertEqual(interactor.lookups, [officer.id])
        XCTAssertEqual(flow.pic.id, officer.id)
        XCTAssertFalse(flow.isError)
        withExtendedLifetime(observer) {}
    }

    @MainActor
    func testReturningWithResolvedOfficerPreservesItWithoutRequery() async {
        let (flow, interactor, officer) = fixture()
        _ = flow.selectDefaultOfficerIfNeeded(user: officer)
        await flow.getUserById(userId: officer.id)
        let resolved = flow.pic
        XCTAssertNil(flow.selectDefaultOfficerIfNeeded(user: officer))
        XCTAssertTrue(flow.pic === resolved)
        XCTAssertEqual(interactor.lookups, [officer.id])
        XCTAssertEqual(flow.selectedPIC, officer.id)
    }

    @MainActor
    func testReturningAfterCancelledPendingLookupRestartsAndIgnoresObsoleteResult() async {
        let (flow, interactor, officer) = fixture()
        let started = expectation(description: "Original officer lookup pending")
        let gate = BootstrapOfficerGate()
        interactor.lookup = { id, call in
            if call == 1 {
                started.fulfill()
                await gate.wait()
                return User(id: id, name: "Cancelled old response", role: .LAB)
            }
            return User(id: id, name: "Recovered officer", role: .LAB)
        }
        _ = flow.selectDefaultOfficerIfNeeded(user: officer)
        let obsolete = Task { await flow.getUserById(userId: officer.id) }
        await fulfillment(of: [started], timeout: 5)
        obsolete.cancel()

        let retryID = flow.selectDefaultOfficerIfNeeded(user: officer)
        XCTAssertEqual(retryID, officer.id, "A pending loading flag must not suppress recovery after cancellation")
        if let retryID { await flow.getUserById(userId: retryID) }
        XCTAssertEqual(flow.pic.name, "Recovered officer")
        XCTAssertFalse(flow.isUserLoading)
        await gate.open()
        await obsolete.value
        XCTAssertEqual(interactor.lookups, [officer.id, officer.id])
        XCTAssertEqual(flow.pic.name, "Recovered officer")
        XCTAssertFalse(flow.isError)
        XCTAssertFalse(flow.isUserLoading)
    }

    @MainActor
    func testAutofillDoesNotOverrideOtherRolesOrBusinessModels() {
        let (flow, interactor, _) = fixture()
        flow.selectedPIC = "manually-selected"
        for user in [User(id: "admin", name: "Admin", role: .ADMIN, businessModel: .B2C),
                     User(id: "facility-officer", name: "Officer", role: .LAB, businessModel: .B2B),
                     User(id: "  ", name: "Missing identity", role: .LAB, businessModel: .B2C)] {
            XCTAssertNil(flow.selectDefaultOfficerIfNeeded(user: user))
        }
        XCTAssertEqual(flow.selectedPIC, "manually-selected")
        XCTAssertTrue(interactor.lookups.isEmpty)
    }
}

@MainActor
private final class BootstrapOfficerInteractor: InputPatientInteractor {
    var lookups: [String] = []
    var lookup: (String, Int) async -> User = { id, _ in User(id: id, name: "Resolved officer", role: .LAB) }
    override func getUserById(userId: String) async throws -> User {
        lookups.append(userId)
        return await lookup(userId, lookups.count)
    }
}

private actor BootstrapOfficerGate {
    private var continuation: CheckedContinuation<Void, Never>?
    private var isOpen = false
    func wait() async {
        if isOpen { return }
        await withCheckedContinuation { continuation = $0 }
    }
    func open() { isOpen = true; continuation?.resume(); continuation = nil }
}
