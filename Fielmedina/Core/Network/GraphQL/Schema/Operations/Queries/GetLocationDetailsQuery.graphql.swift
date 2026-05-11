// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension FielmedinaAPI {
  struct GetLocationDetailsQuery: GraphQLQuery {
    static let operationName: String = "GetLocationDetails"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetLocationDetails($id: ID!) { location(id: $id) { __typename ...LocationSummary storyEn storyFr admissionFee openFrom openTo closedDays { __typename day } } }"#,
        fragments: [ImageFields.self, LocationSummary.self]
      ))

    public var id: ID

    public init(id: ID) {
      self.id = id
    }

    @_spi(Unsafe) public var __variables: Variables? { ["id": id] }

    struct Data: FielmedinaAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("location", Location?.self, arguments: ["id": .variable("id")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetLocationDetailsQuery.Data.self
      ] }

      var location: Location? { __data["location"] }

      /// Location
      ///
      /// Parent Type: `LocationType`
      struct Location: FielmedinaAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.LocationType }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("storyEn", String.self),
          .field("storyFr", String.self),
          .field("admissionFee", FielmedinaAPI.Decimal?.self),
          .field("openFrom", FielmedinaAPI.Time?.self),
          .field("openTo", FielmedinaAPI.Time?.self),
          .field("closedDays", [ClosedDay].self),
          .fragment(LocationSummary.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetLocationDetailsQuery.Data.Location.self,
          LocationSummary.self
        ] }

        var storyEn: String { __data["storyEn"] }
        var storyFr: String { __data["storyFr"] }
        var admissionFee: FielmedinaAPI.Decimal? { __data["admissionFee"] }
        var openFrom: FielmedinaAPI.Time? { __data["openFrom"] }
        var openTo: FielmedinaAPI.Time? { __data["openTo"] }
        var closedDays: [ClosedDay] { __data["closedDays"] }
        var id: FielmedinaAPI.ID { __data["id"] }
        var nameEn: String { __data["nameEn"] }
        var nameFr: String { __data["nameFr"] }
        var latitude: FielmedinaAPI.Decimal { __data["latitude"] }
        var longitude: FielmedinaAPI.Decimal { __data["longitude"] }
        var category: Category? { __data["category"] }
        var images: [Image] { __data["images"] }
        var voiceoverEn: String? { __data["voiceoverEn"] }
        var voiceoverFr: String? { __data["voiceoverFr"] }

        struct Fragments: FragmentContainer {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          var locationSummary: LocationSummary { _toFragment() }
        }

        /// Location.ClosedDay
        ///
        /// Parent Type: `WeekdayType`
        struct ClosedDay: FielmedinaAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.WeekdayType }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("day", Int.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetLocationDetailsQuery.Data.Location.ClosedDay.self
          ] }

          var day: Int { __data["day"] }
        }

        typealias Category = LocationSummary.Category

        typealias Image = LocationSummary.Image
      }
    }
  }

}