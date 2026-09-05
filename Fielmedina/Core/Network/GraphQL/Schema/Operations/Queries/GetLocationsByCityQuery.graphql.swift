// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension FielmedinaAPI {
  struct GetLocationsByCityQuery: GraphQLQuery {
    static let operationName: String = "GetLocationsByCity"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetLocationsByCity($cityId: Int, $categoryId: Int, $limit: Int, $offset: Int) { locations( cityId: $cityId categoryId: $categoryId limit: $limit offset: $offset ) { __typename ...LocationSummary openFrom openTo admissionFee storyEn storyFr } }"#,
        fragments: [CityFields.self, ImageFields.self, LocationSummary.self]
      ))

    public var cityId: GraphQLNullable<Int32>
    public var categoryId: GraphQLNullable<Int32>
    public var limit: GraphQLNullable<Int32>
    public var offset: GraphQLNullable<Int32>

    public init(
      cityId: GraphQLNullable<Int32>,
      categoryId: GraphQLNullable<Int32>,
      limit: GraphQLNullable<Int32>,
      offset: GraphQLNullable<Int32>
    ) {
      self.cityId = cityId
      self.categoryId = categoryId
      self.limit = limit
      self.offset = offset
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "cityId": cityId,
      "categoryId": categoryId,
      "limit": limit,
      "offset": offset
    ] }

    struct Data: FielmedinaAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("locations", [Location].self, arguments: [
          "cityId": .variable("cityId"),
          "categoryId": .variable("categoryId"),
          "limit": .variable("limit"),
          "offset": .variable("offset")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetLocationsByCityQuery.Data.self
      ] }

      var locations: [Location] { __data["locations"] }

      /// Location
      ///
      /// Parent Type: `LocationType`
      struct Location: FielmedinaAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.LocationType }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("openFrom", FielmedinaAPI.Time?.self),
          .field("openTo", FielmedinaAPI.Time?.self),
          .field("admissionFee", FielmedinaAPI.Decimal?.self),
          .field("storyEn", String.self),
          .field("storyFr", String.self),
          .fragment(LocationSummary.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetLocationsByCityQuery.Data.Location.self,
          LocationSummary.self
        ] }

        var openFrom: FielmedinaAPI.Time? { __data["openFrom"] }
        var openTo: FielmedinaAPI.Time? { __data["openTo"] }
        var admissionFee: FielmedinaAPI.Decimal? { __data["admissionFee"] }
        var storyEn: String { __data["storyEn"] }
        var storyFr: String { __data["storyFr"] }
        var id: FielmedinaAPI.ID { __data["id"] }
        var nameEn: String { __data["nameEn"] }
        var nameFr: String { __data["nameFr"] }
        var latitude: FielmedinaAPI.Decimal { __data["latitude"] }
        var longitude: FielmedinaAPI.Decimal { __data["longitude"] }
        var category: Category? { __data["category"] }
        var city: City? { __data["city"] }
        var images: [Image] { __data["images"] }
        var voiceoverEn: String? { __data["voiceoverEn"] }
        var voiceoverFr: String? { __data["voiceoverFr"] }
        var model3d: String? { __data["model3d"] }
        var modelScale: Double { __data["modelScale"] }
        var modelRotation: Double { __data["modelRotation"] }
        var modelAltitude: Double { __data["modelAltitude"] }

        struct Fragments: FragmentContainer {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          var locationSummary: LocationSummary { _toFragment() }
        }

        typealias Category = LocationSummary.Category

        typealias City = LocationSummary.City

        typealias Image = LocationSummary.Image
      }
    }
  }

}