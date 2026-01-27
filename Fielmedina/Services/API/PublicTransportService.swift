//
//  PublicTransportService.swift
//  Fielmedina
//
//  Created by Aslan on 1/22/26.
//

import Foundation
import Apollo

class PublicTransportService {
    static let shared = PublicTransportService()

    private let apollo = Network.shared.apollo

    func fetchTransports(cityId: Int32? = nil, limit: Int32 = 50, offset: Int32? = nil) async throws -> [PublicTransport] {
        var allTransports: [PublicTransport] = []
        var currentOffset = offset ?? 0
        let batchSize = max(limit, 50)

        while true {
            let page = try await fetchTransportsPage(
                cityId: cityId,
                limit: batchSize,
                offset: currentOffset
            )
            allTransports.append(contentsOf: page)

            if page.count < batchSize {
                break
            }
            currentOffset += batchSize
        }

        return allTransports
    }

    private func fetchTransportsPage(
        cityId: Int32?,
        limit: Int32,
        offset: Int32
    ) async throws -> [PublicTransport] {
        let query = FielmedinaAPI.GetTransportsQuery(
            cityId: cityId != nil ? .some(cityId!) : .none,
            limit: .some(limit),
            offset: .some(offset)
        )

        let response = try await apollo.fetch(query: query)

        if let errors = response.errors {
            let message = errors.map { $0.message ?? "Unknown error" }.joined(separator: ", ")
            throw NSError(domain: "Apollo", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
        }

        guard let data = response.data else {
            return []
        }

        return data.publicTransports.map { transport in
            PublicTransport(
                id: transport.id,
                busNumber: transport.busNumber,
                publicTransportType: TransportType(
                    nameEn: transport.publicTransportType?.nameEn ?? "",
                    nameFr: transport.publicTransportType?.nameFr ?? ""
                ),
                fromRegionEn: transport.fromRegionEn ?? "",
                fromRegionFr: transport.fromRegionFr ?? "",
                toRegionEn: transport.toRegionEn ?? "",
                toRegionFr: transport.toRegionFr ?? "",
                times: transport.times.map { TransportTime(time: $0.time) },
                city: transport.city.map { city in
                    TransportCity(
                        id: city.id,
                        nameEn: city.nameEn ?? "",
                        nameFr: city.nameFr ?? ""
                    )
                }
            )
        }
    }
}
