#!/usr/bin/env bash
set -e

echo "=========================================="
echo " 📖 إتقان • تشغيل تطبيق فلاتر (Itqan Quran) "
echo "=========================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLUTTER_DIR="$SCRIPT_DIR/flutter_app"

if [ ! -d "$FLUTTER_DIR" ]; then
    echo "❌ Error: flutter_app directory not found at $FLUTTER_DIR"
    exit 1
fi

cd "$FLUTTER_DIR"
echo "📦 جاري تثبيت الحزم (flutter pub get)..."
flutter pub get

echo "🚀 جاري تشغيل تطبيق فلاتر..."
flutter run "$@"
