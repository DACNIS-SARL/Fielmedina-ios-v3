// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension FielmedinaAPI {
  struct GetMerchantsByCityQuery: GraphQLQuery {
    static let operationName: String = "GetMerchantsByCity"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetMerchantsByCity($cityId: Int, $categoryId: Int, $limit: Int, $offset: Int) { merchants( cityId: $cityId categoryId: $categoryId limit: $limit offset: $offset ) { __typename id nameEn nameFr descriptionEn descriptionFr shortLink latitude longitude priceRange openFrom openTo isFeatured addressEn addressFr phone website category { __typename id nameEn nameFr icon } images { __typename image { __typename ...ImageFields } imageMobile { __typename ...ImageFields } } city { __typename ...CityFields } } }"#,
        fragments: [CityFields.self, ImageFields.self]
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
        .field("merchants", [Merchant].self, arguments: [
          "cityId": .variable("cityId"),
          "categoryId": .variable("categoryId"),
          "limit": .variable("limit"),
          "offset": .variable("offset")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetMerchantsByCityQuery.Data.self
      ] }

      var merchants: [Merchant] { __data["merchants"] }

      /// Merchant
      ///
      /// Parent Type: `MerchantType`
      struct Merchant: FielmedinaAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.MerchantType }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", FielmedinaAPI.ID.self),
          .field("nameEn", String.self),
          .field("nameFr", String.self),
          .field("descriptionEn", String.self),
          .field("descriptionFr", String.self),
          .field("shortLink", String?.self),
          .field("latitude", Double.self),
          .field("longitude", Double.self),
          .field("priceRange", String.self),
          .field("openFrom", String?.self),
          .field("openTo", String?.self),
          .field("isFeatured", Bool.self),
          .field("addressEn", String?.self),
          .field("addressFr", String?.self),
          .field("phone", String?.self),
          .field("website", String?.self),
          .field("category", Category?.self),
          .field("images", [Image].self),
          .field("city", City?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetMerchantsByCityQuery.Data.Merchant.self
        ] }

        var id: FielmedinaAPI.ID { __data["id"] }
        var nameEn: String { __data["nameEn"] }
        var nameFr: String { __data["nameFr"] }
        var descriptionEn: String { __data["descriptionEn"] }
        var descriptionFr: String { __data["descriptionFr"] }
        var shortLink: String? { __data["shortLink"] }
        var latitude: Double { __data["latitude"] }
        var longitude: Double { __data["longitude"] }
        var priceRange: String { __data["priceRange"] }
        var openFrom: String? { __data["openFrom"] }
        var openTo: String? { __data["openTo"] }
        var isFeatured: Bool { __data["isFeatured"] }
        var addressEn: String? { __data["addressEn"] }
        var addressFr: String? { __data["addressFr"] }
        var phone: String? { __data["phone"] }
        var website: String? { __data["website"] }
        var category: Category? { __data["category"] }
        var images: [Image] { __data["images"] }
        var city: City? { __data["city"] }

        /// Merchant.Category
        ///
        /// Parent Type: `MerchantCategoryType`
        struct Category: FielmedinaAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.MerchantCategoryType }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", FielmedinaAPI.ID.self),
            .field("nameEn", String.self),
            .field("nameFr", String.self),
            .field("icon", String?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetMerchantsByCityQuery.Data.Merchant.Category.self
          ] }

          var id: FielmedinaAPI.ID { __data["id"] }
          var nameEn: String { __data["nameEn"] }
          var nameFr: String { __data["nameFr"] }
          var icon: String? { __data["icon"] }
        }

        /// Merchant.Image
        ///
        /// Parent Type: `MerchantImageType`
        struct Image: FielmedinaAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.MerchantImageType }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("image", Image.self),
            .field("imageMobile", ImageMobile?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetMerchantsByCityQuery.Data.Merchant.Image.self
          ] }

          var image: Image { __data["image"] }
          var imageMobile: ImageMobile? { __data["imageMobile"] }

          /// Merchant.Image.Image
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
              GetMerchantsByCityQuery.Data.Merchant.Image.Image.self,
              ImageFields.self
            ] }

            var url: String { __data["url"] }

            struct Fragments: FragmentContainer {
              let __data: DataDict
              init(_dataDict: DataDict) { __data = _dataDict }

              var imageFields: ImageFields { _toFragment() }
            }
          }

          /// Merchant.Image.ImageMobile
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
              GetMerchantsByCityQuery.Data.Merchant.Image.ImageMobile.self,
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

        /// Merchant.City
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
            GetMerchantsByCityQuery.Data.Merchant.City.self,
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