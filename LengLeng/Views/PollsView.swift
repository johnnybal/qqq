import SwiftUI

struct PollsView: View {
    @State private var polls: [Poll] = []
    @State private var isLoading = false
    @State private var showingCreatePoll = false
    @EnvironmentObject var pollService: PollService
    
    var body: some View {
        NavigationView {
            List {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if polls.isEmpty {
                    Text("No polls available")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    ForEach(polls) { poll in
                        PollRow(poll: poll)
                    }
                }
            }
            .navigationTitle("Polls")
            .refreshable {
                await loadPolls()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreatePoll = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreatePoll) {
                CreatePollView()
            }
            .task {
                await loadPolls()
            }
        }
    }
    
    private func loadPolls() async {
        isLoading = true
        do {
            polls = try await pollService.getRecentPolls()
        } catch {
            print("Error loading polls: \(error)")
        }
        isLoading = false
    }
}

struct PollRow: View {
    let poll: Poll
    @EnvironmentObject var pollService: PollService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(poll.title)
                .font(.headline)
            
            Text(poll.description)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            ForEach(poll.options) { option in
                Button(action: {
                    Task {
                        try? await pollService.vote(pollId: poll.id, optionId: option.id)
                    }
                }) {
                    HStack {
                        Text(option.text)
                        Spacer()
                        Text("\(option.votes) votes")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            HStack {
                Text("\(poll.comments.count) comments")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(poll.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
    }
}

struct CreatePollView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var options: [String] = ["", ""]
    @State private var isLoading = false
    @EnvironmentObject var pollService: PollService
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Poll Details")) {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description)
                }
                
                Section(header: Text("Options")) {
                    ForEach(0..<options.count, id: \.self) { index in
                        TextField("Option \(index + 1)", text: $options[index])
                    }
                    
                    Button("Add Option") {
                        options.append("")
                    }
                }
            }
            .navigationTitle("Create Poll")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Create") {
                    Task {
                        await createPoll()
                    }
                }
                .disabled(isLoading || !isValid)
            )
        }
    }
    
    private var isValid: Bool {
        !title.isEmpty && !description.isEmpty && options.allSatisfy { !$0.isEmpty }
    }
    
    private func createPoll() async {
        isLoading = true
        do {
            let poll = Poll(
                id: UUID().uuidString,
                title: title,
                description: description,
                options: options.map { PollOption(id: UUID().uuidString, text: $0, votes: 0) },
                comments: [],
                createdAt: Date()
            )
            try await pollService.createPoll(poll)
            dismiss()
        } catch {
            print("Error creating poll: \(error)")
        }
        isLoading = false
    }
} 