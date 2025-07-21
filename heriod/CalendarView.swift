import SwiftUI
import SwiftData
import UIKit

// MARK: – Calendar View

struct CalendarView: View {
    @Query(sort: \Period.startDate, order: .reverse) private var periods: [Period]
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedDate = Date()
    @State private var showingDayDetail = false
    @State private var selectedPeriods: [Period] = []
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundColor(for: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Month/Year Header
                    HStack {
                        Button(action: {
                            UISelectionFeedbackGenerator.selection()
                            previousMonth()
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(AppTheme.primary)
                                .font(.title2)
                        }
                        
                        Spacer()
                        
                        Text(dateFormatter.string(from: selectedDate))
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button(action: {
                            UISelectionFeedbackGenerator.selection()
                            nextMonth()
                        }) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(AppTheme.primary)
                                .font(.title2)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Calendar Grid
                    calendarGrid
                        .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationTitle("Calendar")
            .sheet(isPresented: $showingDayDetail) {
                DayDetailView(date: selectedDate, periods: selectedPeriods)
            }
        }
    }
    
    private var calendarGrid: some View {
        let monthDates = getDaysInMonth()
        let columns = Array(repeating: GridItem(.flexible()), count: 7)
        
        return LazyVGrid(columns: columns, spacing: 10) {
            // Day headers
            ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
            
            // Calendar days
            ForEach(monthDates, id: \.self) { date in
                if let date = date {
                    dayCell(for: date)
                } else {
                    Color.clear
                        .frame(height: 40)
                }
            }
        }
        .padding()
        .background(AppTheme.cardColor(for: colorScheme))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, y: 3)
    }
    
    private func dayCell(for date: Date) -> some View {
        let dayPeriods = getPeriodsForDate(date)
        let hasPeriod = !dayPeriods.isEmpty
        let isPredictedPeriod = PeriodCalculations.isDateInPredictedPeriod(date, periods: periods)
        let isPredictedPMS = PeriodCalculations.isDateInPredictedPMS(date, periods: periods)
        let isToday = calendar.isDateInToday(date)
        
        return Button(action: {
            UISelectionFeedbackGenerator.selection()
            selectedDate = date
            selectedPeriods = dayPeriods
            if !dayPeriods.isEmpty {
                showingDayDetail = true
            }
        }) {
            ZStack {
                Circle()
                    .fill(hasPeriod ? AppTheme.primary : 
                          isPredictedPeriod ? AppTheme.primary.opacity(0.4) : 
                          isPredictedPMS ? Color.orange.opacity(0.3) :
                          Color.clear)
                    .frame(width: 35, height: 35)
                
                if isPredictedPeriod && !hasPeriod {
                    Circle()
                        .stroke(AppTheme.primary.opacity(0.6), lineWidth: 1.5)
                        .frame(width: 35, height: 35)
                }
                
                if isPredictedPMS && !hasPeriod && !isPredictedPeriod {
                    Circle()
                        .stroke(Color.orange.opacity(0.7), lineWidth: 1.5)
                        .frame(width: 35, height: 35)
                }
                
                if isToday && !hasPeriod && !isPredictedPeriod && !isPredictedPMS {
                    Circle()
                        .stroke(AppTheme.primary, lineWidth: 2)
                        .frame(width: 35, height: 35)
                }
                
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 16, weight: hasPeriod ? .semibold : .regular))
                    .foregroundColor(hasPeriod ? .white : 
                                   isPredictedPeriod ? AppTheme.primary : 
                                   isPredictedPMS ? Color.orange :
                                   .primary)
            }
        }
    }
    
    private func getDaysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedDate),
              let firstOfMonth = calendar.dateInterval(of: .month, for: selectedDate)?.start else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let numberOfDaysInMonth = calendar.range(of: .day, in: .month, for: selectedDate)?.count ?? 0
        
        var days: [Date?] = []
        
        // Add empty cells for days before the first day of the month
        for _ in 1..<firstWeekday {
            days.append(nil)
        }
        
        // Add days of the month
        for day in 1...numberOfDaysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private func getPeriodsForDate(_ date: Date) -> [Period] {
        return periods.filter { period in
            let startDate = period.startDate
            let endDate = period.endDate ?? startDate
            
            return date >= calendar.startOfDay(for: startDate) &&
                   date <= calendar.startOfDay(for: endDate)
        }
    }
    
    private func previousMonth() {
        selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
    }
    
    private func nextMonth() {
        selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
    }
}

// MARK: – Day Detail View

struct DayDetailView: View {
    let date: Date
    let periods: [Period]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundColor(for: colorScheme)
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 20) {
                    Text(dayFormatter.string(from: date))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                    
                    if periods.isEmpty {
                        Text("No period data for this day")
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        Spacer()
                    } else {
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
            }
            .navigationTitle("Day Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { 
                        UIImpactFeedbackGenerator.lightImpact()
                        dismiss() 
                    }
                }
            }
        }
    }
}