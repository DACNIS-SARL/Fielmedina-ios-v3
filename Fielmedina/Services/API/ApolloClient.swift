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
    
    private(set) lazy var apollo: ApolloClient = {
        let url = URL(string: "https://mystory.fielmedina.com/graphql")!
        let store = ApolloStore()
        
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForRequest = 30.0
        let urlSession = URLSession(configuration: sessionConfiguration)
        return ApolloClient(url: url)
    }()
}
