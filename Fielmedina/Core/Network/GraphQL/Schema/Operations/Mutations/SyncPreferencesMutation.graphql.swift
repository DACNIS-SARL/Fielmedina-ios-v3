// @generated
// This file was automatically generated and should not be edited.

@preconcurrency @_exported import ApolloAPI
@preconcurrency @_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension FielmedinaAPI {
  struct SyncPreferencesMutation: GraphQLMutation {
    static let operationName: String = "SyncPreferences"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation SyncPreferences($userUid: UUID!, $firstVisit: Boolean!, $travelingWith: String!, $interests: [String!]!, $updatedAt: DateTime!) { syncUserPreference( userUid: $userUid firstVisit: $firstVisit travelingWith: $travelingWith interests: $interests updatedAt: $updatedAt ) { __typename ok } }"#
      ))

    public var userUid: UUID
    public var firstVisit: Bool
    public var travelingWith: String
    public var interests: [String]
    public var updatedAt: DateTime

    public init(
      userUid: UUID,
      firstVisit: Bool,
      travelingWith: String,
      interests: [String],
      updatedAt: DateTime
    ) {
      self.userUid = userUid
      self.firstVisit = firstVisit
      self.travelingWith = travelingWith
      self.interests = interests
      self.updatedAt = updatedAt
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "userUid": userUid,
      "firstVisit": firstVisit,
      "travelingWith": travelingWith,
      "interests": interests,
      "updatedAt": updatedAt
    ] }

    struct Data: FielmedinaAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("syncUserPreference", SyncUserPreference.self, arguments: [
          "userUid": .variable("userUid"),
          "firstVisit": .variable("firstVisit"),
          "travelingWith": .variable("travelingWith"),
          "interests": .variable("interests"),
          "updatedAt": .variable("updatedAt")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SyncPreferencesMutation.Data.self
      ] }

      var syncUserPreference: SyncUserPreference { __data["syncUserPreference"] }

      /// SyncUserPreference
      ///
      /// Parent Type: `SyncUserPreferencePayload`
      struct SyncUserPreference: FielmedinaAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.SyncUserPreferencePayload }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("ok", Bool.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          SyncPreferencesMutation.Data.SyncUserPreference.self
        ] }

        var ok: Bool { __data["ok"] }
      }
    }
  }

}