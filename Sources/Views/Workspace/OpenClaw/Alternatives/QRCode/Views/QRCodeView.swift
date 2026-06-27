import SwiftUI

struct QRCodeView: View {
    @State private var viewModel = QRCodeViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            if viewModel.isSuccess {
                successView
            } else if viewModel.isScanning {
                scannerView
            } else {
                startView
            }
        }
        .navigationTitle("QR Code")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var startView: some View {
        VStack(spacing: 20) {
            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 80))
                .foregroundStyle(.blue)

            Text("Scan Pairing QR")
                .font(.title2.bold())

            Text("Open the OpenClaw dashboard on your Mac and click 'Show Pairing QR'. Point your camera at the screen.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundStyle(.secondary)

            if let error = viewModel.error {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            Button {
                viewModel.isScanning = true
            } label: {
                Text("Start Scanning")
                    .bold()
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 40)
            .padding(.top, 20)
        }
    }

    private var scannerView: some View {
        ZStack {
            QRCodeScannerView { payload in
                Task {
                    await viewModel.handleScan(payload: payload)
                }
            } onError: { error in
                viewModel.error = error.localizedDescription
                viewModel.isScanning = false
            }
            .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()
                Button("Cancel") {
                    viewModel.isScanning = false
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 40)
            }

            // Scanner overlay
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.white, lineWidth: 2)
                .frame(width: 250, height: 250)
                .background(Color.black.opacity(0.2))
        }
    }

    private var successView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            Text("Paired Successfully")
                .font(.title2.bold())

            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 20)
        }
    }
}
