// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

nonisolated protocol FielmedinaAPI_SelectionSet: ApolloAPI.SelectionSet & ApolloAPI.RootSelectionSet
where Schema == FielmedinaAPI.SchemaMetadata {}

nonisolated protocol FielmedinaAPI_InlineFragment: ApolloAPI.SelectionSet & ApolloAPI.InlineFragment
where Schema == FielmedinaAPI.SchemaMetadata {}

nonisolated protocol FielmedinaAPI_MutableSelectionSet: ApolloAPI.MutableRootSelectionSet
where Schema == FielmedinaAPI.SchemaMetadata {}

nonisolated protocol FielmedinaAPI_MutableInlineFragment: ApolloAPI.MutableSelectionSet & ApolloAPI.InlineFragment
where Schema == FielmedinaAPI.SchemaMetadata {}

extension FielmedinaAPI {
  typealias SelectionSet = FielmedinaAPI_SelectionSet

  typealias InlineFragment = FielmedinaAPI_InlineFragment

  typealias MutableSelectionSet = FielmedinaAPI_MutableSelectionSet

  typealias MutableInlineFragment = FielmedinaAPI_MutableInlineFragment

  nonisolated enum SchemaMetadata: ApolloAPI.SchemaMetadata {
    static let configuration: any ApolloAPI.SchemaConfiguration.Type = SchemaConfiguration.self

    private static let objectTypeMap: [String: ApolloAPI.Object] = [
      "AdType": FielmedinaAPI.Objects.AdType,
      "CityType": FielmedinaAPI.Objects.CityType,
      "CountryType": FielmedinaAPI.Objects.CountryType,
      "EventCategoryType": FielmedinaAPI.Objects.EventCategoryType,
      "EventType": FielmedinaAPI.Objects.EventType,
      "HikingLocationType": FielmedinaAPI.Objects.HikingLocationType,
      "HikingType": FielmedinaAPI.Objects.HikingType,
      "ImageEventType": FielmedinaAPI.Objects.ImageEventType,
      "ImageFieldType": FielmedinaAPI.Objects.ImageFieldType,
      "ImageHikingType": FielmedinaAPI.Objects.ImageHikingType,
      "ImageLocationType": FielmedinaAPI.Objects.ImageLocationType,
      "LocationCategoryType": FielmedinaAPI.Objects.LocationCategoryType,
      "LocationType": FielmedinaAPI.Objects.LocationType,
      "MerchantCategoryType": FielmedinaAPI.Objects.MerchantCategoryType,
      "MerchantImageType": FielmedinaAPI.Objects.MerchantImageType,
      "MerchantProductType": FielmedinaAPI.Objects.MerchantProductType,
      "MerchantRatingType": FielmedinaAPI.Objects.MerchantRatingType,
      "MerchantType": FielmedinaAPI.Objects.MerchantType,
      "Mutation": FielmedinaAPI.Objects.Mutation,
      "OfflineCityType": FielmedinaAPI.Objects.OfflineCityType,
      "PublicTransportNodeType": FielmedinaAPI.Objects.PublicTransportNodeType,
      "PublicTransportTimeType": FielmedinaAPI.Objects.PublicTransportTimeType,
      "PublicTransportTypeType": FielmedinaAPI.Objects.PublicTransportTypeType,
      "Query": FielmedinaAPI.Objects.Query,
      "RegisterDevicePayload": FielmedinaAPI.Objects.RegisterDevicePayload,
      "SyncUserPreferencePayload": FielmedinaAPI.Objects.SyncUserPreferencePayload,
      "TipType": FielmedinaAPI.Objects.TipType,
      "WeekdayType": FielmedinaAPI.Objects.WeekdayType
    ]

    static func objectType(forTypename typename: String) -> ApolloAPI.Object? {
      objectTypeMap[typename]
    }
  }

  nonisolated enum Objects {}
  nonisolated enum Interfaces {}
  nonisolated enum Unions {}

}