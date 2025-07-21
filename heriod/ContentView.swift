// PeriodTrackerApp.swift
// Beautiful, fast, privacy‑preserving period tracker
// SwiftUI + SwiftData only – no UserDefaults, no analytics

import SwiftUI
import SwiftData
import UIKit

// MARK: – Supporting Types

enum FlowIntensity: String, CaseIterable {
    case light  = "Light"
    case medium = "Medium"
    case heavy  = "Heavy"
}

enum Symptom: String, CaseIterable {
    case cramps   = "Cramps"
    case headache = "Headache"
    case backPain = "Back Pain"
    case mood     = "Mood Changes"
    case fatigue  = "Fatigue"
    case bloating = "Bloating"
}

// MARK: – Data Model (SwiftData)

@Model
final class Period {
    @Attribute(.unique) var id: UUID = UUID()
    var startDate: Date = Date.now
    var endDate: Date?
    var flowRaw: String = FlowIntensity.medium.rawValue      // store enum raw value
    var symptomRaw: [String] = []                            // store raw strings
    var notes: String = ""

    // Convenience accessors
    var flow: FlowIntensity {
        get { FlowIntensity(rawValue: flowRaw) ?? .medium }
        set { flowRaw = newValue.rawValue }
    }

    var symptoms: Set<Symptom> {
        get { Set(symptomRaw.compactMap(Symptom.init(rawValue:))) }
        set { symptomRaw = newValue.map(\.rawValue) }
    }

    init(startDate: Date = Date.now,
         endDate: Date? = nil,
         flow: FlowIntensity = .medium,
         symptoms: Set<Symptom> = [],
         notes: String = "") {
        self.startDate  = startDate
        self.endDate    = endDate
        self.flowRaw    = flow.rawValue
        self.symptomRaw = symptoms.map(\.rawValue)
        self.notes      = notes
    }
}

// MARK: – Main Application

struct PeriodTrackerApp: App {
    private let container: ModelContainer = {
        let schema = Schema([Period.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}

// MARK: – Root View

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            PeriodListView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("List")
                }
                .tag(0)
            
            CalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }
                .tag(1)
        }
        .accentColor(AppTheme.primary)
        .onChange(of: selectedTab) { _, _ in
            UISelectionFeedbackGenerator.selection()
        }
    }
}

// MARK: – Prediction Card

struct PredictionCard: View {
    let nextDate: Date
    private var daysUntil: Int { Calendar.current.dateComponents([.day], from: .now, to: nextDate).day ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "calendar.circle")
                    .font(.title2)
                    .foregroundColor(.white)
                Text("Next Period Prediction")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            Text("\(nextDate, formatter: dateFormatter)")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            Text(daysUntil > 0 ? "In \(daysUntil) days" : "Today or overdue")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(AppTheme.primary)
        )
        .shadow(color: AppTheme.primary.opacity(0.3), radius: 10, y: 5)
    }
}

// MARK: – Period Card

struct PeriodCard: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingDetail = false
    let period: Period

    private var duration: Int {
        let endDate = period.endDate ?? .now
        return Calendar.current.dateComponents([.day], from: period.startDate, to: endDate).day ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(period.startDate, formatter: dateFormatter).font(.headline)
                    Text("\(duration) days • \(period.flow.rawValue)")
                        .font(.subheadline).foregroundColor(.secondary)
                }
                Spacer()
                Button { 
                    UIImpactFeedbackGenerator.lightImpact()
                    showingDetail = true 
                } label: {
                    Image(systemName: "chevron.right.circle")
                        .foregroundColor(AppTheme.primary)
                }
            }

            if !period.symptoms.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(period.symptoms), id: \.self) { symptom in
                            Text(symptom.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(AppTheme.secondary)
                                .foregroundColor(AppTheme.primary)
                                .cornerRadius(15)
                        }
                    }
                }
            }
        }
        .padding()
        .background(AppTheme.cardColor(for: colorScheme))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, y: 3)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                UINotificationFeedbackGenerator.warning()
                ctx.delete(period)
                try? ctx.save()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingDetail) {
            PeriodDetailView(period: period)
        }
    }
}

// MARK: – Add Period View

struct AddPeriodView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var ctx

    @State private var startDate = Date()
    @State private var hasEnded  = false
    @State private var endDate: Date? = nil
    @State private var flow: FlowIntensity = .medium
    @State private var selected: Set<Symptom> = []
    @State private var notes = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Period Dates")) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    Toggle("Period has ended", isOn: $hasEnded)
                    if hasEnded {
                        DatePicker("End Date", selection: Binding(get: { endDate ?? startDate }, set: { endDate = $0 }), displayedComponents: .date)
                    }
                }
                Section(header: Text("Flow Intensity")) {
                    Picker("Flow", selection: $flow) {
                        ForEach(FlowIntensity.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented)
                }
                Section(header: Text("Symptoms")) {
                    ForEach(Symptom.allCases, id: \.self) { symptom in
                        MultipleSelectionRow(title: symptom.rawValue, isSelected: selected.contains(symptom)) {
                            selected.toggle(symptom)
                        }
                    }
                }
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes).frame(height: 100)
                }
            }
            .navigationTitle("Add Period")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { 
                        UIImpactFeedbackGenerator.lightImpact()
                        dismiss() 
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { 
                        UINotificationFeedbackGenerator.success()
                        save() 
                    }
                }
            }
        }
    }

    private func save() {
        let period = Period(startDate: startDate,
                            endDate: hasEnded ? endDate : nil,
                            flow: flow,
                            symptoms: selected,
                            notes: notes)   
        ctx.insert(period)
        try? ctx.save()
        dismiss()
    }
}

