import SwiftUI

struct ExerciseLoggingView: View {
    @Binding var log: ExerciseSessionLog

    var body: some View {
        Section(log.exerciseName) {
            Stepper("Duration: \(log.durationMinutes) min", value: $log.durationMinutes, in: 0...180)

            ForEach($log.sets) { $set in
                VStack(alignment: .leading, spacing: 8) {
                    Text("Set \(set.setNumber)")
                        .font(.subheadline.bold())
                    Stepper("Reps: \(set.reps)", value: $set.reps, in: 0...50)
                    HStack {
                        Text("Weight (kg)")
                        Spacer()
                        TextField("0", value: $set.weightKg, format: .number)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }
                .padding(.vertical, 6)
            }

            Button("Add Set") {
                let next = (log.sets.last?.setNumber ?? 0) + 1
                log.sets.append(ExerciseSetLog(setNumber: next, reps: 10, weightKg: 0))
            }
        }
    }
}
