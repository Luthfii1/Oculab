//
//  DateField.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 07/11/24.
//

import SwiftUI

struct DateField: View {
    var title: String
    var isRequired: Bool = false
    var placeholder: String = ""
    var description: String? = nil
    var leftIcon: String? = nil
    var rightIcon: String? = nil
    var isError: Bool = false
    var isDisabled: Bool = false
    var isNumberOnly: Bool = false
    @Binding var date: Date

    @State var isDatePickerVisible = false

    // Colors based on the state (error, disabled, normal)
    private var borderColor: Color {
        if isError {
            return AppColors.red500
        } else if isDisabled {
            return AppColors.slate200
        } else {
            return AppColors.slate100
        }
    }

    private var iconColor: Color {
        if isError {
            return AppColors.red500
        } else if isDisabled {
            return AppColors.slate100
        } else {
            return AppColors.purple700
        }
    }

    private var textColor: Color {
        isDisabled ? AppColors.slate400 : AppColors.slate900
    }

    private var backgroundColor: Color {
        isDisabled ? AppColors.slate50 : AppColors.slate0
    }

    var body: some View {
        VStack(alignment: .leading) {
            // Title and required indicator
            HStack {
                Text(title)
                    .font(AppTypography.s4_1)
                    .foregroundColor(textColor)
                Spacer().frame(width: 2)
                if isRequired {
                    Text("*")
                        .foregroundColor(AppColors.red500)
                }
            }

            Spacer().frame(height: 8)

            // TextField with icons inside the box
            HStack {
                if let leftIcon = leftIcon {
                    Image(systemName: leftIcon)
                        .foregroundColor(iconColor) // Icon color based on state
                        .padding(.leading, 16)
                }

                Button {
                    if !isDisabled {
                        isDatePickerVisible.toggle()
                    }
                } label: {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(
                                Calendar.current.isDate(date, equalTo: Date(), toGranularity: .month) &&
                                    Calendar.current.isDate(date, equalTo: Date(), toGranularity: .day) ?
                                    placeholder :
                                    date.formattedDDMMYYYY()
                            )
                            .foregroundColor(
                                Calendar.current.isDate(
                                    date,
                                    equalTo: Date(),
                                    toGranularity: .month
                                ) &&
                                    Calendar.current.isDate(date, equalTo: Date(), toGranularity: .day) ? AppColors
                                    .slate100 : AppColors.slate900
                            )
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(textColor)

                            Spacer()
                        }

                    }.frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                }

                if let rightIcon = rightIcon {
                    Image(systemName: rightIcon)
                        .foregroundColor(iconColor) // Icon color based on state
                        .padding(.trailing, Decimal.d12)
                }
            }
            .padding(.vertical, Decimal.d12)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: 1)
            )
            .background(backgroundColor)

            Spacer().frame(height: 8)

            if isDatePickerVisible {
                DatePicker("Date of Birth", selection: $date, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(borderColor, lineWidth: 1)
                    )
            }

            // Description or error message
            if let description = description {
                Text(description)
                    .font(AppTypography.p3)
                    .foregroundColor(isError ? AppColors.red500 : AppColors.slate600)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        DateField(
            title: "Tanggal Lahir",
            isRequired: false,
            placeholder: "Pilih Tanggal",
            description: nil,
            rightIcon: "calendar",
            date: .constant(Date())
        )
    }
    .padding()
}
