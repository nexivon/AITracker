import Foundation

struct Summary: Identifiable, Codable {
    let id: UUID
    let articleId: String
    let originalText: String
    let translatedSummary: String
    let targetLanguage: String
    
    init(id: UUID = UUID(), articleId: String, originalText: String, translatedSummary: String, targetLanguage: String) {
        self.id = id
        self.articleId = articleId
        self.originalText = originalText
        self.translatedSummary = translatedSummary
        self.targetLanguage = targetLanguage
    }
}
