import SwiftUI
import SwiftData

// MARK: – Period List View

struct PeriodListView: View {
    @Query(sort: \Period.startDate, order: .reverse) private var periods: [Period]
    @Environment(\.modelContext) private var ctx
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingAdd = false

    private var nextPrediction: Date? {
        guard !isCurrentlyOnPeriod else { return nil }
        return PeriodCalculations.nextPredictedPeriod(from: periods)
    }
    
    private var isCurrentlyOnPeriod: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return periods.contains { period in
            let startDate = Calendar.current.startOfDay(for: period.startDate)
            let endDate = Calendar.current.startOfDay(for: period.endDate ?? period.startDate)
            return today >= startDate && today <= endDate
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundColor(for: colorScheme)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    if let date = nextPrediction {
                        PredictionCard(nextDate: date)
                            .padding(.horizontal)
                    }
                    List {
                        ForEach(periods) { period in
                            PeriodCard(period: period)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 7.5, leading: 16, bottom: 7.5, trailing: 16))
                        }
                    }
                    .listStyle(PlainListStyle())
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Period Tracker")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(AppTheme.primary)
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddPeriodView()
            }
        }
    }
}