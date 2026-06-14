#!/usr/bin/env python3
# =============================================================================
#   Night Light GUI for Hyprland (hyprsunset)
#   Part of: CachyOS + HyDE Complete System Restorer
#   Repo:    https://github.com/omarahmed321/cachyos-restore
#
#   Two modes:
#     python3 nightlight-gui.py           → normal settings panel
#     python3 nightlight-gui.py --setup   → first-run wizard (used by
#                                           restore_my_setup.sh mid-install)
#
#   Installed to: ~/.local/share/bin/nightlight-gui.py
#   Launched via: Super + Alt + N  (Hyprland keybind)
#   Config saved: ~/.config/hypr/nightlight.conf
# =============================================================================

import gi
import subprocess
import os
import re
import sys
import threading

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Gtk, Adw, GLib, Gdk, Gio

HYPRLAND_CONF = os.path.expanduser("~/.config/hypr/hyprland.conf")
CONFIG_FILE   = os.path.expanduser("~/.config/hypr/nightlight.conf")

SETUP_MODE = "--setup" in sys.argv   # True when called from restore_my_setup.sh

TEMP_MIN     = 1000
TEMP_MAX     = 6500
TEMP_DEFAULT = 3500
GAMMA_MIN    = 10
GAMMA_MAX    = 100

CSS = """
/* ── Window / Card ──────────────────────────────────────────────────── */
window.nightlight-window { background-color: transparent; }

.nightlight-card {
    background: alpha(@window_bg_color, 0.95);
    border-radius: 24px;
    border: 1px solid alpha(@window_fg_color, 0.08);
    padding: 28px 24px 24px 24px;
    box-shadow: 0 12px 40px rgba(0, 0, 0, 0.45);
}

/* ── Setup-mode banner ──────────────────────────────────────────────── */
.setup-banner {
    background: linear-gradient(135deg, alpha(#ff9240, 0.12), alpha(#ff5722, 0.05));
    border-radius: 14px;
    border: 1px solid alpha(#ff9240, 0.25);
    padding: 14px 18px;
    margin-bottom: 20px;
}
.setup-banner-title {
    font-size: 13px;
    font-weight: 800;
    color: #ff9240;
    letter-spacing: 0.3px;
}
.setup-banner-body {
    font-size: 11px;
    opacity: 0.7;
    margin-top: 4px;
    line-height: 1.4;
}

/* ── Typography ─────────────────────────────────────────────────────── */
.header-icon    { font-size: 44px; margin-right: 4px; }
.title-label    { font-size: 24px; font-weight: 800; letter-spacing: -0.5px; }
.subtitle-label { font-size: 12px; opacity: 0.6; margin-top: -2px; }
.section-label  { font-size: 11px; font-weight: 800; letter-spacing: 1.5px;
                  color: @accent_color; opacity: 0.85; margin-top: 18px; margin-bottom: 8px; }
.value-badge    { font-size: 30px; font-weight: 900;
                  font-variant-numeric: tabular-nums; }
.unit-label     { font-size: 14px; opacity: 0.6; font-weight: 600;
                  margin-bottom: 4px; }
.desc-label     { font-size: 11px; opacity: 0.7; font-style: italic; }

/* ── Temperature colours ────────────────────────────────────────────── */
.temp-warm { color: #ff7043; }
.temp-mid  { color: #ffca28; }
.temp-cool { color: #29b6f6; }

/* ── Sliders ────────────────────────────────────────────────────────── */
scale {
    padding: 10px 0;
}

scale trough {
    border-radius: 8px;
    min-height: 14px;
    border: 1px solid alpha(@window_fg_color, 0.05);
    box-shadow: inset 0 1px 3px rgba(0, 0, 0, 0.2);
}

.temp-scale trough { 
    background: linear-gradient(to right, #ff3d00, #ff9100, #ffea00, #ffffff, #80d8ff, #29b6f6); 
}

.gamma-scale trough { 
    background: linear-gradient(to right, #1a1a1a, #555555, #aaaaaa, #ffffff); 
}

scale highlight {
    background: transparent;
    border: none;
    box-shadow: none;
}

scale slider {
    background-color: #ffffff;
    border: 3px solid @accent_color;
    border-radius: 50%;
    min-width: 20px;
    min-height: 20px;
    margin-top: -4px;
    margin-bottom: -4px;
    box-shadow: 0 3px 8px rgba(0, 0, 0, 0.45);
    transition: background-color 0.15s, border-color 0.15s, transform 0.1s;
}

scale slider:hover {
    background-color: #f5f5f5;
    border-color: @accent_bg_color;
    transform: scale(1.15);
}

scale slider:focus {
    border-color: @accent_bg_color;
}

scale slider:active {
    background-color: @accent_color;
    border-color: #ffffff;
    transform: scale(1.25);
    box-shadow: 0 1px 4px rgba(0, 0, 0, 0.3);
}

/* ── Preset grid buttons ────────────────────────────────────────────── */
.preset-btn {
    background-color: alpha(@window_fg_color, 0.04);
    border: 1px solid alpha(@window_fg_color, 0.08);
    border-radius: 12px;
    padding: 12px 8px;
    font-size: 13px;
    font-weight: 600;
    color: @window_fg_color;
    transition: background-color 0.2s, border-color 0.2s, transform 0.1s;
}

.preset-btn:hover {
    background-color: alpha(@window_fg_color, 0.08);
    border-color: alpha(@window_fg_color, 0.15);
    transform: translateY(-1px);
}

.preset-btn:active {
    background-color: alpha(@window_fg_color, 0.12);
    transform: translateY(1px);
}

.preset-btn.active-preset {
    background: linear-gradient(135deg, alpha(@accent_color, 0.25), alpha(@accent_color, 0.15));
    border: 2px solid @accent_color;
    color: @accent_color;
    font-weight: 800;
    box-shadow: 0 4px 12px alpha(@accent_color, 0.18);
}

/* ── Action buttons ─────────────────────────────────────────────────── */
.suggested-action {
    background: linear-gradient(135deg, @accent_bg_color, alpha(@accent_bg_color, 0.85));
    border-radius: 14px;
    padding: 14px 20px;
    font-size: 14px;
    font-weight: 800;
    color: @accent_fg_color;
    border: none;
    box-shadow: 0 4px 15px alpha(@accent_bg_color, 0.35);
    transition: background-color 0.2s, transform 0.1s, box-shadow 0.2s;
}

.suggested-action:hover {
    background: @accent_bg_color;
    box-shadow: 0 6px 20px alpha(@accent_bg_color, 0.45);
    transform: translateY(-1px);
}

.suggested-action:active {
    transform: translateY(1px);
    box-shadow: 0 2px 8px alpha(@accent_bg_color, 0.25);
}

.skip-btn {
    background-color: alpha(@window_fg_color, 0.04);
    border: 1px solid alpha(@window_fg_color, 0.08);
    border-radius: 14px;
    padding: 14px 20px;
    font-size: 13px;
    font-weight: 700;
    color: alpha(@window_fg_color, 0.8);
    transition: background-color 0.2s, border-color 0.2s, transform 0.1s;
}

.skip-btn:hover {
    background-color: alpha(@window_fg_color, 0.08);
    border-color: alpha(@window_fg_color, 0.15);
    transform: translateY(-1px);
}

.skip-btn:active {
    transform: translateY(1px);
}

.status-label {
    font-size: 12px;
    font-weight: 700;
    color: #4caf50;
    text-align: center;
}
"""

