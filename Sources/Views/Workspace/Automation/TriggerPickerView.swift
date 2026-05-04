import SwiftUI

struct TriggerPickerView: View {
    let triggers = TriggerActionRegistry.shared.availableTriggers

    var body: some View {
        List(triggers, id: \.self) { trigger in
            Button(trigger) {
                // Select trigger
            }
        }
        .navigationTitle("Select Trigger")
    }
}
