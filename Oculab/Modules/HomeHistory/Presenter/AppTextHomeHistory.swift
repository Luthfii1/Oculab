//
//  AppTextHomeHistory.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 02/08/25.
//

import Foundation

// MARK: HomeHistory Module Texts
typealias AppTextHomeHistory = AppText.HomeHistory
typealias AppTextHomeHistCompFinishedExamCard = AppText.HomeHistory.FinishedExaminationCardComponent
typealias AppTextHomeHistCompStatistic = AppText.HomeHistory.StatisticComponent
typealias AppTextHomeHistCompWeeklyCalendar = AppText.HomeHistory.WeeklyCalendarComponent
typealias AppTextHomeHistCompHomeActivity = AppText.HomeHistory.HomeActivityComponent
typealias AppTextHomeHistCompButtonActivity = AppText.HomeHistory.ButtonActivityComponent
typealias AppTextHomeHistCompHalfCircleProgress = AppText.HomeHistory.HalfCircleProgressComponent

extension AppText {
    enum HomeHistory {
        static let noExaminationMessage = "Tidak ada pemeriksaan diselesaikan pada"
        static let emptyStateImageName = "Empty"

        static let navigationTitleHome = "Tugas Pemeriksaan"
        static let navigationTitleHistory = "Riwayat Pemeriksaan"
        static let taskSectionTitle = "Tugas Pemeriksaan"
        static let newExaminationButton = "Pemeriksaan Baru"
        static let noTaskMessage = "Anda belum ditugaskan untuk melakukan pemeriksaan"
        static let loadingState = AppState.loading("data pemeriksaan anda")

        enum FinishedExaminationCardComponent {
            static let dpjpLabel = "DPJP"
            static let positiveKeyword = "positif"
            static let positiveAltKeyword = "positif"
        }
        
        enum StatisticComponent {
            static let title = "Statistik Pemeriksaan"
            static let tasksCompletedSuffix = "Tugas Selesai"
            static let fromTasksPrefix = "dari"
            static let tasksInTotalSuffix = "Tugas"
            static let positiveLabel = "Positif"
            static let negativeLabel = "Negatif"
        }
        
        enum WeeklyCalendarComponent {
            static let title = "Pemeriksaan Selesai"
        }
        
        enum HomeActivityComponent {
            static let examinationOfficerLabel = "Petugas Pemeriksaan"
        }
        
        enum ButtonActivityComponent {
            // This component doesn't have hardcoded strings, but keeping for consistency
        }
        
        enum HalfCircleProgressComponent {
            // Uses AppValue.percentage directly
        }
    }
}