// @generated
// This file was automatically generated and should not be edited.

@preconcurrency @_exported import ApolloAPI
@preconcurrency @_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension FielmedinaAPI {
  struct ImageFields: FielmedinaAPI.SelectionSet, Fragment {
    static var fragmentDefinition: StaticString {
      #"fragment ImageFields on ImageFieldType { __typename url }"#
    }

    let __data: DataDict
    init(_dataDict: DataDict) { __data = _dataDict }

    static var __parentType: any ApolloAPI.ParentType { FielmedinaAPI.Objects.ImageFieldType }
    static var __selections: [ApolloAPI.Selection] { [
      .field("__typename", String.self),
      .field("url", String.self),
    ] }
    static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      ImageFields.self
    ] }

    var url: String { __data["url"] }
  }

}