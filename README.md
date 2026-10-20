# AntiOnion

This repository configures a Codespace for Tor-routed shell requests and installs Tor Browser with an optional, password-protected remote desktop.

## Codespace Setup

Create the Codespace using the repository's Dev Container configuration in `.devcontainer/`. During creation it installs required Linux runtime libraries, then downloads Tor Expert Bundle 15.0.25 and Tor Browser 15.0.25 into:

```text
~/.local/share/anti-onion/
```

The setup scripts verify each archive's detached signature against pinned Tor Browser Developers signing-key fingerprints before extracting it. The downloaded browser and Tor binaries are not stored in Git.

To apply dependency or Dev Container configuration changes to an existing Codespace, run **Codespaces: Rebuild Container** from the VS Code Command Palette.

## Tor-Routed Shell Requests

Start the Tor client, verify its route, and stop it when finished:

```bash
bash .devcontainer/tor-proxy.sh start
bash .devcontainer/tor-proxy.sh check
curl --socks5-hostname 127.0.0.1:19050 https://check.torproject.org/api/ip
bash .devcontainer/tor-proxy.sh stop
```

The SOCKS listener is bound to `127.0.0.1`. Only commands explicitly configured to use it go through Tor; the Codespace's global network traffic is not redirected. `check` reports whether its own request was seen as coming from a Tor exit node; it does not verify unrelated traffic.

## Tor Browser

When a graphical display is available, launch the installed browser with:

```bash
cd "$HOME/.local/share/anti-onion/tor-browser-15.0.25"
./Browser/start-tor-browser.desktop --detach
```

Installing GTK and X11 libraries does not create a graphical display. A standard Codespace is headless; use the optional remote desktop described below to open the browser. After approving the workspace MCP server and reloading VS Code, the Tor research agent can view screenshots and interact with that desktop.

## Updating Versions

The pinned release version and signing-key fingerprints are in both `.devcontainer/install-tor-expert-bundle.sh` and `.devcontainer/install-tor-browser.sh`. Update these deliberately when adopting a new release, and verify its official Tor signature details before changing the pins.

## Remote Desktop

The Dev Container includes XFCE, TigerVNC, and noVNC. The desktop is opt-in and is not started automatically. Set a VNC password in the Codespace terminal; VNC passwords are limited to 8 characters, so use a unique password:

```bash
mkdir -p "$HOME/.vnc"
vncpasswd "$HOME/.vnc/passwd"
chmod 600 "$HOME/.vnc/passwd"
```

Do not put this password in the repository or share it in chat. Start the desktop with:

```bash
bash .devcontainer/remote-desktop.sh start
```

Open the private forwarded **Tor Browser Remote Desktop** port 6080 in the VS Code **Ports** panel, visit `/vnc.html`, and enter your VNC password. Both the VNC server and noVNC proxy listen on loopback; Codespaces forwards the web port with private visibility.

Tor Browser is available from the XFCE applications menu. Stop the desktop when finished:

```bash
bash .devcontainer/remote-desktop.sh stop
```

This makes the browser visible to you. After approving the `tor-browser-desktop` MCP server in VS Code and reloading the workspace, the Tor research agent can request screenshots and interact with the desktop using bounded mouse, text, key, and scroll tools. The agent cannot access the VNC password; enter it only in noVNC. Do not use the desktop tools to enter credentials, recovery codes, or payment details. Confirm consequential actions such as form submissions or account changes before the agent performs them.
