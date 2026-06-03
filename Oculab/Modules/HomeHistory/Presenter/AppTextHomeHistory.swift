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
        static let noExaminationMessage = "home_history.no_examination_message".localized
        static let emptyStateImageName = "Empty"

        static let navigationTitleHome = "home_history.navigation_title_home".localized
        static let navigationTitleHistory = "home_history.navigation_title_history".localized
        static let taskSectionTitle = "home_history.task_section_title".localized
        static let newExaminationButton = "home_history.new_examination_button".localized
        static let noTaskMessage = "home_history.no_task_message".localized
        static let noTasksInFilterMessage = "home_history.no_tasks_in_filter_message".localized
        static let taskCountFormat = "home_history.task_count_format".localized
        static let loadingState = AppState.loading("home_history.examination_data".localized)

        enum FinishedExaminationCardComponent {
            static let dpjpLabel = "home_history.finished_card.dpjp_label".localized
            static let positiveKeyword = "home_history.finished_card.positive_keyword".localized
            static let positiveAltKeyword = "home_history.finished_card.positive_alt_keyword".localized
        }
        
        enum StatisticComponent {
            static let title = "home_history.statistic.title".localized
            static let tasksCompletedSuffix = "home_history.statistic.tasks_completed_suffix".localized
            static let fromTasksPrefix = "home_history.statistic.from_tasks_prefix".localized
            static let tasksInTotalSuffix = "home_history.statistic.tasks_total_suffix".localized
            static let completionSummary = "home_history.statistic.completion_summary".localized
            static let completionHint = "home_history.statistic.completion_hint".localized
            static let completedChipLabel = "home_history.statistic.completed_chip".localized
            static let pendingChipLabel = "home_history.statistic.pending_chip".localized
            static let positiveLabel = "home_history.statistic.positive_label".localized
            static let negativeLabel = "home_history.statistic.negative_label".localized
        }
        
        enum WeeklyCalendarComponent {
            static let title = "home_history.weekly_calendar.title".localized
        }
        
        enum HomeActivityComponent {
            static let examinationOfficerLabel = "home_history.home_activity.officer_label".localized
            static let patientLabel = "home_history.home_activity.patient_label".localized
            static let dobLabel = "home_history.home_activity.dob_label".localized
            static let plannedDateLabel = "home_history.home_activity.planned_date_label".localized
        }
        
        enum ButtonActivityComponent {
            // This component doesn't have hardcoded strings, but keeping for consistency
        }
        
        enum HalfCircleProgressComponent {
            // Uses AppValue.percentage directly
        }
    }
}