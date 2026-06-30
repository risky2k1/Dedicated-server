# Valheim Wiki

Wiki tài liệu cho Valheim Dedicated Server, xây bằng [Docusaurus](https://docusaurus.io/).

## Yêu cầu

- Node.js >= 20
- [pnpm](https://pnpm.io/)

## Cài đặt

```bash
pnpm install
```

## Chạy local

```bash
pnpm start
```

Mở http://localhost:3000 — thay đổi trong `docs/` được reload tự động.

## Build production

```bash
pnpm build
pnpm serve
```

## Thêm tài liệu

Tạo file `.md` hoặc `.mdx` trong `docs/`. Sidebar tự sinh theo cấu trúc thư mục.
