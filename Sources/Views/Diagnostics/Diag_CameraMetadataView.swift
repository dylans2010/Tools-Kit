import SwiftUI

struct Diag_CameraMetadataView: View {
    var body: some View {
        List {
            Section("Lens Metadata") {
                LabeledContent("Focal Length", value: "24mm (equiv.)")
                LabeledContent("Aperture", value: "f/1.78")
                LabeledContent("Sensor Size", value: "1/1.28\"")
            }

            Section("EXIF Capabilities") {
                LabeledContent("RAW Support", value: "Apple ProRAW")
                LabeledContent("Color Space", value: "Display P3")
                LabeledContent("Max ISO", value: "12800")
            }

            Section("Video Specs") {
                LabeledContent("Max Resolution", value: "4K @ 60fps")
                LabeledContent("HDR", value: "Dolby Vision")
                LabeledContent("ProRes", value: "Available")
            }
        }
        .navigationTitle("Camera Metadata")
    }
}
