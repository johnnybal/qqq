import SwiftUI

struct InviteHistoryView: View {
    let invites: [Invitation]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                if invites.isEmpty {
                    EmptyStateView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(invites) { invite in
                                InviteHistoryRow(invite: invite)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Invite History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct InviteHistoryRow: View {
    let invite: Invitation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Recipient Info
            HStack {
                VStack(alignment: .leading) {
                    Text(invite.recipientName)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(invite.recipientPhone)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                StatusBadge(status: invite.status)
            }
            
            // Message Preview
            Text(invite.message)
                .font(.subheadline)
                .foregroundColor(.white)
                .lineLimit(2)
            
            // Time Info
            HStack {
                Text("Sent \(timeAgoString(from: invite.createdAt))")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if !invite.isExpired {
                    Text("• Expires in \(timeRemainingString(from: invite.expiresAt))")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            // Tracking Info
            if let tracking = invite.trackingData {
                TrackingInfoView(tracking: tracking)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(15)
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func timeRemainingString(from date: Date) -> String {
        let remaining = date.timeIntervalSince(Date())
        let hours = Int(remaining) / 3600
        let minutes = Int(remaining) / 60 % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct StatusBadge: View {
    let status: Invitation.InvitationStatus
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
    
    private var backgroundColor: Color {
        switch status {
        case .sent:
            return .blue
        case .clicked:
            return .orange
        case .installed:
            return .green
        case .expired:
            return .gray
        }
    }
}

struct TrackingInfoView: View {
    let tracking: Invitation.TrackingData
    
    var body: some View {
        HStack(spacing: 15) {
            if let clickedAt = tracking.clickedAt {
                TrackingItem(
                    icon: "hand.tap.fill",
                    label: "Clicked",
                    time: clickedAt
                )
            }
            
            if let installedAt = tracking.installedAt {
                TrackingItem(
                    icon: "checkmark.circle.fill",
                    label: "Installed",
                    time: installedAt
                )
            }
            
            if tracking.reminderCount > 0 {
                TrackingItem(
                    icon: "bell.fill",
                    label: "Reminders",
                    count: tracking.reminderCount
                )
            }
        }
    }
}

struct TrackingItem: View {
    let icon: String
    let label: String
    var time: Date? = nil
    var count: Int? = nil
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            if let time = time {
                Text("(\(timeAgoString(from: time)))")
                    .font(.caption)
                    .foregroundColor(.gray)
            } else if let count = count {
                Text("(\(count))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "paperplane.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Invites Yet")
                .font(.title2)
                .foregroundColor(.white)
            
            Text("Start inviting friends to LengLeng!")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
} 