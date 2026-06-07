//
//  FOVDetailPresenter.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 11/05/25.
//

import Foundation
import SwiftUI

class FOVDetailPresenter: ObservableObject {
    private let interactor: FOVDetailInteractor

    init(interactor: FOVDetailInteractor = FOVDetailInteractor()) {
        self.interactor = interactor
    }

    @Published var zoomScale: CGFloat = 1.0
    @Published var offset: CGSize = .zero
    @Published var description: String?
    @Published var isError: Bool = false
    @Published var isLoading: Bool = false
    @Published var boxes: [BoxModel] = [] {
        didSet {
            numberOfBacilli = boxes.count
        }
    }
    @Published var selectedBox: BoxModel?
    @Published var isSequentialReviewActive: Bool = false
    @Published var fovDetail: FOVDetailData?
    @Published var errorMessage: String?
    @Published var isBoundingBoxAvailable: Bool = true
    @Published var isBoundingBoxVisible: Bool = true
    @Published var isAddBacilliActive: Bool = false
    @Published var enableAddBacilliFeature: Bool = true
    @Published var numberOfBacilli: Int = 0
    @Published var currentFOVId: String?
    var examId: String?

    // For create new box
    @Published var isCreatingNewBox: Bool = false
    @Published var newBoxLocation: CGPoint? = nil
    
    var boundingBoxIcon: String {
        isBoundingBoxVisible ? AppIcon.eye : AppIcon.eyeSlash
    }

    var backgroundColorBoxIcon: Color {
        isBoundingBoxVisible ? AppColors.purple500 : Color.clear
    }

    var lineWidthBoxIcon: CGFloat {
        isBoundingBoxVisible ? 0 : 1
    }
    
    var backgroundColorAddBacilliIcon: Color {
        isAddBacilliActive ? AppColors.purple500 : Color.clear
    }
    
    var lineWidthAddBacilliIcon: CGFloat {
        isAddBacilliActive ? 0 : 1
    }

    var remainingToVerifyCount: Int {
        boxes.filter { $0.status == .none || $0.status == .flagged }.count
    }

    var reviewedCount: Int {
        boxes.filter { $0.status == .verified }.count
    }

    func sortedBoxes(_ source: [BoxModel]) -> [BoxModel] {
        source.sorted { lhs, rhs in
            let leftOrder = lhs.order ?? Int.max
            let rightOrder = rhs.order ?? Int.max
            if leftOrder != rightOrder { return leftOrder < rightOrder }
            return lhs.id < rhs.id
        }
    }

    func pendingBoxes(from source: [BoxModel]) -> [BoxModel] {
        sortedBoxes(source).filter { $0.status == .none || $0.status == .flagged }
    }

    func recommendedNextBox(from source: [BoxModel], excluding boxId: String? = nil) -> BoxModel? {
        if let boxId {
            return nextPendingBox(after: boxId, in: source)
        }
        return pendingBoxes(from: source).first
    }

    func nextPendingBox(after boxId: String, in source: [BoxModel]) -> BoxModel? {
        let sorted = sortedBoxes(source)
        guard let currentIndex = sorted.firstIndex(where: { $0.id == boxId }) else {
            return pendingBoxes(from: source).first
        }

        for index in (currentIndex + 1)..<sorted.count {
            let box = sorted[index]
            if box.status == .none || box.status == .flagged {
                return box
            }
        }

        for index in 0..<currentIndex {
            let box = sorted[index]
            if box.status == .none || box.status == .flagged {
                return box
            }
        }

        return nil
    }

    @MainActor
    func jumpToNextRemaining() {
        isSequentialReviewActive = true
        if let current = selectedBox {
            selectedBox = nextPendingBox(after: current.id, in: boxes)
                ?? pendingBoxes(from: boxes).first
        } else {
            selectedBox = pendingBoxes(from: boxes).first
        }
        resetView()
    }

    @MainActor
    func navigateToBoxInSequence(_ box: BoxModel) {
        isSequentialReviewActive = true
        selectedBox = box
    }

    @MainActor
    func startReviewFromFirst() {
        isSequentialReviewActive = true
        selectedBox = pendingBoxes(from: boxes).first
        resetView()
    }

    @MainActor
    func selectBox(_ box: BoxModel) {
        isSequentialReviewActive = false
        selectedBox = box
    }

    func displayIndex(for box: BoxModel, in source: [BoxModel]) -> Int {
        if let order = box.order { return order }
        guard let index = sortedBoxes(source).firstIndex(where: { $0.id == box.id }) else { return 1 }
        return index + 1
    }

