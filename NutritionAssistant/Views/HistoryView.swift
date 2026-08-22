import SwiftUI
import SwiftData
import Charts


// MARK: - Design Color Tokens  (spec: LINE_COLORS)
private enum NC {
    static let calories = Color(hex: "#FF453A")  // Red
    static let fat      = Color(hex: "#FF9F0A")  // Amber
    static let protein  = Color(hex: "#0A84FF")  // iOS Blue
    static let carbs    = Color(hex: "#BF5AF2")  // Purple
}

// MARK: - Period Options
enum HistoryPeriod: String, CaseIterable, Identifiable {
    case sevenDays    = "7 Days"
    case thirtyDays   = "30 Days"
    case threeMonths  = "3 Months"
    case oneYear      = "1 Year"

    var id: String { rawValue }

    var days: Int {
        switch self {
        case .sevenDays:   return 7
        case .thirtyDays:  return 30
        case .threeMonths: return 90
        case .oneYear:     return 365
        }
    }
}

// MARK: - Time-Series Data Model
struct DailySummary: Identifiable, Equatable {
    var id: Date { date }
    let date:     Date
    let calories: Double
    let fat:      Double
    let protein:  Double
    let carbs:    Double
    var hasData: Bool { calories > 0 || fat > 0 || protein > 0 || carbs > 0 }
}

private struct NutritionChartPoint: Identifiable {
    var id: String { "\(series)-\(date.timeIntervalSince1970)" }
    let date:   Date
    let value:  Double
    let series: String
}

// MARK: - HistoryView

