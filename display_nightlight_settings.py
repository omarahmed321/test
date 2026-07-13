#!/usr/bin/env python3
#===============================================================================
#   Display Settings & Night Light Controller
#   Written from scratch to manage Hyprland monitor resolutions, refresh rates,
#   zoom, rotation, mouse sensitivity, and nightlight (hyprsunset/gammastep).
#===============================================================================

import os
import re
import sys
import subprocess
import tkinter as tk
from tkinter import ttk, messagebox

# Paths
MONITORS_CONF = os.path.expanduser('~/.config/hypr/monitors.conf')
USERPREFS_CONF = os.path.expanduser('~/.config/hypr/userprefs.conf')
NIGHTLIGHT_CONF = os.path.expanduser('~/.config/hypr/nightlight.conf')
SDDM_XSETUP = '/usr/share/sddm/scripts/Xsetup'

# --- Monitor Data Parser ---
def parse_monitors():
    try:
        output = subprocess.check_output(['hyprctl', 'monitors'], text=True)
    except Exception as e:
        print(f"Error running hyprctl: {e}")
        return {}

    monitors = {}
    blocks = output.split('Monitor ')[1:]
    for block in blocks:
        lines = block.strip().split('\n')
        if not lines:
            continue
        
        # Name
        m_name = lines[0].split()[0]
        
        info = {
            'name': m_name,
            'model': 'Unknown',
            'resolution': '1920x1080',
            'hz': '60.00',
            'pos': '0x0',
            'scale': '1.00',
            'transform': '0',
            'modes': {} # { resolution: [hz1, hz2] }
        }
        
        # Current Mode & Position
        if len(lines) > 1:
            match = re.search(r'(\d+x\d+)@([\d\.]+)\s+at\s+(\d+x\d+)', lines[1])
            if match:
                info['resolution'] = match.group(1)
                info['hz'] = str(int(float(match.group(2)))) if float(match.group(2)).is_integer() else f"{float(match.group(2)):.2f}"
                info['pos'] = match.group(3)
        
        # Scale, Transform, Model, Modes
        for line in lines:
            line = line.strip()
            if line.startswith('model:'):
                info['model'] = line.split('model:')[1].strip()
            elif line.startswith('scale:'):
                info['scale'] = line.split('scale:')[1].strip()
            elif line.startswith('transform:'):
                info['transform'] = line.split('transform:')[1].strip()
            elif line.startswith('availableModes:'):
                modes_list = line.split('availableModes:')[1].strip().split()
                for mode in modes_list:
                    # e.g., 1920x1080@60.00Hz
                    m = re.match(r'^(\d+x\d+)@([\d\.]+)Hz$', mode)
                    if m:
                        res = m.group(1)
                        hz = m.group(2)
                        hz_val = str(int(float(hz))) if float(hz).is_integer() else f"{float(hz):.2f}"
                        if res not in info['modes']:
                            info['modes'][res] = []
                        if hz_val not in info['modes'][res]:
                            info['modes'][res].append(hz_val)
                            
        # Sort refresh rates descending
        for res in info['modes']:
            info['modes'][res] = sorted(info['modes'][res], key=float, reverse=True)
            
        monitors[m_name] = info
    return monitors

# --- Load Config Values ---
def get_saved_mouse():
    sens = 0.0
    natural = False
    if os.path.exists(USERPREFS_CONF):
        try:
            with open(USERPREFS_CONF, 'r') as f:
                content = f.read()
            match_sens = re.search(r'^\s*sensitivity\s*=\s*([-\d\.]+)', content, re.MULTILINE)
            if match_sens:
                sens = float(match_sens.group(1))
            match_nat = re.search(r'natural_scroll\s*=\s*(yes|true)', content)
            if match_nat:
                natural = True
        except Exception:
            pass
    return sens, natural

def get_saved_nightlight():
    temp = 3500
    enabled = True
    if os.path.exists(NIGHTLIGHT_CONF):
        try:
            with open(NIGHTLIGHT_CONF, 'r') as f:
                for line in f:
                    if line.startswith('temperature='):
                        temp = int(line.split('=')[1].strip())
                    elif line.startswith('enabled='):
                        enabled = line.split('=')[1].strip().lower() == 'true'
        except Exception:
            pass
    return temp, enabled

