//
//  BillsView.swift
//  HouseMate
//

import SwiftUI

struct BillsView: View {

    private enum Filter: String, CaseIterable, Identifiable {
        case all = "All"
        case upcoming = "Upcoming"
        case paid = "Paid"

        var id: Self { self }
    }

    let bills: [BillModel]
    var onAdd: () -> Void = {}
    var onMarkAsPaid: (BillModel) -> Void = { _ in }
    var onDelete: (BillModel) -> Void = { _ in }

    @State private var selectedFilter: Filter = .all
    @State private var selectedCategory: BillCategory? = nil
    @State private var paidPage = 0

    private let paidPageSize = 10

    var body: some View {
        ZStack {
            backgroundGradient

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 22) {
                    categoryPicker
                    filterPicker

                    if filteredBills.isEmpty {
                        emptyState
                    } else {
                        if !overdueBills.isEmpty {
                            billSection("Overdue", bills: overdueBills, accent: .red)
                        }

                        if !upcomingBills.isEmpty {
                            billSection("Upcoming", bills: upcomingBills, accent: .blue)
                        }

                        if !paidBills.isEmpty {
                            billSection(
                                selectedFilter == .paid ? "Paid" : "Recently Paid",
                                bills: paidBills,
                                accent: .green,
                                totalCount: allPaidBills.count
                            )

                            if selectedFilter == .paid && paidPageCount > 1 {
                                paidPagination
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink {
                    BillStatisticsView(bills: bills)
                        .navigationTitle("Statistics")
                        .navigationBarTitleDisplayMode(.inline)
                } label: {
                    Image(systemName: "chart.bar.xaxis")
                }
                .accessibilityLabel("Open bill statistics")

                Button(action: onAdd) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add bill")
            }
        }
        .animation(.snappy, value: selectedFilter)
        .animation(.snappy, value: selectedCategory)
        .onChange(of: selectedFilter) { _, _ in paidPage = 0 }
        .onChange(of: selectedCategory) { _, _ in paidPage = 0 }
        .onChange(of: allPaidBills.count) { _, _ in
            paidPage = min(paidPage, max(paidPageCount - 1, 0))
        }
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                categoryButton(
                    title: "All",
                    systemImage: "square.grid.2x2.fill",
                    category: nil
                )

                ForEach(availableCategories, id: \.self) { category in
                    categoryButton(
                        title: category.title,
                        systemImage: category.systemImage,
                        category: category
                    )
                }
            }
            .padding(.horizontal, 1)
        }
        .scrollIndicators(.hidden)
    }

    private func categoryButton(
        title: String,
        systemImage: String,
        category: BillCategory?
    ) -> some View {
        let isSelected = selectedCategory == category

        return Button {
            selectedCategory = category
        } label: {
            HStack(spacing: 7) {
                Image(systemName: systemImage)
                    .font(.caption)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 14)
            .frame(height: 42)
            .background(
                isSelected ? Color.blue : Color.primary.opacity(0.07),
                in: Capsule()
            )
            .overlay {
                if !isSelected {
                    Capsule()
                        .stroke(.white.opacity(0.45), lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Show \(title) bills")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var filterPicker: some View {
        Picker("Bill filter", selection: $selectedFilter) {
            ForEach(Filter.allCases) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
    }

    private func billSection(
        _ title: String,
        bills: [BillModel],
        accent: Color,
        totalCount: Int? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle()
                    .fill(accent)
                    .frame(width: 7, height: 7)

                Text(title.uppercased())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(totalCount ?? bills.count)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(bills.enumerated()), id: \.element.id) { index, bill in
                    HouseMateSwipeRow(
                        leadingAction: HouseMateSwipeAction(
                            accessibilityLabel: "Delete \(bill.title)",
                            systemImage: "trash.fill",
                            color: .red,
                            action: { onDelete(bill) }
                        ),
                        trailingAction: paidAction(for: bill)
                    ) {
                        billRow(bill)
                    }

                    if index < bills.count - 1 {
                        Divider()
                            .padding(.leading, 62)
                    }
                }
            }
            .padding(.horizontal, 12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.5), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.05), radius: 12, y: 6)
        }
    }

