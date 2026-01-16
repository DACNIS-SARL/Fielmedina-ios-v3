// @generated
// This file was automatically generated and should not be edited.

@preconcurrency @_exported import ApolloAPI
@preconcurrency @_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension FielmedinaAPI {
  struct LocationSummary: FielmedinaAPI.SelectionSet, Fragment {
    static var fragmentDefinition: StaticString {
      #"fragment LocationSummary on LocationType { __typename id nameEn nameFr latitude longitude category { __typename id nameEn nameFr } images { __typename image { __typename ...ImageFields } imageMobile { __typename ...ImageFields } } }"#
    }

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
      .field("images", [Image].self),
    ] }
    static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      LocationSummary.self
    ] }

    var id: FielmedinaAPI.ID { __data["id"] }
    var nameEn: String { __data["nameEn"] }
    var nameFr: String { __data["nameFr"] }
    var latitude: FielmedinaAPI.Decimal { __data["latitude"] }
    var longitude: FielmedinaAPI.Decimal { __data["longitude"] }
    var category: Category? { __data["category"] }
    var images: [Image] { __data["images"] }

    /// Category
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
        LocationSummary.Category.self
      ] }

      var id: FielmedinaAPI.ID { __data["id"] }
      var nameEn: String { __data["nameEn"] }
      var nameFr: String { __data["nameFr"] }
    }

    /// Image
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
        LocationSummary.Image.self
      ] }

      var image: Image { __data["image"] }
      var imageMobile: ImageMobile? { __data["imageMobile"] }

      /// Image.Image
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
          LocationSummary.Image.Image.self,
          ImageFields.self
        ] }

        var url: String { __data["url"] }

        struct Fragments: FragmentContainer {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          var imageFields: ImageFields { _toFragment() }
        }
      }

      /// Image.ImageMobile
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
          LocationSummary.Image.ImageMobile.self,
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