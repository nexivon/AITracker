import Foundation

protocol AIServiceProtocol {
    func summarize(articleText: String, articleUrl: String, targetLanguage: String) async throws -> String
}

class MockAIService: AIServiceProtocol {
    func summarize(articleText: String, articleUrl: String, targetLanguage: String) async throws -> String {
        try await Task.sleep(nanoseconds: 1_500_000_000)
        return "Bu, orijinali \"\(articleText)\" olan haberin '\(targetLanguage)' diline çevrilmiş örnek Yapay Zeka özetidir. (Mock Veri)"
    }
}
