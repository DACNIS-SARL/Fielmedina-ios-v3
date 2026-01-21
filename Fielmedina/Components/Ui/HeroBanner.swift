import SwiftUI

struct HeroBanner: View {
    private let baseHeight: CGFloat = 320
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                // Background Image with Parallax
                Image("hero-bg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: baseHeight)
                    .clipped()
                    .scrollTransition(axis: .vertical) { content, phase in
                        content
                            .scaleEffect(phase.isIdentity ? 1 : 1.1)
                            .offset(y: phase.isIdentity ? 0 : phase.value * -50)
                    }
                
                // Modern Gradient Overlay
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.4),
                        Color.clear,
                        Color.black.opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: geometry.size.width, height: baseHeight)
                .allowsHitTesting(false)
                
                // Responsive Content constrained to screen width
                VStack(alignment: .leading, spacing: -4) {
                    Text("Tunisia")
                        .font(.system(size: 72, weight: .black))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.4), radius: 8)
                        .minimumScaleFactor(0.3)
                        .lineLimit(1)
                    
                    Text("welcome")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.3), radius: 4)
                        .padding(.leading, 4)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
                .frame(width: geometry.size.width, alignment: .bottomLeading)
                .scrollTransition(axis: .vertical) { content, phase in
                    content
                        .opacity(phase.isIdentity ? 1 : 1 - abs(phase.value))
                        .blur(radius: phase.isIdentity ? 0 : abs(phase.value) * 5)
                        .offset(y: phase.isIdentity ? 0 : phase.value * 20)
                }
            }
        }
        .frame(height: baseHeight)
        .clipped()
    }
}

#Preview {
    ScrollView {
        HeroBanner()
        Color.gray.frame(height: 1000)
    }
    .ignoresSafeArea()
}