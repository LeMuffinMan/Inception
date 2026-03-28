#!/usr/bin/env python3
import os
import sys
import json
import requests

SECRET_PATH = "/run/secrets/groq_api_key"
OUTPUT_PATH = "/var/www/html/magic_site/index.html"

PROMPT_GENERATE = """You are a world-class creative developer and digital artist.

Your mission is to create an extraordinary, experimental, and visually breathtaking single-page web experience that showcases the full power of modern web technologies.

This is NOT a simple landing page.
This is a DEMO of what is possible on the web.

GOAL:
Create an immersive, interactive, and unforgettable experience that feels like a fusion between an artwork, a futuristic UI, and a tech demo.

CREATIVE FREEDOM:
- You are strongly encouraged to be bold, unconventional, and surprising
- Think: Awwwards-level, experimental web design, interactive art, sci-fi interface, or digital installation
- Avoid anything generic or template-like

TECHNOLOGIES:
- Use HTML, CSS, and JavaScript
- Everything must be contained in a SINGLE HTML file
- No external resources (no CDN, no fonts, no libraries)
- You may write complex JS if needed

VISUAL DIRECTION:
- Futuristic / cinematic / immersive
- Advanced use of:
  - gradients
  - lighting effects
  - particles or procedural visuals (canvas allowed)
  - glassmorphism / neumorphism / depth
  - dynamic layouts
- Strong typography hierarchy (even with system fonts)
- Use motion as a core design element

INTERACTIVITY (VERY IMPORTANT):
- The page MUST react to the user:
  - mouse movement
  - scrolling
  - clicks
  - hover effects
- Add micro-interactions everywhere
- Consider:
  - parallax effects
  - animated transitions
  - reactive UI
  - dynamic content

SECTIONS (flexible, you can reinvent them):
1. HERO EXPERIENCE
   - Immediate "wow effect"
   - Could be animated, interactive, or canvas-based
   - Title: INCEPTION
   - Tagline: "Build your infrastructure. Dive deeper."

2. INTERACTIVE SHOWCASE
   - Explain concepts (Docker, Nginx, WordPress, MariaDB)
   - But do it in a creative way (not boring cards)
   - Could be animated diagrams, interactive nodes, or visual storytelling

3. TECH EXPERIENCE
   - Present the stack as a dynamic system
   - Make it feel alive (connections, flows, animations)

4. PLAYGROUND / EXPERIMENT
   - Add something unexpected:
     - mini interactive simulation
     - generative visuals
     - reactive background
     - or a fun interaction

5. FOOTER
   - Minimal but stylish

ADVANCED FEATURES TO CONSIDER:
- Canvas animations (particles, stars, waves, etc.)
- Custom cursor
- Scroll-based animations
- Procedural generation
- 3D-like illusions using CSS
- Dynamic lighting or glow effects
- Sound is NOT allowed

QUALITY BAR:
- This should feel like a premium interactive experience
- Not a static website
- Not a template
- Not basic

CONSTRAINTS:
- Single HTML file
- All CSS inside <style>
- All JS inside <script>
- No external dependencies

OUTPUT:
Return ONLY raw HTML starting with <!DOCTYPE html>
Do not include explanations.
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
        "temperature": 0.8,
        "messages": [{"role": "user", "content": prompt}],
    }

    resp = requests.post(url, headers=headers, json=payload, timeout=60)

    if resp.status_code != 200:
        print(f"ERROR {resp.status_code}: {resp.text}", file=sys.stderr)
        sys.exit(1)

    return resp.json()["choices"][0]["message"]["content"]

def improve_design(api_key: str, html: str) -> str:
    prompt = f"""
You are a senior creative technologist and award-winning frontend engineer.

Your task is to dramatically enhance and evolve the following HTML experience.

This is NOT a simple refinement.
You must push the design, interactivity, and immersion significantly further.

GOALS:
- Transform the page into a high-end, experimental, interactive experience
- Increase the "wow factor"
- Make it feel alive, reactive, and premium

FOCUS AREAS:

1. VISUAL DESIGN
- Improve composition, spacing, and layout rhythm
- Upgrade color systems (richer gradients, lighting, glow)
- Enhance depth (layers, shadows, glass, perspective)
- Make typography more impactful and expressive

2. INTERACTIVITY (CRITICAL)
- Add or improve:
  - mouse tracking effects
  - hover animations
  - scroll-based animations
  - dynamic transitions
- Introduce delightful micro-interactions everywhere

3. MOTION & ANIMATION
- Add smooth, meaningful animations (not random)
- Use keyframes, transforms, opacity, parallax
- Make the UI feel fluid and responsive

4. JAVASCRIPT ENHANCEMENTS
- Improve logic and structure
- Add interactive systems if missing
- Consider:
  - canvas effects
  - reactive backgrounds
  - dynamic elements

5. EXPERIENCE DESIGN
- Improve flow between sections
- Make transitions feel intentional and cinematic
- Reinforce a strong visual identity

6. ORIGINALITY
- Remove anything generic or template-like
- Introduce unique elements or surprising interactions

CONSTRAINTS:
- Keep everything in a SINGLE HTML file
- No external libraries or CDNs
- Use only HTML, CSS, and JavaScript

IMPORTANT:
- Do NOT simplify
- Do NOT remove features unless replacing with better ones
- Prefer bold improvements over safe tweaks

OUTPUT:
Return ONLY the improved HTML starting with <!DOCTYPE html>
No explanations.

HTML:
{html}
"""
    return call_groq(api_key, prompt)

def polish_html(api_key: str, html: str) -> str:
    prompt = f"""
You are an expert frontend architect and code quality specialist.

Your task is to refine, stabilize, and perfect the following HTML experience WITHOUT reducing its visual or interactive richness.

GOALS:
- Ensure production-level quality
- Improve structure, clarity, and maintainability
- Fix any hidden issues

FOCUS:

1. HTML QUALITY
- Ensure valid, clean HTML5 structure
- Improve semantic organization where possible
- Fix nesting or structural inconsistencies

2. CSS OPTIMIZATION
- Remove redundancies and conflicts
- Improve organization and readability
- Ensure consistent naming and structure
- Optimize animations for smooth performance

3. JAVASCRIPT QUALITY
- Clean and organize the code
- Remove unnecessary complexity
- Improve performance and readability
- Avoid global pollution when possible
- Ensure interactions are smooth and bug-free

4. PERFORMANCE
- Avoid unnecessary reflows/repaints
- Optimize animations (prefer transform/opacity)
- Ensure smooth experience on most devices

5. CONSISTENCY
- Harmonize spacing, colors, animation timing
- Ensure visual coherence across sections

6. ROBUSTNESS
- Fix edge cases or fragile logic
- Ensure the page works without errors

IMPORTANT:
- DO NOT downgrade the design
- DO NOT remove animations or interactivity
- DO NOT simplify the experience

CONSTRAINTS:
- Keep everything in a SINGLE HTML file
- No external dependencies

OUTPUT:
Return ONLY the final HTML starting with <!DOCTYPE html>
No explanations.

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
