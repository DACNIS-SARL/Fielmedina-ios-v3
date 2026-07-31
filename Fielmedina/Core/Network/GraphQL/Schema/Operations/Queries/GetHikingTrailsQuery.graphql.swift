// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension FielmedinaAPI {
  struct GetHikingTrailsQuery: GraphQLQuery {
    static let operationName: String = "GetHikingTrails"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetHikingTrails($cityId: Int, $limit: Int, $offset: Int) { hikings(cityId: $cityId, limit: $limit, offset: $offset) { __typename id nameEn nameFr descriptionEn descriptionFr city { __typename id nameEn nameFr } latitude longitude images { __typename image { __typename ...ImageFields } imageMobile { __typename ...ImageFields } } locations { __typename order location { __typename id nameEn nameFr latitude longitude category { __typename id nameEn nameFr } storyEn storyFr voiceoverEn voiceoverFr images { __typename image { __typename ...ImageFields } imageMobile { __typename ...ImageFields } } } } } }"#,
        fragments: [ImageFields.self]
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
        .field("hikings", [Hiking].self, arguments: [
          "cityId": .variable("cityId"),
          "limit": .variable("limit"),
          "offset": .variable("offset")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetHikingTrailsQuery.Data.self
      ] }

      var hikings: [Hiking] { __data["hikings"] }

      /// Hiking
      ///
      /// Parent Type: `HikingType`
      struct Hiking: FielmedinaAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.HikingType }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", FielmedinaAPI.ID.self),
          .field("nameEn", String.self),
          .field("nameFr", String.self),
          .field("descriptionEn", String.self),
          .field("descriptionFr", String.self),
          .field("city", City?.self),
          .field("latitude", Double?.self),
          .field("longitude", Double?.self),
          .field("images", [Image].self),
          .field("locations", [Location].self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetHikingTrailsQuery.Data.Hiking.self
        ] }

        var id: FielmedinaAPI.ID { __data["id"] }
        var nameEn: String { __data["nameEn"] }
        var nameFr: String { __data["nameFr"] }
        var descriptionEn: String { __data["descriptionEn"] }
        var descriptionFr: String { __data["descriptionFr"] }
        var city: City? { __data["city"] }
        var latitude: Double? { __data["latitude"] }
        var longitude: Double? { __data["longitude"] }
        var images: [Image] { __data["images"] }
        var locations: [Location] { __data["locations"] }

        /// Hiking.City
        ///
        /// Parent Type: `CityType`
        struct City: FielmedinaAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.CityType }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", FielmedinaAPI.ID.self),
            .field("nameEn", String?.self),
            .field("nameFr", String?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetHikingTrailsQuery.Data.Hiking.City.self
          ] }

          var id: FielmedinaAPI.ID { __data["id"] }
          var nameEn: String? { __data["nameEn"] }
          var nameFr: String? { __data["nameFr"] }
        }

        /// Hiking.Image
        ///
        /// Parent Type: `ImageHikingType`
        struct Image: FielmedinaAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.ImageHikingType }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("image", Image.self),
            .field("imageMobile", ImageMobile?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetHikingTrailsQuery.Data.Hiking.Image.self
          ] }

          var image: Image { __data["image"] }
          var imageMobile: ImageMobile? { __data["imageMobile"] }

          /// Hiking.Image.Image
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
              GetHikingTrailsQuery.Data.Hiking.Image.Image.self,
              ImageFields.self
            ] }

            var url: String { __data["url"] }

            struct Fragments: FragmentContainer {
              let __data: DataDict
              init(_dataDict: DataDict) { __data = _dataDict }

              var imageFields: ImageFields { _toFragment() }
            }
          }

          /// Hiking.Image.ImageMobile
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
              GetHikingTrailsQuery.Data.Hiking.Image.ImageMobile.self,
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

        /// Hiking.Location
        ///
        /// Parent Type: `HikingLocationType`
        struct Location: FielmedinaAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.HikingLocationType }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("order", Int.self),
            .field("location", Location.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetHikingTrailsQuery.Data.Hiking.Location.self
          ] }

          var order: Int { __data["order"] }
          var location: Location { __data["location"] }

          /// Hiking.Location.Location
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
              .field("latitude", FielmedinaAPI.Decimal.self),
              .field("longitude", FielmedinaAPI.Decimal.self),
              .field("category", Category?.self),
              .field("storyEn", String.self),
              .field("storyFr", String.self),
              .field("voiceoverEn", String?.self),
              .field("voiceoverFr", String?.self),
              .field("images", [Image].self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              GetHikingTrailsQuery.Data.Hiking.Location.Location.self
            ] }

            var id: FielmedinaAPI.ID { __data["id"] }
            var nameEn: String { __data["nameEn"] }
            var nameFr: String { __data["nameFr"] }
            var latitude: FielmedinaAPI.Decimal { __data["latitude"] }
            var longitude: FielmedinaAPI.Decimal { __data["longitude"] }
            var category: Category? { __data["category"] }
            var storyEn: String { __data["storyEn"] }
            var storyFr: String { __data["storyFr"] }
            var voiceoverEn: String? { __data["voiceoverEn"] }
            var voiceoverFr: String? { __data["voiceoverFr"] }
            var images: [Image] { __data["images"] }

            /// Hiking.Location.Location.Category
            ///
            /// Parent Type: `LocationCategoryType`
            struct Category: FielmedinaAPI.SelectionSet {
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
                GetHikingTrailsQuery.Data.Hiking.Location.Location.Category.self
              ] }

              var id: FielmedinaAPI.ID { __data["id"] }
              var nameEn: String { __data["nameEn"] }
              var nameFr: String { __data["nameFr"] }
            }

            /// Hiking.Location.Location.Image
            ///
            /// Parent Type: `ImageLocationType`
            struct Image: FielmedinaAPI.SelectionSet {
              let __data: DataDict
              init(_dataDict: DataDict) { __data = _dataDict }

              static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.ImageLocationType }
              static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("image", Image.self),
                .field("imageMobile", ImageMobile?.self),
              ] }
              static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                GetHikingTrailsQuery.Data.Hiking.Location.Location.Image.self
              ] }

              var image: Image { __data["image"] }
              var imageMobile: ImageMobile? { __data["imageMobile"] }

              /// Hiking.Location.Location.Image.Image
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
                  GetHikingTrailsQuery.Data.Hiking.Location.Location.Image.Image.self,
                  ImageFields.self
                ] }

                var url: String { __data["url"] }

                struct Fragments: FragmentContainer {
                  let __data: DataDict
                  init(_dataDict: DataDict) { __data = _dataDict }

                  var imageFields: ImageFields { _toFragment() }
                }
              }

              /// Hiking.Location.Location.Image.ImageMobile
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
                  GetHikingTrailsQuery.Data.Hiking.Location.Location.Image.ImageMobile.self,
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
          }
        }
      }
    }
  }

}