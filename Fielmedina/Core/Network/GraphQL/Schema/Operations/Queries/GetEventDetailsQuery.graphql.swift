// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension FielmedinaAPI {
  struct GetEventDetailsQuery: GraphQLQuery {
    static let operationName: String = "GetEventDetails"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetEventDetails($id: ID!) { event(id: $id) { __typename id nameEn nameFr descriptionEn descriptionFr shortLink startDate endDate time price category { __typename id nameEn nameFr } images { __typename image { __typename ...ImageFields } imageMobile { __typename ...ImageFields } } boost location { __typename id nameEn nameFr } city { __typename ...CityFields } } }"#,
        fragments: [CityFields.self, ImageFields.self]
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
        .field("event", Event?.self, arguments: ["id": .variable("id")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetEventDetailsQuery.Data.self
      ] }

      var event: Event? { __data["event"] }

      /// Event
      ///
      /// Parent Type: `EventType`
      struct Event: FielmedinaAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.EventType }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", FielmedinaAPI.ID.self),
          .field("nameEn", String.self),
          .field("nameFr", String.self),
          .field("descriptionEn", String.self),
          .field("descriptionFr", String.self),
          .field("shortLink", String?.self),
          .field("startDate", FielmedinaAPI.Date.self),
          .field("endDate", FielmedinaAPI.Date.self),
          .field("time", FielmedinaAPI.Time.self),
          .field("price", FielmedinaAPI.Decimal.self),
          .field("category", Category?.self),
          .field("images", [Image].self),
          .field("boost", Bool.self),
          .field("location", Location?.self),
          .field("city", City?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetEventDetailsQuery.Data.Event.self
        ] }

        var id: FielmedinaAPI.ID { __data["id"] }
        var nameEn: String { __data["nameEn"] }
        var nameFr: String { __data["nameFr"] }
        var descriptionEn: String { __data["descriptionEn"] }
        var descriptionFr: String { __data["descriptionFr"] }
        var shortLink: String? { __data["shortLink"] }
        var startDate: FielmedinaAPI.Date { __data["startDate"] }
        var endDate: FielmedinaAPI.Date { __data["endDate"] }
        var time: FielmedinaAPI.Time { __data["time"] }
        var price: FielmedinaAPI.Decimal { __data["price"] }
        var category: Category? { __data["category"] }
        var images: [Image] { __data["images"] }
        var boost: Bool { __data["boost"] }
        var location: Location? { __data["location"] }
        var city: City? { __data["city"] }

        /// Event.Category
        ///
        /// Parent Type: `EventCategoryType`
        struct Category: FielmedinaAPI.SelectionSet {
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
            GetEventDetailsQuery.Data.Event.Category.self
          ] }

          var id: FielmedinaAPI.ID { __data["id"] }
          var nameEn: String { __data["nameEn"] }
          var nameFr: String { __data["nameFr"] }
        }

        /// Event.Image
        ///
        /// Parent Type: `ImageEventType`
        struct Image: FielmedinaAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.ImageEventType }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("image", Image.self),
            .field("imageMobile", ImageMobile?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetEventDetailsQuery.Data.Event.Image.self
          ] }

          var image: Image { __data["image"] }
          var imageMobile: ImageMobile? { __data["imageMobile"] }

          /// Event.Image.Image
          ///
          /// Parent Type: `ImageFieldType`
          struct Image: FielmedinaAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.ImageFieldType }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .fragment(ImageFields.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              GetEventDetailsQuery.Data.Event.Image.Image.self,
              ImageFields.self
            ] }

            var url: String { __data["url"] }

            struct Fragments: FragmentContainer {
              let __data: DataDict
              init(_dataDict: DataDict) { __data = _dataDict }

              var imageFields: ImageFields { _toFragment() }
            }
          }

          /// Event.Image.ImageMobile
          ///
          /// Parent Type: `ImageFieldType`
          struct ImageMobile: FielmedinaAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.ImageFieldType }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .fragment(ImageFields.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              GetEventDetailsQuery.Data.Event.Image.ImageMobile.self,
              ImageFields.self
            ] }

            var url: String { __data["url"] }

            struct Fragments: FragmentContainer {
              let __data: DataDict
              init(_dataDict: DataDict) { __data = _dataDict }

              var imageFields: ImageFields { _toFragment() }
            }
          }
        }

        /// Event.Location
        ///
        /// Parent Type: `LocationType`
        struct Location: FielmedinaAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.LocationType }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", FielmedinaAPI.ID.self),
            .field("nameEn", String.self),
            .field("nameFr", String.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetEventDetailsQuery.Data.Event.Location.self
          ] }

          var id: FielmedinaAPI.ID { __data["id"] }
          var nameEn: String { __data["nameEn"] }
          var nameFr: String { __data["nameFr"] }
        }

        /// Event.City
        ///
        /// Parent Type: `CityType`
        struct City: FielmedinaAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.CityType }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .fragment(CityFields.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetEventDetailsQuery.Data.Event.City.self,
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

}