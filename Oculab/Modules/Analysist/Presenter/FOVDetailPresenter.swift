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
    @Published var boxes: [BoxModel] = []
    @Published var selectedBox: BoxModel?
    @Published var fovDetail: FOVDetailData?
    @Published var errorMessage: String?
    @Published var isBoundingBoxAvailable: Bool = true
    @Published var isBoundingBoxVisible: Bool = true
    
    var boundingBoxIcon: String {
        isBoundingBoxVisible ? AppIcon.eye : AppIcon.eyeSlash
    }

    var backgroundColorBoxIcon: Color {
        isBoundingBoxVisible ? AppColors.purple500 : Color.clear
    }

    var lineWidthBoxIcon: CGFloat {
        isBoundingBoxVisible ? 0 : 1
    }

    func resetView() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            zoomScale = 1.0
            offset = .zero
        }
    }

    @MainActor
    func fetchData(fovId: UUID) async {
        do {
            let result = try await interactor?.fetchData(fovId: fovId)
            if let result {
                fovDetail = result
                boxes = result.boxes
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

            _ = try await interactor?.updateBoxStatus(boxId: boxId, newStatus: newStatus.rawValue)
        } catch {
            errorMessage = ErrorHandler.shared.handleError(error)
            isError = true
        }
    }
}
