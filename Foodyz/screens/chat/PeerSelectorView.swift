import SwiftUI

struct PeerSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionManager
    @State private var peers: [ChatPeer]
    @State private var isLoading = false
    @State private var errorMessage: String?

    let onSelect: (ChatPeer) -> Void

    init(initialPeers: [ChatPeer] = [], onSelect: @escaping (ChatPeer) -> Void) {
        _peers = State(initialValue: initialPeers)
        self.onSelect = onSelect
    }

    var body: some View {
        NavigationStack {
            List {
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                } else if peers.isEmpty && !isLoading {
                    Section {
                        Text("You don't have anyone to chat with yet. Invite a professional or refresh to try again.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.vertical)
                    }
                }

                ForEach(peers) { peer in
                    Button {
                        handleSelection(peer)
                    } label: {
                        HStack(spacing: 12) {
                            AvatarView(avatarURL: peer.avatarUrl, size: 48, fallback: peer.name)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(peer.name)
                                    .font(.headline)
                                Text(peer.email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Text(peer.role.capitalized)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(AppColors.primary.opacity(0.12))
                                .foregroundColor(AppColors.primary)
                                .clipShape(Capsule())
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .navigationTitle("Start a chat")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .overlay {
                if isLoading {
                    ProgressView()
                }
            }
            .task {
                await loadPeers()
            }
            .refreshable {
                await loadPeers()
            }
        }
        .background(AppColors.background.ignoresSafeArea())
    }

    private func loadPeers() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response = try await ChatAPI.shared.fetchPeers()
            let currentUserId = session.userId
            peers = response.filter { $0.id != currentUserId }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func handleSelection(_ peer: ChatPeer) {
        onSelect(peer)
        dismiss()
    }
}