PRESETS = [
    # (label,           temp,  gamma, description)
    ("🌙  Night Mode",  2700,  100,   "Warm amber — perfect for late night"),
    ("🌆  Evening",     3200,  100,   "Soft warm tone for the evening"),
    ("🏠  Home Comfort",4000,  100,   "Balanced warm-neutral light"),
    ("☀️  Daytime",     5500,  100,   "Natural daylight color"),
    ("❄️  Cool Blue",   6500,  100,   "Crisp cool tone for focus"),
    ("🔅  Dim Night",   2700,   70,   "Dimmed warm — great for sleeping"),
]


# ── Config I/O ────────────────────────────────────────────────────────────────

def _read_conf():
    """Return (temp, gamma, enabled) from saved config or hyprland.conf."""
    if os.path.exists(CONFIG_FILE):
        try:
            txt = open(CONFIG_FILE).read()
            t = int(re.search(r"temperature=(\d+)", txt).group(1)) \
                if re.search(r"temperature=(\d+)", txt) else TEMP_DEFAULT
            g = int(re.search(r"gamma=(\d+)",       txt).group(1)) \
                if re.search(r"gamma=(\d+)",       txt) else GAMMA_MAX
            e = re.search(r"enabled=(\w+)", txt).group(1) == "true" \
                if re.search(r"enabled=(\w+)", txt) else True
            return t, g, e
        except Exception:
            pass
    try:
        txt = open(HYPRLAND_CONF).read()
        m = re.search(r"hyprsunset\s+-t\s+(\d+)", txt)
        return (int(m.group(1)) if m else TEMP_DEFAULT), GAMMA_MAX, True
    except Exception:
        return TEMP_DEFAULT, GAMMA_MAX, True


