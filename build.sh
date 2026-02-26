#!/bin/bash
set -e

cd "$(dirname "$0")/ClaudeWatch"

echo "⚙ 生成 Xcode 项目..."
xcodegen generate -q

if [ "$1" = "release" ]; then
    # 分别构建 arm64 和 x86_64，生成两个 DMG
    echo "🔨 构建 arm64 (Apple Silicon)..."
    xcodebuild -project ClaudeWatch.xcodeproj -scheme ClaudeWatch -configuration Release \
      ARCHS=arm64 ONLY_ACTIVE_ARCH=NO \
      build CONFIGURATION_BUILD_DIR=./build/Release-arm64 2>&1 | grep -E "BUILD|error:" || true

    echo "🔨 构建 x86_64 (Intel)..."
    xcodebuild -project ClaudeWatch.xcodeproj -scheme ClaudeWatch -configuration Release \
      ARCHS=x86_64 ONLY_ACTIVE_ARCH=NO \
      build CONFIGURATION_BUILD_DIR=./build/Release-x86_64 2>&1 | grep -E "BUILD|error:" || true

    VERSION="${2:-1.0.0}"

    echo "📦 打包 DMG..."
    hdiutil create -volname "Claude Watch" -srcfolder ./build/Release-arm64/ClaudeWatch.app \
      -ov -format UDZO ./build/ClaudeWatch-${VERSION}-arm64.dmg
    hdiutil create -volname "Claude Watch" -srcfolder ./build/Release-x86_64/ClaudeWatch.app \
      -ov -format UDZO ./build/ClaudeWatch-${VERSION}-x86_64.dmg

    echo ""
    echo "✅ 打包完成:"
    ls -lh ./build/ClaudeWatch-${VERSION}-*.dmg
else
    # 本地开发：构建当前架构，安装到 Applications
    echo "🔨 构建 Release..."
    xcodebuild -project ClaudeWatch.xcodeproj -scheme ClaudeWatch -configuration Release \
      build CONFIGURATION_BUILD_DIR=./build/Release 2>&1 | grep -E "BUILD|error:" || true

    if [ ! -d "./build/Release/ClaudeWatch.app" ]; then
      echo "❌ 构建失败"
      exit 1
    fi

    echo "🛑 关闭旧进程..."
    pkill -x ClaudeWatch 2>/dev/null && sleep 0.5 || true

    echo "📦 安装到 /Applications..."
    rm -rf /Applications/ClaudeWatch.app
    cp -r ./build/Release/ClaudeWatch.app /Applications/

    echo "🚀 启动..."
    open /Applications/ClaudeWatch.app

    echo "✅ 完成"
fi
