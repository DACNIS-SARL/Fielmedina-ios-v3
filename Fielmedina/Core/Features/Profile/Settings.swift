//
//  Settings.swift
//  Fielmedina
//
//  Created by Aslan on 1/13/26.
//

import SwiftUI


struct SettingsView: View {
    var body: some View {
        VStack {
          Spacer()
          VStack(spacing: 16) {
              Image(systemName: "person")
                  .font(.system(size: 60))
                  .foregroundColor(.yellow)

              Text("Settings")
                  .font(.system(size: 24, weight: .bold))

              Text("Coming soon!")
                  .font(.system(size: 16))
                  .foregroundColor(.secondary)
          }
          Spacer()
      }
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar(.hidden, for: .tabBar)
        
    }
}

#Preview {
    SettingsView()
}
