#!/usr/bin/env python3
"""Capture a few in-browser screenshots of the Godot Web build (server must be running)."""

from pathlib import Path
import time

from playwright.sync_api import sync_playwright

URL = "http://127.0.0.1:8000/"
OUT = Path(__file__).resolve().parents[2] / "uploads" / "screenshots" / "ingame"
VIEWPORT = {"width": 1366, "height": 768}


def click_canvas(page, x: float, y: float) -> None:
    box = page.locator("#canvas").bounding_box()
    if not box:
        raise RuntimeError("game canvas not found")
    page.mouse.click(box["x"] + x, box["y"] + y)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page(viewport=VIEWPORT)
        page.goto(URL, wait_until="domcontentloaded", timeout=60_000)
        page.wait_for_selector("#canvas", timeout=120_000)
        # Godot wasm + pck load
        for _ in range(90):
            hidden = page.evaluate(
                """() => {
                    const s = document.getElementById('status');
                    return s && (s.style.visibility === 'hidden' || s.style.display === 'none');
                }"""
            )
            if hidden:
                break
            time.sleep(1)
        time.sleep(2)
        page.screenshot(path=str(OUT / "ingame-01-title-menu.png"), full_page=False)

        click_canvas(page, 246, 483)  # START GAME (design coords)
        time.sleep(2)
        page.screenshot(path=str(OUT / "ingame-02-story-or-prologue.png"), full_page=False)

        # Dismiss intro / advance if a modal is up (center-bottom)
        click_canvas(page, 683, 600)
        time.sleep(1.5)
        page.screenshot(path=str(OUT / "ingame-03-dungeon-explore.png"), full_page=False)

        browser.close()
    print(f"Saved screenshots under {OUT}")


if __name__ == "__main__":
    main()