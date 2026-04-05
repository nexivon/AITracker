import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: NewsViewModel
    @Environment(\.dismiss) var dismiss
    
    // Kullanıcının Gemini anahtarını güvenli şekilde saklamak için AppStorage yerine Keychain kullanıyoruz
    @State private var apiKey: String = KeychainManager.shared.loadString(key: "geminiAPIKey") ?? ""
    
    let languages = ["Türkçe", "İngilizce", "Almanca", "Fransızca", "İspanyolca", "Rusça", "Arapça"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Zaman Aralığı")) {
                    Picker("Haber Aralığı Seç", selection: $viewModel.selectedTimeRange) {
                        ForEach(TimeRange.allCases) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Özet Dili"), footer: Text("Yapay zeka haberleri Google News'ten (Genelde İngilizce) çekip seçtiğiniz bu dile çevirecektir.")) {
                    Picker("Dil Seç", selection: $viewModel.targetLanguage) {
                        ForEach(languages, id: \.self) { lang in
                            Text(lang).tag(lang)
                        }
                    }
                }
                
                Section(header: Text("Yapay Zeka (Google Gemini) Ayarları"), footer: Text("Haberleri profesyonelce özetlemek ve çevirmek için Google'ın ücretsiz Gemini altyapısı kullanılır. Lütfen aistudio.google.com üzerinden aldığınız API Anahtarını girin. Bu anahtar sadece kendi telefonunuzda şifreli (Keychain) saklanır, hiçbir sunucuya gönderilmez.")) {
                    SecureField("AIzaSy...", text: $apiKey)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onChange(of: apiKey) { newValue in
                            if newValue.trimmingCharacters(in: .whitespaces).isEmpty {
                                KeychainManager.shared.delete(key: "geminiAPIKey")
                            } else {
                                KeychainManager.shared.saveString(key: "geminiAPIKey", value: newValue)
                            }
                        }
                }
            }
            .navigationTitle("Ayarlar")
            .navigationBarItems(trailing: Button("Tamam") {
                dismiss()
            })
        }
    }
}

#Preview {
    SettingsView(viewModel: NewsViewModel())
}
