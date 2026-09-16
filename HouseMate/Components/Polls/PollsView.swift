//
//  PollsView.swift
//  HouseMate
//

import SwiftUI

struct PollsView: View {

    let polls: [PollModel]
    let currentUserId: String
    let members: [HouseholdMemberModel]

    var onAdd: () -> Void = {}
    var onVote: (PollModel, PollOptionModel) -> Void = { _, _ in }
    var onRemoveVote: (PollModel) -> Void = { _ in }
    var onClose: (PollModel) -> Void = { _ in }
    var onDelete: (PollModel) -> Void = { _ in }

    @State private var refreshDate = Date.now
    @State private var selectedPollID: String?

    var body: some View {
        ZStack {
            backgroundGradient

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    if activePolls.isEmpty {
                        emptyState
                    } else {
                        pollPicker

                        if let selectedPoll {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("SELECTED POLL")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.primary.opacity(0.52))
                                    .padding(.horizontal, 4)

                                pollCard(selectedPoll)
                                    .id(selectedPoll.id)
                                    .transition(
                                        .opacity.combined(
                                            with: .move(edge: .trailing)
                                        )
                                    )
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
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onAdd) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Create poll")
            }
        }
        .onAppear {
            refreshDate = .now
            validateSelection()
        }
        .onChange(of: activePollIDs) {
            validateSelection()
        }
    }

    private var pollPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ACTIVE POLLS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.primary.opacity(0.52))
                .padding(.horizontal, 4)

            ScrollView(.horizontal) {
                LazyHStack(spacing: 12) {
                    ForEach(activePolls) { poll in
                        compactPollCard(poll)
                    }
                }
                .scrollTargetLayout()
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
        }
    }

    private func compactPollCard(_ poll: PollModel) -> some View {
        let isSelected = poll.id == selectedPollID
        let hasVoted = poll.selectedOptionId(for: currentUserId) != nil

        return Button {
            HapticFeedback.selection()
            withAnimation(.snappy(duration: 0.28)) {
                selectedPollID = poll.id
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: hasVoted ? "checkmark.circle.fill" : "chart.bar")
                        .foregroundStyle(isSelected ? .white : .purple)

                    Spacer()

                    Text("\(poll.totalVotes)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }

                Text(poll.question)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                Text(hasVoted ? "Voted" : "Waiting for your vote")
                    .font(.caption2)
                    .foregroundStyle(
                        isSelected
                            ? Color.white.opacity(0.78)
                            : Color.primary.opacity(0.52)
                    )
            }
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .padding(14)
            .frame(width: 190, height: 118, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        isSelected
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [.purple, .indigo],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            : AnyShapeStyle(.ultraThinMaterial)
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        isSelected
                            ? Color.white.opacity(0.28)
                            : Color.white.opacity(0.45),
                        lineWidth: 1
                    )
            }
            .shadow(
                color: isSelected
                    ? Color.purple.opacity(0.2)
                    : Color.black.opacity(0.04),
                radius: 10,
                y: 5
            )
            .scaleEffect(isSelected ? 1 : 0.97)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Select poll: \(poll.question)")
    }

    private func pollCard(_ poll: PollModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            creatorRow(for: poll)

            Text(poll.question)
                .font(.headline)
                .fontWeight(.semibold)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 10) {
                ForEach(poll.options) { option in
                    optionButton(option, in: poll)
                }
            }

            HStack {
                Label(votesText(for: poll), systemImage: "person.2.fill")

                Spacer()

                if let expiresAt = poll.expiresAt {
                    Label(expiryText(expiresAt), systemImage: "clock")
                }
            }
            .font(.caption)
            .foregroundStyle(Color.primary.opacity(0.52))
        }
        .padding(16)
        .pollSurface()
    }

    private func creatorRow(for poll: PollModel) -> some View {
        let creator = members.first { $0.userId == poll.createdByUserId }
        let creatorName = creator?.displayName ?? "Unknown member"

        return HStack(spacing: 10) {
            CachedProfileImage(
                urlString: creator?.profileImageUrl,
                displayName: creatorName,
                size: 34
            )

            VStack(alignment: .leading, spacing: 2) {
                Text("\(creatorName) asked")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if let createdAt = poll.createdAt {
                    Text(relativeText(for: createdAt))
                        .font(.caption)
                        .foregroundStyle(Color.primary.opacity(0.52))
                }
            }

            Spacer()

            if poll.createdByUserId == currentUserId {
                pollMenu(poll)
            }
        }
    }

    private func optionButton(
        _ option: PollOptionModel,
        in poll: PollModel
    ) -> some View {
        let isSelected = poll.selectedOptionId(for: currentUserId) == option.id
        let votes = poll.voteCount(for: option)
        let progress = poll.totalVotes == 0
            ? 0
            : Double(votes) / Double(poll.totalVotes)
        let percentage = Int((progress * 100).rounded())

        return Button {
            HapticFeedback.selection()
            if isSelected {
                onRemoveVote(poll)
            } else {
                onVote(poll, option)
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(
                        isSelected
                            ? Color.purple
                            : Color.primary.opacity(0.45)
                    )
                    .contentTransition(.symbolEffect(.replace))

                Text(option.text)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 8)

                Text("\(percentage)%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.primary.opacity(0.55))
                    .monospacedDigit()
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 46)
            .background {
                optionBackground(progress: progress, isSelected: isSelected)
            }
        }
        .buttonStyle(.plain)
        .animation(.snappy(duration: 0.25), value: poll.votesByUserId)
    }

    private func optionBackground(
        progress: Double,
        isSelected: Bool
    ) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(Color.primary.opacity(0.045))

                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(
                        isSelected
                            ? Color.purple.opacity(0.20)
                            : Color.purple.opacity(0.09)
                    )
                    .frame(width: geometry.size.width * progress)

                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(
                        isSelected
                            ? Color.purple.opacity(0.38)
                            : Color.primary.opacity(0.06),
                        lineWidth: 1
                    )
            }
        }
    }

    private func pollMenu(_ poll: PollModel) -> some View {
        Menu {
            Button {
                onClose(poll)
            } label: {
                Label("Close Poll", systemImage: "checkmark.circle")
            }

            Button(role: .destructive) {
                onDelete(poll)
            } label: {
                Label("Delete Poll", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.headline)
                .frame(width: 32, height: 32)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No active polls",
            systemImage: "chart.bar.doc.horizontal",
            description: Text("Create a poll and let your housemates decide together.")
        )
        .frame(maxWidth: .infinity)
        .padding(.top, 54)
    }

    private var activePolls: [PollModel] {
        polls
            .filter { $0.status == .active }
            .sorted {
                ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast)
            }
    }

    private var activePollIDs: [String] {
        activePolls.map(\.id)
    }

    private var selectedPoll: PollModel? {
        activePolls.first { $0.id == selectedPollID } ?? activePolls.first
    }

    private func validateSelection() {
        guard !activePolls.isEmpty else {
            selectedPollID = nil
            return
        }

        if !activePolls.contains(where: { $0.id == selectedPollID }) {
            selectedPollID = activePolls[0].id
        }
    }

    private func votesText(for poll: PollModel) -> String {
        "\(poll.totalVotes) of \(members.count) votes"
    }

    private func relativeText(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: refreshDate)
    }

    private func expiryText(_ date: Date) -> String {
        if date <= refreshDate { return "Ended" }
        return "Ends \(date.formatted(.relative(presentation: .named)))"
    }

    private var backgroundGradient: some View {
        ZStack {
            Color(.secondarySystemBackground)
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.16),
                    Color.indigo.opacity(0.11),
                    Color.blue.opacity(0.07),
                    Color(.secondarySystemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }
}

private extension View {
    func pollSurface() -> some View {
        background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.5), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.05), radius: 12, y: 6)
    }
}

#Preview {
    NavigationStack {
        PollsView(
            polls: PollModel.mockList,
            currentUserId: "1",
            members: HouseholdMemberModel.mockList
        )
        .navigationTitle("Polls")
    }
}
