// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension FielmedinaAPI {
  nonisolated struct CityFields: FielmedinaAPI.SelectionSet, Fragment {
    static var fragmentDefinition: StaticString {
      #"fragment CityFields on CityType { __typename id nameEn nameFr nameAr regionEn regionFr regionAr countryEn countryFr countryAr }"#
    }

    let __data: DataDict
    init(_dataDict: DataDict) { __data = _dataDict }

    static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.CityType }
    static var __selections: [ApolloAPI.Selection] { [
      .field("__typename", String.self),
      .field("id", FielmedinaAPI.ID.self),
      .field("nameEn", String?.self),
      .field("nameFr", String?.self),
      .field("nameAr", String?.self),
      .field("regionEn", String?.self),
      .field("regionFr", String?.self),
      .field("regionAr", String?.self),
      .field("countryEn", String?.self),
      .field("countryFr", String?.self),
      .field("countryAr", String?.self),
    ] }
    static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
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
  }

}