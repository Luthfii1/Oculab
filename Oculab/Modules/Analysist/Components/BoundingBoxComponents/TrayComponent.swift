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
    var onNavigate: ((BoxModel) -> Void)? = nil
    var onVerify: (() -> Void)? = nil
    var onFlag: (() -> Void)? = nil
    var onReject: (() -> Void)? = nil

    private var sortedBoxes: [BoxModel] {
        boxes.sorted {
            ($0.order ?? Int.max, $0.id) < ($1.order ?? Int.max, $1.id)
        }
    }

    private var reviewableBoxes: [BoxModel] {
        sortedBoxes.filter { $0.status == .none || $0.status == .flagged }
    }

    private func displayIndex(for box: BoxModel) -> Int {
        if let order = box.order { return order }
        return (sortedBoxes.firstIndex(where: { $0.id == box.id }) ?? 0) + 1
    }

    var body: some View {
        if let selectedBox = selectedBox,
           let sortedIndex = reviewableBoxes.firstIndex(where: { $0.id == selectedBox.id })
        {
            VStack(alignment: .leading, spacing: Decimal.d16) {
                Text(AppTextAnalysisVerifSheet.title)
                    .font(AppTypography.s4)
                    .foregroundColor(.black)

                HStack(alignment: .center, spacing: Decimal.d16) {
                    Text(
                        AppTextAnalysisVerifSheet.progressBacilliFormat(
                            String(displayIndex(for: selectedBox)),
                            String(sortedBoxes.count)
                        )
                    )
                    .font(AppTypography.p3)
                    .foregroundColor(.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                    Spacer(minLength: Decimal.d8)

                    HStack(spacing: Decimal.d12) {
                        Button(action: {
                            if sortedIndex > 0 {
                                let previous = reviewableBoxes[sortedIndex - 1]
                                onNavigate?(previous)
                                self.selectedBox = previous
                            }
                        }) {
                            Image(systemName: AppIcon.back)
                                .frame(width: 30, height: 30)
                                .background(sortedIndex > 0 ? AppColors.slate100 : AppColors.slate50)
                                .foregroundColor(sortedIndex > 0 ? .black : AppColors.slate300)
                                .clipShape(Circle())
                        }
                        .disabled(sortedIndex == 0)
                        .accessibilityLabel("Previous detection")

                        Button(action: {
                            if sortedIndex < reviewableBoxes.count - 1 {
                                let next = reviewableBoxes[sortedIndex + 1]
                                onNavigate?(next)
                                self.selectedBox = next
                            }
                        }) {
                            Image(systemName: AppIcon.forward)
                                .frame(width: 30, height: 30)
                                .background(
                                    sortedIndex < reviewableBoxes.count - 1
                                        ? AppColors.slate100
                                        : AppColors.slate50
                                )
                                .foregroundColor(
                                    sortedIndex < reviewableBoxes.count - 1 ? .black : AppColors.slate300
                                )
                                .clipShape(Circle())
                        }
                        .disabled(sortedIndex == reviewableBoxes.count - 1)
                        .accessibilityLabel("Next detection")
                    }
                }
                .padding(.horizontal, Decimal.d12)
                .padding(.vertical, Decimal.d12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.slate50)
                .cornerRadius(Decimal.d8)
                .overlay(
                    RoundedRectangle(cornerRadius: Decimal.d8)
                        .inset(by: 0.5)
                        .stroke(AppColors.slate200, lineWidth: 1)
                )

                HStack(spacing: Decimal.d12) {
                    AppButton(
                        title: AppTextAnalysisVerifSheet.deletingButton,
                        leftIcon: AppIcon.delete,
                        colorType: .destructive(.primary),
                        size: .large,
                        isEnabled: true
                    ) {
                        onReject?()
                    }

                    AppButton(
                        title: AppTextAnalysisVerifSheet.verifyingButton,
                        leftIcon: AppIcon.success,
                        colorType: .primary,
                        size: .large,
                        isEnabled: true
                    ) {
                        onVerify?()
                    }
                }
            }
            .padding(.horizontal, Decimal.d16)
            .padding(.top, Decimal.d12)
            .padding(.bottom, Decimal.d16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(AppColors.slate0)
        } else {
            VStack(spacing: Decimal.d12) {
                ProgressView()
                Text(AppTextAnalysisFOVDetail.loadingDataMessage)
                    .font(AppTypography.p3)
                    .foregroundColor(AppColors.slate400)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.slate0)
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
