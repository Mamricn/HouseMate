import Foundation
import Testing
@testable import HouseMate

@Suite("HouseholdManager — household membership and owner permissions")
struct HouseholdManagerTests {

    @Test("Creating a household makes its creator the owner and first member")
    @MainActor
    func createsHouseholdWithOwnerAsFirstMember() async throws {
        let owner = makeUser(id: "owner", name: "Marcin")
        let manager = HouseholdManager(
            householdService: MockHouseholdService(),
            userService: MockUserService(users: [owner])
        )

        let household = try await manager.createHousehold(
            name: "  Our Home  ",
            owner: owner
        )

        #expect(household.name == "Our Home")
        #expect(household.ownerUserId == owner.userId)
        #expect(household.memberIds == [owner.userId])
        #expect(manager.currentHousehold == household)
        #expect(manager.currentMembers.map(\.userId) == [owner.userId])
    }

    @Test("A regular member cannot remove another household member")
    @MainActor
    func preventsMemberFromRemovingAnotherMember() async throws {
        let household = makeHousehold(memberIDs: ["owner", "member", "other"])
        let manager = makeHouseholdManager(household: household)
        try await manager.fetchHousehold(householdID: household.householdId)

        do {
            try await manager.removeMember(
                userID: "other",
                requestedByUserID: "member"
            )
            Issue.record("A non-owner should not be able to remove members")
        } catch let error as HouseholdServiceError {
            guard case .ownerPermissionRequired = error else {
                Issue.record("Expected ownerPermissionRequired, received \(error)")
                return
            }
        }

        #expect(manager.currentMembers.contains { $0.userId == "other" })
        #expect(manager.currentHousehold?.memberIds.contains("other") == true)
    }

    @Test("The owner must transfer ownership before leaving the household")
    @MainActor
    func requiresOwnershipTransferBeforeOwnerLeaves() async throws {
        let household = makeHousehold(memberIDs: ["owner", "member"])
        let manager = makeHouseholdManager(household: household)
        try await manager.fetchHousehold(householdID: household.householdId)

        do {
            try await manager.leaveHousehold(userID: "owner")
            Issue.record("The current owner should not be able to leave")
        } catch let error as HouseholdServiceError {
            guard case .ownershipTransferRequired = error else {
                Issue.record("Expected ownershipTransferRequired, received \(error)")
                return
            }
        }

        #expect(manager.currentHousehold != nil)

        try await manager.transferOwnership(
            to: "member",
            requestedByUserID: "owner"
        )
        #expect(manager.currentHousehold?.ownerUserId == "member")

        try await manager.leaveHousehold(userID: "owner")
        #expect(manager.currentHousehold == nil)
        #expect(manager.currentMembers.isEmpty)
    }

    @Test("Only the household owner can prepare its invite lookup")
    @MainActor
    func onlyOwnerCanPrepareInviteLookup() async throws {
        let household = makeHousehold(memberIDs: ["owner", "member"])
        let manager = makeHouseholdManager(household: household)

        try await manager.ensureInviteLookup(
            for: household,
            requestedByUserID: "owner"
        )

        await #expect(throws: HouseholdServiceError.self) {
            try await manager.ensureInviteLookup(
                for: household,
                requestedByUserID: "member"
            )
        }
    }
}

@MainActor
private func makeHouseholdManager(household: HouseholdModel) -> HouseholdManager {
    let members = household.memberIds.map {
        HouseholdMemberModel(
            memberId: $0,
            householdId: household.householdId,
            userId: $0,
            joinedAt: .now,
            displayName: $0.capitalized
        )
    }

    return HouseholdManager(
        householdService: MockHouseholdService(
            households: [household],
            members: members
        ),
        userService: MockUserService(
            users: household.memberIds.map { makeUser(id: $0, name: $0.capitalized) }
        )
    )
}

private func makeHousehold(memberIDs: [String]) -> HouseholdModel {
    HouseholdModel(
        householdId: "house-tests",
        createdAt: .now,
        name: "Test Home",
        inviteCode: "ABC123",
        createdByUserId: "owner",
        ownerUserId: "owner",
        memberIds: memberIDs
    )
}

private func makeUser(id: String, name: String) -> UserModel {
    UserModel(
        userId: id,
        createdAt: .now,
        email: "\(id)@example.com",
        name: name
    )
}
