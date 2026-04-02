import Foundation

class IdeaGeneratorBackend: ObservableObject {
    @Published var ideas: [String] = []

    private let niches = ["Fitness", "Education", "Finance", "Healthcare", "Travel", "Sustainability", "Gaming", "Pet Care", "Real Estate", "Remote Work"]
    private let technologies = ["AI/ML", "Blockchain", "AR/VR", "IoT", "Mobile App", "SaaS", "Marketplace", "Wearables", "Voice Interface"]
    private let targets = ["for Seniors", "for Students", "for Small Businesses", "for Digital Nomads", "for Busy Parents", "for Creators"]

    func generate() {
        let niche = niches.randomElement() ?? "General"
        let tech = technologies.randomElement() ?? "Platform"
        let target = targets.randomElement() ?? "for Everyone"

        let newIdea = "\(tech) \(niche) solution \(target)"
        ideas.insert(newIdea, at: 0)

        if ideas.count > 10 {
            ideas.removeLast()
        }
    }

    func clear() {
        ideas = []
    }
}
