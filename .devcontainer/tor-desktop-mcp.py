from __future__ import annotations

import io
import os

from mcp.server.fastmcp import FastMCP, Image


mcp = FastMCP("tor-browser-desktop")
ALLOWED_KEYS = {
    "enter", "tab", "escape", "space", "backspace", "delete", "home", "end",
    "pageup", "pagedown", "up", "down", "left", "right", "f5", "f6", "f11",
}


def get_desktop():
    if not os.environ.get("DISPLAY"):
        raise RuntimeError("No desktop display is configured. Start the private remote desktop first.")

    import pyautogui

    pyautogui.FAILSAFE = True
    pyautogui.PAUSE = 0.1
    try:
        pyautogui.size()
    except Exception as error:
        raise RuntimeError("The remote desktop display is not running or is not accessible.") from error
    return pyautogui


def validate_coordinates(x: int, y: int, desktop) -> None:
    width, height = desktop.size()
    if not (0 <= x < width and 0 <= y < height):
        raise ValueError(f"Coordinates must be within the {width}x{height} desktop.")


@mcp.tool()
def screenshot() -> Image:
    """Capture the current remote desktop as a PNG image."""
    get_desktop()
    import mss
    from PIL import Image as PillowImage

    with mss.mss() as capture:
        frame = capture.grab(capture.monitors[0])
    image = PillowImage.frombytes("RGB", frame.size, frame.rgb)
    buffer = io.BytesIO()
    image.save(buffer, format="PNG")
    return Image(data=buffer.getvalue(), format="png")


@mcp.tool()
def click(x: int, y: int, button: str = "left") -> str:
    """Click a screen coordinate using the left, middle, or right mouse button."""
    desktop = get_desktop()
    validate_coordinates(x, y, desktop)
    if button not in {"left", "middle", "right"}:
        raise ValueError("button must be left, middle, or right")
    desktop.click(x=x, y=y, button=button)
    return f"Clicked ({x}, {y}) with {button} button."


@mcp.tool()
def type_text(text: str) -> str:
    """Type non-sensitive text into the focused desktop application."""
    desktop = get_desktop()
    if len(text) > 2000:
        raise ValueError("Text input is limited to 2000 characters per call.")
    desktop.write(text, interval=0.01)
    return f"Typed {len(text)} characters."


@mcp.tool()
def press_key(key: str) -> str:
    """Press one navigation key: enter, tab, escape, space, arrows, or F5/F6/F11."""
    desktop = get_desktop()
    normalized_key = key.lower()
    if normalized_key not in ALLOWED_KEYS:
        raise ValueError(f"Unsupported key: {key}")
    desktop.press(normalized_key)
    return f"Pressed {normalized_key}."


@mcp.tool()
def scroll(clicks: int, x: int, y: int) -> str:
    """Scroll at a screen coordinate; positive clicks scroll up, negative down."""
    desktop = get_desktop()
    validate_coordinates(x, y, desktop)
    if not -50 <= clicks <= 50:
        raise ValueError("clicks must be between -50 and 50")
    desktop.moveTo(x, y)
    desktop.scroll(clicks)
    return f"Scrolled {clicks} clicks at ({x}, {y})."


if __name__ == "__main__":
    mcp.run(transport="stdio")