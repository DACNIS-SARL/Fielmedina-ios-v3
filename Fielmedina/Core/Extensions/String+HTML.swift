//
//  String+HTML.swift
//  Fielmedina
//
//  Created by Aslan on 1/21/26.
//

import Foundation

extension String {
    func htmlToMarkdown() -> AttributedString {
        let text = self
            .replacingOccurrences(of: "<strong>", with: "**", options: .caseInsensitive)
            .replacingOccurrences(of: "</strong>", with: "**", options: .caseInsensitive)
            .replacingOccurrences(of: "<b>", with: "**", options: .caseInsensitive)
            .replacingOccurrences(of: "</b>", with: "**", options: .caseInsensitive)
            .replacingOccurrences(of: "<em>", with: "*", options: .caseInsensitive)
            .replacingOccurrences(of: "</em>", with: "*", options: .caseInsensitive)
            .replacingOccurrences(of: "<i>", with: "*", options: .caseInsensitive)
            .replacingOccurrences(of: "</i>", with: "*", options: .caseInsensitive)
            .replacingOccurrences(of: "<br>", with: "\n", options: .caseInsensitive)
            .replacingOccurrences(of: "<br/>", with: "\n", options: .caseInsensitive)
            .replacingOccurrences(of: "<br />", with: "\n", options: .caseInsensitive)
            .replacingOccurrences(of: "<p>", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "</p>", with: "\n", options: .caseInsensitive)
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            return try AttributedString(markdown: text)
        } catch {
            return AttributedString(text)
        }
    }
    
    func strippingHTML() -> String {
        self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
