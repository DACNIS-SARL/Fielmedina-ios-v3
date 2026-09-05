// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension FielmedinaAPI {
  nonisolated struct LocationSummary: FielmedinaAPI.SelectionSet, Fragment {
    static var fragmentDefinition: StaticString {
      #"fragment LocationSummary on LocationType { __typename id nameEn nameFr latitude longitude category { __typename id nameEn nameFr } city { __typename ...CityFields } images { __typename image { __typename ...ImageFields } imageMobile { __typename ...ImageFields } } voiceoverEn voiceoverFr model3d modelScale modelRotation modelAltitude }"#
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
      .field("city", City?.self),
      .field("images", [Image].self),
      .field("voiceoverEn", String?.self),
      .field("voiceoverFr", String?.self),
      .field("model3d", String?.self),
      .field("modelScale", Double.self),
      .field("modelRotation", Double.self),
      .field("modelAltitude", Double.self),
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
    var city: City? { __data["city"] }
    var images: [Image] { __data["images"] }
    var voiceoverEn: String? { __data["voiceoverEn"] }
    var voiceoverFr: String? { __data["voiceoverFr"] }
    var model3d: String? { __data["model3d"] }
    var modelScale: Double { __data["modelScale"] }
    var modelRotation: Double { __data["modelRotation"] }
    var modelAltitude: Double { __data["modelAltitude"] }

    /// Category
    ///
    /// Parent Type: `LocationCategoryType`
    nonisolated struct Category: FielmedinaAPI.SelectionSet {
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

    /// City
    ///
    /// Parent Type: `CityType`
    nonisolated struct City: FielmedinaAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.CityType }
      static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .fragment(CityFields.self),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        LocationSummary.City.self,
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

    /// Image
    ///
    /// Parent Type: `ImageLocationType`
    nonisolated struct Image: FielmedinaAPI.SelectionSet {
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
      nonisolated struct Image: FielmedinaAPI.SelectionSet {
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
      nonisolated struct ImageMobile: FielmedinaAPI.SelectionSet {
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