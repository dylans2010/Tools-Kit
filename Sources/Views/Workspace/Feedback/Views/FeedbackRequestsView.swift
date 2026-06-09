import SwiftUI

public struct FeedbackRequestsView: View {
    @StateObject private var viewModel = RequestsViewModel()
    @State private var showingCreateRequest = false

    public init() {}

    public var body: some View {
        List {
            ForEach(viewModel.requests) { request in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(request.title)
                            .font(.headline)
                        Spacer()
                        Text(request.status)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.1))
                            .foregroundColor(.orange)
                            .cornerRadius(4)
                    }

                    Text(request.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack {
                        Label(request.category.displayName, systemImage: request.category.icon)
                        Spacer()
                        Button {
                            viewModel.vote(for: request.id)
                        } label: {
                            HStack {
                                Image(systemName: request.hasVoted ? "arrow.up.circle.fill" : "arrow.up.circle")
                                Text("\(request.votes)")
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(request.hasVoted ? Color.blue : Color.gray.opacity(0.1))
                            .foregroundColor(request.hasVoted ? .white : .primary)
                            .cornerRadius(20)
                        }
                        .buttonStyle(.plain)
                    }
                    .font(.caption)
                }
                .padding(.vertical, 5)
            }
        }
        .navigationTitle("Feature Requests")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingCreateRequest = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreateRequest) {
            CreateRequestView()
        }
        .task {
            await viewModel.fetchRequests()
        }
    }
}
