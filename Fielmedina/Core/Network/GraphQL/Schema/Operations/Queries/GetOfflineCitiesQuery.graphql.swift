// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension FielmedinaAPI {
  nonisolated struct GetOfflineCitiesQuery: GraphQLQuery {
    static let operationName: String = "GetOfflineCities"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetOfflineCities($isActive: Boolean) { offlineCities(isActive: $isActive) { __typename id regionId name latitude longitude radius city { __typename id } } }"#
      ))

    public var isActive: GraphQLNullable<Bool>

    public init(isActive: GraphQLNullable<Bool>) {
      self.isActive = isActive
    }

    @_spi(Unsafe) public var __variables: Variables? { ["isActive": isActive] }

    nonisolated struct Data: FielmedinaAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("offlineCities", [OfflineCity].self, arguments: ["isActive": .variable("isActive")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetOfflineCitiesQuery.Data.self
      ] }

      var offlineCities: [OfflineCity] { __data["offlineCities"] }

      /// OfflineCity
      ///
      /// Parent Type: `OfflineCityType`
      nonisolated struct OfflineCity: FielmedinaAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.OfflineCityType }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", FielmedinaAPI.ID.self),
          .field("regionId", String.self),
          .field("name", String.self),
          .field("latitude", FielmedinaAPI.Decimal.self),
          .field("longitude", FielmedinaAPI.Decimal.self),
          .field("radius", Double.self),
          .field("city", City?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetOfflineCitiesQuery.Data.OfflineCity.self
        ] }

        var id: FielmedinaAPI.ID { __data["id"] }
        var regionId: String { __data["regionId"] }
        var name: String { __data["name"] }
        var latitude: FielmedinaAPI.Decimal { __data["latitude"] }
        var longitude: FielmedinaAPI.Decimal { __data["longitude"] }
        var radius: Double { __data["radius"] }
        var city: City? { __data["city"] }

        /// OfflineCity.City
        ///
        /// Parent Type: `CityType`
        nonisolated struct City: FielmedinaAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.CityType }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", FielmedinaAPI.ID.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetOfflineCitiesQuery.Data.OfflineCity.City.self
          ] }

          var id: FielmedinaAPI.ID { __data["id"] }
        }
      }
    }
  }

}