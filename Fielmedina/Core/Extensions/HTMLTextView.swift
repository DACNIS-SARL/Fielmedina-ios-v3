//
//  HTMLTextView.swift
//  Fielmedina
//
//  Created by Aslan on 2/4/26.
//

import SwiftUI
import WebKit

struct HTMLTextView: View {
    let html: String
    let textStyle: UIFont.TextStyle
    let textColor: Color
    let linkColor: Color
    let isBold: Bool
    let lineLimit: Int?

    @State private var contentHeight: CGFloat = .zero

    init(
        html: String,
        textStyle: UIFont.TextStyle = .body,
        textColor: Color = .primary,
        linkColor: Color = .accentColor,
        isBold: Bool = false,
        lineLimit: Int? = nil
    ) {
        self.html = html
        self.textStyle = textStyle
        self.textColor = textColor
        self.linkColor = linkColor
        self.isBold = isBold
        self.lineLimit = lineLimit
    }

    var body: some View {
        HTMLWebView(
            html: wrappedHTML,
            contentHeight: $contentHeight
        )
        .frame(height: contentHeight)
        .accessibilityElement(children: .combine)
    }

    private var wrappedHTML: String {
        let font = UIFont.preferredFont(forTextStyle: textStyle)
        let fontSize = font.pointSize
        let fontWeight = isBold ? "700" : "400"
        let textColorHex = UIColor(textColor).hexString
        let linkColorHex = UIColor(linkColor).hexString
        let clamp = lineLimit.map { "-webkit-line-clamp: \($0);" } ?? ""
        let displayClamp = lineLimit == nil ? "" : "display: -webkit-box; -webkit-box-orient: vertical; overflow: hidden;"

        let style = """
        <style>
        :root { color-scheme: light dark; }
        html, body { margin: 0; padding: 0; background: transparent; }
        body {
          font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "Helvetica Neue", Helvetica, Arial, sans-serif;
          font-size: \(fontSize)px;
          font-weight: \(fontWeight);
          color: \(textColorHex);
          line-height: 1.45;
          word-break: break-word;
        }
        h1, h2, h3, h4 { margin: 0 0 10px 0; line-height: 1.25; }
        h2 { font-size: \(fontSize * 1.2)px; font-weight: 700; }
        h3 { font-size: \(fontSize * 1.05)px; font-weight: 700; }
        p { margin: 0 0 10px 0; }
        ul, ol { margin: 0 0 10px 18px; padding: 0; }
        li { margin: 0 0 6px 0; }
        strong { font-weight: 700; }
        em { font-style: italic; }
        a { color: \(linkColorHex); text-decoration: none; }
        .clamp { \(displayClamp) \(clamp) }
        </style>
        """

        return """
        <html>
          <head>
            <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
            \(style)
          </head>
          <body>
            <div class=\"clamp\">
              \(html)
            </div>
          </body>
        </html>
        """
    }
}

private struct HTMLWebView: UIViewRepresentable {
    let html: String
    @Binding var contentHeight: CGFloat

    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView(frame: .zero)
        view.isOpaque = false
        view.backgroundColor = .clear
        view.scrollView.isScrollEnabled = false
        view.navigationDelegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard context.coordinator.lastHTML != html else { return }
        context.coordinator.lastHTML = html
        uiView.loadHTMLString(html, baseURL: nil)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(contentHeight: $contentHeight)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var contentHeight: CGFloat
        var lastHTML: String?

        init(contentHeight: Binding<CGFloat>) {
            _contentHeight = contentHeight
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("document.body.scrollHeight") { result, _ in
                guard let height = result as? CGFloat else { return }
                if self.contentHeight != height {
                    self.contentHeight = height
                }
            }
        }
    }
}

private extension UIColor {
    var hexString: String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let r = Int(red * 255)
        let g = Int(green * 255)
        let b = Int(blue * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
