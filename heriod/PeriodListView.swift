import SwiftUI
import SwiftData

// MARK: – Period List View

struct PeriodListView: View {
    @Query(sort: \Period.startDate, order: .reverse) private var periods: [Period]
    @Environment(\.modelContext) private var ctx
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingAdd = false

    // Average cycle length across existing periods
    private var averageCycleLength: Int? {
        guard periods.count > 1 else { return nil }
        let sorted = periods.sorted { $0.startDate < $1.startDate }
        var lengths: [Int] = []
        for i in 1..<sorted.count {
            let days = Calendar.current.dateComponents([.day],
                                                        from: sorted[i-1].startDate,
                                                        to: sorted[i].startDate).day ?? 0
            if (1..<60).contains(days) { lengths.append(days) }
        }
        return lengths.isEmpty ? nil : lengths.reduce(0, +) / lengths.count
    }

    private var nextPrediction: Date? {
        guard let last = periods.first, let avg = averageCycleLength else { return nil }
        return Calendar.current.date(byAdding: .day, value: avg, to: last.startDate)
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