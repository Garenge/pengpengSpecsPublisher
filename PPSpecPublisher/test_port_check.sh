#!/bin/bash

echo "🧪 测试端口检查和进程杀死功能"

# 检查端口12345是否被占用
echo "1. 检查端口12345状态..."
lsof -i :12345

# 如果有进程占用端口，显示详细信息
if lsof -i :12345 > /dev/null 2>&1; then
    echo "⚠️  端口12345被占用，进程信息："
    lsof -i :12345
else
    echo "✅ 端口12345未被占用"
fi

echo ""
echo "2. 启动测试进程占用端口12345..."
# 启动一个简单的测试服务器占用端口12345
python3 -m http.server 12345 &
TEST_PID=$!
echo "测试进程PID: $TEST_PID"

# 等待一下让进程启动
sleep 2

echo ""
echo "3. 再次检查端口12345状态..."
lsof -i :12345

echo ""
echo "4. 杀死测试进程..."
kill -9 $TEST_PID

# 等待一下让进程完全退出
sleep 1

echo ""
echo "5. 最终检查端口12345状态..."
if lsof -i :12345 > /dev/null 2>&1; then
    echo "❌ 端口12345仍然被占用"
    lsof -i :12345
else
    echo "✅ 端口12345已成功释放"
fi

echo ""
echo "🎉 测试完成！" 