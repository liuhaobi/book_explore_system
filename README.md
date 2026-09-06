# book_explore_system

书籍抓取、存储与阅读系统。

## 目录规划

- `app/`：Flutter 客户端，支持移动端并可扩展到桌面端和 Web。
- `pc/`：PC 端，预留目录。
- `backend/`：业务 API、用户、书籍、阅读进度和存储服务，预留目录。
- `crawler/`：书籍来源适配、抓取任务和内容清洗，预留目录。

## 当前状态

`app/` 已导入现有 Flutter 项目。运行前进入该目录执行：

```bash
cd app
flutter pub get
flutter run
```

原 Flutter 工程中的构建缓存、本机路径配置和环境变量文件未导入仓库。
