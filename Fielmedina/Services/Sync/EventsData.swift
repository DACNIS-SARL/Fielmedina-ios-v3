//
//  EventsData.swift
//  Fielmedina
//
//  Created by Aslan on 1/13/26.
//

//
//  EventsData.swift
//  Fielmedina
//
//  Created by Aslan on 1/13/26.
//

import Foundation

struct EventsData {
    static let sampleEvents: [Event] = [
        Event(
            id: "1",
            nameEn: "7th International Festival of Circus and Street Arts",
            nameFr: "7ème Festival International du Cirque et des Arts de la Rue",
            startDate: "2026-02-13",
            endDate: "2026-02-20",
            time: "20:30",
            price: "145 TND",
            images: [
                ImageContainer(
                    image: ImageField(url: "event-e"),
                    imageMobile: ImageField(url: "event-e")
                )
            ],
            location: EventLocation(
                id: "loc-1",
                nameEn: "Cultural Center",
                nameFr: "Centre Culturel"
            ),
            category: EventCategory(
                id: "cat-1",
                nameEn: "Spectacle / Show",
                nameFr: "Spectacle"
            )
        ),
        Event(
            id: "2",
            nameEn: "Tabarka Jazz Festival 2026",
            nameFr: "Festival de Jazz de Tabarka 2026",
            startDate: "2026-03-20",
            endDate: nil,
            time: "19:00",
            price: "50 TND",
            images: [
                ImageContainer(
                    image: ImageField(url: "event-e"),
                    imageMobile: ImageField(url: "event-e")
                )
            ],
            location: EventLocation(
                id: "loc-2",
                nameEn: "Tabarka Beach",
                nameFr: "Plage de Tabarka"
            ),
            category: EventCategory(
                id: "cat-2",
                nameEn: "Live Music & Concerts",
                nameFr: "Musique Live & Concerts"
            )
        ),
        Event(
            id: "3",
            nameEn: "Traditional Pottery Workshop",
            nameFr: "Atelier de Poterie Traditionnelle",
            startDate: "2026-04-15",
            endDate: nil,
            time: "10:00",
            price: nil,
            images: [
                ImageContainer(
                    image: ImageField(url: "event-e"),
                    imageMobile: ImageField(url: "event-e")
                )
            ],
            location: EventLocation(
                id: "loc-3",
                nameEn: "Artisan Workshop",
                nameFr: "Atelier d'Artisan"
            ),
            category: EventCategory(
                id: "cat-3",
                nameEn: "Workshop / Class",
                nameFr: "Atelier"
            )
        ),
        Event(
            id: "4",
            nameEn: "Medina Heritage Walking Tour",
            nameFr: "Visite Guidée de la Médina",
            startDate: "2026-04-16",
            endDate: nil,
            time: "09:00",
            price: "25 TND",
            images: [
                ImageContainer(
                    image: ImageField(url: "event-e"),
                    imageMobile: ImageField(url: "event-e")
                )
            ],
            location: EventLocation(
                id: "loc-4",
                nameEn: "Medina of Tunis",
                nameFr: "Médina de Tunis"
            ),
            category: EventCategory(
                id: "cat-4",
                nameEn: "Guided Tour / Walk",
                nameFr: "Visite Guidée"
            )
        ),
        Event(
            id: "5",
            nameEn: "Carthage History Re-enactment",
            nameFr: "Reconstitution Historique de Carthage",
            startDate: "2026-05-01",
            endDate: nil,
            time: "15:00",
            price: "30 TND",
            images: [
                ImageContainer(
                    image: ImageField(url: "event-e"),
                    imageMobile: ImageField(url: "event-e")
                )
            ],
            location: EventLocation(
                id: "loc-5",
                nameEn: "Carthage Ruins",
                nameFr: "Ruines de Carthage"
            ),
            category: EventCategory(
                id: "cat-5",
                nameEn: "Historical Re-enactment",
                nameFr: "Reconstitution Historique"
            )
        ),
        Event(
            id: "6",
            nameEn: "Sousse Summer Market",
            nameFr: "Marché d'Été de Sousse",
            startDate: "2026-06-10",
            endDate: nil,
            time: "08:00",
            price: nil,
            images: [
                ImageContainer(
                    image: ImageField(url: "event-e"),
                    imageMobile: ImageField(url: "event-e")
                )
            ],
            location: EventLocation(
                id: "loc-6",
                nameEn: "Sousse Old Town",
                nameFr: "Vieille Ville de Sousse"
            ),
            category: EventCategory(
                id: "cat-6",
                nameEn: "Market / Fair",
                nameFr: "Marché"
            )
        ),
        Event(
            id: "7",
            nameEn: "Couscous & Harissa Festival",
            nameFr: "Festival du Couscous et Harissa",
            startDate: "2026-07-04",
            endDate: nil,
            time: "12:00",
            price: "35 TND",
            images: [
                ImageContainer(
                    image: ImageField(url: "event-e"),
                    imageMobile: ImageField(url: "event-e")
                )
            ],
            location: EventLocation(
                id: "loc-7",
                nameEn: "Food Market Square",
                nameFr: "Place du Marché"
            ),
            category: EventCategory(
                id: "cat-7",
                nameEn: "Food & Drink Festival",
                nameFr: "Festival Gastronomique"
            )
        ),
        Event(
            id: "8",
            nameEn: "Contemporary Art Exhibition",
            nameFr: "Exposition d'Art Contemporain",
            startDate: "2026-08-08",
            endDate: nil,
            time: "18:00",
            price: nil,
            images: [
                ImageContainer(
                    image: ImageField(url: "event-e"),
                    imageMobile: ImageField(url: "event-e")
                )
            ],
            location: EventLocation(
                id: "loc-8",
                nameEn: "Modern Art Gallery",
                nameFr: "Galerie d'Art Moderne"
            ),
            category: EventCategory(
                id: "cat-8",
                nameEn: "Exhibition / Art Show",
                nameFr: "Exposition"
            )
        ),
        Event(
            id: "9",
            nameEn: "Ramadan Cultural Celebration",
            nameFr: "Célébration Culturelle du Ramadan",
            startDate: "2026-09-15",
            endDate: nil,
            time: "19:30",
            price: nil,
            images: [
                ImageContainer(
                    image: ImageField(url: "event-e"),
                    imageMobile: ImageField(url: "event-e")
                )
            ],
            location: EventLocation(
                id: "loc-9",
                nameEn: "Grand Mosque",
                nameFr: "Grande Mosquée"
            ),
            category: EventCategory(
                id: "cat-9",
                nameEn: "Cultural Festival",
                nameFr: "Festival Culturel"
            )
        ),
        Event(
            id: "10",
            nameEn: "Autumn Harvest Festival",
            nameFr: "Festival des Récoltes d'Automne",
            startDate: "2026-10-20",
            endDate: nil,
            time: "11:00",
            price: "20 TND",
            images: [
                ImageContainer(
                    image: ImageField(url: "event-e"),
                    imageMobile: ImageField(url: "event-e")
                )
            ],
            location: EventLocation(
                id: "loc-10",
                nameEn: "Countryside Farm",
                nameFr: "Ferme Rurale"
            ),
            category: EventCategory(
                id: "cat-10",
                nameEn: "Seasonal Event",
                nameFr: "Événement Saisonnier"
            )
        )
    ]
}
