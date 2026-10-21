import Alamofire
import XCTest
@testable import Oculab

final class ConcurrentReadTests: XCTestCase {
    @MainActor
    private func withService(_ body: (NetworkService) async throws -> Void) async rethrows {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ConcurrentReadURLProtocol.self]
        let session = Session(configuration: configuration)
        let service = NetworkService(retryManager: NetworkRetryManager(monitorsConnectivity: false),
                                     baseService: AlamofireNetworkService(session: session))
        defer {
            ConcurrentReadURLProtocol.handler = nil
            session.session.invalidateAndCancel()
        }
        try await body(service)
    }

    private let endpoint = "https://oculab-concurrency.invalid/user/get-user-data-by-id/officer"

    @MainActor
    func testOverlappingReadersAtSameEndpointReceiveTheirOwnResponses() async throws {
        try await withService { service in
            let started = expectation(description: "First officer lookup held")
            var held: ConcurrentReadURLProtocol?
            var consumers: [String] = []
            ConcurrentReadURLProtocol.handler = { request in
                let consumer = request.request.value(forHTTPHeaderField: "X-Consumer") ?? ""
                consumers.append(consumer)
                if consumers.count == 1 {
                    held = request
                    started.fulfill()
                } else {
                    request.respond(value: consumer)
                }
            }
            let first = Task { () throws -> APIResponse<String> in
                try await service.get(urlString: endpoint, headers: ["X-Consumer": "first-screen"])
            }
            await fulfillment(of: [started], timeout: 5)
            do {
                let second: APIResponse<String> = try await service.get(urlString: endpoint, headers: ["X-Consumer": "second-screen"])
                XCTAssertEqual(second.data, "second-screen")
            } catch { XCTFail("A second read must not be rejected as an operation in progress: \(error)") }
            held?.respond(value: "first-screen")
            let response = try await first.value
            XCTAssertEqual(response.data, "first-screen")
            XCTAssertEqual(consumers, ["first-screen", "second-screen"])
        }
    }

    @MainActor
    func testCancelingOneReaderDoesNotCancelAnotherOrBlockNextRead() async throws {
        try await withService { service in
            let started = expectation(description: "Cancelable lookup held")
            var held: ConcurrentReadURLProtocol?
            var requests = 0
            ConcurrentReadURLProtocol.handler = { request in
                requests += 1
                if requests == 1 {
                    held = request
                    started.fulfill()
                } else { request.respond(value: "current-screen") }
            }
            let first = Task { () throws -> APIResponse<String> in
                try await service.get(urlString: endpoint, headers: nil)
            }
            await fulfillment(of: [started], timeout: 5)
            let second = Task { () throws -> APIResponse<String> in
                try await service.get(urlString: endpoint, headers: nil)
            }
            first.cancel()
            held?.respond(value: "dismissed-screen")
            do { _ = try await first.value; XCTFail("The dismissed read must remain canceled") }
            catch { XCTAssertTrue(error is CancellationError || (error as? URLError)?.code == .cancelled) }
            let response = try await second.value
            XCTAssertEqual(response.data, "current-screen")
            let next: APIResponse<String> = try await service.get(urlString: endpoint, headers: nil)
            XCTAssertEqual(next.data, "current-screen")
            XCTAssertEqual(requests, 3)
        }
    }

    @MainActor
    func testAnotherReadCanCompleteWhileFirstReaderRetries() async throws {
        try await withService { service in
            let attempted = expectation(description: "First read failed transiently")
            var requests = 0
            ConcurrentReadURLProtocol.handler = { request in
                requests += 1
                if requests == 1 {
                    request.fail(URLError(.timedOut))
                    attempted.fulfill()
                } else { request.respond(value: "response-\(requests)") }
            }
            let first = Task { () throws -> APIResponse<String> in
                try await service.get(urlString: endpoint, headers: nil)
            }
            await fulfillment(of: [attempted], timeout: 5)
            let second: APIResponse<String> = try await service.get(urlString: endpoint, headers: nil)
            XCTAssertEqual(second.data, "response-2")
            let retried = try await first.value
            XCTAssertEqual(retried.data, "response-3")
            XCTAssertEqual(requests, 3)
        }
    }

    @MainActor
    func testDuplicateWritesRemainProtectedWhileFirstWriteIsPending() async throws {
        try await withService { service in
            let started = expectation(description: "Patient creation held")
            var held: ConcurrentReadURLProtocol?
            var requests = 0
            ConcurrentReadURLProtocol.handler = { request in
                requests += 1
                held = request
                started.fulfill()
            }
            let first = Task { () throws -> APIResponse<String> in
                try await service.post(urlString: endpoint, headers: nil, body: ["name": "Patient"])
            }
            await fulfillment(of: [started], timeout: 5)
            do {
                let _: APIResponse<String> = try await service.post(urlString: endpoint, headers: nil, body: ["name": "Patient"])
                XCTFail("Duplicate writes must remain protected")
            } catch NetworkError.networkError(let message, _) {
                XCTAssertEqual(message, "Operation already in progress")
            } catch { XCTFail("Unexpected rejection: \(error)") }
            held?.respond(value: "created-once")
            let response = try await first.value
            XCTAssertEqual(response.data, "created-once")
            XCTAssertEqual(requests, 1)
        }
    }
}

private final class ConcurrentReadURLProtocol: URLProtocol {
    private static let handlerLock = NSLock()
    private static var storedHandler: (@MainActor (ConcurrentReadURLProtocol) -> Void)?
    static var handler: (@MainActor (ConcurrentReadURLProtocol) -> Void)? {
        get { handlerLock.lock(); defer { handlerLock.unlock() }; return storedHandler }
        set { handlerLock.lock(); defer { handlerLock.unlock() }; storedHandler = newValue }
    }
    private let terminalLock = NSLock()
    private var isTerminal = false

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Task { @MainActor in
            guard let handler = Self.handler else { fail(URLError(.unsupportedURL)); return }
            handler(self)
        }
    }
    override func stopLoading() { _ = finishOnce() }

    private func finishOnce() -> Bool {
        terminalLock.lock()
        defer { terminalLock.unlock() }
        guard !isTerminal else { return false }
        isTerminal = true
        return true
    }

    func respond(value: String) {
        guard finishOnce() else { return }
        let data = try! JSONSerialization.data(withJSONObject: ["status": "success", "code": 200, "message": "OK", "data": value])
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil,
                                       headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
    func fail(_ error: Error) {
        guard finishOnce() else { return }
        client?.urlProtocol(self, didFailWithError: error)
    }
}
