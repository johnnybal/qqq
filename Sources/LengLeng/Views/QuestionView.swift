import SwiftUI

struct QuestionView: View {
    @StateObject private var pollService = PollService.shared
    
    var body: some View {
        List {
            ForEach(pollService.polls) { poll in
                PollCard(poll: poll)
            }
        }
        .refreshable {
            await pollService.fetchPolls()
        }
        .overlay(
            Group {
                if pollService.polls.isEmpty {
                    ContentUnavailableView(
                        "No Questions Yet",
                        systemImage: "questionmark.circle",
                        description: Text("Check back later for new questions!")
                    )
                }
            }
        )
        .task {
            await pollService.fetchPolls()
        }
    }
}

struct PollCard: View {
    let poll: Poll
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(poll.question)
                .font(.headline)
            
            ForEach(poll.options, id: \.self) { option in
                Button(action: {
                    // TODO: Implement voting
                }) {
                    HStack {
                        Text(option)
                        Spacer()
                        Text("\(poll.votes[option, default: 0])")
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.bordered)
            }
            
            HStack {
                Text(poll.category)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(poll.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
} 