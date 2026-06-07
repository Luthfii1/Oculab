//
//  ExamDataPresenter.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 18/10/24.
//

import SwiftUI

class ExamDataPresenter: ObservableObject {
    // MARK: - Dependencies
    private let interactor: ExamInteractor
    let videoPresenter = VideoRecordPresenter.shared
    
    // MARK: - Published Properties
    @Published var isLoading: Bool = false
    @Published var isSubmittingExamination: Bool = false
    @Published var recordVideo: URL?

    var buttonTitle: String {
        isSubmittingExamination ? AppTextExam.buttonSubmitting : AppTextExam.buttonStartAnalysis
    }
    @Published var examDetailData: ExaminationDetailData = .init(
        examinationId: AppValue.empty,
        pic: AppValue.empty,
        slideId: AppValue.empty,
        examinationGoal: AppValue.empty,
        type: AppValue.empty,
        dpjp: AppValue.empty
    )
    @Published var patientDetailData: PatientDetailData = .init(
        patientId: AppValue.empty,
        name: AppValue.empty,
        nik: AppValue.empty,
        dob: AppValue.empty,
        sex: AppValue.empty,
        bpjs: AppValue.empty
    )
    @Published var examinations: [AdminExaminationData] = []
    @Published var submissionError: String?

    // MARK: - Initialization
    init(interactor: ExamInteractor) {
        self.interactor = interactor
    }
    
    // MARK: - Computed Properties
    var isButtonEnabled: Bool {
        return recordVideo != nil && !isLoading && !isSubmittingExamination
    }

    var startAnalysisHint: String? {
        guard recordVideo == nil, !isLoading, !isSubmittingExamination else { return nil }
        return AppTextExamDetail.startAnalysisHint
    }

    var patientDisplayRows: [(label: String, value: String)] {
        [
            (AppPatient.name, displayOrDash(patientDetailData.name)),
            (AppPatient.nik, displayOrDash(patientDetailData.nik)),
            (AppPatient.dateOfBirth, displayOrDash(patientDetailData.dob)),
            (AppPatient.gender, formatPatientSex(patientDetailData.sex)),
            (AppPatient.bpjsNumber, displayOrDash(patientDetailData.bpjs)),
        ]
    }

    var specimenDisplayRows: [(label: String, value: String)] {
        [
            (AppMedical.Examination.slideId, displayOrDash(examDetailData.slideId)),
            (AppMedical.Examination.purpose, formatExamGoal(examDetailData.examinationGoal)),
            (AppMedical.Examination.specimenType, formatPreparationType(examDetailData.type)),
        ]
    }

    private func displayOrDash(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? AppValue.defaultStrike : trimmed
    }

    private func formatPatientSex(_ raw: String) -> String {
        switch raw.uppercased() {
        case "MALE": return AppPatient.Gender.male
        case "FEMALE": return AppPatient.Gender.female
        default:
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? AppValue.defaultStrike : trimmed.capitalized
        }
    }

    private func formatExamGoal(_ raw: String) -> String {
        switch raw.uppercased() {
        case ExamGoalType.SCREENING.rawValue:
            return AppTextTaskAssignInputExam.screeningChoice
        case ExamGoalType.TREATMENT.rawValue:
            return AppTextTaskAssignInputExam.followUpChoice
        default:
            return displayOrDash(raw)
        }
    }

    private func formatPreparationType(_ raw: String) -> String {
        switch raw.uppercased() {
        case ExamPreparationType.SP.rawValue:
            return AppTextTaskAssignInputExam.morningChoice
        case ExamPreparationType.SPS.rawValue:
            return AppTextTaskAssignInputExam.anytimeChoice
        default:
            return displayOrDash(raw)
        }
    }
    
    var firstExamination: AdminExaminationData? {
        examinations.first
    }
    
    var secondExamination: AdminExaminationData? {
        examinations.count > 1 ? examinations[1] : nil
    }
    
    var staffInterpretation: String {
        firstExamination?.expertResult ?? AppState.notAvailable
    }

    @MainActor
    func resetState() {
        examinations = []
        recordVideo = nil
    }
}