struct HistoryView: View {
    // MARK: SwiftData
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ConsumedItem.logicalDate, order: .reverse)
    private var consumedItems: [ConsumedItem]
    @Query private var userSettingsList: [UserSettings]

    private var dayStartHour: Int {
        userSettingsList.first?.dayStartHour ?? 0
    }

    /// Optional closure injected by ContentView to switch to the Today tab.
    var onNavigateToToday: (() -> Void)? = nil

    // MARK: State
    @State private var selectedPeriod: HistoryPeriod = .sevenDays
    @State private var showSettings = false

    // MARK: - Date Helpers
    private var today: Date { Date().logicalDay(startHour: dayStartHour) }
    private var periodStartDate: Date {
        Calendar.current.date(byAdding: .day,
                              value: -(selectedPeriod.days - 1),
                              to: today) ?? today
    }

    // MARK: - O(N + D) Data Aggregation
    /// Groups all ConsumedItems by logical day in O(N) then walks the date
    /// range sequentially in O(D), filling missing days with zeros.
    private var dailySummaries: [DailySummary] {
        let cal = Calendar.current

        // Pass 1 – group by logical midnight (O(N))
        let byDay = Dictionary(grouping: consumedItems) {
            cal.startOfDay(for: $0.logicalDate)
        }

        // Pass 2 – reduce each bucket to numeric totals (O(N))
        var totals: [Date: (c: Double, f: Double, p: Double, cb: Double)] = [:]
        for (date, items) in byDay {
            totals[date] = (
                c:  items.reduce(0) { $0 + Double($1.calories) },
                f:  items.reduce(0) { $0 + $1.fat },
                p:  items.reduce(0) { $0 + $1.protein },
                cb: items.reduce(0) { $0 + $1.carb }
            )
        }

        // Pass 3 – sequential walk from periodStart → today, inserting zeros (O(D))
        var result: [DailySummary] = []
        var cursor = cal.startOfDay(for: periodStartDate)
        let endDay = cal.startOfDay(for: today)

        while cursor <= endDay {
            if let t = totals[cursor] {
                result.append(DailySummary(date: cursor,
                                           calories: t.c, fat: t.f,
                                           protein: t.p, carbs: t.cb))
            } else {
                result.append(DailySummary(date: cursor,
                                           calories: 0, fat: 0,
                                           protein: 0, carbs: 0))
            }
            guard let next = cal.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return result
    }

    // MARK: - Period Averages (non-zero days only)
    private func avg(_ values: [Double]) -> Double {
        let v = values.filter { $0 > 0 }
        return v.isEmpty ? 0 : v.reduce(0, +) / Double(v.count)
    }

    private var avgCalories: Double { avg(dailySummaries.map(\.calories)) }
    private var avgFat:      Double { avg(dailySummaries.map(\.fat))     }
    private var avgProtein:  Double { avg(dailySummaries.map(\.protein)) }
    private var avgCarbs:    Double { avg(dailySummaries.map(\.carbs))   }

    // MARK: - User Goals
    private var userSettings: UserSettings? { userSettingsList.first }
    private var calGoal:     Double { Double(userSettings?.userCaloriesGoal ?? 2000) }
    private var fatGoal:     Double { Double(userSettings?.userFatGoal     ?? 80)   }
    private var proteinGoal: Double { Double(userSettings?.userProteinGoal ?? 110)  }
    private var carbGoal:    Double { Double(userSettings?.userCarbGoal    ?? 210)  }

    // MARK: - Dual Y-Axis Normalization
    /// Left axis scale (Calories) — max value + 15% headroom
    private var maxCalories: Double {
        max(dailySummaries.map(\.calories).max() ?? 0, 500) * 1.15
    }
    /// Maximum gram value across all macro series + 15% headroom
    private var maxMacros: Double {
        let m = [dailySummaries.map(\.fat).max()     ?? 0,
                 dailySummaries.map(\.protein).max() ?? 0,
                 dailySummaries.map(\.carbs).max()   ?? 0].max() ?? 0
        return max(m, 50) * 1.15
    }
    /// Multiply any gram value by this factor to plot it on the calorie axis
    private var macroScale: Double {
        maxMacros > 0 ? maxCalories / maxMacros : 1
    }

    /// Flat array of all four normalized series — O(4D) build cost
    private var chartPoints: [NutritionChartPoint] {
        dailySummaries.flatMap { s in [
            NutritionChartPoint(date: s.date, value: s.calories,             series: "Calories"),
            NutritionChartPoint(date: s.date, value: s.fat     * macroScale, series: "Fat"),
            NutritionChartPoint(date: s.date, value: s.protein * macroScale, series: "Protein"),
            NutritionChartPoint(date: s.date, value: s.carbs   * macroScale, series: "Carbs"),
        ]}
    }

    // MARK: - X-Axis Tick Generation
    private var xAxisTicks: [Date] {
        let cal    = Calendar.current
        let endDay = cal.startOfDay(for: today)
        let start  = cal.startOfDay(for: periodStartDate)

        switch selectedPeriod {
        case .sevenDays:
            // One tick per day
            return dailySummaries.map { cal.startOfDay(for: $0.date) }

        case .thirtyDays:
            // 4 weekly ticks
            return [21, 14, 7, 0].compactMap {
                cal.date(byAdding: .day, value: -$0, to: endDay)
            }.filter { $0 >= start }

        case .threeMonths:
            // 4 evenly spaced ticks: 90, 60, 30, 0 days ago
            return [90, 60, 30, 0].compactMap {
                cal.date(byAdding: .day, value: -$0, to: endDay)
            }.filter { $0 >= start }

        case .oneYear:
            // Monthly ticks from first month of period through today
            var ticks: [Date] = []
            let comps = cal.dateComponents([.year, .month], from: start)
            var cursor = cal.date(from: comps) ?? start
            while cursor <= endDay {
                if cursor >= start { ticks.append(cursor) }
                guard let next = cal.date(byAdding: .month, value: 1, to: cursor) else { break }
                cursor = next
            }
            return ticks
        }
    }

    private func xAxisLabel(for date: Date) -> String {
        let todayMidnight = Calendar.current.startOfDay(for: today)
        if date == todayMidnight { return "Today" }

        let f = DateFormatter()
        switch selectedPeriod {
        case .sevenDays:                    f.dateFormat = "EEE"
        case .thirtyDays, .threeMonths:    f.dateFormat = "M/d"
        case .oneYear:                      f.dateFormat = "MMM"
        }
        return f.string(from: date)
    }

    private var chartCardHeight: CGFloat {
        UIScreen.main.bounds.height * 0.40
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    headerAndPicker
                    chartCard

                    Text("Weekly Average")
                        .font(.title3.bold())
                    weeklyAverageGrid

                    Text("Daily Log")
                        .font(.title3.bold())
                    dailyLogCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { onNavigateToToday?() }) {
                        HStack(spacing: 3) {
                            Image(systemName: "chevron.left").fontWeight(.semibold)
                            Text("Today")
                        }
                        .foregroundColor(.accentColor)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.primary)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }

    // MARK: - Header & Period Picker

    @ViewBuilder
    private var headerAndPicker: some View {
        HStack(alignment: .center) {
            Text("Nutrition History")
                .font(.title2.bold())
            Spacer()
            // Pill-shaped dropdown menu
            Menu {
                ForEach(HistoryPeriod.allCases) { period in
                    Button(period.rawValue) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedPeriod = period
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selectedPeriod.rawValue)
                        .font(.subheadline.weight(.medium))
                    Image(systemName: "chevron.down")
                        .font(.caption.bold())
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(Capsule())
            }
        }
    }

    // MARK: - Chart Card

    @ViewBuilder
    private var chartCard: some View {
        VStack(spacing: 0) {
            ZStack {
                // ── Core Swift Chart ──────────────────────────────────────────
                Chart(chartPoints) { point in
                    LineMark(
                        x: .value("Day",   point.date,  unit: .day),
                        y: .value("Value", point.value),
                        series: .value("Series", point.series)
                    )
                    .foregroundStyle(by: .value("Series", point.series))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                }
                // Map each series name → its exact spec colour
                .chartForegroundStyleScale([
                    "Calories": NC.calories,
                    "Fat":      NC.fat,
                    "Protein":  NC.protein,
                    "Carbs":    NC.carbs,
                ])
                .chartLegend(.hidden)
                .chartYScale(domain: 0...maxCalories)
                // ── Y-Axis (Dual) ─────────────────────────────────────────────
                .chartYAxis {
                    // Leading – Calorie values + dashed horizontal grid lines
                    AxisMarks(position: .leading,
                              values: .automatic(desiredCount: 5)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.4, dash: [4, 3]))
                            .foregroundStyle(Color.secondary.opacity(0.20))
                        AxisTick()
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(v >= 1000 ? "\(Int(v / 1000))k" : "\(Int(v))")
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    // Trailing – Gram values (no duplicate grid lines)
                    AxisMarks(position: .trailing,
                              values: .automatic(desiredCount: 5)) { value in
                        AxisTick()
                        AxisValueLabel {
                            if let v = value.as(Double.self), macroScale > 0 {
                                Text("\(Int((v / macroScale).rounded()))")
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                // ── X-Axis ────────────────────────────────────────────────────
                .chartXAxis {
                    AxisMarks(values: xAxisTicks) { value in
                        AxisValueLabel {
                            if let d = value.as(Date.self) {
                                Text(xAxisLabel(for: d))
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(.horizontal, 22) // Room for axis value labels

                // ── Rotated Axis Title Labels (overlay) ───────────────────────
                HStack(spacing: 0) {
                    Text("Calories")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(NC.calories)
                        .rotationEffect(.degrees(-90))
                        .frame(width: 18)
                    Spacer()
                    Text("Grams")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(90))
                        .frame(width: 18)
                }
            }
            .frame(height: chartCardHeight)
            .padding(.horizontal, 4)
            .padding(.top, 14)

            // ── Legend Row ────────────────────────────────────────────────────
            HStack(spacing: 0) {
                Spacer()
                chartLegendEntry("Calories", NC.calories)
                chartLegendEntry("Fat",      NC.fat)
                chartLegendEntry("Protein",  NC.protein)
                chartLegendEntry("Carbs",    NC.carbs)
                Spacer()
            }
            .padding(.vertical, 12)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    @ViewBuilder
    private func chartLegendEntry(_ name: String, _ color: Color) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(color)
                .frame(width: 20, height: 3)
            Text(name)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 6)
    }

    // MARK: - Weekly Average Grid

    @ViewBuilder
    private var weeklyAverageGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())],
            spacing: 12
        ) {
            WeeklySummaryCard(label: "Avg Calories", value: avgCalories, unit: "kcal/day",
                              color: NC.calories, progress: avgCalories / calGoal)
            WeeklySummaryCard(label: "Avg Protein",  value: avgProtein,  unit: "g/day",
                              color: NC.protein,  progress: avgProtein  / proteinGoal)
            WeeklySummaryCard(label: "Avg Carbs",    value: avgCarbs,    unit: "g/day",
                              color: NC.carbs,    progress: avgCarbs    / carbGoal)
            WeeklySummaryCard(label: "Avg Fat",      value: avgFat,      unit: "g/day",
                              color: NC.fat,      progress: avgFat      / fatGoal)
        }
    }

    // MARK: - Daily Log Card

    @ViewBuilder
    private var dailyLogCard: some View {
        let logDays = dailySummaries
            .filter(\.hasData)
            .sorted { $0.date > $1.date } // Newest first

        VStack(spacing: 0) {
            if logDays.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary.opacity(0.35))
                    Text("No food logged in this period")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 44)
            } else {
                ForEach(logDays.indices, id: \.self) { i in
                    DailyLogRow(
                        summary:     logDays[i],
                        fatGoal:     fatGoal,
                        proteinGoal: proteinGoal,
                        carbGoal:    carbGoal
                    )
                    if i < logDays.count - 1 {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 1)
    }
}

// MARK: - Weekly Summary Card

private struct WeeklySummaryCard: View {
    let label:    String
    let value:    Double
    let unit:     String
    let color:    Color
    let progress: Double   // 0.0 – 1.0+ (capped in bar)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(formattedValue)
                    .font(.title2.bold())
                    .foregroundColor(color)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 0)

            // Progress bar toward goal
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(color.opacity(0.15))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * max(0, min(progress, 1.0)))
                }
            }
            .frame(height: 4)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
        .frame(height: 108)
    }

    private var formattedValue: String {
        let n = Int(value.rounded())
        return n >= 1000 ? "\(n / 1000),\(String(format: "%03d", n % 1000))" : "\(n)"
    }
}

