// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension FielmedinaAPI {
  struct GetCityTipsQuery: GraphQLQuery {
    static let operationName: String = "GetCityTips"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetCityTips($cityId: Int, $limit: Int, $offset: Int) { tips(cityId: $cityId, limit: $limit, offset: $offset) { __typename id descriptionEn descriptionFr } locationCategories { __typename id nameEn nameFr } eventCategories { __typename id nameEn nameFr } }"#
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
        .field("tips", [Tip].self, arguments: [
          "cityId": .variable("cityId"),
          "limit": .variable("limit"),
          "offset": .variable("offset")
        ]),
        .field("locationCategories", [LocationCategory].self),
        .field("eventCategories", [EventCategory].self),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetCityTipsQuery.Data.self
      ] }

      var tips: [Tip] { __data["tips"] }
      var locationCategories: [LocationCategory] { __data["locationCategories"] }
      var eventCategories: [EventCategory] { __data["eventCategories"] }

      /// Tip
      ///
      /// Parent Type: `TipType`
      struct Tip: FielmedinaAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.TipType }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", FielmedinaAPI.ID.self),
          .field("descriptionEn", String.self),
          .field("descriptionFr", String.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetCityTipsQuery.Data.Tip.self
        ] }

        var id: FielmedinaAPI.ID { __data["id"] }
        var descriptionEn: String { __data["descriptionEn"] }
        var descriptionFr: String { __data["descriptionFr"] }
      }

      /// LocationCategory
      ///
      /// Parent Type: `LocationCategoryType`
      struct LocationCategory: FielmedinaAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.LocationCategoryType }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", FielmedinaAPI.ID.self),
          .field("nameEn", String.self),
          .field("nameFr", String.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetCityTipsQuery.Data.LocationCategory.self
        ] }

        var id: FielmedinaAPI.ID { __data["id"] }
        var nameEn: String { __data["nameEn"] }
        var nameFr: String { __data["nameFr"] }
      }

      /// EventCategory
      ///
      /// Parent Type: `EventCategoryType`
      struct EventCategory: FielmedinaAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.EventCategoryType }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", FielmedinaAPI.ID.self),
          .field("nameEn", String.self),
          .field("nameFr", String.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetCityTipsQuery.Data.EventCategory.self
        ] }

        var id: FielmedinaAPI.ID { __data["id"] }
        var nameEn: String { __data["nameEn"] }
        var nameFr: String { __data["nameFr"] }
      }
    }
  }

}