// MARK: – Period Detail / Edit View

struct PeriodDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var ctx

    @State private var editing = false
    @State private var draft: Period
    @State private var hasEnded: Bool

    let period: Period

    init(period: Period) {
        self.period = period
        _draft     = State(initialValue: Period(startDate: period.startDate, endDate: period.endDate, flow: period.flow, symptoms: period.symptoms, notes: period.notes))
        _hasEnded  = State(initialValue: period.endDate != nil)
    }

    var body: some View {
        NavigationView {
            if editing {
                editForm
            } else {
                detail
            }
        }
    }

    // Detail readonly
    private var detail: some View {
        Form {
            infoSection
            symptomSection
            notesSection
            Section {
                Button(role: .destructive) {
                    UINotificationFeedbackGenerator.error()
                    ctx.delete(period)
                    try? ctx.save()
                    dismiss()
                } label: { Text("Delete Period") }
            }
        }
        .navigationTitle("Period Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                closeButton
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") { 
                    UIImpactFeedbackGenerator.lightImpact()
                    editing = true 
                }
            }
        }
    }

    // Edit form
    private var editForm: some View {
        Form {
            Section(header: Text("Period Dates")) {
                DatePicker("Start Date", selection: $draft.startDate, displayedComponents: .date)
                Toggle("Period has ended", isOn: $hasEnded)
                if hasEnded {
                    DatePicker("End Date", selection: Binding(get: { draft.endDate ?? draft.startDate }, set: { draft.endDate = $0 }), displayedComponents: .date)
                }
            }
            Section(header: Text("Flow Intensity")) {
                Picker("Flow", selection: $draft.flow) {
                    ForEach(FlowIntensity.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.segmented)
            }
            Section(header: Text("Symptoms")) {
                ForEach(Symptom.allCases, id: \.self) { symptom in
                    MultipleSelectionRow(title: symptom.rawValue, isSelected: draft.symptoms.contains(symptom)) {
                        draft.symptoms.toggle(symptom)
                    }
                }
            }
            Section(header: Text("Notes")) {
                TextEditor(text: $draft.notes).frame(height: 100)
            }
        }
        .navigationTitle("Edit Period")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { 
                    UIImpactFeedbackGenerator.lightImpact()
                    editing = false 
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") { 
                    UINotificationFeedbackGenerator.success()
                    applyChanges() 
                }
            }
        }
    }

    // Helpers
    private var infoSection: some View {
        Section(header: Text("Period Information")) {
            labeled("Start Date", period.startDate, formatter: dateFormatter)
            if let end = period.endDate { labeled("End Date", end, formatter: dateFormatter) }
            labeled("Flow Intensity", period.flow.rawValue)
        }
    }
    private var symptomSection: some View {
        Group {
            if !period.symptoms.isEmpty {
                Section(header: Text("Symptoms")) {
                    ForEach(Array(period.symptoms), id: \.self) { Text($0.rawValue) }
                }
            }
        }
    }
    private var notesSection: some View {
        Group {
            if !period.notes.isEmpty {
                Section(header: Text("Notes")) { Text(period.notes) }
            }
        }
    }
    private func labeled(_ title: String, _ value: String) -> some View {
        HStack { Text(title); Spacer(); Text(value).foregroundColor(.secondary) }
    }
    private func labeled(_ title: String, _ date: Date, formatter: DateFormatter) -> some View {
        labeled(title, formatter.string(from: date))
    }
    private var closeButton: some View { 
        Button("Close") { 
            UIImpactFeedbackGenerator.lightImpact()
            dismiss() 
        } 
    }

    private func applyChanges() {
        if !hasEnded { draft.endDate = nil }
        period.startDate = draft.startDate
        period.endDate   = draft.endDate
        period.flow      = draft.flow
        period.symptoms  = draft.symptoms
        period.notes     = draft.notes
        try? ctx.save()
        editing = false
    }
}

// MARK: – Reusable Multiple Selection Row

struct MultipleSelectionRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            UISelectionFeedbackGenerator.selection()
            action()
        }) {
            HStack {
                Text(title).foregroundColor(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark").foregroundColor(AppTheme.primary)
                }
            }
        }
    }
}

extension Set {
    mutating func toggle(_ element: Element) {
        if contains(element) { remove(element) } else { insert(element) }
    }
}

// MARK: – Utilities

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let (a, r, g, b): (UInt64, UInt64, UInt64, UInt64)
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue:  Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

let dateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateStyle = .medium
    return f
}()
