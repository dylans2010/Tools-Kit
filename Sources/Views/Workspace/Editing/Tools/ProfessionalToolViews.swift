import SwiftUI

struct ProfessionalToolsDashboard: View {
    @StateObject private var suite = ProfessionalEditingSuite.shared
    @State private var sceneDetectionRunning = false
    @State private var motionTrackingActive = false
    @State private var gradingPreset: String = "None"
    @State private var audioEnhancementMode: String = "Off"
    @State private var batchExportFormat: String = "4K-ProRes"

    var body: some View {
        List {
            Section {
                Button {
                    sceneDetectionRunning = true
                    suite.runSceneDetection()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        sceneDetectionRunning = false
                    }
                } label: {
                    HStack {
                        Label("Scene Detection", systemImage: "film.stack")
                        Spacer()
                        if sceneDetectionRunning {
                            ProgressView()
                        } else {
                            Text("\(suite.detectedScenes) scenes")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Toggle(isOn: $motionTrackingActive) {
                    Label("Motion Tracking", systemImage: "scope")
                }
                .onChange(of: motionTrackingActive) { _, active in
                    if active {
                        suite.startMotionTracking()
                    } else {
                        suite.stopMotionTracking()
                    }
                }

                Button {
                    suite.stabilizeFootage()
                } label: {
                    Label("Stabilize Footage", systemImage: "video.badge.waveform")
                }

                Button {
                    suite.generateThumbnails()
                } label: {
                    Label("Generate Thumbnails", systemImage: "photo.on.rectangle")
                }
            } header: {
                Label("Video Tools", systemImage: "video")
            }

            Section {
                Picker(selection: $gradingPreset) {
                    Text("None").tag("None")
                    Text("Cinematic").tag("Cinematic")
                    Text("Warm Tone").tag("Warm")
                    Text("Cool Tone").tag("Cool")
                    Text("Desaturated").tag("Desaturated")
                    Text("High Contrast").tag("HighContrast")
                } label: {
                    Label("Grading Preset", systemImage: "camera.filters")
                }
                .onChange(of: gradingPreset) { _, preset in
                    suite.applyColorGrade(preset)
                }

                Button {
                    suite.autoMatchColors()
                } label: {
                    Label("Match Colors", systemImage: "plus.viewfinder")
                }

                Button {
                    suite.autoWhiteBalance()
                } label: {
                    Label("Auto White Balance", systemImage: "sun.max")
                }
            } header: {
                Label("Color & Light", systemImage: "paintpalette")
            }

            Section {
                Picker(selection: $audioEnhancementMode) {
                    Text("Off").tag("Off")
                    Text("Noise Reduction").tag("NoiseReduction")
                    Text("Voice Boost").tag("VoiceBoost")
                    Text("Normalize").tag("Normalize")
                    Text("Compression").tag("Compression")
                } label: {
                    Label("Enhancement Mode", systemImage: "waveform.path.badge.plus")
                }
                .onChange(of: audioEnhancementMode) { _, mode in
                    suite.applyAudioEnhancement(mode)
                }

                Button {
                    suite.removeBackgroundNoise()
                } label: {
                    Label("Remove Background Noise", systemImage: "waveform.badge.minus")
                }
            } header: {
                Label("Audio", systemImage: "speaker.wave.3")
            }

            Section {
                Picker(selection: $batchExportFormat) {
                    Text("4K ProRes").tag("4K-ProRes")
                    Text("1080p H.264").tag("1080-H264")
                    Text("720p Web").tag("720-Web")
                } label: {
                    Label("Export Format", systemImage: "square.and.arrow.up")
                }

                Button {
                    suite.batchExport(projects: EditingManager.shared.projects, format: batchExportFormat)
                } label: {
                    Label("Batch Export All", systemImage: "arrow.up.doc.on.clipboard")
                }

                Button {
                    suite.openTemplateStudio()
                } label: {
                    Label("Template Studio", systemImage: "square.grid.2x2")
                }
            } header: {
                Label("Project", systemImage: "folder")
            }
        }
        .navigationTitle("Professional Suite")
    }
}

struct BatchProcessingView: View {
    let projects: [EditingProject]
    @StateObject private var suite = ProfessionalEditingSuite.shared

    var body: some View {
        VStack {
            Text("Batch Process \(projects.count) Projects")
                .font(.headline)

            List(projects) { project in
                Label(project.name, systemImage: "doc")
            }

            Button("Export All (4K)") {
                suite.batchExport(projects: projects, format: "4K-ProRes")
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
    }
}
