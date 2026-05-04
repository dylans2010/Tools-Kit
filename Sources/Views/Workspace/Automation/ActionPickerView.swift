import SwiftUI

struct ActionPickerView: View {
    let actions = TriggerActionRegistry.shared.availableActions

    var body: some View {
        List(actions, id: \.self) { action in
            Button(action) {
                // Select action
            }
        }
        .navigationTitle("Select Action")
    }
}