// MARK: - Daily Log Row

private struct DailyLogRow: View {
    let summary:     DailySummary
    let fatGoal:     Double
    let proteinGoal: Double
    let carbGoal:    Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // ── Top: Day name · short date                   Calories kcal > ──
            HStack {
                HStack(spacing: 5) {
                    Text(dayName)
                        .font(.headline)
                    Text(shortDate)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                HStack(spacing: 3) {
                    Text(formattedCalories)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(NC.calories)
                    Text("kcal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // ── Middle: Parallel macro progress bars ──────────────────────────
            HStack(spacing: 6) {
                MacroProgressBar(value: summary.fat,     goal: fatGoal,     color: NC.fat)
                MacroProgressBar(value: summary.protein, goal: proteinGoal, color: NC.protein)
                MacroProgressBar(value: summary.carbs,   goal: carbGoal,    color: NC.carbs)
            }
            .frame(height: 5)

            // ── Bottom: Gram values with colored labels ────────────────────────
            HStack(spacing: 14) {
                macroLabel("Fat",     value: summary.fat,     color: NC.fat)
                macroLabel("Protein", value: summary.protein, color: NC.protein)
                macroLabel("Carbs",   value: summary.carbs,   color: NC.carbs)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private func macroLabel(_ name: String, value: Double, color: Color) -> some View {
        HStack(spacing: 2) {
            Text(name)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(Int(value.rounded()))g")
                .font(.caption.weight(.semibold))
                .foregroundColor(color)
        }
    }

    private var dayName: String {
        let f = DateFormatter(); f.dateFormat = "EEEE"
        return f.string(from: summary.date)
    }

    private var shortDate: String {
        let f = DateFormatter(); f.dateFormat = "MMM d"
        return f.string(from: summary.date)
    }

    private var formattedCalories: String {
        let n = Int(summary.calories.rounded())
        return n >= 1000 ? "\(n / 1000),\(String(format: "%03d", n % 1000))" : "\(n)"
    }
}

// MARK: - Macro Progress Bar

private struct MacroProgressBar: View {
    let value: Double
    let goal:  Double
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(color.opacity(0.15))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Capsule()
                    .fill(color)
                    .frame(width: geo.size.width * max(0, min(value / max(goal, 1), 1.0)))
            }
        }
    }
}

// MARK: - Preview  (seeded with spec's reference data)

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ConsumedItem.self, FoodItem.self, UserSettings.self,
        configurations: config
    )

