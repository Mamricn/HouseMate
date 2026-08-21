//
//  HouseholdView.swift
//  HouseMate
//
//  Created by Marcin Turek on 17/08/2026.
//

import SwiftUI

@Observable
final class HouseholdViewModel {

    var selectedDate: Date = .now

    var currentUser: UserModel = UserModel.mockList[0]

    var members: [HouseholdMemberModel] = HouseholdMemberModel.mockList
    var tasks: [TaskModel] = TaskModel.mockList
    var shoppingItems: [ShoppingItemModel] = ShoppingItemModel.mockList
    var bills: [BillModel] = BillModel.mockList

    // MARK: - Task Actions

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

    func deleteTask(_ task: TaskModel) {
        tasks.removeAll {
            $0.id == task.id
        }
    }

    // MARK: - Shopping Actions

    func addShoppingItem(
        name: String,
        quantity: Int
    ) {
        guard let householdId = currentUser.householdId else {
            return
        }

        let newItem = ShoppingItemModel(
            itemId: UUID().uuidString,
            householdId: householdId,
            createdAt: .now,
            name: name,
            quantity: quantity,
            addedByUserId: currentUser.id,
            isPurchased: false
        )

        shoppingItems.append(newItem)
    }

    func toggleShoppingItem(
        _ item: ShoppingItemModel
    ) {
        guard let index = shoppingItems.firstIndex(where: {
            $0.id == item.id
        }) else {
            return
        }

        shoppingItems[index].isPurchased.toggle()
    }

    func deleteShoppingItem(
        _ item: ShoppingItemModel
    ) {
        shoppingItems.removeAll {
            $0.id == item.id
        }
    }

    func clearPurchasedShoppingItems() {
        shoppingItems.removeAll {
            $0.isPurchased
        }
    }

    // MARK: - Bill Actions

    func markBillAsPaid(_ bill: BillModel) {
        guard let index = bills.firstIndex(where: {
            $0.id == bill.id
        }) else {
            return
        }

        bills[index].status = .paid
        bills[index].paidByUserId = currentUser.id
    }

    func deleteBill(_ bill: BillModel) {
        bills.removeAll {
            $0.id == bill.id
        }
    }
}

struct HouseholdView: View {

    @State var viewModel: HouseholdViewModel

    @State private var showsAddShoppingItem = false
    @State private var toast: AppToast?

    var body: some View {
        ZStack {
            backgroundGradient
            content
            toastOverlay
        }
        .sheet(
            isPresented: $showsAddShoppingItem
        ) {
            addShoppingItemSheet
        }
    }

    // MARK: - Content

    private var content: some View {
        ScrollView {
            LazyVStack(
                alignment: .leading,
                spacing: 20
            ) {
                header
                scheduleCard
                shoppingCard
                billsCard
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 35)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Household")
                .font(
                    .system(
                        size: 30,
                        weight: .bold,
                        design: .rounded
                    )
                )

            Text("Manage your home together")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 8)
    }

    // MARK: - Schedule

    private var scheduleCard: some View {
        ScheduleCardView(
            selectedDate: $viewModel.selectedDate,
            tasks: viewModel.tasks,
            members: viewModel.members,
            showsAddButton: true,
            onAdd: {
                addChore()
            },
            onToggleStatus: { task in
                withAnimation {
                    viewModel.toggleTaskStatus(task)
                }

                showToast(
                    message: task.status == .completed
                        ? "Chore marked as pending"
                        : "Chore completed",
                    systemImage: task.status == .completed
                        ? "arrow.uturn.backward.circle"
                        : "checkmark.circle.fill",
                    color: task.status == .completed
                        ? .orange
                        : .green
                )
            },
            onDelete: { task in
                withAnimation {
                    viewModel.deleteTask(task)
                }

                showToast(
                    message: "\(task.title) deleted",
                    systemImage: "calendar.badge.minus",
                    color: .red
                )
            }
        )
        .householdCardShadow()
    }

    // MARK: - Shopping

    private var shoppingCard: some View {
        ShoppingCardView(
            items: viewModel.shoppingItems,
            showsAddButton: true,
            onAdd: {
                showsAddShoppingItem = true
            },
            onTogglePurchased: { item in
                withAnimation {
                    viewModel.toggleShoppingItem(item)
                }

                showToast(
                    message: item.isPurchased
                        ? "\(item.name) added back"
                        : "\(item.name) purchased",
                    systemImage: item.isPurchased
                        ? "arrow.uturn.backward.circle"
                        : "cart.badge.checkmark",
                    color: item.isPurchased
                        ? .orange
                        : .green
                )
            },
            onDelete: { item in
                withAnimation {
                    viewModel.deleteShoppingItem(item)
                }

                showToast(
                    message: "\(item.name) deleted",
                    systemImage: "trash.fill",
                    color: .red
                )
            },
            onClearPurchased: {
                withAnimation {
                    viewModel.clearPurchasedShoppingItems()
                }

                showToast(
                    message: "Purchased items cleared",
                    systemImage: "checkmark.circle.fill",
                    color: .green
                )
            }
        )
        .householdCardShadow()
    }

    // MARK: - Bills

    private var billsCard: some View {
        BillsCardView(
            bills: viewModel.bills,
            title: "All Bills",
            showsAddButton: true,
            onAdd: {
                addBill()
            },
            onMarkAsPaid: { bill in
                withAnimation {
                    viewModel.markBillAsPaid(bill)
                }

                showToast(
                    message: "\(bill.title) marked as paid",
                    systemImage: "checkmark.circle.fill",
                    color: .green
                )
            },
            onDelete: { bill in
                withAnimation {
                    viewModel.deleteBill(bill)
                }

                showToast(
                    message: "\(bill.title) deleted",
                    systemImage: "trash.fill",
                    color: .red
                )
            }
        )
        .householdCardShadow()
    }

    // MARK: - Shopping Sheet

    private var addShoppingItemSheet: some View {
        AddShoppingItemView { name, quantity in
            withAnimation {
                viewModel.addShoppingItem(
                    name: name,
                    quantity: quantity
                )
            }

            showToast(
                message: "\(name) added",
                systemImage: "cart.badge.plus",
                color: .green
            )
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Toast

    @ViewBuilder
    private var toastOverlay: some View {
        if let toast {
            VStack {
                AppToastView(toast: toast)
                    .transition(
                        .move(edge: .top)
                        .combined(with: .opacity)
                    )

                Spacer()
            }
            .padding(.top, 12)
            .zIndex(100)
            .allowsHitTesting(false)
        }
    }

    private func showToast(
        message: String,
        systemImage: String,
        color: Color
    ) {
        let newToast = AppToast(
            message: message,
            systemImage: systemImage,
            color: color
        )

        withAnimation(.spring(response: 0.4)) {
            toast = newToast
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 2.5
        ) {
            guard toast?.id == newToast.id else {
                return
            }

            withAnimation(.easeInOut(duration: 0.25)) {
                toast = nil
            }
        }
    }

    // MARK: - Add Actions

    private func addChore() {
        // Tutaj później otworzymy AddChoreView.
    }

    private func addBill() {
        // Tutaj później otworzymy AddBillView.
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

// MARK: - Card Shadow

private extension View {

    func householdCardShadow() -> some View {
        shadow(
            color: Color.black.opacity(0.07),
            radius: 14,
            x: 0,
            y: 7
        )
    }
}

// MARK: - Preview

#Preview {
    HouseholdView(
        viewModel: HouseholdViewModel()
    )
}
