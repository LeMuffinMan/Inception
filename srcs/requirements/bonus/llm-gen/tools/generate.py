#!/usr/bin/env python3
import os
import sys
import json
import requests

SECRET_PATH = "/run/secrets/groq_api_key"
OUTPUT_PATH = "/var/www/static/index.html"

PROMPT = """Generate a single self-contained HTML page.
Requirements:
- A creative, modern landing page for a 42 school project called "Inception"
- Dark theme, striking typography, smooth CSS animations
- Sections: hero (title + tagline), what it does (Docker stack explanation), tech stack badges
- Pure HTML + CSS only, no JavaScript frameworks, no external resources
- All styles must be in a <style> block inside <head>
- The page must work offline (no CDN links)
- Output ONLY the raw HTML, starting with <!DOCTYPE html>, no explanation, no markdown fences
"""


def read_secret() -> str:
    try:
        with open(SECRET_PATH) as f:
            return f.read().strip()
    except FileNotFoundError:
        key = os.environ.get("GROQ_API_KEY", "")
        if not key:
            print("[llm-gen] ERROR: no API key found in secret or env", file=sys.stderr)
            sys.exit(1)
        return key


def call_groq(api_key: str) -> str:
    url = "https://api.groq.com/openai/v1/chat/completions"
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }
    payload = {
        "model": "llama-3.3-70b-versatile",
        "max_tokens": 4096,
        "temperature": 0.8,
        "messages": [
            {
                "role": "user",
                "content": PROMPT,
            }
        ],
    }

    print("[llm-gen] Calling Groq API...", flush=True)
    resp = requests.post(url, headers=headers, json=payload, timeout=60)

    if resp.status_code != 200:
        print(f"[llm-gen] ERROR {resp.status_code}: {resp.text}", file=sys.stderr)
        sys.exit(1)

    data = resp.json()
    content = data["choices"][0]["message"]["content"]
    return content


def clean_html(raw: str) -> str:
    """Strip accidental markdown fences if the model added them."""
    raw = raw.strip()
    if raw.startswith("```"):
        lines = raw.splitlines()
        inner = lines[1:-1] if lines[-1].strip() == "```" else lines[1:]
        raw = "\n".join(inner)
    return raw


def write_output(html: str) -> None:
    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
    with open(OUTPUT_PATH, "w") as f:
        f.write(html)
    print(f"[llm-gen] Written to {OUTPUT_PATH}", flush=True)


if __name__ == "__main__":
    api_key = read_secret()
    raw = call_groq(api_key)
    html = clean_html(raw)
    write_output(html)
    print("[llm-gen] Done.", flush=True)
