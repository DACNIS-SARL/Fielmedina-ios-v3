// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension FielmedinaAPI {
  nonisolated struct GetMerchantDetailsQuery: GraphQLQuery {
    static let operationName: String = "GetMerchantDetails"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetMerchantDetails($id: ID!) { merchant(id: $id) { __typename id nameEn nameFr descriptionEn descriptionFr shortLink latitude longitude priceRange openFrom openTo isFeatured addressEn addressFr phone website category { __typename id nameEn nameFr icon } images { __typename image { __typename ...ImageFields } imageMobile { __typename ...ImageFields } } products { __typename id nameEn nameFr price image } ratings { __typename id stars reviewerName comment createdAt } city { __typename ...CityFields } } }"#,
        fragments: [CityFields.self, ImageFields.self]
      ))

    public var id: ID

    public init(id: ID) {
      self.id = id
    }

    @_spi(Unsafe) public var __variables: Variables? { ["id": id] }

    nonisolated struct Data: FielmedinaAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("merchant", Merchant?.self, arguments: ["id": .variable("id")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetMerchantDetailsQuery.Data.self
      ] }

      var merchant: Merchant? { __data["merchant"] }

      /// Merchant
      ///
      /// Parent Type: `MerchantType`
      nonisolated struct Merchant: FielmedinaAPI.SelectionSet {
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
          .field("products", [Product].self),
          .field("ratings", [Rating].self),
          .field("city", City?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetMerchantDetailsQuery.Data.Merchant.self
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
        var products: [Product] { __data["products"] }
        var ratings: [Rating] { __data["ratings"] }
        var city: City? { __data["city"] }

        /// Merchant.Category
        ///
        /// Parent Type: `MerchantCategoryType`
        nonisolated struct Category: FielmedinaAPI.SelectionSet {
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
            GetMerchantDetailsQuery.Data.Merchant.Category.self
          ] }

          var id: FielmedinaAPI.ID { __data["id"] }
          var nameEn: String { __data["nameEn"] }
          var nameFr: String { __data["nameFr"] }
          var icon: String? { __data["icon"] }
        }

        /// Merchant.Image
        ///
        /// Parent Type: `MerchantImageType`
        nonisolated struct Image: FielmedinaAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.MerchantImageType }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("image", Image.self),
            .field("imageMobile", ImageMobile?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetMerchantDetailsQuery.Data.Merchant.Image.self
          ] }

          var image: Image { __data["image"] }
          var imageMobile: ImageMobile? { __data["imageMobile"] }

          /// Merchant.Image.Image
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
              GetMerchantDetailsQuery.Data.Merchant.Image.Image.self,
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
          nonisolated struct ImageMobile: FielmedinaAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.ImageFieldType }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .fragment(ImageFields.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              GetMerchantDetailsQuery.Data.Merchant.Image.ImageMobile.self,
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

        /// Merchant.Product
        ///
        /// Parent Type: `MerchantProductType`
        nonisolated struct Product: FielmedinaAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.MerchantProductType }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", FielmedinaAPI.ID.self),
            .field("nameEn", String.self),
            .field("nameFr", String.self),
            .field("price", Double?.self),
            .field("image", String?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetMerchantDetailsQuery.Data.Merchant.Product.self
          ] }

          var id: FielmedinaAPI.ID { __data["id"] }
          var nameEn: String { __data["nameEn"] }
          var nameFr: String { __data["nameFr"] }
          var price: Double? { __data["price"] }
          var image: String? { __data["image"] }
        }

        /// Merchant.Rating
        ///
        /// Parent Type: `MerchantRatingType`
        nonisolated struct Rating: FielmedinaAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.MerchantRatingType }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", FielmedinaAPI.ID.self),
            .field("stars", Int.self),
            .field("reviewerName", String.self),
            .field("comment", String?.self),
            .field("createdAt", FielmedinaAPI.DateTime.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetMerchantDetailsQuery.Data.Merchant.Rating.self
          ] }

          var id: FielmedinaAPI.ID { __data["id"] }
          var stars: Int { __data["stars"] }
          var reviewerName: String { __data["reviewerName"] }
          var comment: String? { __data["comment"] }
          var createdAt: FielmedinaAPI.DateTime { __data["createdAt"] }
        }

        /// Merchant.City
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
            GetMerchantDetailsQuery.Data.Merchant.City.self,
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