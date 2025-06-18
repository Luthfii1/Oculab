//
//  TrayComponent.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 20/05/25.
//

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
            ZStack {
                AppColors.slate0.ignoresSafeArea()
                VStack(alignment: .leading, spacing: Decimal.d16) {
                    VStack(alignment: .leading) {
                        Text("Verifikasi Bakteri")
                            .font(AppTypography.s4)
                            .foregroundColor(.black)
                    }
                    .padding(.top, Decimal.d16)

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
                                .foregroundColor(currentIndex > 0 ? .black : AppColors.slate100)
                                .disabled(currentIndex == 0)

                                Button(action: {
                                    if currentIndex < boxes.count - 1 {
                                        self.selectedBox = boxes[currentIndex + 1]
                                    }
                                }) {
                                    Image(systemName: "chevron.right")
                                }
                                .foregroundColor(currentIndex < boxes.count - 1 ? .black : AppColors.slate100)
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

                    VStack(alignment: .leading, spacing: Decimal.d12) {
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
                    }
                    .padding(.bottom, Decimal.d16)
                }
                .padding(.horizontal, Decimal.d16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

struct TrayView_Previews: PreviewProvider {
    @State static var selectedBox: BoxModel? = BoxModel(
        id: "box_2",
        width: 25,
        height: 30,
        x: 180,
        y: 400,
        status: .none
    )
    static let boxes = [
        BoxModel(id: "box_1", width: 17, height: 10, x: 40, y: 300, status: .none),
        BoxModel(id: "box_2", width: 25, height: 30, x: 180, y: 400, status: .none),
        BoxModel(id: "box_3", width: 20, height: 25, x: 70, y: 170, status: .none),
        BoxModel(id: "box_4", width: 15, height: 15, x: 210, y: 200, status: .none),
        BoxModel(id: "box_5", width: 15, height: 20, x: 130, y: 350, status: .none),
    ]

    static var previews: some View {
        // Bind selectedBox to state for interactivity
        StatefulPreviewWrapper(selectedBox) { selectedBoxBinding in
            TrayView(
                selectedBox: selectedBoxBinding,
                boxes: boxes,
                onVerify: { print("Verify tapped") },
                onFlag: { print("Flag tapped") },
                onReject: { print("Reject tapped") }
            )
        }
        .previewLayout(.sizeThatFits)
    }
}

struct StatefulPreviewWrapper<Value: Equatable, Content: View>: View {
    @State var value: Value
    var content: (Binding<Value>) -> Content

    init(_ value: Value, content: @escaping (Binding<Value>) -> Content) {
        _value = State(wrappedValue: value)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}
