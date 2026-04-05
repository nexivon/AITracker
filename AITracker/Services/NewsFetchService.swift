import Foundation

protocol NewsFetchServiceProtocol {
    func fetchLatestAIArticles(timeRange: TimeRange) async throws -> [Article]
}

enum TimeRange: String, CaseIterable, Identifiable {
    case lastHour = "Son 1 Saat"
    case last12Hours = "Son 12 Saat"
    case last24Hours = "Son 24 Saat"
    case lastWeek = "Son 1 Hafta"
    
    var id: String { self.rawValue }
    
    var googleNewsQuery: String {
        switch self {
        case .lastHour: return "1h"
        case .last12Hours: return "12h"
        case .last24Hours: return "1d"
        case .lastWeek: return "7d"
        }
    }
}

class GoogleNewsFetchService: NSObject, NewsFetchServiceProtocol, XMLParserDelegate {
    private var articles: [Article] = []
    
    private var currentElement = ""
    private var currentTitle = ""
    private var currentLink = ""
    private var currentPubDate = ""
    private var currentDescription = ""
    private var currentSource = ""
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    func fetchLatestAIArticles(timeRange: TimeRange) async throws -> [Article] {
        articles.removeAll()
        
        let query = "(\"artificial intelligence\" OR \"generative ai\" OR ChatGPT OR Gemini OR \"Google AI\" OR Anthropic OR OpenAI) when:\(timeRange.googleNewsQuery)"
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "artificial+intelligence"
        
        let urlString = "https://news.google.com/rss/search?q=\(encodedQuery)&hl=en-US&gl=US&ceid=US:en"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        try Task.checkCancellation()
        
        let parser = XMLParser(data: data)
        parser.delegate = self
        
        if parser.parse() {
            return articles
        } else {
            throw URLError(.cannotParseResponse)
        }
    }
    
    // MARK: - XMLParserDelegate
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if currentElement == "item" {
            currentTitle = ""
            currentLink = ""
            currentPubDate = ""
            currentDescription = ""
            currentSource = ""
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        switch currentElement {
        case "title": currentTitle += string
        case "link": currentLink += string
        case "pubDate": currentPubDate += string
        case "description": currentDescription += string
        case "source": currentSource += string
        default: break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            let cleanTitle = currentTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanLink = currentLink.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanPubDate = currentPubDate.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanDesc = currentDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanSource = currentSource.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // HTML etiketlerini metinden temizle ve entity'leri düzelt
            let strippedDesc = cleanDesc.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
                .replacingOccurrences(of: "&nbsp;", with: " ")
                .replacingOccurrences(of: "&quot;", with: "\"")
                .replacingOccurrences(of: "&#39;", with: "'")
            
            // Eğer URL aynıysa Database (Kalıcı kayıt) sorunsuz çalışsın diye ID olarak URL'yi kullanıyoruz
            let id = cleanLink.isEmpty ? UUID().uuidString : cleanLink
            let date = dateFormatter.date(from: cleanPubDate) ?? Date()
            
            let article = Article(
                id: id,
                title: cleanTitle,
                description: strippedDesc.isEmpty ? cleanTitle : strippedDesc,
                url: cleanLink,
                imageUrl: nil, // Google RSS genelde görsel basmaz, UI bunu gradyanla çözer
                publishedAt: date,
                source: cleanSource.isEmpty ? "Google News" : cleanSource
            )
            articles.append(article)
        }
    }
}
