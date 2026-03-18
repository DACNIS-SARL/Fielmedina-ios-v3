//
//  TipService.swift
//  Fielmedina
//
//  Created by Aslan on 1/21/26.
//

import Foundation
import Apollo

class TipService {
    static let shared = TipService()
    
    private let apollo = Network.shared.apollo
    
    func fetchTips(cityId: Int32? = nil, limit: Int32 = 10, forceRefresh: Bool = false) async throws -> [Tip] {
        let query = FielmedinaAPI.GetCityTipsQuery(
            cityId: cityId != nil ? .init(integerLiteral: cityId!) : .none,
            limit: .init(integerLiteral: limit),
            offset: .none
        )
        
        let data = forceRefresh
            ? try await apollo.fetchFresh(query: query)
            : try await apollo.fetchNetworkAware(query: query)
        
        return data.tips.map { gTip in
            Tip(
                id: gTip.id,
                descriptionEn: gTip.descriptionEn,
                descriptionFr: gTip.descriptionFr
            )
        }
    }
}
