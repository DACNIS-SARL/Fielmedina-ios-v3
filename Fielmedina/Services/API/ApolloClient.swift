//
//  ApolloClient.swift
//  Fielmedina
//
//  Created by Aslan on 1/16/26.
//

import Foundation
import Apollo
import ApolloAPI

class Network {
    static let shared = Network()
    
    enum Environment {
        case production
        case development
        
        var baseURL: URL {
            switch self {
            case .production:
                return URL(string: "https://mystory.fielmedina.com/graphql")!
            case .development:
                return URL(string: "https://mystory.fielmedina.com/graphql")!
            }
        }
    }
    
    static let currentEnvironment: Environment = .production
    
    private(set) lazy var apollo: ApolloClient = {
        let store = CacheConfigurator.makeApolloStore()
        let urlSession = CacheConfigurator.makeApolloURLSession()
        let transport = RequestChainNetworkTransport(
            urlSession: urlSession,
            interceptorProvider: DefaultInterceptorProvider.shared,
            store: store,
            endpointURL: Network.currentEnvironment.baseURL
        )

        return ApolloClient(networkTransport: transport, store: store)
    }()
}
