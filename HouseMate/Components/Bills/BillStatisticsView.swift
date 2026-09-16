//
//  BillStatisticsView.swift
//  HouseMate
//

import Charts
import SwiftUI

struct BillStatisticsView: View {

    enum Period: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case sixMonths = "6 Months"
        case year = "Year"

        var id: Self { self }

        var dateComponent: Calendar.Component {
            switch self {
            case .week: .weekOfYear
            case .month, .sixMonths: .month
            case .year: .year
            }
        }

        var value: Int {
            switch self {
            case .week, .month, .year: -1
            case .sixMonths: -6
            }
        }
    }

    let bills: [BillModel]

    @State private var selectedPeriod: Period = .month

    private let calendar = Calendar.autoupdatingCurrent

    var body: some View {
        ZStack {
            backgroundGradient

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    periodPicker
                    summaryCard
                    categoryCard
                }
                .padding(18)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var periodPicker: some View {
        Picker("Statistics period", selection: $selectedPeriod) {
            ForEach(Period.allCases) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Total spent")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(totalSpent, format: .currency(code: "GBP"))
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .contentTransition(.numericText(value: totalSpent))

            HStack(spacing: 12) {
                summaryMetric(
                    title: "Paid bills",
                    value: "\(paidBills.count)",
                    systemImage: "checkmark.circle.fill",
                    color: .green
                )

                summaryMetric(
                    title: "Average",
                    value: averageSpent.formatted(.currency(code: "GBP")),
                    systemImage: "chart.line.uptrend.xyaxis",
                    color: .blue
                )
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dashboardSurface()
        .animation(.snappy, value: selectedPeriod)
    }

    private func summaryMetric(
        title: String,
        value: String,
        systemImage: String,
        color: Color
    ) -> some View {
        HStack(spacing: 9) {
            Image(systemName: systemImage)
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("By category")
                .font(.headline)

            if categorySpending.isEmpty {
                Label("No paid bills in this period", systemImage: "chart.pie")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                Chart(categorySpending) { item in
                    SectorMark(
                        angle: .value("Amount", item.amount),
                        innerRadius: .ratio(0.62),
                        angularInset: 2
                    )
                    .cornerRadius(4)
                    .foregroundStyle(item.color)
                }
                .frame(height: 170)
                .chartBackground { _ in
                    VStack(spacing: 2) {
                        Text("Spent")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(totalSpent, format: .currency(code: "GBP"))
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(categorySpending) { item in
                        HStack(spacing: 7) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 8, height: 8)

                            Text(item.category.title)
                                .font(.caption)
                                .lineLimit(1)

                            Spacer(minLength: 2)

                            Text(item.amount, format: .currency(code: "GBP"))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(18)
        .dashboardSurface()
        .animation(.snappy, value: selectedPeriod)
    }

    private var paidBills: [BillModel] {
        guard let startDate = calendar.date(
            byAdding: selectedPeriod.dateComponent,
            value: selectedPeriod.value,
            to: .now
        ) else { return [] }

        return bills.filter { bill in
            bill.status == .paid && (bill.paidAt ?? .distantPast) >= startDate
        }
    }

    private var totalSpent: Double {
        paidBills.reduce(0) { $0 + $1.amount }
    }

    private var averageSpent: Double {
        guard !paidBills.isEmpty else { return 0 }
        return totalSpent / Double(paidBills.count)
    }

    private var categorySpending: [CategorySpending] {
        Dictionary(grouping: paidBills, by: \.category)
            .map { category, bills in
                CategorySpending(
                    category: category,
                    amount: bills.reduce(0) { $0 + $1.amount }
                )
            }
            .sorted { $0.amount > $1.amount }
    }

    private var backgroundGradient: some View {
        ZStack {
            Color(.secondarySystemBackground)

            LinearGradient(
                colors: [
                    Color.blue.opacity(0.18),
                    Color.purple.opacity(0.10),
                    Color.cyan.opacity(0.08),
                    Color(.secondarySystemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.blue.opacity(0.13))
                .frame(width: 260, height: 260)
                .blur(radius: 75)
                .offset(x: 150, y: -280)

            Circle()
                .fill(Color.purple.opacity(0.09))
                .frame(width: 240, height: 240)
                .blur(radius: 80)
                .offset(x: -150, y: 310)
        }
        .ignoresSafeArea()
    }
}

private struct CategorySpending: Identifiable {
    let category: BillCategory
    let amount: Double

    var id: BillCategory { category }

    var color: Color {
        switch category {
        case .electricity: .yellow
        case .water: .cyan
        case .internet: .blue
        case .rent: .indigo
        case .gas: .orange
        case .councilTax: .purple
        case .subscription: .pink
        case .other: .gray
        }
    }
}

private extension View {
    func dashboardSurface() -> some View {
        background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.5), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
    }
}

#Preview {
    NavigationStack {
        BillStatisticsView(bills: BillModel.mockList)
            .navigationTitle("Statistics")
    }
}
