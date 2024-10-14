//
//  AnalysisResultView.swift
//  Oculab
//
//  Created by Risa on 14/10/24.
//

import SwiftUI

struct AnalysisResultView: View {
    var body: some View {
        VStack {
            FolderCard(
                title: "0 BTA",
                images: "9 Gambar"
            )
            FolderCard(
                title: "1-9 BTA",
                images: "9 Gambar"
            )
            FolderCard(
                title: "≥ 10 BTA",
                images: "9 Gambar"
            )
        }
    }
}

#Preview {
    AnalysisResultView()
}
