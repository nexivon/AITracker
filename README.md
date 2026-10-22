# AITracker

AI destekli haber takip ve özetleme uygulaması. Haberleri otomatik olarak çeker, Google Gemini API ile özetler ve sesli okuma özelliği sunar.

## Özellikler

- Güncel haberleri otomatik çekme
- Google Gemini AI ile akıllı haber özetleme
- Sesli haber okuma (Text-to-Speech)
- Haber kaydetme ve favoriler
- Güvenli API anahtarı yönetimi (Keychain)
- Temiz ve modern SwiftUI arayüzü

## Proje Yapısı

```
AITracker/
├── AITrackerApp.swift          # Uygulama giriş noktası
├── ContentView.swift           # Ana görünüm
├── Models/
│   ├── Article.swift           # Haber veri modeli
│   └── Summary.swift           # Özet veri modeli
├── Views/
│   ├── HomeView.swift          # Ana sayfa
│   ├── DetailView.swift        # Haber detay sayfası
│   ├── SavedNewsView.swift     # Kaydedilen haberler
│   └── SettingsView.swift      # Ayarlar
├── ViewModels/
│   └── NewsViewModel.swift     # Haber iş mantığı
└── Services/
    ├── AIService.swift         # AI servis katmanı
    ├── GeminiService.swift     # Google Gemini API entegrasyonu
    ├── NewsFetchService.swift  # Haber çekme servisi
    ├── SpeechCoordinator.swift # Sesli okuma koordinatörü
    └── KeychainManager.swift   # API anahtarı güvenli depolama
```

## Gereksinimler

- iOS 17.0+
- Xcode 15.0+
- Google Gemini API anahtarı

## Kurulum

1. Projeyi klonlayın:
   ```bash
   git clone https://github.com/nexivon/AITracker.git
   ```
2. Xcode ile `AITracker.xcodeproj` dosyasını açın.
3. Ayarlar sayfasından Gemini API anahtarınızı girin.
4. Projeyi çalıştırın.

## Teknolojiler

- **SwiftUI** — Modern deklaratif UI framework
- **Google Gemini API** — AI destekli haber özetleme
- **AVFoundation** — Sesli okuma (TTS)
- **Keychain Services** — Güvenli veri depolama
- **MVVM** — Mimari tasarım deseni

## Lisans

MIT License