def _save_conf(t, g, e):
    """Write settings to nightlight.conf."""
    os.makedirs(os.path.dirname(CONFIG_FILE), exist_ok=True)
    with open(CONFIG_FILE, "w") as f:
        f.write(f"temperature={t}\ngamma={g}\n"
                f"enabled={'true' if e else 'false'}\n")


def _patch_hyprland(t, e):
    """Update the exec-once hyprsunset line in hyprland.conf."""
    try:
        txt = open(HYPRLAND_CONF).read()
        new_line = (f"exec-once = hyprsunset -t {t}" if e
                    else f"#exec-once = hyprsunset -t {t}  # DISABLED")
        txt = re.sub(r"#?exec-once = hyprsunset.*", new_line, txt)
        open(HYPRLAND_CONF, "w").write(txt)
    except Exception as ex:
        print(f"[nightlight] Warning: could not update hyprland.conf: {ex}")


def _apply_live(t, g, e):
    """Kill existing hyprsunset and restart with new settings."""
    subprocess.run(["pkill", "-x", "hyprsunset"], capture_output=True)
    if e:
        subprocess.Popen(
            ["hyprsunset", "-t", str(t), "-g", str(g)],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )


# ── Application ───────────────────────────────────────────────────────────────

class NightLightApp(Adw.Application):
    def __init__(self):
        super().__init__(
            application_id="com.hyde.nightlight",
            flags=Gio.ApplicationFlags.FLAGS_NONE,
        )
        self.connect("activate", self._on_activate)

    def _on_activate(self, app):
        win = NightLightWindow(application=app)
        win.present()


