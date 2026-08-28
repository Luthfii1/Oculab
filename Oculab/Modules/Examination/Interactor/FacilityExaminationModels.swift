//
//  FacilityExaminationModels.swift
//  Oculab
//

import Foundation

struct HistoryExamFilters: Equatable {
    var fromDate: Date
    var toDate: Date
    var status: StatusType?
    var grading: GradingType?
    var picId: String?

    static func defaultRange(around date: Date = .now) -> HistoryExamFilters {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .day, value: -7, to: date) ?? date
        return HistoryExamFilters(
            fromDate: calendar.startOfDay(for: start),
            toDate: calendar.startOfDay(for: date),
            status: .FINISHED,
            grading: nil,
            picId: nil
        )
    }

    func queryItems() -> [URLQueryItem] {
        var items: [URLQueryItem] = [
            URLQueryItem(name: "from", value: fromDate.formattedYearMonthDay()),
            URLQueryItem(name: "to", value: toDate.formattedYearMonthDay()),
        ]

        if let status {
            items.append(URLQueryItem(name: "status", value: status.rawValue))
        }
        if let grading, grading != .unknown {
            items.append(URLQueryItem(name: "grading", value: grading.apiValue))
        }
        if let picId, !picId.isEmpty {
            items.append(URLQueryItem(name: "picId", value: picId.lowercased()))
        }

        return items
    }
}

struct FacilityExaminationListData: Decodable {
    let items: [FacilityExaminationItem]
    let total: Int
    let limit: Int
    let offset: Int
}

struct FacilityExaminationItem: Decodable, Identifiable {
    var id: String { examinationId }

    let examinationId: String
    let observationId: String
    let slideId: String
    let patientId: String?
    let patientName: String
    let patientDob: String?
    let picId: String?
    let picName: String
    let dpjpName: String
    let statusExamination: StatusType
    let examinationDate: String?
    let finalGrading: String?
    let archivedAt: String?

    func asFinishedCard() -> FinishedExaminationCardData {
        FinishedExaminationCardData(
            examinationId: examinationId,
            patientId: patientId ?? AppValue.empty,
            slideId: slideId,
            patientName: patientName,
            patientDob: patientDob ?? AppValue.empty,
            dpjpName: dpjpName,
            finalGradingResult: GradingType.fromAPIValue(finalGrading ?? AppValue.empty)
        )
    }
}

struct AdminObservationUpdateBody: Encodable {
    let picId: String?
    let archived: Bool?
}

struct AdminObservationUpdateData: Decodable {
    let observationId: String
    let picId: String?
    let picName: String?
    let archivedAt: String?
}
