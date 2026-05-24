//
//  WeeklyCalendar.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 06/11/24.
//

import SwiftUI

struct WeeklyCalendar: View {
    @Binding var selectedDate: Date
    var onDateSelected: (Date) -> Void

    @State private var currentWeekOffset = 0
    @State private var currentDate = Date()
    @State private var currentWeek: [Date] = []
    @State private var isDatePickerVisible = false
    
    // MARK: - Constants
    private enum DateFormat {
        static let dayOfWeek = "E"
        static let monthYear = "MMMM yyyy"
    }
    
    private enum Constants {
        static let daysInWeek = 7
        static let animationDuration: Double = 0.3
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(alignment: .center, spacing: Decimal.d16) {
                HStack(alignment: .center) {
                    HStack {
                        Image(systemName: AppIcon.textBadgeCheckmark)
                            .resizable()
                            .frame(width: Decimal.d16 + Decimal.d2, height: Decimal.d16 + Decimal.d2)
                            .foregroundColor(AppColors.purple500)

                        Text(AppTextHomeHistCompWeeklyCalendar.title)
                            .padding(.leading, Decimal.d8)
                            .font(AppTypography.s4_1)
                    }
                    Spacer()

                    Text(getMonthAndYear(for: selectedDate))
                        .font(AppTypography.s6)
                        .foregroundColor(AppColors.slate900)

                    Button(action: {
                        withAnimation {
                            isDatePickerVisible.toggle()
                        }
                    }) {
                        Image(systemName: AppIcon.calendar)
                            .resizable()
                            .frame(width: Decimal.d16 + Decimal.d2, height: Decimal.d16 + Decimal.d2)
                            .font(.title)
                            .foregroundColor(AppColors.purple500)
                            .padding(Decimal.d8)
                            .background(AppColors.purple50)
                            .cornerRadius(Decimal.d8)
                    }
                }
                .padding(.top, 16)

                HStack(alignment: .center) {
                    ForEach(currentWeek, id: \.self) { date in

                        VStack(spacing: Decimal.d8) {
                            Text(getDayOfWeek(date: date))
                                .font(AppTypography.s6)
                                .foregroundColor(AppColors.slate100)

                            Text(String(getDayOfMonth(date: date)))
                                .font(AppTypography.p2)
                                .foregroundColor(
                                    isSameDay(date1: date, date2: selectedDate) ? AppColors
                                        .slate0 : AppColors.slate900
                                )
                                .padding(Decimal.d8)
                                .background(
                                    Circle()
                                        .fill(isSameDay(date1: date, date2: selectedDate) ? AppColors.pink400 : .clear)
                                )
                                .frame(width: 40)
                        }
                        .padding(.vertical, Decimal.d6)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(8)
                        .onTapGesture {
                            selectedDate = date
                        }
                    }
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                if value.translation.width < 0 {
                                    swipeLeft()
                                } else if value.translation.width > 0 {
                                    swipeRight()
                                }
                            }
                    )
                }

                .onAppear {
                    setupCurrentWeek()
                }
            }

            if isDatePickerVisible {
                Color.black.opacity(0.4) // Dim background
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation {
                            isDatePickerVisible = false
                        }
                    }

                VStack {
                    DatePicker(
                        AppPatient.Placeholder.selectDate,
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(radius: 8)
                    .onChange(of: selectedDate) { _, newDate in
                        currentWeek = getWeek(for: newDate)
                        withAnimation {
                            isDatePickerVisible = false
                        }
                    }
                }
                .frame(width: 300)
                .transition(.scale) // Smooth scaling animation
            }
        }
    }

    private func swipeLeft() {
        if let nextWeekDate = Calendar.current.date(byAdding: .day, value: Constants.daysInWeek, to: selectedDate) {
            selectedDate = nextWeekDate
            currentWeek = getWeek(for: nextWeekDate)
        }
    }

    private func swipeRight() {
        if let previousWeekDate = Calendar.current.date(byAdding: .day, value: -Constants.daysInWeek, to: selectedDate) {
            selectedDate = previousWeekDate
            currentWeek = getWeek(for: previousWeekDate)
        }
    }

    private func setupCurrentWeek() {
        currentWeek = getWeek(for: selectedDate)
    }

    private func getWeek(for date: Date) -> [Date] {
        let calendar = Calendar.current
        var weekDates: [Date] = []

        guard let startOfWeek = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        ) else {
            return [date]
        }

        for i in 0..<Constants.daysInWeek {
            if let weekDate = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
                weekDates.append(weekDate)
            }
        }
        return weekDates
    }

    private func getDayOfWeek(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = DateFormat.dayOfWeek
        return dateFormatter.string(from: date)
    }

    private func getDayOfMonth(date: Date) -> Int {
        let calendar = Calendar.current
        return calendar.component(.day, from: date)
    }

    private func getMonthAndYear(for date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current // Use current locale for localization
        dateFormatter.dateFormat = DateFormat.monthYear
        return dateFormatter.string(from: date)
    }

    private func isSameDay(date1: Date, date2: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(date1, inSameDayAs: date2)
    }
}

//#Preview {
//    @Previewable @State var selectedDate = Date()
//    WeeklyCalendarView(selectedDate: $selectedDate)
//}
