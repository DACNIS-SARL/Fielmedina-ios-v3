// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension FielmedinaAPI {
  nonisolated struct ForgetMeMutation: GraphQLMutation {
    static let operationName: String = "ForgetMe"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation ForgetMe($userUid: UUID!) { forgetMe(userUid: $userUid) { __typename ok } }"#
      ))

    public var userUid: UUID

    public init(userUid: UUID) {
      self.userUid = userUid
    }

    @_spi(Unsafe) public var __variables: Variables? { ["userUid": userUid] }

    nonisolated struct Data: FielmedinaAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("forgetMe", ForgetMe.self, arguments: ["userUid": .variable("userUid")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ForgetMeMutation.Data.self
      ] }

      var forgetMe: ForgetMe { __data["forgetMe"] }

      /// ForgetMe
      ///
      /// Parent Type: `SyncUserPreferencePayload`
      nonisolated struct ForgetMe: FielmedinaAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.SyncUserPreferencePayload }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("ok", Bool.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          ForgetMeMutation.Data.ForgetMe.self
        ] }

        var ok: Bool { __data["ok"] }
      }
    }
  }

}