class NightLightWindow(Adw.ApplicationWindow):
    def __init__(self, **kw):
        super().__init__(**kw)
        self.set_title("Night Light — Setup" if SETUP_MODE else "Night Light")
        self.set_default_size(450, -1)
        self.set_resizable(False)
        self.add_css_class("nightlight-window")

        self._t, self._g, self._en = _read_conf()
        self._timer        = None
        self._preset_btns  = []   # kept to highlight active preset
        self._active_preset_idx = None

        # Load CSS
        p = Gtk.CssProvider()
        p.load_from_string(CSS)
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(), p,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )
        self._build()

    # ── UI ────────────────────────────────────────────────────────────────────

    def _build(self):
        # We put outer box directly in content instead of a ScrolledWindow to prevent scrollbars and clipping
        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        outer.set_margin_top(22);  outer.set_margin_bottom(22)
        outer.set_margin_start(22); outer.set_margin_end(22)
        self.set_content(outer)

        card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        card.add_css_class("nightlight-card")
        outer.append(card)

        # ── Setup-mode banner ────────────────────────────────────────────────
        if SETUP_MODE:
            banner = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
            banner.add_css_class("setup-banner")
            card.append(banner)

            btitle = Gtk.Label(label="⚙️  Installation Step: Night Light Setup")
            btitle.set_halign(Gtk.Align.START)
            btitle.add_css_class("setup-banner-title")
            banner.append(btitle)

            bbody = Gtk.Label(
                label="Choose a color temperature preset for your display.\n"
                       "You can always change this later with  Super + Alt + N.")
            bbody.set_halign(Gtk.Align.START)
            bbody.set_wrap(True)
            bbody.add_css_class("setup-banner-body")
            banner.append(bbody)

        # ── Header ───────────────────────────────────────────────────────────
        hdr = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=14)
        hdr.set_margin_bottom(20)
        card.append(hdr)

        ico = Gtk.Label(label="🌙")
        ico.add_css_class("header-icon")
        hdr.append(ico)

        tb = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        tb.set_valign(Gtk.Align.CENTER)
        hdr.append(tb)

        t_lbl = Gtk.Label(label="Night Light")
        t_lbl.set_halign(Gtk.Align.START)
        t_lbl.add_css_class("title-label")
        tb.append(t_lbl)

        s_lbl = Gtk.Label(label="hyprsunset — Wayland color temperature")
        s_lbl.set_halign(Gtk.Align.START)
        s_lbl.add_css_class("subtitle-label")
        tb.append(s_lbl)

        self.toggle = Gtk.Switch()
        self.toggle.set_active(self._en)
        self.toggle.set_valign(Gtk.Align.CENTER)
        self.toggle.set_halign(Gtk.Align.END)
        self.toggle.set_hexpand(True)
        self.toggle.connect("state-set", self._on_toggle)
        hdr.append(self.toggle)

        sep = Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL)
        sep.set_margin_bottom(18)
        card.append(sep)

        # ── Presets (prominent in setup mode) ────────────────────────────────
        pl = Gtk.Label(label="CHOOSE A PRESET" if SETUP_MODE else "PRESETS")
        pl.set_halign(Gtk.Align.START)
        pl.add_css_class("section-label")
        card.append(pl)

        grid = Gtk.Grid()
        grid.set_row_spacing(8); grid.set_column_spacing(8)
        grid.set_margin_top(10); grid.set_margin_bottom(6)
        card.append(grid)

        for i, (name, t, g, tip) in enumerate(PRESETS):
            b = Gtk.Button(label=name)
            b.set_tooltip_text(f"{tip}\n{t}K · {g}% brightness")
            b.set_hexpand(True)
            b.add_css_class("preset-btn")
            b.connect("clicked", self._on_preset, i, t, g)
            grid.attach(b, i % 2, i // 2, 1, 1)
            self._preset_btns.append(b)

        # Highlight the preset that matches current settings
        self._highlight_matching_preset(self._t, self._g)

        # ── Temperature slider ────────────────────────────────────────────────
        sep_t = Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL)
        sep_t.set_margin_top(14); sep_t.set_margin_bottom(10)
        card.append(sep_t)

        lbl = Gtk.Label(label="FINE TUNE — TEMPERATURE")
        lbl.set_halign(Gtk.Align.START)
        lbl.add_css_class("section-label")
        card.append(lbl)

        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        row.set_margin_top(8); row.set_margin_bottom(4)
        card.append(row)

        self.tv = Gtk.Label(label=str(self._t))
        self.tv.add_css_class("value-badge"); self.tv.add_css_class("temp-warm")
        row.append(self.tv)

        u = Gtk.Label(label="K")
        u.add_css_class("unit-label"); u.set_valign(Gtk.Align.END)
        row.append(u)

        self.td = Gtk.Label()
        self.td.set_halign(Gtk.Align.END); self.td.set_hexpand(True)
        self.td.set_valign(Gtk.Align.END); self.td.set_margin_bottom(4)
        self.td.add_css_class("subtitle-label")
        row.append(self.td)

        self.ts = Gtk.Scale.new_with_range(
            Gtk.Orientation.HORIZONTAL, TEMP_MIN, TEMP_MAX, 100)
        self.ts.set_value(self._t); self.ts.set_draw_value(False)
        self.ts.set_hexpand(True); self.ts.set_margin_bottom(8)
        self.ts.add_css_class("temp-scale")
        for mk, lb in [(2700,"2700"),(4000,"4000"),(5500,"5500"),(6500,"6500K")]:
            self.ts.add_mark(mk, Gtk.PositionType.BOTTOM, lb)
        self.ts.connect("value-changed", self._on_temp)
        card.append(self.ts)

        # ── Gamma / Brightness slider ─────────────────────────────────────────
        gl = Gtk.Label(label="FINE TUNE — BRIGHTNESS")
        gl.set_halign(Gtk.Align.START)
        gl.add_css_class("section-label"); gl.set_margin_top(8)
        card.append(gl)

        gr = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        gr.set_margin_top(8); gr.set_margin_bottom(4)
        card.append(gr)

        self.gv = Gtk.Label(label=str(self._g))
        self.gv.add_css_class("value-badge")
        gr.append(self.gv)

        gu = Gtk.Label(label="%")
        gu.add_css_class("unit-label"); gu.set_valign(Gtk.Align.END)
        gr.append(gu)

        self.gs = Gtk.Scale.new_with_range(
            Gtk.Orientation.HORIZONTAL, GAMMA_MIN, GAMMA_MAX, 5)
        self.gs.set_value(self._g); self.gs.set_draw_value(False)
        self.gs.set_hexpand(True); self.gs.set_margin_bottom(16)
        self.gs.add_css_class("gamma-scale")
        for mk, lb in [(30,"30%"),(70,"70%"),(100,"100%")]:
            self.gs.add_mark(mk, Gtk.PositionType.BOTTOM, lb)
        self.gs.connect("value-changed", self._on_gamma)
        card.append(self.gs)

        # ── Bottom action area ────────────────────────────────────────────────
        sep_b = Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL)
        sep_b.set_margin_top(6); sep_b.set_margin_bottom(14)
        card.append(sep_b)

        if SETUP_MODE:
            # Setup mode: two buttons side by side
            btn_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
            card.append(btn_row)

            skip_btn = Gtk.Button(label="Skip for now")
            skip_btn.add_css_class("skip-btn")
            skip_btn.set_hexpand(True)
            skip_btn.connect("clicked", self._on_skip)
            btn_row.append(skip_btn)

            apply_btn = Gtk.Button(label="💾  Apply & Continue Installation")
            apply_btn.add_css_class("suggested-action")
            apply_btn.add_css_class("apply-btn")
            apply_btn.set_hexpand(True)
            apply_btn.connect("clicked", self._on_apply_setup)
            btn_row.append(apply_btn)

        else:
            # Normal mode: save button
            sv = Gtk.Button(label="💾  Save to Startup Config")
            sv.add_css_class("suggested-action")
            sv.set_margin_top(4)
            sv.connect("clicked", self._on_save)
            card.append(sv)

        self.sl = Gtk.Label(label="")
        self.sl.add_css_class("status-label"); self.sl.set_margin_top(8)
        card.append(self.sl)

        # Init display
        self._upd_temp(self._t)
        self._set_sens(self._en)

    # ── Callbacks ─────────────────────────────────────────────────────────────

    def _on_toggle(self, sw, state):
        self._en = state
        self._set_sens(state)
        self._debounce()

    def _on_temp(self, sc):
        self._t = int(sc.get_value())
        self._upd_temp(self._t)
        self._highlight_matching_preset(self._t, self._g)
        self._debounce()

    def _on_gamma(self, sc):
        self._g = int(sc.get_value())
        self.gv.set_label(str(self._g))
        self._highlight_matching_preset(self._t, self._g)
        self._debounce()

    def _on_preset(self, b, idx, t, g):
        """Apply a preset — move sliders, highlight the button."""
        self.ts.set_value(t)
        self.gs.set_value(g)
        if not self._en:
            self.toggle.set_active(True)

    def _on_save(self, b):
        """Normal mode: save config + patch hyprland.conf."""
        def _do():
            _save_conf(self._t, self._g, self._en)
            _patch_hyprland(self._t, self._en)
            GLib.idle_add(self._show_status,
                          f"✓ Saved — {self._t}K · {self._g}% brightness")
        threading.Thread(target=_do, daemon=True).start()

    def _on_apply_setup(self, b):
        """Setup mode: save, apply live, then close (installation continues)."""
        def _do():
            _save_conf(self._t, self._g, self._en)
            _patch_hyprland(self._t, self._en)
            _apply_live(self._t, self._g, self._en)
            GLib.idle_add(self.close)
        threading.Thread(target=_do, daemon=True).start()

    def _on_skip(self, b):
        """Setup mode: keep 3500K default, just close."""
        self.close()

    # ── Helpers ───────────────────────────────────────────────────────────────

    def _debounce(self):
        """Apply hyprsunset 400 ms after the last change."""
        if self._timer:
            GLib.source_remove(self._timer)
        self._timer = GLib.timeout_add(400, self._do_apply)

    def _do_apply(self):
        self._timer = None
        threading.Thread(
            target=_apply_live, args=(self._t, self._g, self._en), daemon=True
        ).start()
        return False

    def _set_sens(self, e):
        self.ts.set_sensitive(e)
        self.gs.set_sensitive(e)

    def _upd_temp(self, t):
        self.tv.set_label(str(t))
        for c in ["temp-warm", "temp-mid", "temp-cool"]:
            self.tv.remove_css_class(c)
        if t <= 3500:
            self.tv.add_css_class("temp-warm"); d = "🔴 Very warm · amber"
        elif t <= 4500:
            self.tv.add_css_class("temp-mid");  d = "🟡 Warm neutral · balanced"
        elif t <= 5500:
            d = "⚪ Natural · daylight"
        else:
            self.tv.add_css_class("temp-cool"); d = "🔵 Cool · blue-white"
        self.td.set_label(d)

    def _highlight_matching_preset(self, t, g):
        """Highlight the preset button whose (temp, gamma) matches current."""
        for i, btn in enumerate(self._preset_btns):
            _, pt, pg, _ = PRESETS[i]
            if pt == t and pg == g:
                btn.add_css_class("active-preset")
            else:
                btn.remove_css_class("active-preset")

    def _show_status(self, msg):
        self.sl.set_label(msg)
        GLib.timeout_add_seconds(4, lambda: self.sl.set_label("") or False)


# ── Entry point ───────────────────────────────────────────────────────────────

if __name__ == "__main__":
    NightLightApp().run(None)
