import SwiftUI

struct PollsView: View {
    @StateObject private var viewModel = PollsViewModel()
    @State private var showingCreatePoll = false
    
    var body: some View {
        NavigationView {
            List(viewModel.polls) { poll in
                PollCell(poll: poll)
            }
            .navigationTitle("Polls")
            .toolbar {
                Button(action: { showingCreatePoll = true }) {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingCreatePoll) {
                CreatePollView()
            }
            .refreshable {
                await viewModel.fetchPolls()
            }
        }
    }
}

struct PollCell: View {
    let poll: Poll
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(poll.question)
                .font(.headline)
            
            ForEach(poll.options, id: \.id) { option in
                HStack {
                    Text(option.text)
                    Spacer()
                    Text("\(Int((Double(option.voteCount) / Double(poll.totalVotes)) * 100))%")
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Text(poll.category.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text(poll.expiresAt.timeAgoDisplay())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

class PollsViewModel: ObservableObject {
    @Published var polls: [Poll] = []
    
    init() {
        Task {
            await fetchPolls()
        }
    }
    
    @MainActor
    func fetchPolls() async {
        FirebaseService.shared.fetchPolls { [weak self] result in
            switch result {
            case .success(let polls):
                self?.polls = polls
            case .failure(let error):
                print("Error fetching polls: \(error)")
            }
        }
    }
} 