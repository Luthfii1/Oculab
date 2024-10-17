//
//  HomePresenter.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 16/10/24.
//

import Foundation

class HomePresenter: ObservableObject {
    @Published var positifCount: Int = 0
    @Published var negatifCount: Int = 0
    @Published var selectedLatestActivity: LatestActivityType = .semua

    func getStatisticData() {
        positifCount = 5
        negatifCount = 2
    }

    func newInputRecord() {
        Router.shared.navigateTo(.instructionRecord)
    }

    func filterLatestActivity(typeActivity: LatestActivityType) {
        selectedLatestActivity = typeActivity
        print("Pressed: ", typeActivity.rawValue)
    }
}
