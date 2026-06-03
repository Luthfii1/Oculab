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
    var placeholder: String = AppValue.empty
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
            return AppColors.purple100
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
        isDisabled ? AppColors.slate500 : AppColors.slate900
    }

    private var backgroundColor: Color {
        isDisabled ? AppColors.purple50 : AppColors.slate0
    }

    private var displayDateText: String {
        let isPlaceholderDay = Calendar.current.isDate(date, equalTo: Date(), toGranularity: .month)
            && Calendar.current.isDate(date, equalTo: Date(), toGranularity: .day)
        return isPlaceholderDay ? placeholder : date.formattedDDMMYYYY()
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
                    Text(AppValue.required)
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

                if isDisabled {
                    Text(displayDateText)
                        .foregroundStyle(textColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                } else {
                    Button {
                        isDatePickerVisible.toggle()
                    } label: {
                        Text(displayDateText)
                            .foregroundStyle(
                                displayDateText == placeholder ? AppColors.slate400 : AppColors.slate900
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                    }
                    .buttonStyle(.plain)
                }

                if let rightIcon = rightIcon, !isDisabled {
                    Image(systemName: rightIcon)
                        .foregroundColor(iconColor)
                        .padding(.trailing, AppConstants.TaskAssignmentUI.elementSpacing)
                }
            }
            .padding(.vertical, AppConstants.TaskAssignmentUI.elementSpacing)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: 1)
            )
            .background(backgroundColor)
            .allowsHitTesting(!isDisabled)

            Spacer().frame(height: 8)

            if isDatePickerVisible {
                VStack(spacing: 0) {
                    // Header with Done button
                    HStack {
                        Text(AppPatient.Placeholder.selectDate)
                            .font(AppTypography.s4_1)
                            .foregroundColor(AppColors.slate900)
                        
                        Spacer()
                        
                        Button(AppAction.done) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isDatePickerVisible = false
                            }
                        }
                        .font(AppTypography.s4_1)
                        .foregroundColor(AppColors.purple500)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(AppColors.purple50)
                    
                    DatePicker(AppValue.empty, selection: $date, in: ...Date(), displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .padding()
                        .background(AppColors.slate0)
                        .onChange(of: date) { _, _ in
                            // Hide date picker after date selection (when date actually changes)
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isDatePickerVisible = false
                            }
                        }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: 1)
                )
                .background(AppColors.slate0)
                .cornerRadius(8)
            }

            // Description or error message
            if let description = description {
                Text(description)
                    .font(AppTypography.p3)
                    .foregroundColor(isError ? AppColors.red500 : AppColors.slate400)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        DateField(
            title: AppPatient.dateOfBirth,
            isRequired: false,
            placeholder: AppPatient.Placeholder.selectDate,
            description: nil,
            rightIcon: AppIcon.calendar,
            date: .constant(Date())
        )
    }
    .padding()
}
