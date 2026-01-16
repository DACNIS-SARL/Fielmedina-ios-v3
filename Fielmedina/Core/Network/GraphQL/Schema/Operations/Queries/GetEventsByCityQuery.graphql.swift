// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension FielmedinaAPI {
  struct GetEventsByCityQuery: GraphQLQuery {
    static let operationName: String = "GetEventsByCity"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetEventsByCity($cityId: Int, $categoryId: Int, $limit: Int, $offset: Int) { events(cityId: $cityId, categoryId: $categoryId, limit: $limit, offset: $offset) { __typename id nameEn nameFr startDate endDate time price category { __typename id nameEn nameFr } images { __typename image { __typename ...ImageFields } imageMobile { __typename ...ImageFields } } location { __typename id nameEn nameFr } } }"#,
        fragments: [ImageFields.self]
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
        .field("events", [Event].self, arguments: [
          "cityId": .variable("cityId"),
          "categoryId": .variable("categoryId"),
          "limit": .variable("limit"),
          "offset": .variable("offset")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetEventsByCityQuery.Data.self
      ] }

      var events: [Event] { __data["events"] }

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
          .field("startDate", FielmedinaAPI.Date.self),
          .field("endDate", FielmedinaAPI.Date.self),
          .field("time", FielmedinaAPI.Time.self),
          .field("price", FielmedinaAPI.Decimal.self),
          .field("category", Category?.self),
          .field("images", [Image].self),
          .field("location", Location?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetEventsByCityQuery.Data.Event.self
        ] }

        var id: FielmedinaAPI.ID { __data["id"] }
        var nameEn: String { __data["nameEn"] }
        var nameFr: String { __data["nameFr"] }
        var startDate: FielmedinaAPI.Date { __data["startDate"] }
        var endDate: FielmedinaAPI.Date { __data["endDate"] }
        var time: FielmedinaAPI.Time { __data["time"] }
        var price: FielmedinaAPI.Decimal { __data["price"] }
        var category: Category? { __data["category"] }
        var images: [Image] { __data["images"] }
        var location: Location? { __data["location"] }

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
            GetEventsByCityQuery.Data.Event.Category.self
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
            GetEventsByCityQuery.Data.Event.Image.self
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
              GetEventsByCityQuery.Data.Event.Image.Image.self,
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
              GetEventsByCityQuery.Data.Event.Image.ImageMobile.self,
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
            GetEventsByCityQuery.Data.Event.Location.self
          ] }

          var id: FielmedinaAPI.ID { __data["id"] }
          var nameEn: String { __data["nameEn"] }
          var nameFr: String { __data["nameFr"] }
        }
      }
    }
  }

}