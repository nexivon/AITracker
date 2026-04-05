import SwiftUI
import AVFoundation

struct DetailView: View {
    @ObservedObject var viewModel: NewsViewModel
    let article: Article
    
    @State private var summary: Summary?
    @State private var isLoadingSummary = false
    @State private var summaryError: String?
    
    // Sesli Okuma
    @StateObject private var speechCoordinator = SpeechCoordinator()
    
    var currentArticle: Article {
        viewModel.articles.first(where: { $0.id == article.id }) ?? article
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Image
                ZStack(alignment: .bottomLeading) {
                    if let imageUrlStr = currentArticle.imageUrl, let url = URL(string: imageUrlStr) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image.resizable().aspectRatio(contentMode: .fill)
                            } else {
                                Color.gray.opacity(0.3)
                            }
                        }
                        .frame(height: 220)
                        .clipped()
                        .cornerRadius(12)
                    } else {
                        LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                            .frame(height: 220)
                            .cornerRadius(12)
                    }
                    
                    Text(currentArticle.source)
                        .font(.caption)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.purple)
                        .cornerRadius(6)
                        .padding(12)
                }
                
                // Title and Date
                VStack(alignment: .leading, spacing: 10) {
                    Text(currentArticle.title)
                        .font(.system(.title2, design: .serif))
                        .fontWeight(.black)
                        .foregroundColor(.primary)
                    
                    Text(currentArticle.publishedAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Interaction Buttons
                HStack(spacing: 16) {
                    Button(action: {
                        withAnimation(.spring) {
                            viewModel.toggleSave(for: currentArticle)
                        }
                    }) {
                        HStack {
                            Image(systemName: currentArticle.isSaved ? "bookmark.fill" : "bookmark")
                            Text(currentArticle.isSaved ? "Kaydedildi" : "Kaydet")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                        .foregroundColor(currentArticle.isSaved ? .purple : .primary)
                    }
                    
                    if let url = URL(string: currentArticle.url) {
                        ShareLink(item: url, subject: Text(currentArticle.title), message: Text("Yapay Zeka Haberi: \(currentArticle.title)")) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Paylaş")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                            .foregroundColor(.primary)
                        }
                    }
                }
                
                // AI Summary Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "sparkles.square.filled.on.square")
                            .font(.title)
                            .foregroundColor(.purple)
                        
                        Text("AI Detaylı Analizi")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            
                        Spacer()
                        
                        // Sesli Dinle Butonu
                        if summary != nil {
                            Button(action: {
                                toggleSpeech()
                            }) {
                                Image(systemName: speechCoordinator.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2")
                                    .font(.title2)
                                    .foregroundColor(speechCoordinator.isSpeaking ? .orange : .purple)
                            }
                        }
                    }
                    
                    if isLoadingSummary {
                        HStack(spacing: 12) {
                            ProgressView()
                            Text("Yapay zeka detaylı analizi hazırlıyor...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.vertical, 20)
                    } else if let error = summaryError {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.callout)
                            
                            Button(action: {
                                Task { await loadSummary() }
                            }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Tekrar Dene")
                                        .fontWeight(.semibold)
                                }
                                .font(.caption)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.15))
                                .foregroundColor(.red)
                                .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                    } else if let summary = summary {
                        Text(summary.translatedSummary)
                            .font(.body)
                            .lineSpacing(6)
                            .padding(16)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                        // Orijinal Haberi Oku Butonu
                        if let url = URL(string: currentArticle.url) {
                            Link(destination: url) {
                                HStack {
                                    Text("Orijinal Haberi Oku")
                                        .fontWeight(.bold)
                                    Image(systemName: "arrow.up.right.square.fill")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .foregroundColor(.purple)
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                            }
                            .padding(.top, 10)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color(UIColor.systemBackground).opacity(0.95), for: .navigationBar)
        .task {
            // Önce senkron cache'e bak — API çağrısı ve loading state olmadan anlık döner
            if let cached = viewModel.getCachedSummary(for: currentArticle) {
                summary = cached
                return
            }
            await loadSummary()
        }
        .onDisappear {
            speechCoordinator.stop()
        }
    }
    
    private func loadSummary() async {
        guard summary == nil else { return }
        isLoadingSummary = true
        summaryError = nil
        do {
            summary = try await viewModel.getSummary(for: currentArticle)
        } catch {
            summaryError = error.localizedDescription
        }
        isLoadingSummary = false
    }
    
    private func toggleSpeech() {
        let textToRead = summary?.translatedSummary ?? currentArticle.description
        
        // Eğer çeviri dili Türkçe veya İngilizce vs ise o dile uygun ses ata
        // Basitlik için cihazın lokal sesini veya "tr-TR" atayalım, uygulamanın dinamik dili:
        let targetCode = viewModel.targetLanguage == "Türkçe" ? "tr-TR" : 
                         viewModel.targetLanguage == "İngilizce" ? "en-US" : 
                         viewModel.targetLanguage == "Almanca" ? "de-DE" :
                         viewModel.targetLanguage == "Fransızca" ? "fr-FR" : "tr-TR"
        
        speechCoordinator.speakToggle(text: textToRead, languageCode: targetCode)
    }
}
