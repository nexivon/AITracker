import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = NewsViewModel()
    @State private var showingSettings = false
    
    var filteredArticles: [Article] {
        if viewModel.searchText.isEmpty {
            return viewModel.articles
        } else {
            return viewModel.articles.filter { $0.title.localizedCaseInsensitiveContains(viewModel.searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Şık Arka Plan
                LinearGradient(colors: [Color(UIColor.systemBackground), Color("BackgroundGradient", bundle: nil).opacity(0.1) ], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Yapay Zeka Dünyası Taranıyor...")
                            .foregroundColor(.secondary)
                            .padding(.top, 16)
                            .font(.callout)
                    }
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text(error)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        Button(action: { Task { await viewModel.fetchNews() } }) {
                            Text("Tekrar Dene")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.purple)
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                } else if filteredArticles.isEmpty && !viewModel.searchText.isEmpty {
                    VStack {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("Haber bulunamadı.")
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 24) {
                            ForEach(filteredArticles) { article in
                                NavigationLink(value: article) {
                                    ArticleCardView(article: article, viewModel: viewModel)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await viewModel.fetchNews()
                    }
                }
            }
            .navigationTitle("AI Gündemi")
            .navigationDestination(for: Article.self) { article in
                DetailView(viewModel: viewModel, article: article)
            }
            .searchable(text: $viewModel.searchText, prompt: "Makale veya kelime ara...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        NavigationLink(destination: SavedNewsView(viewModel: viewModel)) {
                            Image(systemName: "bookmark.fill")
                                .font(.headline)
                                .foregroundColor(.purple)
                                .padding(8)
                                .background(Color.purple.opacity(0.1))
                                .clipShape(Circle())
                        }
                        
                        Button(action: { showingSettings = true }) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.headline)
                                .foregroundColor(.purple)
                                .padding(8)
                                .background(Color.purple.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(viewModel: viewModel)
            }
            .task {
                if viewModel.articles.isEmpty {
                    await viewModel.fetchNews()
                }
            }
        }
    }
}

struct ArticleCardView: View {
    let article: Article
    @ObservedObject var viewModel: NewsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Görsel Alanı (Google News genelde resim vermez, bu yüzden şık fallback)
            ZStack(alignment: .bottomLeading) {
                if let imageUrlStr = article.imageUrl, let url = URL(string: imageUrlStr) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            FallbackGradient()
                        }
                    }
                } else {
                    FallbackGradient()
                }
                
                // Kapak Üzeri Zaman Damgası
                Text(article.publishedAt, style: .time)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(6)
                    .background(.ultraThinMaterial)
                    .cornerRadius(6)
                    .padding(12)
            }
            .frame(height: 160)
            .clipped()
            
            // İçerik Alanı
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(article.source.uppercased())
                        .font(.caption)
                        .fontWeight(.black)
                        .foregroundColor(.purple)
                    Spacer()
                }
                
                Text(article.title)
                    .font(.headline)
                    .fontWeight(.heavy)
                    .foregroundColor(.primary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.purple)
                    Text("Detaylı Okuma")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring) {
                            viewModel.toggleSave(for: article)
                        }
                    }) {
                        Image(systemName: article.isSaved ? "bookmark.fill" : "bookmark")
                            .foregroundColor(article.isSaved ? .purple : .gray.opacity(0.6))
                            .font(.system(size: 22))
                    }
                }
                .padding(.top, 6)
            }
            .padding(16)
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 8)
    }
}

struct FallbackGradient: View {
    var body: some View {
        LinearGradient(colors: [Color.purple.opacity(0.7), Color.indigo.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

#Preview {
    HomeView()
}
