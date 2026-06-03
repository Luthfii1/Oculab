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
    @Published var boxes: [BoxModel] = [] {
        didSet {
            numberOfBacilli = boxes.count
        }
    }
    @Published var selectedBox: BoxModel?
    @Published var fovDetail: FOVDetailData?
    @Published var errorMessage: String?
    @Published var isBoundingBoxAvailable: Bool = true
    @Published var isBoundingBoxVisible: Bool = true
    @Published var isAddBacilliActive: Bool = false
    @Published var enableAddBacilliFeature: Bool = true
    @Published var numberOfBacilli: Int = 0
    @Published var currentFOVId: String?

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
        fovDetail = nil
        errorMessage = nil
        isBoundingBoxAvailable = true
        isBoundingBoxVisible = true
        isAddBacilliActive = false
        numberOfBacilli = 0
        currentFOVId = nil
        isCreatingNewBox = false
        newBoxLocation = nil
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
        } catch {
            _ = ErrorHandler.shared.handleError(error, context: .examination)
        }
        
        // Reset creation state
        isCreatingNewBox = false
        newBoxLocation = nil
    }

    // network things
    @MainActor
    func fetchData(fovId: String) async {
        do {
            let result = try await interactor.fetchData(fovId: fovId)
            currentFOVId = fovId
            fovDetail = result
            boxes = result.boxes.filter { $0.status != .trashed }
            isBoundingBoxAvailable = true
            isError = false
            errorMessage = nil
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
            boxes[index].status = newStatus

            _ = try await interactor.updateBoxStatus(boxId: boxId, newStatus: newStatus.rawValue)

            // Move selection to the next box with status .none or .flagged, else nil
            if let currentIndex = boxes.firstIndex(where: { $0.id == boxId }),
               !boxes.isEmpty {
                let safeIndex = min(currentIndex, boxes.count - 1)
                let forwardSlice = (safeIndex + 1) < boxes.count
                    ? Array(boxes[(safeIndex + 1)...])
                    : []
                let backwardSlice = safeIndex > 0
                    ? Array(boxes[..<safeIndex])
                    : []
                let nextCandidates = forwardSlice + backwardSlice
                selectedBox = nextCandidates.first(where: { $0.status == .none || $0.status == .flagged })
            } else {
                selectedBox = nil
            }

            // refetch all boxes
            guard let fovId = currentFOVId else { Logger.error("No fovId set"); return }
            await fetchData(fovId: fovId)

        } catch {
            errorMessage = ErrorHandler.shared.handleError(error)
            isError = true
        }
    }
}
