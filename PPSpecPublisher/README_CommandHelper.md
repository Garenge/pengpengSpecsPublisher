# CommandHelper 端口检查和自动启动功能

## 功能说明

这个项目现在包含了自动端口检查和进程管理功能，确保CommandHelper能够正常运行。

### 主要功能

1. **端口检查**: 在启动CommandHelper之前，自动检查端口12345是否被占用
2. **进程杀死**: 如果端口被占用，自动查找并杀死占用该端口的进程
3. **用户友好提示**: 当CommandHelper未启动时，提供直观的启动指导

## 实现细节

### CommandHelper (main.m)

在`CommandHelper/main.m`中添加了以下功能：

- `isPortOccupied:` - 检查指定端口是否被占用
- `killProcessesUsingPort:` - 杀死占用指定端口的进程
- 在初始化时自动调用端口检查和进程杀死功能

### CommandClient (CommandClient.m)

在`CommandClient.m`中添加了以下功能：

- `showHelperStartupInstructions` - 显示启动说明
- `openHelperFolder` - 打开CommandHelper所在文件夹
- `getHelperPath` - 获取CommandHelper路径
- 连接失败时显示用户友好的提示对话框

### AppDelegate (AppDelegate.m)

在`AppDelegate.m`中添加了：

- CommandClient的初始化
- 应用启动时自动检查CommandHelper连接

## 使用方法

1. **正常使用**: 直接运行应用，系统会自动检查CommandHelper连接
2. **手动测试**: 运行测试脚本 `test_port_check.sh` 来验证端口检查功能

## 测试

运行测试脚本：

```bash
cd PPSpecPublisher
./test_port_check.sh
```

这个脚本会：
1. 检查端口12345的当前状态
2. 启动一个测试进程占用端口12345
3. 验证端口被占用
4. 杀死测试进程
5. 验证端口被释放

## 工作流程

1. **应用启动** → AppDelegate初始化CommandClient
2. **连接尝试** → CommandClient尝试连接端口12345
3. **连接失败** → 显示对话框，提供"打开文件夹"选项
4. **用户操作** → 用户点击"打开文件夹"，双击CommandHelper启动
5. **重试连接** → 用户点击"重试连接"，成功连接到CommandHelper
6. **连接断开** → 自动重连机制

## 日志输出

系统会输出详细的日志信息：

- 🔍 端口检查状态
- ⚠️ 端口被占用警告
- 🔫 进程杀死信息
- ✅ 成功操作确认
- ❌ 错误信息
- 📋 CommandHelper启动说明

## 注意事项

1. **权限要求**: 应用需要权限来杀死其他进程
2. **macOS权限**: 可能需要授予应用"完全磁盘访问权限"
3. **端口号**: 当前硬编码为12345，如需修改请同时修改相关文件
4. **路径问题**: CommandHelper路径获取已优化，支持多种路径查找方式

## 故障排除

### 常见问题

1. **连接失败**: 确保CommandHelper已经启动
2. **权限问题**: 确保应用有网络访问权限
3. **路径问题**: 确保CommandHelper文件存在于正确位置

### 解决步骤

1. 运行应用
2. 如果显示"需要启动CommandHelper"对话框
3. 点击"打开文件夹"按钮
4. 双击CommandHelper文件启动
5. 回到应用，点击"重试连接" 