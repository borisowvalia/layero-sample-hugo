# layero-sample-hugo

SSG regression fixture for Hugo / Jekyll / Eleventy / Zola / MkDocs / Docusaurus i18n.

Pre-built артефакты в pretty-URL раскладке: каждый раздел — директория с
`index.html` внутри. Это позволяет тестировать edge nginx `@ssg_dir_fallback`
до того, как Hugo binary окажется в base image билдера.

## Layout

```
/                       → index.html
/about/                 → about/index.html
/blog/2026-01-hello/    → blog/2026-01-hello/index.html
/docs/ru/intro/         → docs/ru/intro/index.html
/docs/en/intro/         → docs/en/intro/index.html
/styles.css             → asset
/404.html               → custom 404 page (если nginx научится отдавать его)
```

## Regression test plan

После раскатки edge nginx с `@ssg_dir_fallback` патчем, для каждого URL ниже
должен прийти **корректный** контент:

| URL | Ожидание |
|-----|----------|
| `/` | hugo demo home |
| `/about/` | about page |
| `/about` | about page (без trailing slash) |
| `/docs/ru/intro/` | russian intro |
| `/blog/2026-01-hello/` | blog post |
| `/totally-missing` | корневой index.html (SPA fallback срабатывает после @ssg_dir_fallback) |

Без патча `/about/`, `/about`, `/docs/ru/intro/`, `/blog/2026-01-hello/`
вернут **корневой index.html** вместо ожидаемой страницы — это симптом бага,
из-за которого Hugo/Jekyll/etc были непригодны для платформенного хостинга.

## Деплой

```bash
cd fixtures/sample-spas/layero-sample-hugo
layero deploy --type static -y
```
