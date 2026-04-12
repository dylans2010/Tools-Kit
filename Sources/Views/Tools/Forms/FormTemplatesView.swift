import SwiftUI

struct FormTemplatesView: View {
    @ObservedObject var backend: FormsBackend
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Button("Customer Feedback") {
                backend.add(FeedbackFormTemplate.build())
                dismiss()
            }
            Button("Event Registration") {
                backend.add(EventRegistrationFormTemplate.build())
                dismiss()
            }
            Button("Job Application") {
                backend.add(JobApplicationFormTemplate.build())
                dismiss()
            }
        }
        .navigationTitle("Form Templates")
        .toolbar { Button("Close") { dismiss() } }
    }
}
