// @generated
// This file was automatically generated and should not be edited.

@preconcurrency import ApolloAPI

protocol FielmedinaAPI_SelectionSet: ApolloAPI.SelectionSet & ApolloAPI.RootSelectionSet
where Schema == FielmedinaAPI.SchemaMetadata {}

protocol FielmedinaAPI_InlineFragment: ApolloAPI.SelectionSet & ApolloAPI.InlineFragment
where Schema == FielmedinaAPI.SchemaMetadata {}

protocol FielmedinaAPI_MutableSelectionSet: ApolloAPI.MutableRootSelectionSet
where Schema == FielmedinaAPI.SchemaMetadata {}

protocol FielmedinaAPI_MutableInlineFragment: ApolloAPI.MutableSelectionSet & ApolloAPI.InlineFragment
where Schema == FielmedinaAPI.SchemaMetadata {}

extension FielmedinaAPI {
  typealias SelectionSet = FielmedinaAPI_SelectionSet

  typealias InlineFragment = FielmedinaAPI_InlineFragment

  typealias MutableSelectionSet = FielmedinaAPI_MutableSelectionSet

  typealias MutableInlineFragment = FielmedinaAPI_MutableInlineFragment

  enum SchemaMetadata: ApolloAPI.SchemaMetadata {
    static let configuration: any ApolloAPI.SchemaConfiguration.Type = SchemaConfiguration.self

    static func objectType(forTypename typename: String) -> ApolloAPI.Object? {
      switch typename {
      case "AdType": return FielmedinaAPI.Objects.AdType
      case "CityType": return FielmedinaAPI.Objects.CityType
      case "CountryType": return FielmedinaAPI.Objects.CountryType
      case "EventCategoryType": return FielmedinaAPI.Objects.EventCategoryType
      case "EventType": return FielmedinaAPI.Objects.EventType
      case "HikingLocationType": return FielmedinaAPI.Objects.HikingLocationType
      case "HikingType": return FielmedinaAPI.Objects.HikingType
      case "ImageEventType": return FielmedinaAPI.Objects.ImageEventType
      case "ImageFieldType": return FielmedinaAPI.Objects.ImageFieldType
      case "ImageHikingType": return FielmedinaAPI.Objects.ImageHikingType
      case "ImageLocationType": return FielmedinaAPI.Objects.ImageLocationType
      case "LocationCategoryType": return FielmedinaAPI.Objects.LocationCategoryType
      case "LocationType": return FielmedinaAPI.Objects.LocationType
      case "Mutation": return FielmedinaAPI.Objects.Mutation
      case "PublicTransportNodeType": return FielmedinaAPI.Objects.PublicTransportNodeType
      case "PublicTransportTimeType": return FielmedinaAPI.Objects.PublicTransportTimeType
      case "PublicTransportTypeType": return FielmedinaAPI.Objects.PublicTransportTypeType
      case "Query": return FielmedinaAPI.Objects.Query
      case "RegisterDevicePayload": return FielmedinaAPI.Objects.RegisterDevicePayload
      case "SyncUserPreferencePayload": return FielmedinaAPI.Objects.SyncUserPreferencePayload
      case "TipType": return FielmedinaAPI.Objects.TipType
      case "WeekdayType": return FielmedinaAPI.Objects.WeekdayType
      default: return nil
      }
    }
  }

  enum Objects {}
  enum Interfaces {}
  enum Unions {}

}