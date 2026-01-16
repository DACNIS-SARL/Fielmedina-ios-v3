// @generated
// This file was automatically generated and should not be edited.

@preconcurrency @_exported import ApolloAPI
@preconcurrency @_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension FielmedinaAPI {
  struct RegisterFcmDeviceMutation: GraphQLMutation {
    static let operationName: String = "RegisterFcmDevice"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation RegisterFcmDevice($registrationId: String!, $type: String!, $userUid: UUID!, $name: String) { registerFcmDevice( registrationId: $registrationId type: $type userUid: $userUid name: $name ) { __typename message ok } }"#
      ))

    public var registrationId: String
    public var type: String
    public var userUid: UUID
    public var name: GraphQLNullable<String>

    public init(
      registrationId: String,
      type: String,
      userUid: UUID,
      name: GraphQLNullable<String>
    ) {
      self.registrationId = registrationId
      self.type = type
      self.userUid = userUid
      self.name = name
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "registrationId": registrationId,
      "type": type,
      "userUid": userUid,
      "name": name
    ] }

    struct Data: FielmedinaAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("registerFcmDevice", RegisterFcmDevice.self, arguments: [
          "registrationId": .variable("registrationId"),
          "type": .variable("type"),
          "userUid": .variable("userUid"),
          "name": .variable("name")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        RegisterFcmDeviceMutation.Data.self
      ] }

      var registerFcmDevice: RegisterFcmDevice { __data["registerFcmDevice"] }

      /// RegisterFcmDevice
      ///
      /// Parent Type: `RegisterDevicePayload`
      struct RegisterFcmDevice: FielmedinaAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.RegisterDevicePayload }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("message", String?.self),
          .field("ok", Bool.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          RegisterFcmDeviceMutation.Data.RegisterFcmDevice.self
        ] }

        var message: String? { __data["message"] }
        var ok: Bool { __data["ok"] }
      }
    }
  }

}