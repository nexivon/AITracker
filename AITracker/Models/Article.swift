import Foundation

struct Article: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let description: String
    let url: String
    let imageUrl: String? // Added for UI aesthetics
    let publishedAt: Date
    let source: String
    var isSaved: Bool = false // Ability to save/bookmark
    
    static var mockData: [Article] {
        return [
            Article(id: "1", title: "OpenAI Announces GPT-5 with Multimodal Core", description: "The highly anticipated GPT-5 model features deep multimodal reasoning out of the box, changing the landscape of AI development.", url: "https://openai.com", imageUrl: "https://images.unsplash.com/photo-1677442136019-21780ecad995?w=800&q=80", publishedAt: Date(), source: "TechCrunch"),
            Article(id: "2", title: "Apple integrates Native AI into iOS 18", description: "Apple Intelligence brings massive on-device changes to the ecosystem, prioritizing privacy and seamless integration across all apps.", url: "https://apple.com", imageUrl: "https://images.unsplash.com/photo-1620712948343-0088b3f50348?w=800&q=80", publishedAt: Date().addingTimeInterval(-3600), source: "The Verge"),
            Article(id: "3", title: "Mistral releases new open-source 7B model", description: "A highly efficient 7B model matching proprietary performance benchmarks and available entirely for free on HuggingFace.", url: "https://mistral.ai", imageUrl: "https://images.unsplash.com/photo-1655610214690-3486ddfd2a83?w=800&q=80", publishedAt: Date().addingTimeInterval(-7200), source: "HackerNews"),
            Article(id: "4", title: "Google DeepMind beats Math Olympiad", description: "AlphaMath achieves silver-medal equivalent performance on the International Mathematical Olympiad.", url: "https://deepmind.google", imageUrl: "https://images.unsplash.com/photo-1635326546377-504c554e2fe7?w=800&q=80", publishedAt: Date().addingTimeInterval(-14400), source: "AI Weekly")
        ]
    }
}
