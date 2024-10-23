//
//  ExamInteractor.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 18/10/24.
//

import Foundation

class ExamInteractor {
    private let url = URL(string: "https://example.com/api/examinations")!

    func submitExamination(examData: ExaminationRequest) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let jsonData = try JSONEncoder().encode(examData)
            request.httpBody = jsonData
        } catch {
            print("Failed to encode examination data: \(error)")
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("Error submitting examination data: \(error)")
                return
            }
            guard let data = data else { return }

            print("Response: \(String(data: data, encoding: .utf8) ?? "")")
        }
        task.resume()
    }
}

struct ExaminationRequest: Codable {
    var examinationId: String
    var goal: String
    var preparationType: String
    var slideId: String
    var recordVideo: String
}
