//
//  HouseholdPollsCardView.swift
//  HouseMate
//
//  Created by Marcin Turek on 24/08/2026.
//


import SwiftUI

struct HouseholdPollsCardView: View {

    let polls: [PollModel]
    let currentUserId: String
    let members: [HouseholdMemberModel]

    var showsAddButton: Bool = true

    var onAdd: () -> Void = {}

    var onVote: (
        _ poll: PollModel,
        _ option: PollOptionModel
    ) -> Void = { _, _ in }

    var onClose: ((PollModel) -> Void)? = nil
    var onDelete: ((PollModel) -> Void)? = nil

    @State private var refreshDate = Date.now

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            if activePolls.isEmpty {
                emptyState
            } else {
                pollsCarousel
            }
        }
        .padding()
        .background {
            cardBackground
        }
        .onAppear {
            refreshDate = .now
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Household Polls")
                .font(.title3)
                .fontWeight(.semibold)

            Spacer()

            if showsAddButton {
                Button {
                    onAdd()
                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                }
            }
        }
    }

    // MARK: - Carousel

    private var pollsCarousel: some View {
        TabView {
            ForEach(activePolls) { poll in
                pollPage(poll)
                    .padding(.horizontal, 2)
            }
        }
        .tabViewStyle(
            .page(indexDisplayMode: .automatic)
        )
        .indexViewStyle(
            .page(backgroundDisplayMode: .always)
        )
        .frame(height: carouselHeight)
    }

    // MARK: - Poll Page

    private func pollPage(
        _ poll: PollModel
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            creatorInformation(for: poll)

            Text("“\(poll.question)”")
                .font(.headline)
                .fontWeight(.semibold)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )

            VStack(spacing: 10) {
                ForEach(poll.options) { option in
                    optionButton(
                        option,
                        in: poll
                    )
                }
            }

            Spacer(minLength: 0)

            pollFooter(poll)
        }
        .padding(.horizontal, 4)
        .padding(.top, 4)
        .padding(.bottom, 28)
    }

    // MARK: - Creator

    private func creatorInformation(
        for poll: PollModel
    ) -> some View {
        let creatorName = members.first {
            $0.userId == poll.createdByUserId
        }?.displayName ?? "Unknown member"

        return HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("\(creatorName) asked")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if let createdAt = poll.createdAt {
                    Text(
                        relativeCreationText(
                            for: createdAt
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if poll.createdByUserId == currentUserId {
                pollMenu(for: poll)
            }
        }
    }

    // MARK: - Poll Option

    private func optionButton(
        _ option: PollOptionModel,
        in poll: PollModel
    ) -> some View {
        let isSelected =
            poll.selectedOptionId(
                for: currentUserId
            ) == option.id

        let numberOfVotes =
            poll.voteCount(for: option)

        let progress = voteProgress(
            votes: numberOfVotes,
            totalVotes: poll.totalVotes
        )

        let percentage = Int(
            (progress * 100).rounded()
        )

        return Button {
            onVote(
                poll,
                option
            )
        } label: {
            HStack(spacing: 10) {
                Image(
                    systemName: isSelected
                        ? "checkmark.circle.fill"
                        : "circle"
                )
                .font(.title3)
                .foregroundStyle(
                    isSelected
                        ? Color.blue
                        : Color.secondary
                )

                Text(option.text)
                    .font(.subheadline)
                    .fontWeight(
                        isSelected
                            ? .semibold
                            : .regular
                    )
                    .foregroundStyle(.primary)

                Spacer()

                Text("\(percentage)%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background {
                optionBackground(
                    progress: progress,
                    isSelected: isSelected
                )
            }
        }
        .buttonStyle(.plain)
    }

    private func optionBackground(
        progress: Double,
        isSelected: Bool
    ) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
                .fill(
                    Color(.secondarySystemBackground)
                )

                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
                .fill(
                    isSelected
                        ? Color.blue.opacity(0.18)
                        : Color.blue.opacity(0.08)
                )
                .frame(
                    width: geometry.size.width * progress
                )

                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
                .stroke(
                    isSelected
                        ? Color.blue.opacity(0.35)
                        : Color.clear,
                    lineWidth: 1
                )
            }
        }
    }

    // MARK: - Footer

    private func pollFooter(
        _ poll: PollModel
    ) -> some View {
        Text(
            "\(poll.totalVotes) of " +
            "\(members.count) votes"
        )
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    // MARK: - Poll Menu

    private func pollMenu(
        for poll: PollModel
    ) -> some View {
        Menu {
            if onClose != nil {
                Button {
                    onClose?(poll)
                } label: {
                    Label(
                        "Close Poll",
                        systemImage: "checkmark.circle"
                    )
                }
            }

            if onDelete != nil {
                Button(role: .destructive) {
                    onDelete?(poll)
                } label: {
                    Label(
                        "Delete Poll",
                        systemImage: "trash"
                    )
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.headline)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 28))
                .foregroundStyle(.blue)

            Text("No active polls")
                .font(.subheadline)
                .fontWeight(.semibold)

            Text("Create a poll for your housemates.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
    }

    // MARK: - Calculated Values

    private var activePolls: [PollModel] {
        polls
            .filter {
                $0.status == .active
            }
            .sorted {
                ($0.createdAt ?? .distantPast)
                    > ($1.createdAt ?? .distantPast)
            }
    }

    private var carouselHeight: CGFloat {
        let maximumOptions =
            activePolls
                .map(\.options.count)
                .max() ?? 2

        let height =
            175 + CGFloat(maximumOptions * 54)

        return min(
            max(height, 300),
            430
        )
    }

    private func voteProgress(
        votes: Int,
        totalVotes: Int
    ) -> Double {
        guard totalVotes > 0 else {
            return 0
        }

        return Double(votes)
            / Double(totalVotes)
    }

    private func relativeCreationText(
        for date: Date
    ) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full

        return formatter.localizedString(
            for: date,
            relativeTo: refreshDate
        )
    }

    // MARK: - Background

    private var cardBackground: some View {
        RoundedRectangle(
            cornerRadius: 24,
            style: .continuous
        )
        .fill(.ultraThickMaterial)
        .overlay {
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
            .stroke(
                .white.opacity(0.35),
                lineWidth: 1
            )
        }
    }
}

// MARK: - Previews

#Preview("Polls") {
    HouseholdPollsCardView(
        polls: PollModel.mockList,
        currentUserId: "1",
        members: HouseholdMemberModel.mockList,
        onAdd: {
            print("Add poll")
        },
        onVote: { poll, option in
            print(
                "Vote \(option.text) in \(poll.question)"
            )
        },
        onClose: { poll in
            print("Close \(poll.question)")
        },
        onDelete: { poll in
            print("Delete \(poll.question)")
        }
    )
    .padding()
}

#Preview("Empty") {
    HouseholdPollsCardView(
        polls: [],
        currentUserId: "1",
        members: HouseholdMemberModel.mockList
    )
    .padding()
}
