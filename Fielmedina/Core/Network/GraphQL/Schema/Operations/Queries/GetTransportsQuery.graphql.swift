// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension FielmedinaAPI {
  struct GetTransportsQuery: GraphQLQuery {
    static let operationName: String = "GetTransports"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetTransports($cityId: Int, $limit: Int, $offset: Int) { publicTransports(cityId: $cityId, limit: $limit, offset: $offset) { __typename id busNumber publicTransportType { __typename nameEn nameFr } fromRegionEn fromRegionFr toRegionEn toRegionFr times { __typename time } } }"#
      ))

    public var cityId: GraphQLNullable<Int32>
    public var limit: GraphQLNullable<Int32>
    public var offset: GraphQLNullable<Int32>

    public init(
      cityId: GraphQLNullable<Int32>,
      limit: GraphQLNullable<Int32>,
      offset: GraphQLNullable<Int32>
    ) {
      self.cityId = cityId
      self.limit = limit
      self.offset = offset
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "cityId": cityId,
      "limit": limit,
      "offset": offset
    ] }

    struct Data: FielmedinaAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("publicTransports", [PublicTransport].self, arguments: [
          "cityId": .variable("cityId"),
          "limit": .variable("limit"),
          "offset": .variable("offset")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetTransportsQuery.Data.self
      ] }

      var publicTransports: [PublicTransport] { __data["publicTransports"] }

      /// PublicTransport
      ///
      /// Parent Type: `PublicTransportNodeType`
      struct PublicTransport: FielmedinaAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.PublicTransportNodeType }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", FielmedinaAPI.ID.self),
          .field("busNumber", String.self),
          .field("publicTransportType", PublicTransportType?.self),
          .field("fromRegionEn", String?.self),
          .field("fromRegionFr", String?.self),
          .field("toRegionEn", String?.self),
          .field("toRegionFr", String?.self),
          .field("times", [Time].self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetTransportsQuery.Data.PublicTransport.self
        ] }

        var id: FielmedinaAPI.ID { __data["id"] }
        var busNumber: String { __data["busNumber"] }
        var publicTransportType: PublicTransportType? { __data["publicTransportType"] }
        var fromRegionEn: String? { __data["fromRegionEn"] }
        var fromRegionFr: String? { __data["fromRegionFr"] }
        var toRegionEn: String? { __data["toRegionEn"] }
        var toRegionFr: String? { __data["toRegionFr"] }
        var times: [Time] { __data["times"] }

        /// PublicTransport.PublicTransportType
        ///
        /// Parent Type: `PublicTransportTypeType`
        struct PublicTransportType: FielmedinaAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.PublicTransportTypeType }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("nameEn", String.self),
            .field("nameFr", String.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetTransportsQuery.Data.PublicTransport.PublicTransportType.self
          ] }

          var nameEn: String { __data["nameEn"] }
          var nameFr: String { __data["nameFr"] }
        }

        /// PublicTransport.Time
        ///
        /// Parent Type: `PublicTransportTimeType`
        struct Time: FielmedinaAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.PublicTransportTimeType }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("time", FielmedinaAPI.Time.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetTransportsQuery.Data.PublicTransport.Time.self
          ] }

          var time: FielmedinaAPI.Time { __data["time"] }
        }
      }
    }
  }

}