#!/usr/bin/env bash
# Smoke-test для @ssg_dir_fallback патча в edge nginx.
#
# Usage:
#   ./smoke.sh https://<slug>.layero.ru
#   ./smoke.sh https://<slug>-<sha7>.preview.layero.ru
#
# Каждая проверка: ожидается 200 + контент с конкретным data-page маркером.
# Без патча проверки 2–5 fail'ятся (отдают корневой index.html через @spa_fallback).

set -u

BASE="${1:-}"
if [[ -z "$BASE" ]]; then
    echo "usage: $0 <base_url>" >&2
    exit 2
fi
BASE="${BASE%/}"

pass=0
fail=0

check() {
    local label="$1" url="$2" marker="$3"
    local body
    body="$(curl -fsS -L --max-time 10 "$url" 2>/dev/null || true)"
    if [[ -z "$body" ]]; then
        printf "  ✗ %-40s — empty response from %s\n" "$label" "$url"
        fail=$((fail + 1))
        return
    fi
    if grep -qF "$marker" <<<"$body"; then
        printf "  ✓ %-40s\n" "$label"
        pass=$((pass + 1))
    else
        printf "  ✗ %-40s — '%s' not found in response from %s\n" "$label" "$marker" "$url"
        fail=$((fail + 1))
    fi
}

echo "Smoke against $BASE"

# Positive: корневой index.html отдан напрямую.
check "root /"                       "$BASE/"                      'data-page="home"'

# Critical: SSG pretty URL с trailing slash — это was failing pre-patch.
check "ssg /about/ (trailing slash)" "$BASE/about/"                'data-page="about"'
check "ssg /about (no slash)"        "$BASE/about"                 'data-page="about"'

# Nested directory routing.
check "nested /blog/2026-01-hello/"  "$BASE/blog/2026-01-hello/"   'data-page="blog-post"'
check "deeply nested /docs/ru/intro/" "$BASE/docs/ru/intro/"        'data-page="docs-ru-intro"'
check "deeply nested /docs/en/intro/" "$BASE/docs/en/intro/"        'data-page="docs-en-intro"'

# Static asset на root — должен отдаваться напрямую (без fallback).
check "static asset /styles.css"     "$BASE/styles.css"            ':root'

# SPA-fallback safety net: несуществующая страница → корневой index.html.
# Это ожидаемое поведение (как у Netlify/Vercel для SPA-репо).
check "spa fallback /totally-missing" "$BASE/totally-missing"      'data-page="home"'

echo
echo "passed: $pass, failed: $fail"
[[ $fail -eq 0 ]] && exit 0 || exit 1
