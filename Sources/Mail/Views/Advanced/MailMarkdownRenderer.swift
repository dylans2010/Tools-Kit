import SwiftUI

struct MailMarkdownRenderer: View {
    let source: String
    let schema: MailAIOutputSchema

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let attributedString = try? AttributedString(markdown: source, options: .init(allowsExtendedAttributes: false, interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
                Text(attributedString)
            } else {
                Text(source)
            }
        }
    }
}