# --- Main App ---
class App(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("Display & Night Light Manager")
        self.geometry("500x500")
        
        # Styling
        self.configure(bg='#282828')
        self.setup_styles()
        
        # Load Data
        self.monitors = parse_monitors()
        self.saved_sens, self.saved_nat = get_saved_mouse()
        self.saved_temp, self.saved_nl_enabled = get_saved_nightlight()
        
        # UI Elements
        self.build_ui()
        
    def setup_styles(self):
        style = ttk.Style()
        style.theme_use('clam')
        style.configure('.', background='#282828', foreground='#ebdbb2', font=('JetBrains Mono', 10))
        style.configure('TFrame', background='#282828')
        style.configure('TLabel', background='#282828', foreground='#ebdbb2')
        style.configure('TNotebook', background='#282828', borderwidth=0)
        style.configure('TNotebook.Tab', background='#3c3836', foreground='#a89984', padding=[12, 6])
        style.map('TNotebook.Tab', background=[('selected', '#282828')], foreground=[('selected', '#ebdbb2')])
        style.configure('TCombobox', fieldbackground='#3c3836', background='#504945', foreground='#ebdbb2')
        style.map('TCombobox', fieldbackground=[('readonly', '#3c3836')], foreground=[('readonly', '#ebdbb2')])
        style.configure('TButton', background='#3c3836', foreground='#ebdbb2', borderwidth=1, focuscolor='none', padding=[10, 5])
        style.map('TButton', background=[('active', '#504945')])
        style.configure('TCheckbutton', background='#282828', foreground='#ebdbb2')
        style.map('TCheckbutton', background=[('active', '#282828')])
        
    def build_ui(self):
        notebook = ttk.Notebook(self)
        notebook.pack(fill='both', expand=True, padx=15, pady=15)
        
        # Tab 1: Monitors & Mouse
        tab_monitors = ttk.Frame(notebook)
        notebook.add(tab_monitors, text="Monitors & Mouse")
        
        # Monitor Selection
        ttk.Label(tab_monitors, text="Monitor:").grid(row=0, column=0, sticky='w', pady=8, padx=10)
        self.m_names = list(self.monitors.keys())
        self.m_labels = [f"{name} ({self.monitors[name]['model']})" for name in self.m_names]
        
        self.m_combo = ttk.Combobox(tab_monitors, values=self.m_labels, state="readonly", width=30)
        self.m_combo.grid(row=0, column=1, sticky='w', pady=8, padx=10)
        self.m_combo.bind("<<ComboboxSelected>>", self.on_monitor_changed)
        
        # Resolution Selection
        ttk.Label(tab_monitors, text="Resolution:").grid(row=1, column=0, sticky='w', pady=8, padx=10)
        self.res_combo = ttk.Combobox(tab_monitors, state="readonly", width=20)
        self.res_combo.grid(row=1, column=1, sticky='w', pady=8, padx=10)
        self.res_combo.bind("<<ComboboxSelected>>", self.on_res_changed)
        
        # Refresh Rate Selection
        ttk.Label(tab_monitors, text="Refresh Rate (Hz):").grid(row=2, column=0, sticky='w', pady=8, padx=10)
        self.hz_combo = ttk.Combobox(tab_monitors, state="readonly", width=15)
        self.hz_combo.grid(row=2, column=1, sticky='w', pady=8, padx=10)
        
        # Scaling Zoom
        ttk.Label(tab_monitors, text="Zoom (Scale):").grid(row=3, column=0, sticky='w', pady=8, padx=10)
        self.scale_combo = ttk.Combobox(tab_monitors, values=["1", "1.25", "1.5", "1.75", "2"], state="readonly", width=10)
        self.scale_combo.grid(row=3, column=1, sticky='w', pady=8, padx=10)
        
        # Transform Rotation
        ttk.Label(tab_monitors, text="Rotation:").grid(row=4, column=0, sticky='w', pady=8, padx=10)
        self.rot_combo = ttk.Combobox(tab_monitors, values=["Normal", "Portrait (90°)", "Flipped (180°)", "Flipped Portrait (270°)"], state="readonly", width=25)
        self.rot_combo.grid(row=4, column=1, sticky='w', pady=8, padx=10)
        
        # Separator
        ttk.Separator(tab_monitors, orient='horizontal').grid(row=5, column=0, columnspan=2, sticky='ew', pady=15)
        
        # Mouse Sensitivity Slider
        ttk.Label(tab_monitors, text="Mouse Speed (-1.0 to 1.0):").grid(row=6, column=0, sticky='w', pady=5, padx=10)
        self.sens_slider = tk.Scale(tab_monitors, from_=-1.0, to=1.0, resolution=0.05, orient='horizontal', bg='#3c3836', fg='#ebdbb2', troughcolor='#282828', highlightthickness=0)
        self.sens_slider.set(self.saved_sens)
        self.sens_slider.grid(row=6, column=1, sticky='we', pady=5, padx=10)
        
        # Natural Scroll Checkbox
        self.nat_var = tk.BooleanVar(value=self.saved_nat)
        self.nat_check = ttk.Checkbutton(tab_monitors, text="Enable Natural Scrolling", variable=self.nat_var)
        self.nat_check.grid(row=7, column=0, columnspan=2, sticky='w', pady=5, padx=10)
        
        # Tab 2: Night Light
        tab_nl = ttk.Frame(notebook)
        notebook.add(tab_nl, text="Night Light")
        
        # Toggle Switch
        self.nl_var = tk.BooleanVar(value=self.saved_nl_enabled)
        self.nl_check = ttk.Checkbutton(tab_nl, text="Enable Screen Warmth (Night Light)", variable=self.nl_var, command=self.on_nl_toggle)
        self.nl_check.pack(anchor='w', pady=20, padx=20)
        
        # Temp Slider
        self.temp_label = ttk.Label(tab_nl, text=f"Color Temperature: {self.saved_temp}K")
        self.temp_label.pack(anchor='w', pady=5, padx=20)
        
        self.temp_slider = tk.Scale(tab_nl, from_=1000, to=6500, resolution=100, orient='horizontal', bg='#3c3836', fg='#ebdbb2', troughcolor='#282828', highlightthickness=0, command=self.on_temp_slide)
        self.temp_slider.set(self.saved_temp)
        self.temp_slider.pack(fill='x', pady=10, padx=20)
        
        # Action Buttons Bottom
        action_frame = ttk.Frame(self)
        action_frame.pack(fill='x', side='bottom', padx=15, pady=15)
        
        ttk.Button(action_frame, text="Close", command=self.destroy).pack(side='left')
        ttk.Button(action_frame, text="Apply & Save", command=self.apply_all).pack(side='right')
        
        # Set Default selections
        if self.m_names:
            self.m_combo.current(0)
            self.on_monitor_changed(None)
            
    def on_monitor_changed(self, event):
        idx = self.m_combo.current()
        if idx < 0:
            return
        m_name = self.m_names[idx]
        m_info = self.monitors[m_name]
        
        # Set available resolutions
        resolutions = list(m_info['modes'].keys())
        self.res_combo.configure(values=resolutions)
        
        # Preselect current resolution
        if m_info['resolution'] in resolutions:
            self.res_combo.set(m_info['resolution'])
        elif resolutions:
            self.res_combo.current(0)
        self.on_res_changed(None)
        
        # Preselect scale
        scale_val = m_info['scale']
        # normalize
        scale_val = str(int(float(scale_val))) if float(scale_val).is_integer() else f"{float(scale_val):.2f}".rstrip('0').rstrip('.')
        if scale_val in ["1", "1.25", "1.5", "1.75", "2"]:
            self.scale_combo.set(scale_val)
        else:
            self.scale_combo.set("1")
            
        # Preselect rotation/transform
        t_val = int(m_info['transform']) % 4
        self.rot_combo.current(t_val)
        
    def on_res_changed(self, event):
        idx = self.m_combo.current()
        if idx < 0:
            return
        m_name = self.m_names[idx]
        m_info = self.monitors[m_name]
        res = self.res_combo.get()
        
        # Set available hz
        hz_rates = m_info['modes'].get(res, ["60.00"])
        self.hz_combo.configure(values=hz_rates)
        
        # Preselect current hz or highest
        if m_info['hz'] in hz_rates:
            self.hz_combo.set(m_info['hz'])
        elif hz_rates:
            self.hz_combo.current(0)
            
    def on_temp_slide(self, val):
        self.temp_label.configure(text=f"Color Temperature: {val}K")
        if self.nl_var.get():
            # Update dynamically in background
            subprocess.run(['pkill', '-x', 'hyprsunset'], capture_output=True)
            subprocess.Popen(['hyprsunset', '-t', str(val)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            
    def on_nl_toggle(self):
        enabled = self.nl_var.get()
        if enabled:
            temp = self.temp_slider.get()
            subprocess.run(['pkill', '-x', 'hyprsunset'], capture_output=True)
            subprocess.Popen(['hyprsunset', '-t', str(temp)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        else:
            subprocess.run(['pkill', '-x', 'hyprsunset'], capture_output=True)
            
    def apply_all(self):
        idx = self.m_combo.current()
        if idx < 0:
            messagebox.showerror("Error", "Please select a monitor first.")
            return
        m_name = self.m_names[idx]
        m_info = self.monitors[m_name]
        
        res = self.res_combo.get()
        hz = self.hz_combo.get()
        scale = self.scale_combo.get()
        rot_idx = self.rot_combo.current()
        
        # 1. Update Monitor config
        pos = m_info['pos']
        res_hz = f"{res}@{hz}"
        # Set command
        cmd = f"{m_name},{res_hz},{pos},{scale}"
        if rot_idx > 0:
            cmd += f",transform,{rot_idx}"
            
        try:
            # Apply dynamically
            subprocess.run(['hyprctl', 'keyword', 'monitor', cmd], check=True)
            # Persist to monitors.conf
            with open(MONITORS_CONF, 'w') as f:
                f.write(f"monitor = {cmd}\n")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to apply monitor config: {e}")
            return
            
        # 2. Update Mouse config
        sens = self.sens_slider.get()
        natural = self.nat_var.get()
        try:
            subprocess.run(['hyprctl', 'keyword', 'input:sensitivity', f"{sens:.2f}"], check=True)
            subprocess.run(['hyprctl', 'keyword', 'input:touchpad:natural_scroll', 'true' if natural else 'false'], check=True)
            
            # Write to userprefs.conf
            userprefs_content = f"""# Dynamic User Preferences
input {{
    sensitivity = {sens:.2f}
    accel_profile = flat
    touchpad {{
        natural_scroll = {"yes" if natural else "no"}
    }}
}}
"""
            with open(USERPREFS_CONF, 'w') as f:
                f.write(userprefs_content)
        except Exception as e:
            messagebox.showerror("Error", f"Failed to apply mouse preferences: {e}")
            return
            
        # 3. Update Night Light config
        nl_enabled = self.nl_var.get()
        temp = self.temp_slider.get()
        try:
            # Save nightlight.conf
            with open(NIGHTLIGHT_CONF, 'w') as f:
                f.write(f"temperature={temp}\n")
                f.write(f"enabled={'true' if nl_enabled else 'false'}\n")
                
            # If enabled, start hyprsunset, else kill it
            subprocess.run(['pkill', '-x', 'hyprsunset'], capture_output=True)
            if nl_enabled:
                subprocess.Popen(['hyprsunset', '-t', str(temp)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                
            # Update SDDM Xsetup for Night Light (requires root/sudo, write if we can)
            # Check if SDDM Xsetup exists and update gammastep values
            if os.path.exists(SDDM_XSETUP):
                # Update Xsetup template with the saved temperature & state
                sddm_cmd = f"sudo sed -i 's/TEMP=[0-9]*/TEMP={temp}/g' {SDDM_XSETUP}"
                subprocess.run(sddm_cmd, shell=True, capture_output=True)
                sddm_state = 'true' if nl_enabled else 'false'
                sddm_state_cmd = f"sudo sed -i 's/ENABLED=[a-z]*/ENABLED={sddm_state}/g' {SDDM_XSETUP}"
                subprocess.run(sddm_state_cmd, shell=True, capture_output=True)
        except Exception as e:
            print(f"Warning: Failed to sync nightlight with SDDM: {e}")
            
        # Reload Hyprland session configs
        subprocess.run(['hyprctl', 'reload'], capture_output=True)
        messagebox.showinfo("Success", "All settings applied and saved successfully!")

if __name__ == "__main__":
    # Ensure Wayland/Hyprland session
    if not os.environ.get('WAYLAND_DISPLAY'):
        print("Error: Wayland display not found. This manager is designed for Hyprland.")
        sys.exit(1)
        
    app = App()
    app.mainloop()
