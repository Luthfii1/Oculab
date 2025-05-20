//
//  TrayComponent.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 20/05/25.
//

import SwiftUI

import SwiftUI

struct TrayView: View {
    @Binding var selectedBox: BoxModel?
    let boxes: [BoxModel]
    var onVerify: (() -> Void)? = nil
    var onFlag: (() -> Void)? = nil
    var onReject: (() -> Void)? = nil

    var body: some View {
        if let selectedBox = selectedBox,
           let currentIndex = boxes.firstIndex(where: { $0.id == selectedBox.id })
        {
            VStack(alignment: .leading, spacing: Decimal.d24) {
                VStack(alignment: .leading) {
                    Spacer().frame(height: 52)
                    Text("Verifikasi Bakteri")
                        .font(AppTypography.s4)
                }

                VStack(alignment: .leading, spacing: Decimal.d12) {
                    HStack {
                        Text("Anotasi \(selectedBox.id)")
                            .font(AppTypography.p3)
                            .foregroundColor(.black)
                        Spacer()
                        HStack(spacing: Decimal.d8) {
                            Button(action: {
                                if currentIndex > 0 {
                                    self.selectedBox = boxes[currentIndex - 1]
                                }
                            }) {
                                Image(systemName: "chevron.left")
                            }
                            .disabled(currentIndex == 0)

                            Button(action: {
                                if currentIndex < boxes.count - 1 {
                                    self.selectedBox = boxes[currentIndex + 1]
                                }
                            }) {
                                Image(systemName: "chevron.right")
                            }
                            .disabled(currentIndex == boxes.count - 1)
                        }
                    }
                    .padding(.horizontal, Decimal.d12)
                    .padding(.vertical, Decimal.d12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.slate50)
                    .cornerRadius(Decimal.d8)
                    .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
                    .overlay(
                        RoundedRectangle(cornerRadius: Decimal.d8)
                            .inset(by: 0.5)
                            .stroke(AppColors.slate200, lineWidth: 1)
                    )
                }

                Button(action: { onVerify?() }) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("Verifikasi Anotasi Bakteri").font(AppTypography.p3)
                    }
                    .foregroundColor(.black)
                }
                .buttonStyle(.plain)

                Button(action: { onFlag?() }) {
                    HStack {
                        Image(systemName: "flag.fill")
                        Text("Flag Anotasi Bakteri").font(AppTypography.p3)
                    }
                    .foregroundColor(.black)
                }
                .buttonStyle(.plain)

                Button(action: { onReject?() }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Konfirmasi Bukan Bakteri").font(AppTypography.p3)
                    }
                    .foregroundColor(AppColors.red700)
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, Decimal.d16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

struct TrayView_Previews: PreviewProvider {
    static var previews: some View {
        BoxesGroupComponentView(width: 300, height: 400, boxes: [
            BoxModel(id: 1, width: 100, height: 50, x: 50, y: 50),
            BoxModel(id: 2, width: 100, height: 50, x: 150, y: 150),
            BoxModel(id: 3, width: 100, height: 50, x: 250, y: 250)
        ])
    }
}
