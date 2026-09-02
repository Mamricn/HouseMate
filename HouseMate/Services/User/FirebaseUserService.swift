//
//  FirebaseUserService.swift
//  HouseMate
//
//  Created by Marcin Turek on 25/08/2026.
//



import Foundation
import FirebaseFirestore

@MainActor
final class FirebaseUserService: UserServiceProtocol {

    private let database: Firestore

    private var usersCollection: CollectionReference {
        database.collection("users")
    }

    init(
        database: Firestore = Firestore.firestore()
    ) {
        self.database = database
    }

    func fetchUser(
        userID: String
    ) async throws -> UserModel? {
        let snapshot = try await usersCollection
            .document(userID)
            .getDocument()

        guard snapshot.exists,
              let data = snapshot.data()
        else {
            return nil
        }

        return try Firestore.Decoder().decode(
            UserModel.self,
            from: data
        )
    }

    func createUser(
        from authInfo: UserAuthInfo
    ) async throws -> UserModel {
        if let existingUser = try await fetchUser(
            userID: authInfo.uid
        ) {
            return existingUser
        }

        let user = UserModel(
            userId: authInfo.uid,
            createdAt: authInfo.creationDate ?? .now,
            creationVersion: appVersion,
            email: authInfo.email,
            lastSignInDate:
                authInfo.lastSignInDate ?? .now,
            name: authInfo.displayName,
            profileImageUrl:
                authInfo.profileImageURL?.absoluteString,
            householdId: nil
        )

        try await saveUser(user)

        return user
    }

    func saveUser(
        _ user: UserModel
    ) async throws {
        let data = try Firestore.Encoder().encode(user)

        try await usersCollection
            .document(user.userId)
            .setData(
                data,
                merge: true
            )
    }

    func updateHouseholdID(
        _ householdID: String?,
        for userID: String
    ) async throws {
        let value: Any

        if let householdID {
            value = householdID
        } else {
            value = FieldValue.delete()
        }

        try await usersCollection
            .document(userID)
            .updateData([
                "household_id": value
            ])
    }

    func deleteUserData(userID: String) async throws {
        let userReference = usersCollection.document(userID)
        let notificationsSnapshot = try await userReference
            .collection("notifications")
            .getDocuments()

        for startIndex in stride(
            from: 0,
            to: notificationsSnapshot.documents.count,
            by: 450
        ) {
            let endIndex = min(
                startIndex + 450,
                notificationsSnapshot.documents.count
            )
            let batch = database.batch()

            for document in notificationsSnapshot.documents[
                startIndex..<endIndex
            ] {
                batch.deleteDocument(document.reference)
            }

            try await batch.commit()
        }

        try await userReference.delete()
    }

    private var appVersion: String? {
        Bundle.main.object(
            forInfoDictionaryKey:
                "CFBundleShortVersionString"
        ) as? String
    }
}
