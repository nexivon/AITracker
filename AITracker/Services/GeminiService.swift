import Foundation

class GeminiService: AIServiceProtocol {

    /// gemini-2.5-flash free tier: 10 RPM → istekler arası min 6.5 saniye
    private var lastRequestDate: Date = .distantPast
    private let minRequestInterval: TimeInterval = 6.5

    // Web sitesindeki ham HTML'i okuyup metne dönüştüren yardımcı fonksiyon
    private func fetchWebpageText(url: String) async -> String {
        guard let fetchUrl = URL(string: url) else { return "" }
        var request = URLRequest(url: fetchUrl)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        do {
            // Google News linkleri genelde redirect (yönlendirme) yapar. URLSession bunu otomatik takip eder.
            let (data, _) = try await URLSession.shared.data(for: request)
            if let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) {
                let text = html
                    .replacingOccurrences(of: "<style[^>]*>.*?</style>", with: " ", options: [.regularExpression, .caseInsensitive])
                    .replacingOccurrences(of: "<script[^>]*>.*?</script>", with: " ", options: [.regularExpression, .caseInsensitive])
                    .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
                    .replacingOccurrences(of: "&nbsp;", with: " ")
                    .replacingOccurrences(of: "&quot;", with: "\"")
                    .replacingOccurrences(of: "&#39;", with: "'")
                
                // Gemini'ye göndermek üzere gereksiz yükü azaltıyoruz (İlk 25.000 karakter, oldukça yeterli)
                return String(text.prefix(25000))
            }
        } catch {
            return ""
        }
        return ""
    }
    
    func summarize(articleText: String, articleUrl: String, targetLanguage: String) async throws -> String {
        let apiKey = KeychainManager.shared.loadString(key: "geminiAPIKey") ?? ""
        if apiKey.trimmingCharacters(in: .whitespaces).isEmpty {
            throw NSError(domain: "AIService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Özetleme yapabilmek için lütfen 'Ayarlar' sekmesinden ücretsiz Google Gemini API Anahtarınızı giriniz."])
        }
        
        // API anahtarı formatını doğrula (boş veya çok kısa anahtarları reddet)
        if apiKey.count < 10 {
            throw NSError(domain: "AIService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Geçersiz API anahtarı. Lütfen 'Ayarlar' sekmesinden geçerli bir Google Gemini API anahtarı girin."])
        }
        
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Rate limiting: gemini-2.5-flash free tier 10 RPM sınırını aşmamak için
        let elapsed = Date().timeIntervalSince(lastRequestDate)
        if elapsed < minRequestInterval {
            let delay = minRequestInterval - elapsed
            print("[GeminiService] Rate limit: \(String(format: "%.1f", delay))s bekleniyor...")
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        lastRequestDate = Date()

        // Sitenin gerçek verisini çekiyoruz
        let websiteContent = await fetchWebpageText(url: articleUrl)
        
        let prompt = """
        Aşağıdaki haberi detaylıca incele ve hedef dil olan '\(targetLanguage)' diline çok kapsamlı bir özet çıkar. 
        Mümkün olduğunca detay ver, özet metni en az 2 veya 3 paragraftan oluşsun. Ayrıca haberin en can alıcı 3 noktasını maddeler (bullet points) halinde en sonda vurgula.
        Sadece doğrudan haberi ve analizi ver, hiçbir karşılama mesajı veya kişisel yorum ekleme.
        
        Kısa Haber Başlığı/Açıklaması:
        \(articleText)
        
        Haberin Kendi Sitesinden Kazınan Tam Metni (JS ve reklam kodlarını görmezden gel ve içinden ana haberi bul):
        \(websiteContent)
        """
        
        let parameters: [String: Any] = [
            "contents": [ [ "parts": [ ["text": prompt] ] ] ],
            "generationConfig": [ "temperature": 0.4, "maxOutputTokens": 8192 ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        
        return try await performGeminiRequest(request: request)
    }
    
    private func performGeminiRequest(request: URLRequest, attempt: Int = 1) async throws -> String {
        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500

        guard statusCode == 200 else {
            let rawBody = String(data: data, encoding: .utf8) ?? "(binary response)"
            print("[GeminiService] HTTP \(statusCode) hatası. Response body:\n\(rawBody)")

            let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let rawMessage = (errorJson?["error"] as? [String: Any])?["message"] as? String ?? ""
            let isRateLimit = statusCode == 429 || rawMessage.lowercased().contains("quota") || rawMessage.lowercased().contains("rate")

            // İlk 429'da 5 saniye bekle ve otomatik tekrar dene
            if isRateLimit && attempt == 1 {
                try await Task.sleep(nanoseconds: 5_000_000_000)
                return try await performGeminiRequest(request: request, attempt: 2)
            }

            let errorMessage: String
            if isRateLimit {
                errorMessage = "API istek limitine ulaşıldı (ücretsiz planda dakikada maks. 10 istek). Lütfen 1 dakika bekleyip tekrar deneyin."
            } else if statusCode == 401 || statusCode == 403 {
                errorMessage = "API anahtarı geçersiz veya yetkisiz. Lütfen Ayarlar'dan anahtarınızı kontrol edin."
            } else {
                errorMessage = rawMessage.isEmpty ? "Google Gemini sunucusundan geçersiz yanıt alındı (\(statusCode))." : rawMessage
            }

            throw NSError(domain: "AIService", code: statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let candidates = json?["candidates"] as? [[String: Any]],
           let firstCandidate = candidates.first,
           let content = firstCandidate["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]],
           let firstPartText = parts.first?["text"] as? String {
            return firstPartText.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        throw URLError(.cannotParseResponse)
    }
}
