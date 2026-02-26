#!/bin/bash
set -e

cd "$(dirname "$0")/ClaudeWatch"

echo "⚙ 生成 Xcode 项目..."
xcodegen generate -q

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