// MARK: - Video Management Methods
extension ExamDataPresenter {
    @MainActor
    func saveVideo() {
        recordVideo = videoPresenter.previewURL
    }

    private func deleteTemporaryFile(at url: URL) {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: url.path) else {
            Logger.warning("Temporary file does not exist at path: \(url.path)", category: .examination)
            return
        }
        
        do {
            try fileManager.removeItem(at: url)
            Logger.info("Successfully deleted temporary video file at: \(url.path)", category: .examination)
        } catch {
            Logger.error("Error deleting temporary video file: \(error.localizedDescription)", category: .examination)
        }
    }
}

// MARK: - Navigation Methods
extension ExamDataPresenter {
    func newVideoRecord() {
        Router.shared.navigateTo(.videoRecord(slideId: examDetailData.slideId))
    }

    func navigateToAnalysisResult(examinationId: String) {
        Router.shared.navigateTo(.analysisResult(examinationId: examinationId))
    }
}

// MARK: - Submission Methods
extension ExamDataPresenter {
    @MainActor
    func handleSubmit() async -> Bool {
        isSubmittingExamination = true
        defer { isSubmittingExamination = false }
        submissionError = nil

        guard let fileURL = recordVideo else {
            Logger.warning("Submit button pressed but recordVideo URL is nil", category: .examination)
            return false
        }

        do {
            let videoData = try Data(contentsOf: fileURL)
            Logger.info("Video data loaded successfully with size: \(videoData.count) bytes", category: .examination)

            _ = try await interactor.submitExamination(
                examVideo: videoData,
                examinationId: examDetailData.examinationId,
                patientId: patientDetailData.patientId
            )

            Logger.info("Examination submitted successfully", category: .examination)

            recordVideo = nil
            videoPresenter.previewURL = nil
            deleteTemporaryFile(at: fileURL)

            let examinationId = examDetailData.examinationId
            AnalysisTrackingStore.track(examinationId: examinationId)
            Task { @MainActor in
                AnalysisRealtimeService.shared.subscribe(to: examinationId)
                await ExaminationNotificationService.shared.requestAuthorizationIfNeeded()
            }
            navigateToAnalysisResult(examinationId: examinationId)
            return true
        } catch {
            Logger.error("Error submitting or loading video data: \(error)", category: .examination)
            submissionError = ErrorHandler.shared.handleError(error, context: .examination)
            return false
        }
    }
}

// MARK: - Data Fetching Methods
extension ExamDataPresenter {
    @MainActor
    func fetchData(examId: String, patientId: String, userRole: RolesType) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let patientResponse = try await interactor.getPatientById(patientId: patientId)
            patientDetailData = patientResponse
            
            if userRole == .ADMIN {
                await fetchAdminExaminationData(examId: examId)
            } else {
                await fetchRegularExaminationData(examId: examId)
            }
            
        } catch {
            _ = ErrorHandler.shared.handleError(error, context: .examination)
        }
    }
    
    @MainActor
    private func fetchAdminExaminationData(examId: String) async {
        do {
            let examinationResponse = try await interactor.getAdminExamDetail(observationId: examId)
            examinations = examinationResponse.examinations
            
            // Map admin data to examDetailData for compatibility
            examDetailData = ExaminationDetailData(
                examinationId: examinationResponse.observationId,
                pic: examinationResponse.picName,
                slideId: examinationResponse.examinations.first?.slideId ?? AppValue.empty,
                examinationGoal: examinationResponse.goal,
                type: examinationResponse.examinations.first?.preparationType ?? AppValue.empty,
                dpjp: examinationResponse.dpjpName
            )
        } catch {
            Logger.error("Failed to fetch admin examination data: \(error)", category: .examination)
            _ = ErrorHandler.shared.handleError(error, context: .examination)
        }
    }
    
    @MainActor
    private func fetchRegularExaminationData(examId: String) async {
        do {
            let examinationResponse = try await interactor.getExamById(examId: examId)
            examDetailData = examinationResponse
            examinations = []
        } catch {
            Logger.error("Failed to fetch regular examination data: \(error)", category: .examination)
            _ = ErrorHandler.shared.handleError(error, context: .examination)
        }
    }
}
