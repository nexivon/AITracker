import SwiftUI
import Combine

@MainActor
class NewsViewModel: ObservableObject {
    @Published var articles: [Article] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var searchText: String = ""
    @Published var savedArticleIDs: Set<String> = []
    
    var savedArticlesList: [Article] {
        articles.filter { $0.isSaved }
    }
    
    private var fetchTask: Task<Void, Never>?
    private let articlesCacheKey = "offline_articles_cache"
    private let summaryCacheKey = "summary_cache"
    private var summaryCache: [String: Summary] = {
        guard let data = UserDefaults.standard.data(forKey: "summary_cache"),
              let decoded = try? JSONDecoder().decode([String: Summary].self, from: data)
        else { return [:] }
        return decoded
    }()
    
    @Published var selectedTimeRange: TimeRange = .last24Hours {
        didSet {
            UserDefaults.standard.set(selectedTimeRange.rawValue, forKey: "selectedTimeRange")
            Task {
                await fetchNews()
            }
        }
    }

    @Published var targetLanguage: String = "Türkçe" {
        didSet {
            UserDefaults.standard.set(targetLanguage, forKey: "targetLanguage")
        }
    }
    
    private let newsService: NewsFetchServiceProtocol
    private let aiService: AIServiceProtocol
    
    init(newsService: NewsFetchServiceProtocol = GoogleNewsFetchService(),
         aiService: AIServiceProtocol = GeminiService()) {
        self.newsService = newsService
        self.aiService = aiService

        if let saved = UserDefaults.standard.stringArray(forKey: "savedArticleIDs") {
            self.savedArticleIDs = Set(saved)
        }
        if let savedRange = UserDefaults.standard.string(forKey: "selectedTimeRange"),
           let range = TimeRange(rawValue: savedRange) {
            self._selectedTimeRange = Published(initialValue: range)
        }
        if let savedLang = UserDefaults.standard.string(forKey: "targetLanguage") {
            self._targetLanguage = Published(initialValue: savedLang)
        }
    }
    
    func fetchNews() async {
        let currentTask = Task { @MainActor in
            isLoading = true
            errorMessage = nil
            
            do {
                let fetched = try await newsService.fetchLatestAIArticles(timeRange: selectedTimeRange)
                try Task.checkCancellation()
                
                // Kalıcı kaydedilmişlerin durumunu yükle
                let ids = savedArticleIDs
                self.articles = fetched.map { article in
                    var mutated = article
                    mutated.isSaved = ids.contains(article.id)
                    return mutated
                }
                saveArticlesCache(articles: self.articles)
            } catch is CancellationError {
                // Task iptal edildi, bir şey yapma
            } catch {
                if let cached = loadCache(), !cached.isEmpty {
                    self.articles = cached
                    errorMessage = "Çevrimdışı mod: Güncel haberler yüklenemedi, cihazdaki veriler gösteriliyor."
                } else {
                    errorMessage = "Haberler yüklenirken hata oluştu: \(error.localizedDescription)"
                }
            }
            
            if !Task.isCancelled {
                isLoading = false
            }
        }
        
        fetchTask?.cancel()
        fetchTask = currentTask
        await currentTask.value
    }
    
    func toggleSave(for article: Article) {
        if let index = articles.firstIndex(where: { $0.id == article.id }) {
            articles[index].isSaved.toggle()
            if articles[index].isSaved {
                savedArticleIDs.insert(article.id)
            } else {
                savedArticleIDs.remove(article.id)
            }
            UserDefaults.standard.set(Array(savedArticleIDs), forKey: "savedArticleIDs")
        }
    }
    
    /// Cache'te varsa anında döner, API çağrısı yapmaz.
    func getCachedSummary(for article: Article) -> Summary? {
        let key = "\(article.id)_\(targetLanguage)"
        return summaryCache[key]
    }

    func getSummary(for article: Article) async throws -> Summary {
        let key = "\(article.id)_\(targetLanguage)"
        if let cached = summaryCache[key] {
            return cached
        }
        let summaryText = try await aiService.summarize(articleText: article.description, articleUrl: article.url, targetLanguage: targetLanguage)
        let summary = Summary(articleId: article.id, originalText: article.description, translatedSummary: summaryText, targetLanguage: targetLanguage)
        summaryCache[key] = summary
        persistSummaryCache()
        return summary
    }

    private func persistSummaryCache() {
        if let encoded = try? JSONEncoder().encode(summaryCache) {
            UserDefaults.standard.set(encoded, forKey: summaryCacheKey)
        }
    }
    
    private func saveArticlesCache(articles: [Article]) {
        if let encoded = try? JSONEncoder().encode(articles) {
            UserDefaults.standard.set(encoded, forKey: articlesCacheKey)
        }
    }

    private func loadCache() -> [Article]? {
        if let data = UserDefaults.standard.data(forKey: articlesCacheKey),
           let decoded = try? JSONDecoder().decode([Article].self, from: data) {
            return decoded
        }
        return nil
    }
}
