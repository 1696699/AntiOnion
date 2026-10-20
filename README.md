# AntiOnion

This repository configures a Codespace for Tor-routed shell requests and installs Tor Browser for manual use when a graphical display is available.

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

Installing GTK and X11 libraries does not create a graphical display. A standard Codespace is headless, so using the browser window requires a separately configured remote desktop. The Tor research agent has shell access but no browser UI or browser-control tool; it can route specific shell requests through Tor, but cannot inspect or operate Tor Browser pages.

## Updating Versions

The pinned release version and signing-key fingerprints are in both `.devcontainer/install-tor-expert-bundle.sh` and `.devcontainer/install-tor-browser.sh`. Update these deliberately when adopting a new release, and verify its official Tor signature details before changing the pins.
