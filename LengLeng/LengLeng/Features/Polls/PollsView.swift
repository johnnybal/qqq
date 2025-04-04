import SwiftUI

struct PollsView: View {
    @StateObject private var viewModel = PollsViewModel()
    
    var body: some View {
        NavigationView {
            List(viewModel.polls) { poll in
                PollCell(poll: poll, onVote: { optionId in
                    Task {
                        await viewModel.voteOnPoll(pollId: poll.id, optionId: optionId)
                    }
                })
            }
            .navigationTitle("Polls")
            .refreshable {
                await viewModel.fetchPolls()
            }
        }
    }
}

struct PollCell: View {
    let poll: Poll
    let onVote: (String) -> Void
    @State private var selectedOption: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(poll.question)
                .font(.headline)
                .padding(.bottom, 4)
            
            ForEach(poll.options, id: \.id) { option in
                Button(action: {
                    if selectedOption == nil {
                        selectedOption = option.id
                        onVote(option.id)
                    }
                }) {
                    HStack {
                        Text(option.text)
                            .foregroundColor(selectedOption == option.id ? .white : .primary)
                        Spacer()
                        if poll.totalVotes > 0 {
                            Text("\(Int((Double(option.voteCount) / Double(poll.totalVotes)) * 100))%")
                                .foregroundColor(selectedOption == option.id ? .white : .secondary)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedOption == option.id ? Color.blue : Color.gray.opacity(0.1))
                    )
                }
                .disabled(selectedOption != nil)
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
            .padding(.top, 8)
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
    
    @MainActor
    func voteOnPoll(pollId: String, optionId: String) async {
        FirebaseService.shared.voteOnPoll(pollId: pollId, optionId: optionId) { [weak self] result in
            switch result {
            case .success:
                Task {
                    await self?.fetchPolls()
                }
            case .failure(let error):
                print("Error voting on poll: \(error)")
            }
        }
    }
} 