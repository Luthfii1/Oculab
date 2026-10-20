import SwiftUI

/// An empty birth date stays empty until the user confirms a calendar date.
struct PatientBirthDateField: View {
    @Binding var date: Date?
    @State private var isPresented = false
    @State private var draftDate = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AppPatient.dateOfBirth + " *")
                .font(AppTypography.p3)
                .foregroundStyle(AppColors.slate900)
            Button {
                draftDate = date ?? Date()
                isPresented = true
            } label: {
                HStack {
                    Text(date.map { $0.formatted(date: .abbreviated, time: .omitted) } ?? AppPatient.Placeholder.selectDate)
                        .foregroundStyle(date == nil ? AppColors.slate400 : AppColors.slate900)
                    Spacer(minLength: 8)
                    Image(systemName: "calendar").foregroundStyle(AppColors.slate500)
                }
                .font(AppTypography.p2)
                .padding(12)
                .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
                .background(AppColors.slate0, in: RoundedRectangle(cornerRadius: 12))
                .overlay { RoundedRectangle(cornerRadius: 12).stroke(AppColors.slate200, lineWidth: 1) }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(AppPatient.dateOfBirth)
            .accessibilityValue(date.map { $0.formatted(date: .long, time: .omitted) } ?? AppPatient.Placeholder.selectDate)
        }
        .sheet(isPresented: $isPresented) {
            NavigationStack {
                DatePicker(AppPatient.dateOfBirth, selection: $draftDate, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                    .navigationTitle(AppPatient.dateOfBirth)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(AppCommon.cancel) { isPresented = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button(AppAction.done) {
                                date = draftDate
                                isPresented = false
                            }
                        }
                    }
            }
            .tint(AppColors.purple500)
        }
    }
}
