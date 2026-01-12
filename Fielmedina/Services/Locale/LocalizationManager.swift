////
////  LocalizationManager.swift
////  Fielmedina
////
////  Created by Aslan on 1/8/26.
////
//
//import Foundation
//import SwiftUI
//
//
//class LocalizationManager: ObservableObject {
//    static let shared = LocalizationManager()
//    
//    @Published var currentLanguage: Language = .english
//    
//    enum Language: String, CaseIterable {
//        case english = "en"
//        case french = "fr"
//        
//        var displayName: String {
//            switch self {
//            case .english:
//                return "English"
//            case .french:
//                return "Français"
//            }
//        }
//        
//        var flag: String {
//            switch self {
//            case .english:
//                return "🇺🇸"
//            case .french:
//                return "🇫🇷"
//            }
//        }
//    }
//    
//    private init() {
//        // Load saved language preference
//        if let savedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage"),
//           let language = Language(rawValue: savedLanguage) {
//            currentLanguage = language
//        } else {
//            // Default to system language or English
//            let systemLanguage = Locale.current.language.languageCode?.identifier ?? "en"
//            currentLanguage = Language(rawValue: systemLanguage) ?? .english
//        }
//    }
//    
//    func setLanguage(_ language: Language) {
//        currentLanguage = language
//        UserDefaults.standard.set(language.rawValue, forKey: "selectedLanguage")
//        
//        // Post notification for language change
//        NotificationCenter.default.post(name: .languageChanged, object: language)
//    }
//    
//    func localizedString(for key: String, comment: String = "") -> String {
//        let bundle = Bundle.main
//        let languageCode = currentLanguage.rawValue
//        
//        // Try to get localized string from bundle
//        if let path = bundle.path(forResource: languageCode, ofType: "lproj"),
//           let languageBundle = Bundle(path: path) {
//            return languageBundle.localizedString(forKey: key, value: key, table: nil)
//        }
//        
//        // Fallback to main bundle
//        return bundle.localizedString(forKey: key, value: key, table: nil)
//    }
//}
//
//// MARK: - Notification Names
//extension Notification.Name {
//    static let languageChanged = Notification.Name("languageChanged")
//}
//
//// MARK: - String Extension for Localization
//extension String {
//    var localized: String {
//        return LocalizationManager.shared.localizedString(for: self)
//    }
//    
//    func localized(with arguments: CVarArg...) -> String {
//        let format = LocalizationManager.shared.localizedString(for: self)
//        return String(format: format, arguments: arguments)
//    }
//}
