// @generated
// This file was automatically generated and should not be edited.

@preconcurrency @_exported import ApolloAPI
@preconcurrency @_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension FielmedinaAPI {
  struct GetAdsQuery: GraphQLQuery {
    static let operationName: String = "GetAds"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetAds($countryId: Int, $cityId: Int, $limit: Int) { ads(countryId: $countryId, cityId: $cityId, isActive: true, limit: $limit) { __typename id name link country { __typename id name } city { __typename id nameEn } imageMobile { __typename ...ImageFields } imageTablet { __typename ...ImageFields } } }"#,
        fragments: [ImageFields.self]
      ))

    public var countryId: GraphQLNullable<Int32>
    public var cityId: GraphQLNullable<Int32>
    public var limit: GraphQLNullable<Int32>

    public init(
      countryId: GraphQLNullable<Int32>,
      cityId: GraphQLNullable<Int32>,
      limit: GraphQLNullable<Int32>
    ) {
      self.countryId = countryId
      self.cityId = cityId
      self.limit = limit
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "countryId": countryId,
      "cityId": cityId,
      "limit": limit
    ] }

    struct Data: FielmedinaAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("ads", [Ad].self, arguments: [
          "countryId": .variable("countryId"),
          "cityId": .variable("cityId"),
          "isActive": true,
          "limit": .variable("limit")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetAdsQuery.Data.self
      ] }

      var ads: [Ad] { __data["ads"] }

      /// Ad
      ///
      /// Parent Type: `AdType`
      struct Ad: FielmedinaAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.AdType }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", FielmedinaAPI.ID.self),
          .field("name", String?.self),
          .field("link", String.self),
          .field("country", Country?.self),
          .field("city", City?.self),
          .field("imageMobile", ImageMobile?.self),
          .field("imageTablet", ImageTablet?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetAdsQuery.Data.Ad.self
        ] }

        var id: FielmedinaAPI.ID { __data["id"] }
        var name: String? { __data["name"] }
        var link: String { __data["link"] }
        var country: Country? { __data["country"] }
        var city: City? { __data["city"] }
        var imageMobile: ImageMobile? { __data["imageMobile"] }
        var imageTablet: ImageTablet? { __data["imageTablet"] }

        /// Ad.Country
        ///
        /// Parent Type: `CountryType`
        struct Country: FielmedinaAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.CountryType }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", FielmedinaAPI.ID.self),
            .field("name", String.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetAdsQuery.Data.Ad.Country.self
          ] }

          var id: FielmedinaAPI.ID { __data["id"] }
          var name: String { __data["name"] }
        }

        /// Ad.City
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
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetAdsQuery.Data.Ad.City.self
          ] }

          var id: FielmedinaAPI.ID { __data["id"] }
          var nameEn: String? { __data["nameEn"] }
        }

        /// Ad.ImageMobile
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
            GetAdsQuery.Data.Ad.ImageMobile.self,
            ImageFields.self
          ] }

          var url: String { __data["url"] }

          struct Fragments: FragmentContainer {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            var imageFields: ImageFields { _toFragment() }
          }
        }

        /// Ad.ImageTablet
        ///
        /// Parent Type: `ImageFieldType`
        struct ImageTablet: FielmedinaAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.ImageFieldType }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .fragment(ImageFields.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetAdsQuery.Data.Ad.ImageTablet.self,
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