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
            }
        } catch {
            errorMessage = ErrorHandler.shared.handleError(error, context: .examination)
            isError = true
        }
    }

    @MainActor
    func verifyingFOV(fovId: UUID) async {
        do {
            _ = try await interactor?.verifyingFOV(fovId: fovId)
        } catch {
            errorMessage = ErrorHandler.shared.handleError(error, context: .examination)
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
