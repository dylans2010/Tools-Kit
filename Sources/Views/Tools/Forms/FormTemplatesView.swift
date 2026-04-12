import SwiftUI

struct FormTemplatesView: View {
    @ObservedObject var backend: FormsBackend
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section("Popular") {
                templateButton("Customer Feedback", form: FeedbackFormTemplate.build())
                templateButton("Event Registration", form: EventRegistrationFormTemplate.build())
                templateButton("Job Application", form: JobApplicationFormTemplate.build())
                templateButton("Bug Report", form: BugReportFormTemplate.build())
                templateButton("IT Service Request", form: ITServiceRequestFormTemplate.build())
                templateButton("Course Evaluation", form: CourseEvaluationFormTemplate.build())
                templateButton("Order Intake", form: OrderIntakeFormTemplate.build())
            }
        }
        .navigationTitle("Form Templates")
        .toolbar { Button("Close") { dismiss() } }
    }

    private func templateButton(_ title: String, form: FormDocument) -> some View {
        Button(title) {
            backend.add(form)
            dismiss()
        }
    }
}
