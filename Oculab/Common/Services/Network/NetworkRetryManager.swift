//
//  NetworkRetryManager.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 12/08/25.
//

import Foundation
import Network

/// Manages network retry logic with exponential backoff and intelligent retry strategies
@MainActor
class NetworkRetryManager: ObservableObject {
    
    // MARK: - Configuration
    
    private struct RetryConfig {
        static let maxRetryAttempts = 3
        static let baseDelay: TimeInterval = 1.0
        static let maxDelay: TimeInterval = 16.0
        static let backoffMultiplier: Double = 2.0
        static let timeoutInterval: TimeInterval = 30.0
    }
    
    // MARK: - Network Monitoring
    
    private let networkMonitor = NWPathMonitor()
    private let networkQueue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isConnected: Bool = true
    @Published var connectionType: NetworkConnectionType = .unknown
    
    enum NetworkConnectionType {
        case wifi, cellular, ethernet, unknown
    }
    
    // MARK: - Retry State
    
    private var activeRetries: [String: RetryOperation] = [:]
    
    private struct RetryOperation {
        let id: String
        var currentAttempt: Int
        var lastAttemptTime: Date
        let maxAttempts: Int
        let operation: () async throws -> Void
    }
    
    // MARK: - Initialization
    
    nonisolated init() {
        Task { @MainActor in
            startNetworkMonitoring()
        }
    }
    
    deinit {
        networkMonitor.cancel()
    }
    
    // MARK: - Public API
    
    /// Executes a network operation with automatic retry logic
    /// - Parameters:
    ///   - id: Unique identifier for this operation (prevents duplicate retries)
    ///   - maxAttempts: Maximum number of retry attempts (default: 3)
    ///   - operation: The async operation to perform
    /// - Returns: The result of the operation
    /// - Throws: The last error encountered if all retries fail
    func executeWithRetry<T>(
        id: String,
        maxAttempts: Int = RetryConfig.maxRetryAttempts,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        
        // Check if we already have an active retry for this operation
        if activeRetries[id] != nil {
            throw NetworkError.operationInProgress
        }
        
        var lastError: Error?
        
        for attempt in 1...maxAttempts {
            do {
                let result = try await performOperationWithTimeout(operation)
                
                // Success - clean up and return
                activeRetries.removeValue(forKey: id)
                return result
                
            } catch {
                lastError = error
                
                // Don't retry for certain types of errors
                if !shouldRetry(error: error) {
                    activeRetries.removeValue(forKey: id)
                    throw error
                }
                
                // Don't retry on the last attempt
                if attempt == maxAttempts {
                    break
                }
                
                // Calculate delay and wait
                let delay = calculateDelay(for: attempt)
                
                print("🔄 Network retry \(attempt)/\(maxAttempts) for operation '\(id)' after \(delay)s delay")
                
                // Track retry operation
                activeRetries[id] = RetryOperation(
                    id: id,
                    currentAttempt: attempt,
                    lastAttemptTime: Date(),
                    maxAttempts: maxAttempts,
                    operation: {}
                )
                
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        // All retries failed
        activeRetries.removeValue(forKey: id)
        
        if let lastError = lastError {
            throw NetworkError.allRetriesFailed(
                attempts: maxAttempts,
                lastError: lastError
            )
        } else {
            throw NetworkError.unknownError
        }
    }
    
    // MARK: - Private Methods
    
    private func performOperationWithTimeout<T>(
        _ operation: @escaping () async throws -> T
    ) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            // Add the main operation
            group.addTask {
                try await operation()
            }
            
            // Add timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(RetryConfig.timeoutInterval * 1_000_000_000))
                throw NetworkError.timeout
            }
            
            // Return the first result (either success or timeout)
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    private func shouldRetry(error: Error) -> Bool {
        // Don't retry if there's no network connection
        guard isConnected else { return false }
        
        // Check error types that should be retried
        if let networkError = error as? NetworkError {
            switch networkError {
            case .networkError(let message, _):
                // Retry for network-related errors but not authentication
                return !message.lowercased().contains("authentication")
            case .apiError:
                return false // Don't retry API-level errors
            }
        }
        
        // Check URLError types
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut, .cannotConnectToHost, .networkConnectionLost, .notConnectedToInternet:
                return true
            case .badURL, .unsupportedURL, .userAuthenticationRequired, .userCancelledAuthentication:
                return false
            default:
                return true // Retry unknown URL errors
            }
        }
        
        // Retry unknown errors
        return true
    }
    
    private func calculateDelay(for attempt: Int) -> TimeInterval {
        let exponentialDelay = RetryConfig.baseDelay * pow(RetryConfig.backoffMultiplier, Double(attempt - 1))
        
        // Add jitter to prevent thundering herd
        let jitter = Double.random(in: 0.1...0.3)
        let delayWithJitter = exponentialDelay * (1 + jitter)
        
        return min(delayWithJitter, RetryConfig.maxDelay)
    }
    
    private func startNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.updateConnectionType(from: path)
            }
        }
        
        networkMonitor.start(queue: networkQueue)
    }
    
    private func updateConnectionType(from path: NWPath) {
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .ethernet
        } else {
            connectionType = .unknown
        }
    }
}

// MARK: - Enhanced Network Errors

extension NetworkError {
    static let timeout = NetworkError.networkError("Request timed out", endpoint: nil)
    static let operationInProgress = NetworkError.networkError("Operation already in progress", endpoint: nil)
    static let unknownError = NetworkError.networkError("Unknown network error", endpoint: nil)
    
    static func allRetriesFailed(attempts: Int, lastError: Error, endpoint: String? = nil) -> NetworkError {
        return .networkError("All \(attempts) retry attempts failed. Last error: \(lastError.localizedDescription)", endpoint: endpoint)
    }
}
