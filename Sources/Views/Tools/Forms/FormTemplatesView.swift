import SwiftUI

struct FormTemplatesView: View {
    @ObservedObject var backend: FormsBackend
    @Environment(\.dismiss) private var dismiss

    private let templates: [(title: String, subtitle: String, icon: String, form: FormDocument)] = [
        ("Customer Feedback", "Capture sentiment, ratings, and comments.", "bubble.left.and.bubble.right.fill", FeedbackFormTemplate.build()),
        ("Event Registration", "Collect attendee details and logistics.", "ticket.fill", EventRegistrationFormTemplate.build()),
        ("Job Application", "Screen candidates with structured entries.", "person.text.rectangle.fill", JobApplicationFormTemplate.build()),
        ("Bug Report", "Track reproducible issues with severity.", "ladybug.fill", BugReportFormTemplate.build()),
        ("IT Service Request", "Intake incidents and service needs.", "desktopcomputer", ITServiceRequestFormTemplate.build()),
        ("Course Evaluation", "Gather educational quality feedback.", "graduationcap.fill", CourseEvaluationFormTemplate.build()),
        ("Order Intake", "Collect product/order requirements clearly.", "cart.fill", OrderIntakeFormTemplate.build())
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Popular")
                    .font(.headline)
                    .padding(.horizontal)
                ForEach(templates, id: \.title) { template in
                    Button {
                        backend.add(template.form)
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: template.icon)
                                .font(.title3)
                                .foregroundColor(.blue)
                                .frame(width: 36, height: 36)
                                .background(Color.blue.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(template.title)
                                    .font(.subheadline.bold())
                                    .foregroundColor(.primary)
                                Text(template.subtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Form Templates")
        .toolbar { Button("Close") { dismiss() } }
    }
}
