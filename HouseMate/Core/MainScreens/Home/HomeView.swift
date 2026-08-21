//
//  HomeView.swift
//  HouseMate
//
//  Created by Marcin Turek on 17/08/2026.
//

import SwiftUI



@Observable
final class HomeViewModel {

    var user: UserModel = UserModel.mockList[0]

    var tasks: [TaskModel] = TaskModel.mockList
    var notes: [NoteModel] = NoteModel.mockList
    var shoppingItems: [ShoppingItemModel] = ShoppingItemModel.mockList
    var bills: [BillModel] = BillModel.mockList
    var members: [HouseholdMemberModel] = HouseholdMemberModel.mockList

    private let calendar = Calendar.autoupdatingCurrent

    var userName: String {
        let name = user.name?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let name, !name.isEmpty else {
            return "there"
        }

        return name
    }

    var formattedToday: String {
        Date.now.formatted(
            .dateTime
                .weekday(.wide)
                .day(.twoDigits)
                .month(.twoDigits)
        )
    }

    // Zadania przypisane do użytkownika na dzisiaj
    var todaysTasks: [TaskModel] {
        tasks
            .filter { task in
                guard let dueDate = task.dueDate else {
                    return false
                }

                return task.assignedToUserId == user.id
                    && calendar.isDateInToday(dueDate)
            }
            .sorted {
                ($0.dueDate ?? .distantFuture)
                    < ($1.dueDate ?? .distantFuture)
            }
    }

    // Notatki z ostatnich 7 dni
    var notesFromLastSevenDays: [NoteModel] {
        let today = calendar.startOfDay(for: .now)

        guard
            let sevenDaysAgo = calendar.date(
                byAdding: .day,
                value: -6,
                to: today
            ),
            let tomorrow = calendar.date(
                byAdding: .day,
                value: 1,
                to: today
            )
        else {
            return []
        }

        return notes
            .filter { note in
                guard let createdAt = note.createdAt else {
                    return false
                }

                return createdAt >= sevenDaysAgo
                    && createdAt < tomorrow
            }
            .sorted {
                ($0.createdAt ?? .distantPast)
                    > ($1.createdAt ?? .distantPast)
            }
    }

    // Produkty dodane dzisiaj lub wczoraj
    var recentShoppingItems: [ShoppingItemModel] {
        let today = calendar.startOfDay(for: .now)

        guard
            let yesterday = calendar.date(
                byAdding: .day,
                value: -1,
                to: today
            ),
            let tomorrow = calendar.date(
                byAdding: .day,
                value: 1,
                to: today
            )
        else {
            return []
        }

        return shoppingItems
            .filter { item in
                guard let createdAt = item.createdAt else {
                    return false
                }

                return createdAt >= yesterday
                    && createdAt < tomorrow
            }
            .sorted {
                ($0.createdAt ?? .distantPast)
                    > ($1.createdAt ?? .distantPast)
            }
    }

    // Rachunki na dzisiaj i kolejne 3 dni
    var upcomingBills: [BillModel] {
        let today = calendar.startOfDay(for: .now)

        guard let endDate = calendar.date(
            byAdding: .day,
            value: 4,
            to: today
        ) else {
            return []
        }

        return bills
            .filter { bill in
                guard let dueDate = bill.dueDate else {
                    return false
                }

                return bill.status == .upcoming
                    && dueDate >= today
                    && dueDate < endDate
            }
            .sorted {
                ($0.dueDate ?? .distantFuture)
                    < ($1.dueDate ?? .distantFuture)
            }
    }
    
    func toggleTaskStatus(_ task: TaskModel) {
        guard let index = tasks.firstIndex(where: {
            $0.id == task.id
        }) else {
            return
        }

        tasks[index].status =
            tasks[index].status == .completed
            ? .pending
            : .completed
    }

    func toggleShoppingItem(_ item: ShoppingItemModel) {
        guard let index = shoppingItems.firstIndex(where: {
            $0.id == item.id
        }) else {
            return
        }

        shoppingItems[index].isPurchased.toggle()
    }
    
    func markBillAsPaid(_ bill: BillModel) {
        guard let index = bills.firstIndex(where: {
            $0.id == bill.id
        }) else {
            return
        }

        bills[index].status = .paid
        bills[index].paidByUserId = user.id
    }
}


struct HomeView: View {

    @State var viewModel: HomeViewModel

    var body: some View {
        ZStack {
            backgroundGradient

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    header

                    TaskCardView(
                        tasks: viewModel.todaysTasks,
                        members: viewModel.members,
                        showsAddButton: false,
                        onToggleStatus: { task in
                            withAnimation {
                                viewModel.toggleTaskStatus(task)
                            }
                        }
                    )
                    .dashboardShadow()

                    NotesCardView(notes: viewModel.notesFromLastSevenDays,
                                  showsAddButton: false
                    )
                    .dashboardShadow()

                    ShoppingCardView(
                        items: viewModel.recentShoppingItems,
                        showsAddButton: false,
                        onTogglePurchased: { item in
                            withAnimation {
                                viewModel.toggleShoppingItem(item)
                            }
                        }
                    )
                    .dashboardShadow()

                    BillsCardView(
                        bills: viewModel.upcomingBills,
                        title: "Upcoming Bills",
                        showsAddButton: false,
                        onMarkAsPaid: { bill in
                            withAnimation {
                                viewModel.markBillAsPaid(bill)
                            }
                        }
                    )
                    .dashboardShadow()
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 35)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hello \(viewModel.userName)")
                    .font(.system(size: 30, weight: .bold, design: .rounded))

                Text("It’s \(viewModel.formattedToday)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            profileImage
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 8)
    }

    private var profileImage: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)

            Image(systemName: "person.fill")
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(.blue)
        }
        .frame(width: 52, height: 52)
        .overlay {
            Circle()
                .stroke(.white.opacity(0.45), lineWidth: 1)
        }
        .shadow(
            color: .blue.opacity(0.15),
            radius: 10,
            y: 5
        )
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        ZStack {
            Color(.systemBackground)

            LinearGradient(
                colors: [
                    Color.blue.opacity(0.18),
                    Color.purple.opacity(0.10),
                    Color.cyan.opacity(0.08),
                    Color(.systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.blue.opacity(0.14))
                .frame(width: 280, height: 280)
                .blur(radius: 70)
                .offset(x: 150, y: -300)

            Circle()
                .fill(Color.purple.opacity(0.10))
                .frame(width: 250, height: 250)
                .blur(radius: 80)
                .offset(x: -160, y: 300)
        }
        .ignoresSafeArea()
    }
}

private extension View {

    func dashboardShadow() -> some View {
        self
            .shadow(
                color: Color.black.opacity(0.07),
                radius: 14,
                x: 0,
                y: 7
            )
    }
}

#Preview {
    HomeView(viewModel: HomeViewModel())
}
