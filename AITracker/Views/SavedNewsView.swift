import SwiftUI

struct SavedNewsView: View {
    @ObservedObject var viewModel: NewsViewModel
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(UIColor.systemBackground), Color("BackgroundGradient", bundle: nil).opacity(0.1) ], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            if viewModel.savedArticlesList.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bookmark.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("Henüz kaydedilmiş bir haber yok.")
                        .foregroundColor(.secondary)
                        .font(.headline)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 24) {
                        ForEach(viewModel.savedArticlesList) { article in
                            NavigationLink(value: article) {
                                ArticleCardView(article: article, viewModel: viewModel)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Kaydedilenler")
        .navigationBarTitleDisplayMode(.inline)
    }
}
