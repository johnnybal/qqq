import SwiftUI

struct ComplimentCard: View {
    let compliment: Compliment
    @State private var showingReportSheet = false
    @State private var showingActionSheet = false
    @EnvironmentObject private var firestoreService: FirestoreService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if compliment.isAnonymous {
                    Text("Anonymous")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else if let sender = compliment.sender {
                    Text(sender.displayName)
                        .font(.headline)
                }
                
                Spacer()
                
                Button(action: { showingActionSheet = true }) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                }
            }
            
            Text(compliment.message)
                .font(.body)
            
            HStack {
                Text(compliment.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if compliment.isAnonymous {
                    Image(systemName: "theatermasks")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text("Options"),
                buttons: [
                    .default(Text("Report")) {
                        showingReportSheet = true
                    },
                    .cancel()
                ]
            )
        }
        .sheet(isPresented: $showingReportSheet) {
            ReportView(
                contentId: compliment.id,
                contentType: "compliment"
            )
        }
    }
} 