    private func billRow(_ bill: BillModel) -> some View {
        HStack(spacing: 12) {
            HouseMateSymbolView(
                systemName: bill.category.systemImage,
                color: color(for: bill.status),
                size: 42,
                symbolSize: 17
            )

            if selectedCategory == nil {
                VStack(alignment: .leading, spacing: 3) {
                    Text(verbatim: bill.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    Text(verbatim: categoryAndDateText(for: bill))
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .lineLimit(1)
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: 40, alignment: .leading)
            } else {
                if let dateText = dateText(for: bill) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(verbatim: bill.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(1)

                        Text(verbatim: dateText)
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .lineLimit(1)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight: 40, alignment: .leading)
                } else {
                    Text(verbatim: bill.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 5) {
                Text(bill.amount, format: .currency(code: "GBP"))
                    .font(.subheadline)
                    .fontWeight(.semibold)

                statusLabel(bill.status)
            }
        }
        .padding(.vertical, 11)
    }

    private func paidAction(for bill: BillModel) -> HouseMateSwipeAction? {
        guard bill.status != .paid else { return nil }

        return HouseMateSwipeAction(
            accessibilityLabel: "Mark \(bill.title) as paid",
            systemImage: "checkmark",
            color: .green,
            action: { onMarkAsPaid(bill) }
        )
    }

    private func statusLabel(_ status: BillStatus) -> some View {
        Text(statusTitle(status))
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(color(for: status))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color(for: status).opacity(0.12), in: Capsule())
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No bills here",
            systemImage: selectedFilter == .paid ? "checkmark.circle" : "doc.text",
            description: Text(emptyDescription)
        )
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    private var filteredBills: [BillModel] {
        let categoryBills = bills.filter { bill in
            selectedCategory == nil || bill.category == selectedCategory
        }

        return switch selectedFilter {
        case .all:
            categoryBills.filter { bill in
                bill.status != .paid || wasPaidRecently(bill)
            }
        case .upcoming:
            categoryBills.filter { $0.status != .paid }
        case .paid:
            categoryBills.filter { $0.status == .paid }
        }
    }

    private var availableCategories: [BillCategory] {
        BillCategory.allCases.filter { category in
            bills.contains { $0.category == category }
        }
    }

    private var overdueBills: [BillModel] {
        filteredBills
            .filter { $0.status == .overdue }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    private var upcomingBills: [BillModel] {
        filteredBills
            .filter { $0.status == .upcoming }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    private var paidBills: [BillModel] {
        let bills = allPaidBills

        guard selectedFilter == .paid else { return bills }

        let page = min(paidPage, max(paidPageCount - 1, 0))
        let startIndex = page * paidPageSize
        let endIndex = min(startIndex + paidPageSize, bills.count)
        guard startIndex < endIndex else { return [] }

        return Array(bills[startIndex..<endIndex])
    }

    private var allPaidBills: [BillModel] {
        filteredBills
            .filter { $0.status == .paid }
            .sorted { ($0.paidAt ?? .distantPast) > ($1.paidAt ?? .distantPast) }
    }

    private var paidPageCount: Int {
        max(1, Int(ceil(Double(allPaidBills.count) / Double(paidPageSize))))
    }

    private var paidPagination: some View {
        HStack(spacing: 14) {
            Button {
                paidPage = max(paidPage - 1, 0)
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 38, height: 38)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .disabled(paidPage == 0)

            Text("Page \(paidPage + 1) of \(paidPageCount)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            Button {
                paidPage = min(paidPage + 1, paidPageCount - 1)
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 38, height: 38)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .disabled(paidPage >= paidPageCount - 1)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private func wasPaidRecently(_ bill: BillModel) -> Bool {
        guard let paidAt = bill.paidAt,
              let cutoff = Calendar.autoupdatingCurrent.date(byAdding: .day, value: -3, to: .now) else {
            return false
        }

        return paidAt >= cutoff
    }

    private var emptyDescription: String {
        let categoryText = selectedCategory.map { " in \($0.title.lowercased())" } ?? ""

        return switch selectedFilter {
        case .all: "There are no bills\(categoryText)."
        case .upcoming: "There are no upcoming or overdue bills\(categoryText)."
        case .paid: "There are no paid bills\(categoryText)."
        }
    }

    private func categoryAndDateText(for bill: BillModel) -> String {
        let category = bill.category.rowTitle
        guard let dateText = dateText(for: bill) else { return category }
        return "\(category) • \(dateText)"
    }

    private func dateText(for bill: BillModel) -> String? {
        let date = bill.status == .paid ? bill.paidAt : bill.dueDate
        guard let date else { return nil }

        let prefix = bill.status == .paid ? "Paid" : "Due"
        return "\(prefix) \(date.formatted(.dateTime.day().month(.abbreviated)))"
    }

    private func statusTitle(_ status: BillStatus) -> String {
        switch status {
        case .upcoming: "Upcoming"
        case .paid: "Paid"
        case .overdue: "Overdue"
        }
    }

    private func color(for status: BillStatus) -> Color {
        switch status {
        case .upcoming: .blue
        case .paid: .green
        case .overdue: .red
        }
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
        }
        .ignoresSafeArea()
    }
}

#Preview {
    NavigationStack {
        BillsView(bills: BillModel.mockList)
            .navigationTitle("Bills")
    }
}