    func resetView() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            zoomScale = 1.0
            offset = .zero
        }
    }

    @MainActor
    func resetState() {
        zoomScale = 1.0
        offset = .zero
        description = nil
        isError = false
        boxes = []
        selectedBox = nil
        isSequentialReviewActive = false
        fovDetail = nil
        errorMessage = nil
        isBoundingBoxAvailable = true
        isBoundingBoxVisible = true
        isAddBacilliActive = false
        numberOfBacilli = 0
        currentFOVId = nil
        examId = nil
        isCreatingNewBox = false
        newBoxLocation = nil
    }

    func notifyValidationDataChanged() {
        guard let examId, !examId.isEmpty else { return }
        NotificationCenter.default.post(
            name: .fovVerificationUpdated,
            object: nil,
            userInfo: ["examId": examId]
        )
    }

    // functions for create new button
    func startCreatingBox(at location: CGPoint) {
        newBoxLocation = location
        isCreatingNewBox = true
    }

    func cancelBoxCreation() {
        isCreatingNewBox = false
        newBoxLocation = nil
    }

    @MainActor
    func confirmBoxCreation(frame: CGRect, frameWidth: Int, frameHeight: Int, scaleX: Double, scaleY: Double) async {
        // The existing boxes use center positioning, so we need to convert the frame
        // from top-left positioning to center positioning for consistency
        
        // Calculate the center point of the editable box in view coordinates
        let centerX = frame.midX
        let centerY = frame.midY
        
        // Convert the center point back to database coordinates
        let databaseCenterX = centerX / scaleX
        let databaseCenterY = centerY / scaleY
        
        // Convert size to database coordinates
        let databaseWidth = (frame.width / scaleX) + 10 // fixed variable, this number already looks good
        let databaseHeight = (frame.height / scaleY) + 10 // fixed variable, this number already looks good
        
        // Calculate the top-left position in database coordinates (what the API expects)
        let databaseX = databaseCenterX - databaseWidth / 2
        let databaseY = (databaseCenterY - databaseHeight / 2) + 25 // fixed variable, this number already looks good
        
        // Create new box model
        let newBox = AddBoxRequest(
            x: databaseX,
            y: databaseY,
            width: databaseWidth,
            height: databaseHeight
        )
        
        guard let currentFOVId = currentFOVId else { return }
        
        do {
            _ = try await interactor.addBox(fovId: currentFOVId, newBox: newBox)
            await fetchData(fovId: currentFOVId)
            notifyValidationDataChanged()
        } catch {
            _ = ErrorHandler.shared.handleError(error, context: .examination)
        }
        
        // Reset creation state
        isCreatingNewBox = false
        newBoxLocation = nil
    }

    // network things
    @MainActor
    func fetchData(fovId: String, autoSelectFirst: Bool = false) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await interactor.fetchData(fovId: fovId)
            currentFOVId = fovId
            fovDetail = result
            boxes = sortedBoxes(result.boxes.filter { $0.status != .trashed })
            isBoundingBoxAvailable = true
            isError = false
            errorMessage = nil

            if autoSelectFirst {
                selectedBox = recommendedNextBox(from: boxes)
            }
        } catch {
            let errorDetails = ErrorHandler.shared.handleError(error, context: .examination)
            
            // Check if this is a "no bounding box data" error (404)
            if let networkError = error as? NetworkError,
               case .apiError(let apiErrorResponse, _) = networkError,
               apiErrorResponse.data.errorType == "RESOURCE_NOT_FOUND" {
                
                // This is expected - FOV exists but no bounding box data yet
                isBoundingBoxAvailable = false
                isError = false
                errorMessage = AppTextAnalysisFOVDetail.boundingBoxNotAvailableMessage
                
                // Create a minimal fovDetail so the image can still be shown
                fovDetail = FOVDetailData(frameWidth: 0, frameHeight: 0, boxes: [])
                
            } else {
                // This is an unexpected error
                errorMessage = errorDetails
                isError = true
                isBoundingBoxAvailable = false
            }
        }
    }

    @MainActor
    func verifyingFOV(fovId: String) async {
        // Only attempt to verify if bounding box data is available
        guard isBoundingBoxAvailable else { 
            Logger.info("Skipping FOV verification - no bounding box data available", category: .examination)
            return 
        }
        
        do {
            _ = try await interactor.verifyingFOV(fovId: fovId)
        } catch {
            let errorDetails = ErrorHandler.shared.handleError(error, context: .examination)
            errorMessage = errorDetails
            isError = true
        }
    }

    @MainActor
    func updateBoxStatus(boxId: String, newStatus: BoxStatus) async {
        do {
            guard let index = boxes.firstIndex(where: { $0.id == boxId }) else { return }

            let advanceSequentially = isSequentialReviewActive
            let nextBox = advanceSequentially ? nextPendingBox(after: boxId, in: boxes) : nil

            boxes[index].status = newStatus
            if newStatus == .trashed {
                boxes.remove(at: index)
            }

            if advanceSequentially {
                selectedBox = nextBox
                if nextBox == nil {
                    isSequentialReviewActive = false
                }
            } else {
                selectedBox = nil
            }

            _ = try await interactor.updateBoxStatus(boxId: boxId, newStatus: newStatus.rawValue)

            guard let fovId = currentFOVId else { Logger.error("No fovId set"); return }
            await refreshBoxesQuietly(fovId: fovId)
            notifyValidationDataChanged()

        } catch {
            errorMessage = ErrorHandler.shared.handleError(error)
            isError = true
            if let fovId = currentFOVId {
                await fetchData(fovId: fovId)
            }
        }
    }

    @MainActor
    private func refreshBoxesQuietly(fovId: String) async {
        do {
            let result = try await interactor.fetchData(fovId: fovId)
            fovDetail = result
            boxes = sortedBoxes(result.boxes.filter { $0.status != .trashed })

            if let selected = selectedBox,
               let refreshed = boxes.first(where: { $0.id == selected.id })
            {
                selectedBox = refreshed
            }
        } catch {
            Logger.error("Failed to refresh boxes after status update", category: .examination)
        }
    }
}
