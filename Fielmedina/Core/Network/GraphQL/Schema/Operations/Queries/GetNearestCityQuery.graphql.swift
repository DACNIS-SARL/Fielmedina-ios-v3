// @generated
// This file was automatically generated and should not be edited.

@preconcurrency @_exported import ApolloAPI
@preconcurrency @_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension FielmedinaAPI {
  struct GetNearestCityQuery: GraphQLQuery {
    static let operationName: String = "GetNearestCity"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetNearestCity($lat: Float!, $lon: Float!) { nearestCity(lat: $lat, lon: $lon) { __typename ...CityFields } }"#,
        fragments: [CityFields.self]
      ))

    public var lat: Double
    public var lon: Double

    public init(
      lat: Double,
      lon: Double
    ) {
      self.lat = lat
      self.lon = lon
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "lat": lat,
      "lon": lon
    ] }

    struct Data: FielmedinaAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("nearestCity", NearestCity?.self, arguments: [
          "lat": .variable("lat"),
          "lon": .variable("lon")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetNearestCityQuery.Data.self
      ] }

      var nearestCity: NearestCity? { __data["nearestCity"] }

      /// NearestCity
      ///
      /// Parent Type: `CityType`
      struct NearestCity: FielmedinaAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.CityType }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .fragment(CityFields.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetNearestCityQuery.Data.NearestCity.self,
          CityFields.self
        ] }

        var id: FielmedinaAPI.ID { __data["id"] }
        var nameEn: String? { __data["nameEn"] }
        var nameFr: String? { __data["nameFr"] }
        var nameAr: String? { __data["nameAr"] }
        var regionEn: String? { __data["regionEn"] }
        var regionFr: String? { __data["regionFr"] }
        var regionAr: String? { __data["regionAr"] }
        var countryEn: String? { __data["countryEn"] }
        var countryFr: String? { __data["countryFr"] }
        var countryAr: String? { __data["countryAr"] }

        struct Fragments: FragmentContainer {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          var cityFields: CityFields { _toFragment() }
        }
      }
    }
  }

}