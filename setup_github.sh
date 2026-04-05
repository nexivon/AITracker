#!/bin/bash
# AITracker - GitHub Setup Script
# Bu script'i Terminal'de çalıştır: bash setup_github.sh

set -e

echo "🔧 AITracker GitHub kurulumu başlıyor..."

# 1. Gereksiz dosyaları temizle
echo "🧹 Gereksiz dosyalar temizleniyor..."
rm -rf build/
rm -rf .claude/
rm -rf AITracker_Inceleme_Raporu.md
find . -name ".DS_Store" -delete 2>/dev/null || true

# 2. Eski .git varsa sil, yeniden başlat
echo "📦 Git repo oluşturuluyor..."
rm -rf .git
git init
git add .
git commit -m "Initial commit: AITracker - AI destekli haber takip ve özetleme uygulaması

- Google Gemini API ile akıllı haber özetleme
- Sesli haber okuma (Text-to-Speech)
- Haber kaydetme ve favoriler
- Güvenli API anahtarı yönetimi (Keychain)
- SwiftUI + MVVM mimarisi"

# 3. GitHub'a push
echo "🚀 GitHub repo oluşturuluyor..."
if command -v gh &> /dev/null; then
    gh repo create AITracker --public --source=. --push
    echo "✅ Tamamlandı! GitHub repo'nuz hazır."
else
    echo "⚠️  'gh' CLI bulunamadı."
    echo ""
    echo "Seçenek 1: gh CLI kur ve tekrar çalıştır:"
    echo "  brew install gh && gh auth login"
    echo ""
    echo "Seçenek 2: GitHub'da manuel repo oluştur, sonra:"
    echo "  git remote add origin https://github.com/KULLANICI_ADIN/AITracker.git"
    echo "  git branch -M main"
    echo "  git push -u origin main"
fi
