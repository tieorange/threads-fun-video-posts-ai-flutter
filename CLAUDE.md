# 🤖 Claude Code Context — Funny Threads AI

> **Reference:** See [AGENTS.md](./AGENTS.md) for complete project documentation
> **Last Updated:** 2026-02-27
> **Project Status:** MVP Complete ✅

---

## 🎯 Quick Reference

| Field | Value |
|-------|-------|
| **Product** | Funny Threads AI (ThreadGen AI) |
| **Stack** | Flutter Web + Node.js/Express/TypeScript |
| **Architecture** | Clean Architecture (3-layer) |
| **Key Rule** | No AI API integration — manual copy/paste workflow |

---

## 📁 Key File Locations

### Backend (Node.js/Express)
```
apps/backend/
├── src/main.ts                    # Entry point
├── src/infrastructure/express/app.ts  # DI wiring
├── src/features/video_processing/
│   ├── domain/usecases/           # Business logic
│   ├── data/datasources/          # yt-dlp, FFmpeg
│   └── presentation/controllers/  # API endpoints
└── storage/                       # captions/, videos/, clips/, jobs/
```

### Frontend (Flutter)
```
apps/frontend/
├── lib/main.dart                  # Entry point
├── lib/core/di/injection.dart     # GetIt wiring
├── lib/features/video_processing/
│   ├── domain/usecases/           # Business logic
│   ├── data/datasources/          # Dio HTTP client
│   └── presentation/cubits/       # State management
└── lib/i18n/                      # Localization
```

---

## ⚠️ Critical Constraints

1. **No AI API integration** — manual copy/paste only
2. **Strict TypeScript** — no `any` allowed
3. **Material Design 3** — no custom theming
4. **Clean architecture** — 3-layer (Domain → Data → Presentation)
5. **Local filesystem** — no database for MVP
6. **Manual DTOs** — no codegen for video_processing
7. **Dart 3 sealed classes** — not equatable

---

## 🔗 Full Documentation

**👉 [AGENTS.md](./AGENTS.md) contains:**
- Complete project structure
- API endpoints with examples
- Architecture rules
- Tech stack details
- Error handling patterns
- Common tasks (adding features, endpoints, pages)
- Debugging tips
- Code quality checklist
- Quick start guide

---

> **For Claude Code:** This file exists because Claude Code auto-reads `CLAUDE.md`. The full documentation is in `AGENTS.md` to maintain a single source of truth while supporting multiple AI agent tools.
