import SwiftUI

struct CitationFormatsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Academic Styles") {
                    CitationRow(name: "APA 7th Edition",
                                description: "Commonly used in psychology, education, and sciences.",
                                format: "Smith, J. (2024). *The Future of AI*. Tech Press. https://doi.org/10.1234/5678")

                    CitationRow(name: "MLA 9th Edition",
                                description: "Used in humanities, literature, and cultural studies.",
                                format: "Smith, John. \"The Future of AI.\" *Journal of Technology*, vol. 12, no. 3, 2024, pp. 45–67.")

                    CitationRow(name: "Chicago 17th (Author-Date)",
                                description: "Used in physical, natural, and social sciences.",
                                format: "Smith, John. 2024. *The Future of AI*. San Francisco: Tech Press.")

                    CitationRow(name: "Chicago 17th (Notes-Bibliography)",
                                description: "Common in history and the arts.",
                                format: "Smith, John. *The Future of AI*. San Francisco: Tech Press, 2024.")

                    CitationRow(name: "Harvard",
                                description: "Standard style in many UK and Australian universities.",
                                format: "Smith, J. (2024) *The Future of AI*. San Francisco: Tech Press.")

                    CitationRow(name: "Turabian 9th",
                                description: "A variation of Chicago style for student papers.",
                                format: "Smith, John. *The Future of AI*. San Francisco: Tech Press, 2024.")

                    CitationRow(name: "Vancouver",
                                description: "Used in medicine and biological sciences.",
                                format: "Smith J. The Future of AI. Tech Jour. 2024 Jan;12(3):45-67. doi:10.1234/5678")

                    CitationRow(name: "IEEE",
                                description: "Used in engineering, computer science, and IT.",
                                format: "[1] J. Smith, \"The Future of AI,\" *Journal of Technology*, vol. 12, no. 3, pp. 45–67, Jan. 2024.")

                    CitationRow(name: "ACS",
                                description: "The American Chemical Society style.",
                                format: "Smith, J.; Doe, B. *Chem. Tech. Jour.* **2024**, *12*, 45-67.")

                    CitationRow(name: "AMA",
                                description: "American Medical Association style.",
                                format: "Smith J, Doe B. The Future of AI. *Journal Name*. 2024;12(3):45-67. doi:10.1234/5678")

                    CitationRow(name: "ASA",
                                description: "American Sociological Association style.",
                                format: "Smith, John. 2024. \"The Future of AI.\" *Social Tech Journal* 12(3):45-67.")

                    CitationRow(name: "APSA",
                                description: "American Political Science Association style.",
                                format: "Smith, John. 2024. *The Future of AI*. San Francisco: Tech Press.")

                    CitationRow(name: "AAA",
                                description: "American Anthropological Association style.",
                                format: "Smith, John. 2024. The Future of AI. *Anthr. Tech.* 12(3):45-67.")

                    CitationRow(name: "CSE Name-Year",
                                description: "Council of Science Editors style.",
                                format: "Smith J, Doe B. 2024. The Future of AI. Sci Tech J. 12:45-67.")

                    CitationRow(name: "NLM",
                                description: "National Library of Medicine style for medical journals.",
                                format: "Smith J, Doe B. The future of AI. Sci Tech J. 2024 Jan;12(3):45-67.")
                }

                Section("Legal & Government") {
                    CitationRow(name: "Bluebook Brief",
                                description: "Citation style for legal briefs.",
                                format: "Brief for Petitioner at 12, Smith v. Jones, 123 U.S. 456 (2024).")

                    CitationRow(name: "Legal Case (US)",
                                description: "Standard US legal case citation.",
                                format: "Smith v. Jones, 123 F.3d 456 (9th Cir. 2024).")

                    CitationRow(name: "Bluebook (Law Review)",
                                description: "Uniform system of citation for legal documents.",
                                format: "John Smith, *The Future of AI*, 12 Tech. J. 45 (2024).")

                    CitationRow(name: "OSCOLA",
                                description: "Oxford Standard for Citation of Legal Authorities.",
                                format: "John Smith, *The Future of AI* (Tech Press 2024) 45.")

                    CitationRow(name: "AGLC4",
                                description: "Australian Guide to Legal Citation.",
                                format: "John Smith, *The Future of AI* (Tech Press, 2024) 45.")
                }

                Section("Science & Medicine") {
                    CitationRow(name: "Nature",
                                description: "Standard for Nature journals.",
                                format: "Smith, J. et al. The Future of AI. *Nature* 12, 45-67 (2024). https://doi.org/10.1234/5678")

                    CitationRow(name: "APA PsycInfo Journal",
                                description: "Specific APA format for psychology journals.",
                                format: "Smith, J., & Doe, B. (2024). The Future of AI. *Psychology of Tech, 12*(3), pp. 45–67. https://doi.org/10.1234/5678")
                }

                Section("Business & Reports") {
                    CitationRow(name: "APA Report",
                                description: "Formatting for professional and technical reports.",
                                format: "Smith, J. (2024). *The Future of AI* (Report No. 123). AI Agency. https://agency.gov/report")

                    CitationRow(name: "Government Document",
                                description: "Style for official government publications.",
                                format: "National AI Agency. (2024). *The Future of AI*. Government Printing Office. https://agency.gov/doc")

                    CitationRow(name: "Press Release",
                                description: "Format for official company announcements.",
                                format: "Tech Corp. (2024, May 20). *Announcing The Future of AI* [Press release]. https://techcorp.com/news")
                }

                Section("Web & Digital") {
                    CitationRow(name: "APA Website",
                                description: "Citing content from the open web.",
                                format: "Smith, J. (2024, May 20). *The Future of AI*. Tech Today. https://techtoday.com/ai")

                    CitationRow(name: "MLA Website",
                                description: "Web citation for humanities.",
                                format: "Smith, John. \"The Future of AI.\" *Tech Today*, 20 May 2024, https://techtoday.com/ai.")

                    CitationRow(name: "APA Social Media",
                                description: "Citing tweets, posts, or social content.",
                                format: "Smith, J. [@jsmith]. (2024, May 20). *Excited to share my thoughts on the future of AI!* [Tweet]. X. https://x.com/jsmith/status/123")

                    CitationRow(name: "Wikipedia",
                                description: "Citing wiki entries.",
                                format: "\"The Future of AI.\" *Wikipedia*, Wikimedia Foundation, 20 May 2024, https://en.wikipedia.org/wiki/Future_of_AI.")
                }

                Section("Books & Chapters") {
                    CitationRow(name: "APA Book Chapter",
                                description: "Citing a specific chapter within an edited book.",
                                format: "Smith, J. (2024). The Future of AI. In B. Doe (Ed.), *Tech Anthology* (pp. 45–67). Tech Press.")

                    CitationRow(name: "MLA Book",
                                description: "Standard MLA book citation.",
                                format: "Smith, John. *The Future of AI*. Tech Press, 2024.")

                    CitationRow(name: "Chicago Book (N-B)",
                                description: "Notes-Bibliography style for books.",
                                format: "Smith, John. *The Future of AI*. San Francisco: Tech Press, 2024.")

                    CitationRow(name: "Edited Volume",
                                description: "Citing a complete edited collection.",
                                format: "Smith, John, ed. *The Future of AI*. San Francisco: Tech Press, 2024.")
                }

                Section("Thesis & Dissertations") {
                    CitationRow(name: "APA Dissertation",
                                description: "Citing doctoral level research.",
                                format: "Smith, J. (2024). *The Future of AI* [Doctoral dissertation, Tech University]. ProQuest Database.")

                    CitationRow(name: "MLA Thesis",
                                description: "Citing master's level research.",
                                format: "Smith, John. \"The Future of AI.\" Master's thesis, Tech University, 2024.")
                }

                Section("Conference & Presentations") {
                    CitationRow(name: "APA Conference Paper",
                                description: "Citing papers presented at conferences.",
                                format: "Smith, J. (2024, May). *The Future of AI* [Paper presentation]. AI World 2024, San Francisco.")

                    CitationRow(name: "IEEE Conference",
                                description: "IEEE format for conference proceedings.",
                                format: "[1] J. Smith, \"The Future of AI,\" in *Proc. AI World*, San Francisco, 2024, pp. 45–67.")
                }

                Section("Film, Music, Podcasts") {
                    CitationRow(name: "APA Film",
                                description: "Citing films or documentaries.",
                                format: "Smith, J. (Director). (2024). *The Future of AI* [Film]. AI Studios.")

                    CitationRow(name: "MLA Film",
                                description: "MLA style for audiovisual work.",
                                format: "*The Future of AI*. Directed by John Smith, AI Studios, 2024.")

                    CitationRow(name: "APA Podcast Episode",
                                description: "Citing individual podcast episodes.",
                                format: "Smith, J. (Host). (2024, May 20). The Future of AI (No. 42) [Audio podcast episode]. In *Tech Talk*. AI Network. https://techtalk.fm/42")

                    CitationRow(name: "APA Song",
                                description: "Citing individual songs.",
                                format: "The AI Band. (2024). *The Future of AI* [Song]. On *Digital Dreams*. Synth Label.")

                    CitationRow(name: "Movie Script",
                                description: "Format for citing screenplays.",
                                format: "Smith, John. *The Future of AI*. Screenplay, 2024.")
                }

                Section("Miscellaneous") {
                    CitationRow(name: "Personal Interview",
                                description: "Citing a private interview.",
                                format: "Smith, John. Personal interview. 20 May 2024.")

                    CitationRow(name: "Lecture",
                                description: "Citing a live presentation or lecture.",
                                format: "Smith, John. \"The Future of AI.\" Guest Lecture, University of Tech, 20 May 2024.")

                    CitationRow(name: "Software",
                                description: "Citing computer software or apps.",
                                format: "Smith, J. (2024). *Tools-Kit* (Version 1.0) [Mobile app]. App Store.")

                    CitationRow(name: "Standard",
                                description: "Citing technical standards (ISO, ANSI).",
                                format: "International Organization for Standardization. (2024). *Information technology* (ISO Standard No. 12345).")

                    CitationRow(name: "Patent",
                                description: "Citing an official patent.",
                                format: "Smith, John. (2024). U.S. Patent No. 1,234,567. Washington, DC: U.S. Patent and Trademark Office.")
                }
            }
            .navigationTitle("Citations")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct CitationRow: View {
    let name: String
    let description: String
    let format: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(name)
                .font(.subheadline.bold())
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Text(format)
                    .font(.caption.italic())
                    .foregroundColor(.blue)
                Spacer()
                Button {
                    UIPasteboard.general.string = format
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                }
            }
            .padding(8)
            .background(Color.blue.opacity(0.05))
            .cornerRadius(8)
        }
        .padding(.vertical, 4)
    }
}
