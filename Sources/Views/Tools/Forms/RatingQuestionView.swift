import SwiftUI

/// Interactive star-based rating question component for filling out a form.
struct RatingQuestionView: View {
    let question: FormQuestion
    @Binding var answer: String

    private var ratingOptions: [String] {
        if question.options.count >= 2,
           let min = Int(question.options[0]),
           let max = Int(question.options[1]),
           min <= max {
            return (min...max).map(String.init)
        }
        let cleaned = question.options.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return cleaned.isEmpty ? ["1", "2", "3", "4", "5"] : cleaned
    }

    private var currentInt: Int {
        Int(answer) ?? 0
    }

    private var maxInt: Int {
        Int(ratingOptions.last ?? "5") ?? 5
    }

    private var minInt: Int {
        Int(ratingOptions.first ?? "1") ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Star row (works best for 1-10 range; uses stars for ≤ 10)
            if ratingOptions.count <= 10 {
                HStack(spacing: 6) {
                    ForEach(ratingOptions, id: \.self) { option in
                        let optInt = Int(option) ?? 0
                        let selected = currentInt > 0 && optInt <= currentInt
                        Button {
                            answer = option
                        } label: {
                            Image(systemName: selected ? "star.fill" : "star")
                                .font(.title2)
                                .foregroundColor(selected ? .orange : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                // Segmented picker for larger ranges
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ratingOptions, id: \.self) { option in
                            let selected = answer == option
                            Button {
                                answer = option
                            } label: {
                                Text(option)
                                    .font(.subheadline.bold())
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(selected ? Color.orange : Color(.secondarySystemBackground))
                                    .foregroundColor(selected ? .white : .primary)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            if !answer.isEmpty {
                HStack {
                    Text("Selected:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(answer)
                        .font(.caption.bold())
                    Spacer()
                    Button {
                        answer = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
