//
//  UtilView.swift
//  Fielmedina
//
//  Created by Aslan on 1/8/26.
//

//
//  UtilView.swift
//  Fielmedina
//
//  Created by Aslan on 1/8/26.
//

import SwiftUI

struct UtilView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    VStack(spacing: 8) {
                        Text("Emergency Contacts")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        Text("Tap any contact to call immediately")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .opacity(0.8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 32)
                    
                    VStack(spacing: 20) {
                        EmergencyContactCard(
                            title: "Police",
                            subtitle: String(localized: "police_subtitle"),
                            phoneNumber: "197",
                            icon: "shield.fill",
                            backgroundColor: Color(red: 0.082, green: 0.396, blue: 0.753),
                            cardBackgroundColor: Color(red: 0.890, green: 0.949, blue: 0.992),
                            strokeColor: Color(red: 0.082, green: 0.396, blue: 0.753),
                            onCall: callNumber
                        )
                        
                        EmergencyContactCard(
                            title: "Ambulance",
                            subtitle: String(localized: "medical_subtitle"),
                            phoneNumber: "192",
                            icon: "cross.fill",
                            backgroundColor: Color(red: 0.827, green: 0.184, blue: 0.184),
                            cardBackgroundColor: Color(red: 1.0, green: 0.922, blue: 0.933),
                            strokeColor: Color(red: 0.827, green: 0.184, blue: 0.184),
                            onCall: callNumber
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    EmergencyWarningCard()
                    
                    AdsCarousel()
                    Spacer()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SettingsButton()
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                FirebaseUtils.trackFeatureUsage(featureName: "emergency_view_displayed", parameters: [
                    "contact_count": 2,
                    "has_warning": true
                ])
            }
        }
    }
    
    func callNumber(_ number: String) {
        let cleanNumber = number.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "+", with: "")
            .replacingOccurrences(of: "-", with: "")
        
        if let url = URL(string: "tel://\(cleanNumber)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                FirebaseUtils.trackFeatureUsage(featureName: "phone_call_launched", parameters: [
                    "phone_number": cleanNumber,
                    "call_type": "emergency"
                ])
            } else {
                FirebaseUtils.logError(NSError(domain: "EmergencyView", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "Cannot open phone URL"
                ]), additionalUserInfo: ["phone_number": cleanNumber])
            }
        }
    }
}

struct EmergencyContactCard: View {
    let title: String
    let subtitle: String
    let phoneNumber: String
    let icon: String
    let backgroundColor: Color
    let cardBackgroundColor: Color
    let strokeColor: Color
    let onCall: (String) -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var adaptiveCardBackground: Color {
        colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemGray6)
    }
    var adaptiveBadgeBackground: Color {
        Color.white
    }
    var adaptiveBorder: Color {
        colorScheme == .dark ? strokeColor.opacity(0.8) : strokeColor
    }
    
    var body: some View {
        Button(action: {
            FirebaseUtils.trackButtonTap(buttonName: "emergency_call_\(title.lowercased())", screenName: "Emergency")
            FirebaseUtils.trackFeatureUsage(featureName: "emergency_call_initiated", parameters: [
                "service": title,
                "phone_number": phoneNumber
            ])
            onCall(phoneNumber)
        }) {
            HStack(alignment: .center, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(colorScheme == .dark ? Color(.systemBackground) : .white)
                        .frame(width: 48, height: 48)
                        .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(backgroundColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(backgroundColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    
                    Text(subtitle)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                        .opacity(0.95)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(nil)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(phoneNumber)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(backgroundColor)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(adaptiveBadgeBackground)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.08), radius: 1, x: 0, y: 1)
            }
            .padding(20)
            .background(adaptiveCardBackground)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(adaptiveBorder, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmergencyWarningCard: View {
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.yellow)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                Text("Emergency Use Only")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                Text("These numbers are for genuine emergencies only. Misuse may result in legal consequences.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemGray6))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
        .padding(.horizontal, 24)
        .padding(.top, 70)
        .padding(.bottom, 50)
    }
}

#Preview {
    UtilView()
}