    // User goals matching the spec's mock data for realistic progress bars
    let settings = UserSettings(
        userCaloriesGoal: 2200, userCaloriesGoalType: .goal,
        userFatGoal: 90,        userFatGoalType: .limit,
        userSaturatedFatGoal: 25, userSaturatedFatGoalType: .limit,
        userTransFatGoal: 0,    userTransFatGoalType: .limit,
        userProteinGoal: 160,   userProteinGoalType: .goal,
        userCarbGoal: 265,      userCarbGoalType: .goal,
        userDietaryFiberGoal: 28, userDietaryFiberGoalType: .goal,
        userAddedSugarGoal: 50, userAddedSugarGoalType: .limit
    )
    container.mainContext.insert(settings)

    // Spec's dailyData reference array
    let mockDays: [(daysAgo: Int, cal: Int, fat: Double, protein: Double, carbs: Double)] = [
        (0, 2250,  90, 160, 265),
        (1, 1920,  76, 140, 230),
        (2, 2050,  80, 145, 242),
        (3, 1750,  65, 128, 195),
        (4, 2100,  85, 152, 255),
        (5, 1850,  72, 138, 220),
    ]

    let calendar = Calendar.current
    let today = Date().logicalDay(startHour: 0)

    for mock in mockDays {
        let logDate = calendar.date(byAdding: .day, value: -mock.daysAgo, to: today) ?? today
        let item = ConsumedItem(
            timestamp:    logDate.addingTimeInterval(43200), // noon timestamp
            logicalDate:  logDate,
            name:         "Daily Meals",
            servingSize:  1.0,
            servingUnit:  "day",
            calories:     mock.cal,
            fat:          mock.fat,
            saturatedFat: mock.fat * 0.28,
            transFat:     0,
            protein:      mock.protein,
            carb:         mock.carbs,
            dietaryFiber: 26,
            addedSugar:   28,
            category:     .preparedFoods
        )
        container.mainContext.insert(item)
    }

    return HistoryView()
        .modelContainer(container)
}
