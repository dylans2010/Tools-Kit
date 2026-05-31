import SwiftUI

struct FunnelBuilderView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @ObservedObject var analyticsService = AnalyticsService.shared
    @State private var selectedAppID: UUID?
    @State private var showingCreator = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                appSelector

                if let appID = selectedAppID {
                    funnelList(appID: appID)
                } else {
                    EmptyStateView(icon: "filter", title: "Select App", message: "Choose an application to manage its conversion funnels.")
                        .padding(.top, 40)
                }
            }
            .padding()
        }
        .navigationTitle("Funnel Builder")
        .background(Color(uiColor: .systemGroupedBackground))
        .onAppear {
            if selectedAppID == nil { selectedAppID = appService.apps.first?.id }
        }
        .toolbar {
            if selectedAppID != nil {
                Button { showingCreator = true } label: { Image(systemName: "plus.circle.fill") }
            }
        }
        .sheet(isPresented: $showingCreator) {
            NewFunnelSheet(appID: selectedAppID ?? UUID())
        }
    }

    private var appSelector: some View {
        Picker("App", selection: $selectedAppID) {
            ForEach(appService.apps) { app in
                Text(app.name).tag(Optional(app.id))
            }
        }
        .pickerStyle(.menu)
        .padding(8)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private func funnelList(appID: UUID) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Active Funnels").font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                funnelCard(name: "User Onboarding", conversion: 0.64)
                funnelCard(name: "Subscription Flow", conversion: 0.12)
            }
        }
    }

    private func funnelCard(name: String, conversion: Double) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(name).font(.subheadline.bold())
                Spacer()
                Text("\(Int(conversion * 100))% Conv.").font(.caption2.bold()).foregroundStyle(.green)
            }

            VStack(alignment: .leading, spacing: 6) {
                stepBar(label: "App Open", val: 1.0)
                stepBar(label: "Sign Up", val: 0.75)
                stepBar(label: "Profile Complete", val: conversion)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func stepBar(label: String, val: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label).font(.system(size: 8)).foregroundStyle(.secondary)
                Spacer()
            }
            ProgressView(value: val)
                .progressViewStyle(.linear)
                .tint(.blue.opacity(val))
        }
    }
}

struct NewFunnelSheet: View {
    let appID: UUID
    @Environment(\.dismiss) var dismiss
    @State private var funnelName = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Funnel Details") {
                    TextField("Funnel Name (e.g. Checkout)", text: $funnelName)
                }
                Section("Steps") {
                    Text("Add events to track in this funnel.").font(.caption).foregroundStyle(.secondary)
                    Button { /* add event */ } label: { Label("Add Event Step", systemImage: "plus.circle") }
                }
            }
            .navigationTitle("New Funnel")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { dismiss() }.disabled(funnelName.isEmpty)
                }
            }
        }
    }
}
