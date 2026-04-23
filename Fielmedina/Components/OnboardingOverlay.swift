//
//  OnboardingOverlay.swift
//  Fielmedina
//
//  Created by Aslan on 4/23/26.
//

import SwiftUI

struct OnboardingOverlay: View {
    let onDismiss: () -> Void
    
    @State private var isVisible = false
    @State private var arrowProgress: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var bubbleOpacity: Double = 0
    @State private var bubbleOffset: CGFloat = 20
    @State private var glowOpacity: Double = 0
    
    private let ringRadius: CGFloat = 22
    
    private func getSafeTop() -> CGFloat {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window.safeAreaInsets.top > 0 ? window.safeAreaInsets.top : 47
        }
        return 47
    }
    
    var body: some View {
        GeometryReader { geo in
            let screenSize = geo.size
            let safeTop = getSafeTop()
            
            // Adjusted X coordinate with more right margin to perfectly align with the gear
            let gearCenter = CGPoint(
                x: screenSize.width - 38,
                y: safeTop + 22
            )
            
            // Shifted the bubble higher up and offset to the left for a natural flow
            let bubbleCenter = CGPoint(
                x: screenSize.width / 2,
                y: gearCenter.y + 130
            )
            
            ZStack {
                // MARK: - Dark scrim with cutout
                ScrimWithSpotlight(
                    spotlightCenter: gearCenter,
                    spotlightRadius: ringRadius
                )
                .fill(style: FillStyle(eoFill: true))
                .foregroundStyle(Color.black.opacity(0.75))
                .ignoresSafeArea()
                
                // MARK: - Pulsing glow rings around gear
                Circle()
                    .stroke(Color.white.opacity(glowOpacity * 0.4), lineWidth: 2)
                    .frame(width: ringRadius * 2 * pulseScale,
                           height: ringRadius * 2 * pulseScale)
                    .position(gearCenter)
                
                Circle()
                    .stroke(Color.white.opacity(glowOpacity * 0.9), lineWidth: 1.5)
                    .frame(width: ringRadius * 2, height: ringRadius * 2)
                    .position(gearCenter)
                
                // MARK: - Curved arrow from gear → bubble
                curvedArrow(from: gearCenter, to: bubbleCenter)
                    .trim(from: 0, to: arrowProgress)
                    .stroke(
                        Color.white,
                        style: StrokeStyle(
                            lineWidth: 2.0,
                            lineCap: .round,
                            lineJoin: .round,
                            dash: [6, 6]
                        )
                    )
                
                // Arrow tip (chevron)
                if arrowProgress > 0.85 {
                    arrowTip(at: bubbleCenter)
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 2.0, lineCap: .round, lineJoin: .round))
                        .opacity(Double(min(1, (arrowProgress - 0.85) * 7)))
                }
                
                // MARK: - Floating text (No Box, No Icon)
                Text("onboarding_overlay_message")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.95))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)
                    .frame(width: screenSize.width - 64)
                    .offset(y: bubbleOffset)
                    .opacity(bubbleOpacity)
                    .position(x: bubbleCenter.x, y: bubbleCenter.y + 10)
            }
            .opacity(isVisible ? 1 : 0)
            .contentShape(Rectangle())
            .onTapGesture { dismissOverlay() }
        }
        .ignoresSafeArea()
        .onAppear { startAnimations() }
    }
    
    // MARK: - Arrow path from gear to bubble
    
    private func curvedArrow(from start: CGPoint, to end: CGPoint) -> Path {
        let exitPoint = CGPoint(x: start.x - 8, y: start.y + ringRadius + 4)
        // Entry point is at the top edge of the new bubble (roughly)
        let entryPoint = CGPoint(x: end.x + 30, y: end.y - 30)
        
        let cp1 = CGPoint(
            x: exitPoint.x - 40,
            y: exitPoint.y + (entryPoint.y - exitPoint.y) * 0.3
        )
        let cp2 = CGPoint(
            x: entryPoint.x + 60,
            y: entryPoint.y - (entryPoint.y - exitPoint.y) * 0.3
        )
        
        return Path { p in
            p.move(to: exitPoint)
            p.addCurve(to: entryPoint, control1: cp1, control2: cp2)
        }
    }
    
    private func arrowTip(at end: CGPoint) -> Path {
        let tip = CGPoint(x: end.x + 30, y: end.y - 30)
        return Path { p in
            p.move(to: CGPoint(x: tip.x - 6, y: tip.y - 8))
            p.addLine(to: tip)
            p.addLine(to: CGPoint(x: tip.x + 7, y: tip.y - 7))
        }
    }
    
    // MARK: - Animations
    
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.4)) {
            isVisible = true
            glowOpacity = 1
        }
        
        withAnimation(
            .easeInOut(duration: 1.1)
            .repeatForever(autoreverses: true)
            .delay(0.2)
        ) {
            pulseScale = 1.3
        }
        
        withAnimation(.easeInOut(duration: 1.0).delay(0.3)) {
            arrowProgress = 1.0
        }
        
        withAnimation(.spring(response: 0.55, dampingFraction: 0.7).delay(0.8)) {
            bubbleOffset = 0
            bubbleOpacity = 1
        }
    }
    
    private func dismissOverlay() {
        withAnimation(.easeIn(duration: 0.25)) {
            isVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// MARK: - Shape: full-screen rect with circular hole

private struct ScrimWithSpotlight: Shape {
    let spotlightCenter: CGPoint
    let spotlightRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(rect)
        path.addEllipse(in: CGRect(
            x: spotlightCenter.x - spotlightRadius,
            y: spotlightCenter.y - spotlightRadius,
            width: spotlightRadius * 2,
            height: spotlightRadius * 2
        ))
        return path
    }
}

#Preview {
    ZStack {
        Color.blue
        OnboardingOverlay(onDismiss: {})
    }
}
