//
//  FOVDetailPresenter.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 11/05/25.
//

import Foundation
import SwiftUI

class FOVDetailPresenter: ObservableObject {
    var interactor: FOVDetailInteractor? = FOVDetailInteractor()

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
    @Published var enableAddBacilliFeature: Bool = false
    @Published var numberOfBacilli: Int = 0
    @Published var currentFOVId: UUID?

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

    // functions for create new button
    func startCreatingBox(at location: CGPoint) {
        newBoxLocation = location
        isCreatingNewBox = true
    }

    func cancelBoxCreation() {
        isCreatingNewBox = false
        newBoxLocation = nil
    }

    func confirmBoxCreation(frame: CGRect, frameWidth: Int, frameHeight: Int, scaleX: Double, scaleY: Double) {
        // Convert from view coordinates back to database coordinates
        let databaseX = frame.minX / scaleX
        let databaseY = frame.minY / scaleY
        let databaseWidth = frame.width / scaleX
        let databaseHeight = frame.height / scaleY
        
        // Create new box model
        let newBox = BoxModel(
            id: UUID().uuidString, // Generate temporary ID
            width: databaseWidth,
            height: databaseHeight,
            x: databaseX,
            y: databaseY,
            status: .verified
        )
        
        // Add to local boxes array
        boxes.append(newBox)
        
        // Print the final result
        print("=== NEW BOUNDING BOX CREATED ===")
        print("Database coordinates:")
        print("x: \(databaseX)")
        print("y: \(databaseY)")
        print("width: \(databaseWidth)")
        print("height: \(databaseHeight)")
        print("status: \(newBox.status)")
        print("===============================")
        
        // TODO: Send to API/database here
        // await interactor?.createNewBox(...)
        
        // Reset creation state
        isCreatingNewBox = false
        newBoxLocation = nil
    }

    // network things
    @MainActor
    func fetchData(fovId: UUID) async {
        do {
            let result = try await interactor?.fetchData(fovId: fovId)
            if let result {
                currentFOVId = fovId
                fovDetail = result
                boxes = result.boxes.filter { $0.status != .trashed }
                isBoundingBoxAvailable = true
                isError = false
                errorMessage = nil
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
    func verifyingFOV(fovId: UUID) async {
        // Only attempt to verify if bounding box data is available
        guard isBoundingBoxAvailable else { 
            Logger.info("Skipping FOV verification - no bounding box data available", category: .examination)
            return 
        }
        
        do {
            _ = try await interactor?.verifyingFOV(fovId: fovId)
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

            let result = try await interactor?.updateBoxStatus(boxId: boxId, newStatus: newStatus.rawValue)

            // If boxes updated, move selection to the next box with status .none or .flagged, else nil
            if (result != nil) {
                // Find the next box with status .none or .flagged, skipping the current box
                if let currentIndex = boxes.firstIndex(where: { $0.id == boxId }) {
                    // Search forward first
                    let nextCandidates = boxes[(currentIndex+1)...] + boxes[..<currentIndex]
                    if let nextBox = nextCandidates.first(where: { $0.status == .none || $0.status == .flagged }) {
                        selectedBox = nextBox
                    } else {
                        selectedBox = nil
                    }
                } else {
                    selectedBox = nil
                }
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
