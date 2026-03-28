#!/usr/bin/env python3
import os
import sys
import json
import requests

SECRET_PATH = "/run/secrets/groq_api_key"
OUTPUT_PATH = "/var/www/html/magic_site/index.html"

PROMPT_GENERATE = """You are an award-winning web designer.

Create a visually stunning, highly polished single HTML landing page.

ART DIRECTION:
- Futuristic cinematic interface (inspired by sci-fi like Interstellar / Tron)
- Dark immersive background with glowing gradients (deep purple, electric blue, neon accents)
- Glassmorphism UI (blur, transparency, layered depth)
- Strong typography (bold, large, dramatic hierarchy)
- Smooth CSS animations (floating, glowing, subtle motion)

STRUCTURE:
1. HERO
   - Title: INCEPTION
   - Tagline: "Build your infrastructure. Dive deeper."
   - Animated gradient background
   - Centered layout, very impactful

2. FEATURES
   - Explain Docker stack (Nginx, WordPress, MariaDB)
   - Use modern cards with hover effects
   - Each card should feel interactive (elevation, glow)

3. TECH STACK
   - Stylish badges (Docker, Nginx, WordPress, MariaDB)
   - Responsive grid layout

4. FOOTER
   - Minimal, elegant, subtle glow

TECHNICAL REQUIREMENTS:
- cette ligne doit apparaitre : <title>INCEPTION</title>
- Pure HTML + CSS only
- No JavaScript
- No external resources (no CDN, no fonts)
- Everything in ONE file
- All styles inside <style>

ADVANCED CSS:
- gradients
- animations (@keyframes)
- flexbox/grid
- pseudo-elements
- backdrop-filter (glass effect)

IMPORTANT:
- This must look like a premium Awwwards-level landing page
- Avoid generic or basic design
- Add depth, spacing, and visual hierarchy

OUTPUT:
Return ONLY raw HTML starting with <!DOCTYPE html>
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


def call_groq(api_key: str, prompt: str) -> str:
    url = "https://api.groq.com/openai/v1/chat/completions"
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }
    payload = {
        "model": "llama-3.3-70b-versatile",
        "max_tokens": 4096,
        "temperature": 0.9,
        "messages": [{"role": "user", "content": prompt}],
    }

    resp = requests.post(url, headers=headers, json=payload, timeout=60)

    if resp.status_code != 200:
        print(f"ERROR {resp.status_code}: {resp.text}", file=sys.stderr)
        sys.exit(1)

    return resp.json()["choices"][0]["message"]["content"]

def improve_design(api_key: str, html: str) -> str:
    prompt = f"""
You are a senior frontend designer.

Improve this HTML page to make it visually stunning and modern.

FOCUS:
- Better spacing and layout
- Stronger typography hierarchy
- More polished colors and gradients
- Add smooth animations
- Enhance glassmorphism effects
- Make it feel premium and futuristic

CONSTRAINTS:
- Keep pure HTML + CSS
- Keep single file
- Do not add JavaScript

Return ONLY the improved HTML.

HTML:
{html}
"""
    return call_groq(api_key, prompt)

def polish_html(api_key: str, html: str) -> str:
    prompt = f"""
Clean and refine this HTML page.

GOALS:
- Fix any structural issues
- Ensure valid HTML5
- Improve readability
- Optimize CSS
- Remove redundancies

Do NOT simplify design.
Do NOT remove animations.

Return ONLY final HTML.

HTML:
{html}
"""
    return call_groq(api_key, prompt)

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

    print("[1/3] Generating base...", flush=True)
    html = call_groq(api_key, PROMPT_GENERATE)
    html = clean_html(html)

    print("[2/3] Improving design...", flush=True)
    html = improve_design(api_key, html)
    html = clean_html(html)

    print("[3/3] Polishing...", flush=True)
    html = polish_html(api_key, html)
    html = clean_html(html)

    write_output(html)

    print("[llm-gen] Done.", flush=True)
