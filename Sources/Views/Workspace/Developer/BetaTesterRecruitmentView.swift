import SwiftUI

struct BetaTesterRecruitmentView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared

    var body: some View {
        List {
            Section("Recruitment Campaigns") {
                if store.recruitmentCampaigns.isEmpty {
                    Text("No campaigns active.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(store.recruitmentCampaigns) { campaign in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(campaign.name).font(.subheadline.bold())
                                Spacer()
                                Text(campaign.status)
                                    .font(.system(size: 8, weight: .black))
                                    .foregroundStyle(campaign.status == "Active" ? .green : .secondary)
                            }

                            ProgressView(value: Double(campaign.enrolledCount) / Double(campaign.targetCount))
                                .tint(.blue)

                            HStack {
                                Text("\(campaign.enrolledCount) / \(campaign.targetCount) enrolled").font(.caption).foregroundStyle(.secondary)
                                Spacer()
                                Button("Copy Link") { }
                                    .font(.caption.bold())
                                    .buttonStyle(.bordered)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }

            Section {
                Button {
                    var current = store.recruitmentCampaigns
                    current.append(RecruitmentCampaign(name: "Internal Dogfooding", targetCount: 50, enrolledCount: 0, status: "Active"))
                    store.saveRecruitmentCampaigns(current)
                } label: {
                    Label("Start Recruitment Campaign", systemImage: "megaphone.fill")
                }
            }
        }
        .navigationTitle("Recruitment")
        .onAppear {
            if store.recruitmentCampaigns.isEmpty {
                store.saveRecruitmentCampaigns([
                    RecruitmentCampaign(name: "Summer 2024 Alpha", targetCount: 500, enrolledCount: 342, status: "Active"),
                    RecruitmentCampaign(name: "Power Users Focus", targetCount: 100, enrolledCount: 98, status: "Full")
                ])
            }
        }
    }
}
