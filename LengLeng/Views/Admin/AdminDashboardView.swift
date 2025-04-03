import SwiftUI
import Charts

struct AdminDashboardView: View {
    @StateObject private var analyticsService = AnalyticsService.shared
    @State private var selectedTimeRange: AnalyticsTimeRange = .week
    @State private var isLoading = false
    @State private var error: Error?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Time Range Picker
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach([AnalyticsTimeRange.day, .week, .month, .year, .all], id: \.self) { range in
                            Text(range.displayName).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        // User Engagement Section
                        if let engagement = analyticsService.userEngagementMetrics {
                            AnalyticsCard(title: "User Engagement") {
                                VStack(spacing: 15) {
                                    MetricRow(title: "Daily Active Users", value: "\(engagement.dailyActiveUsers)")
                                    MetricRow(title: "Weekly Active Users", value: "\(engagement.weeklyActiveUsers)")
                                    MetricRow(title: "Monthly Active Users", value: "\(engagement.monthlyActiveUsers)")
                                    MetricRow(title: "Avg. Session Duration", value: engagement.formattedAverageSessionDuration)
                                    MetricRow(title: "Retention Rate", value: engagement.formattedRetentionRate)
                                    MetricRow(title: "Churn Rate", value: engagement.formattedChurnRate)
                                }
                            }
                        }
                        
                        // Poll Analytics Section
                        if let polls = analyticsService.pollAnalytics {
                            AnalyticsCard(title: "Poll Analytics") {
                                VStack(spacing: 15) {
                                    MetricRow(title: "Total Polls", value: "\(polls.totalPolls)")
                                    MetricRow(title: "Active Polls", value: "\(polls.activePolls)")
                                    MetricRow(title: "Total Votes", value: "\(polls.totalVotes)")
                                    MetricRow(title: "Avg. Votes per Poll", value: String(format: "%.1f", polls.averageVotesPerPoll))
                                    MetricRow(title: "Participation Rate", value: polls.formattedParticipationRate)
                                }
                            }
                        }
                        
                        // Conversion Metrics Section
                        if let conversions = analyticsService.conversionMetrics {
                            AnalyticsCard(title: "Conversion Metrics") {
                                VStack(spacing: 15) {
                                    MetricRow(title: "Total Signups", value: "\(conversions.totalSignups)")
                                    MetricRow(title: "Premium Conversions", value: "\(conversions.premiumConversions)")
                                    MetricRow(title: "Invite Acceptance Rate", value: conversions.formattedInviteAcceptanceRate)
                                    MetricRow(title: "Premium Conversion Rate", value: conversions.formattedPremiumConversionRate)
                                }
                            }
                        }
                        
                        // Retention Analysis Section
                        if let retention = analyticsService.retentionAnalysis {
                            AnalyticsCard(title: "Retention Analysis") {
                                VStack(spacing: 15) {
                                    MetricRow(title: "Cohort Size", value: "\(retention.cohortSize)")
                                    MetricRow(title: "Day 1 Retention", value: retention.formattedDay1Retention)
                                    MetricRow(title: "Day 7 Retention", value: retention.formattedDay7Retention)
                                    MetricRow(title: "Day 30 Retention", value: retention.formattedDay30Retention)
                                    MetricRow(title: "Returning Users", value: "\(retention.returningUsers)")
                                }
                            }
                        }
                        
                        // Currency Analytics Section
                        if let currency = analyticsService.currencyAnalytics {
                            AnalyticsCard(title: "Currency Analytics") {
                                VStack(spacing: 15) {
                                    MetricRow(title: "Total Flames Awarded", value: "\(currency.totalFlamesAwarded) 🔥")
                                    MetricRow(title: "Total Gems Awarded", value: "\(currency.totalGemsAwarded) 💎")
                                    MetricRow(title: "Avg. Flames per User", value: currency.formattedAverageFlames)
                                    MetricRow(title: "Avg. Gems per User", value: currency.formattedAverageGems)
                                }
                            }
                        }
                        
                        // School Analytics Section
                        if !analyticsService.schoolAnalytics.isEmpty {
                            AnalyticsCard(title: "School Analytics") {
                                VStack(spacing: 15) {
                                    ForEach(analyticsService.schoolAnalytics, id: \.schoolId) { school in
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(school.schoolName)
                                                .font(.headline)
                                            
                                            MetricRow(title: "Total Users", value: "\(school.totalUsers)")
                                            MetricRow(title: "Active Users", value: "\(school.activeUsers)")
                                            MetricRow(title: "Premium Users", value: "\(school.premiumUsers)")
                                            MetricRow(title: "Engagement Rate", value: school.formattedEngagementRate)
                                            MetricRow(title: "Premium Conversion", value: school.formattedPremiumConversionRate)
                                        }
                                        .padding()
                                        .background(Color(.systemBackground))
                                        .cornerRadius(12)
                                        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Analytics Dashboard")
            .refreshable {
                await loadAnalytics()
            }
            .task {
                await loadAnalytics()
            }
            .onChange(of: selectedTimeRange) { _ in
                Task {
                    await loadAnalytics()
                }
            }
            .alert("Error", isPresented: .constant(error != nil)) {
                Button("OK") {
                    error = nil
                }
            } message: {
                Text(error?.localizedDescription ?? "Unknown error")
            }
        }
    }
    
    private func loadAnalytics() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await analyticsService.fetchAnalytics(timeRange: selectedTimeRange)
        } catch {
            self.error = error
        }
    }
}

struct AnalyticsCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            
            content
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
}

struct MetricRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    AdminDashboardView()
} 