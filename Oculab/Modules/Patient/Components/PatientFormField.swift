import SwiftUI

struct PatientFormField: View {
    @Bindable var presenter: PatientPresenter

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text(AppTextPatientIntake.demographicsTitle).font(.headline)
                Text(AppTextPatientIntake.requiredHint).font(.subheadline).foregroundStyle(.secondary)
            }
            input(AppPatient.name, required: true, placeholder: AppTextPatientCompFormField.namePlaceholder,
                  text: Binding(get: { presenter.patient.name }, set: { presenter.patient.name = $0; presenter.handleNameChange() }), error: .name)

            VStack(alignment: .leading, spacing: 8) {
                PatientBirthDateField(date: $presenter.selectedDoB)
                    .onChange(of: presenter.selectedDoB) { presenter.handleDateOfBirthChange() }
                Text(AppTextPatientIntake.birthDateHint).font(.caption).foregroundStyle(.secondary)
                fieldError(.dateOfBirth)
            }

            VStack(alignment: .leading, spacing: 8) {
                AppRadioButton(title: AppPatient.gender, isRequired: true,
                               choices: [AppPatient.Gender.female, AppPatient.Gender.male],
                               isDisabled: presenter.isSavingPatient, selectedChoice: $presenter.selectedSex)
                    .onChange(of: presenter.selectedSex) { presenter.handleGenderChange() }
                fieldError(.sex)
            }

            Divider()
            VStack(alignment: .leading, spacing: 8) {
                Text(AppTextPatientIntake.identifiersTitle).font(.headline)
                Text(AppTextPatientIntake.identifiersHint).font(.subheadline).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            input(AppTextPatientIntake.medicalRecordNumber, placeholder: AppTextPatientIntake.medicalRecordPlaceholder,
                  text: Binding(get: { presenter.patient.medicalRecordNumber ?? "" }, set: { presenter.patient.medicalRecordNumber = $0; presenter.handleMedicalRecordChange() }),
                  error: .medicalRecordNumber)
            input(AppPatient.nik, placeholder: AppPatient.Placeholder.nik, text: Binding(get: { presenter.patient.NIK }, set: { presenter.patient.NIK = $0; presenter.handleNIKChange() }), error: .nik, numeric: true)
            input(AppPatient.bpjsNumber, placeholder: AppPatient.Placeholder.bpjs, text: $presenter.BPJSnumber, error: .bpjs, numeric: true)
                .onChange(of: presenter.BPJSnumber) { presenter.handleBPJSChange() }
        }
        .disabled(presenter.isSavingPatient)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(AppAction.done) { presenter.dismissKeyboard() }
            }
        }
    }

    private func input(_ title: String, required: Bool = false, placeholder: String, text: Binding<String>, error: PatientIntakeField, numeric: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(title).font(.subheadline.weight(.semibold))
                if required { Text("*").foregroundStyle(AppColors.red500) }
                else { Text(AppForm.optional).font(.caption).foregroundStyle(.secondary) }
            }
            TextField(placeholder, text: text)
                .keyboardType(numeric ? .numberPad : .default)
                .textInputAutocapitalization(error == .name ? .words : .never)
                .autocorrectionDisabled(error != .name)
                .padding(14)
                .background(AppColors.slate0)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay { RoundedRectangle(cornerRadius: 8).stroke(presenter.fieldErrors[error] == nil ? AppColors.slate300 : AppColors.red500) }
                .accessibilityLabel(title)
            fieldError(error)
        }
    }

    @ViewBuilder
    private func fieldError(_ field: PatientIntakeField) -> some View {
        if let error = presenter.fieldErrors[field] {
            Label(error, systemImage: "exclamationmark.circle")
                .font(.caption).foregroundStyle(AppColors.red700)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
