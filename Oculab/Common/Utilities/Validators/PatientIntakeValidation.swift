import Foundation

enum PatientIntakeField: CaseIterable, Hashable {
    case name, nik, bpjs, dateOfBirth, sex, medicalRecordNumber

    var validationKey: String {
        switch self {
        case .name: return ValidationFieldName.patientName.fieldName
        case .nik: return ValidationFieldName.patientNIK.fieldName
        case .bpjs: return ValidationFieldName.patientBPJS.fieldName
        case .dateOfBirth: return ValidationFieldName.patientDateOfBirth.fieldName
        case .sex: return ValidationFieldName.patientGender.fieldName
        case .medicalRecordNumber: return "patient_medical_record_number"
        }
    }
}

/// Local intake rules, shared by the patient directory and task assignment.
/// Readiness never publishes errors or changes the patient's data.
enum PatientIntakeValidation {
    static func errors(for patient: Patient, now: Date = Date(), calendar: Calendar = .current) -> [PatientIntakeField: String] {
        var result: [PatientIntakeField: String] = [:]
        if patient.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            result[.name] = "patient.intake.validation.name_required".localized
        }
        let nik = patient.NIK.trimmingCharacters(in: .whitespacesAndNewlines)
        if !nik.isEmpty && nik.range(of: "^[0-9]{16}$", options: .regularExpression) == nil {
            result[.nik] = "patient.intake.validation.nik_invalid".localized
        }
        let bpjs = (patient.BPJS ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !bpjs.isEmpty && bpjs.range(of: "^[0-9]{13}$", options: .regularExpression) == nil {
            result[.bpjs] = "patient.intake.validation.bpjs_invalid".localized
        }
        if let birthDate = patient.DoB {
            if calendar.startOfDay(for: birthDate) > calendar.startOfDay(for: now) {
                result[.dateOfBirth] = "patient.intake.validation.birth_date_future".localized
            }
        } else {
            result[.dateOfBirth] = "patient.intake.validation.birth_date_required".localized
        }
        if patient.sex != .MALE && patient.sex != .FEMALE {
            result[.sex] = "patient.intake.validation.sex_required".localized
        }
        if let mrn = patient.medicalRecordNumber?.trimmingCharacters(in: .whitespacesAndNewlines), mrn.utf16.count > 64 {
            result[.medicalRecordNumber] = "patient.intake.validation.medical_record_too_long".localized
        }
        return result
    }

    static func isReady(patient: Patient, now: Date = Date(), calendar: Calendar = .current) -> Bool {
        errors(for: patient, now: now, calendar: calendar).isEmpty
    }
}
