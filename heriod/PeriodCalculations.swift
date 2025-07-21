import Foundation

// MARK: - Period Calculations Utility

struct PeriodCalculations {
    
    /// Calculate average cycle length across existing periods
    static func averageCycleLength(from periods: [Period]) -> Int? {
        if periods.count < 2 {
            // Fallback to standard 28-day cycle for single period
            return periods.isEmpty ? nil : 28
        }
        
        let sorted = periods.sorted { $0.startDate < $1.startDate }
        var lengths: [Int] = []
        
        for i in 1..<sorted.count {
            let days = Calendar.current.dateComponents([.day],
                                                      from: sorted[i-1].startDate,
                                                      to: sorted[i].startDate).day ?? 0
            if (1..<60).contains(days) { 
                lengths.append(days) 
            }
        }
        
        return lengths.isEmpty ? 28 : lengths.reduce(0, +) / lengths.count
    }
    
    /// Predict next period start date based on historical data
    static func nextPredictedPeriod(from periods: [Period]) -> Date? {
        guard let lastPeriod = periods.first,
              let avgLength = averageCycleLength(from: periods) else { 
            return nil 
        }
        
        return Calendar.current.date(byAdding: .day, value: avgLength, to: lastPeriod.startDate)
    }
    
    /// Check if a given date falls within the predicted period range
    static func isDateInPredictedPeriod(_ date: Date, periods: [Period], predictedDuration: Int = 5) -> Bool {
        guard let predictedStart = nextPredictedPeriod(from: periods) else { 
            return false 
        }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let predictedStartDay = Calendar.current.startOfDay(for: predictedStart)
        
        guard let predictedEnd = Calendar.current.date(byAdding: .day, value: predictedDuration - 1, to: predictedStart) else {
            return false
        }
        let predictedEndDay = Calendar.current.startOfDay(for: predictedEnd)
        
        return startOfDay >= predictedStartDay && startOfDay <= predictedEndDay
    }
}