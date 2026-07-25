#!/usr/bin/env bash
set -Eeuo pipefail

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$STATE_HOME/ilyamiro-visual-backups/$STAMP"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mAttention:\033[0m %s\n' "$*" >&2; }

backup_path() {
  local path="$1"
  [[ -e "$path" || -L "$path" ]] || return 0
  local rel="${path#$HOME/}"
  mkdir -p "$BACKUP/$(dirname "$rel")"
  cp -a "$path" "$BACKUP/$(dirname "$rel")/"
}

mkdir -p "$CONFIG_HOME"/{hypr,waybar,rofi,kitty,dunst}
mkdir -p "$BACKUP"

for path in \
  "$CONFIG_HOME/hypr/ilyamiro-visual.conf" \
  "$CONFIG_HOME/hypr/hyprland.conf" \
  "$CONFIG_HOME/waybar/config.jsonc" \
  "$CONFIG_HOME/waybar/style.css" \
  "$CONFIG_HOME/rofi/config.rasi" \
  "$CONFIG_HOME/rofi/theme.rasi" \
  "$CONFIG_HOME/kitty/kitty.conf" \
  "$CONFIG_HOME/dunst/dunstrc"
do
  backup_path "$path"
done

log "Installation du thème visuel inspiré d'ilyamiro…"

cat > "$CONFIG_HOME/hypr/ilyamiro-visual.conf" <<'EOF'
# Visuel inspiré d'ilyamiro/nixos-configuration.
# Aucun écran, raccourci, shell ou script personnel n'est importé.

general {
    gaps_in = 6
    gaps_out = 12
    border_size = 2
    col.active_border = rgba(89b4faff) rgba(cba6f7ff) 45deg
    col.inactive_border = rgba(45475acc)
    layout = dwindle
    resize_on_border = true
}

decoration {
    rounding = 14
    active_opacity = 1.0
    inactive_opacity = 0.94
    fullscreen_opacity = 1.0

    shadow {
        enabled = true
        range = 18
        render_power = 3
        color = rgba(11111bcc)
    }

    blur {
        enabled = true
        size = 7
        passes = 3
        new_optimizations = true
        ignore_opacity = true
    }
}

animations {
    enabled = true

    bezier = fluide, 0.16, 1, 0.3, 1
    bezier = rapide, 0.4, 0, 0.2, 1

    animation = windows, 1, 5, fluide
    animation = windowsOut, 1, 4, rapide, popin 80%
    animation = fade, 1, 4, rapide
    animation = border, 1, 6, fluide
    animation = workspaces, 1, 5, fluide, slide
}

misc {
    disable_hyprland_logo = true
    disable_splash_rendering = true
    animate_manual_resizes = true
    animate_mouse_windowdragging = true
    focus_on_activate = true
}
EOF

MAIN="$CONFIG_HOME/hypr/hyprland.conf"
touch "$MAIN"

# Supprime seulement les anciennes lignes de thème créées par nos scripts.
sed -i \
  -e '/^[[:space:]]*source[[:space:]]*=[[:space:]]*~\/.config\/hypr\/xnm-visual.conf/d' \
  -e '/^[[:space:]]*source[[:space:]]*=[[:space:]]*~\/.config\/hypr\/ilyamiro-visual.conf/d' \
  "$MAIN"

{
  printf '\n# Thème visuel inspiré d’ilyamiro\n'
  printf 'source = ~/.config/hypr/ilyamiro-visual.conf\n'
} >> "$MAIN"

cat > "$CONFIG_HOME/waybar/config.jsonc" <<'EOF'
{
  "layer": "top",
  "position": "top",
  "height": 38,
  "margin-top": 8,
  "margin-left": 10,
  "margin-right": 10,
  "spacing": 8,

  "modules-left": ["custom/menu", "hyprland/workspaces", "hyprland/window"],
  "modules-center": ["clock"],
  "modules-right": ["pulseaudio", "network", "battery", "tray"],

  "custom/menu": {
    "format": "",
    "tooltip": false,
    "on-click": "rofi -show drun"
  },

  "hyprland/workspaces": {
    "format": "{icon}",
    "format-icons": {
      "1": "1",
      "2": "2",
      "3": "3",
      "4": "4",
      "5": "5",
      "active": "●",
      "default": "○"
    },
    "on-click": "activate"
  },

  "hyprland/window": {
    "max-length": 45,
    "separate-outputs": true
  },

  "clock": {
    "format": "󰥔 {:%H:%M}",
    "format-alt": "󰃭 {:%A %d %B %Y}",
    "locale": "fr_FR.UTF-8",
    "tooltip-format": "<big>{:%A %d %B %Y}</big>\n<tt>{calendar}</tt>"
  },

  "pulseaudio": {
    "format": "{icon} {volume}%",
    "format-muted": "󰝟 Muet",
    "format-icons": {
      "default": ["", "", ""]
    },
    "on-click": "pavucontrol"
  },

  "network": {
    "format-wifi": "  {signalStrength}%",
    "format-ethernet": "󰈀 Réseau",
    "format-disconnected": "󰖪 Hors ligne",
    "tooltip-format-wifi": "{essid}\n{ipaddr}"
  },

  "battery": {
    "states": {
      "warning": 25,
      "critical": 10
    },
    "format": "{icon} {capacity}%",
    "format-charging": "󰂄 {capacity}%",
    "format-plugged": " {capacity}%",
    "format-icons": ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
  },

  "tray": {
    "spacing": 8
  }
}
EOF

cat > "$CONFIG_HOME/waybar/style.css" <<'EOF'
@define-color bg rgba(17, 17, 27, 0.88);
@define-color surface rgba(30, 30, 46, 0.96);
@define-color surface2 #45475a;
@define-color text #cdd6f4;
@define-color subtext #bac2de;
@define-color blue #89b4fa;
@define-color mauve #cba6f7;
@define-color green #a6e3a1;
@define-color yellow #f9e2af;
@define-color red #f38ba8;

* {
  border: none;
  border-radius: 0;
  font-family: "JetBrainsMono Nerd Font";
  font-size: 13px;
  min-height: 0;
}

window#waybar {
  background: transparent;
  color: @text;
}

#custom-menu,
#workspaces,
#window,
#clock,
#pulseaudio,
#network,
#battery,
#tray {
  background: @surface;
  border: 1px solid @surface2;
  border-radius: 13px;
  margin: 4px 0;
  padding: 0 12px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.35);
}

#custom-menu {
  color: @blue;
  font-size: 17px;
  margin-left: 2px;
}

#workspaces {
  padding: 0 5px;
}

#workspaces button {
  color: @subtext;
  background: transparent;
  border-radius: 9px;
  padding: 0 8px;
}

#workspaces button.active {
  color: #11111b;
  background: @mauve;
}

#workspaces button:hover {
  color: #11111b;
  background: @blue;
}

#window {
  color: @text;
}

#clock {
  color: #11111b;
  background: linear-gradient(90deg, @blue, @mauve);
  font-weight: bold;
  padding: 0 16px;
}

#pulseaudio { color: @blue; }
#network { color: @mauve; }
#battery { color: @green; }
#battery.warning { color: @yellow; }
#battery.critical { color: @red; }

tooltip {
  background: #1e1e2e;
  color: @text;
  border: 1px solid @surface2;
  border-radius: 10px;
}
EOF

cat > "$CONFIG_HOME/rofi/config.rasi" <<'EOF'
configuration {
  modi: "drun,run";
  show-icons: true;
  display-drun: "Applications";
  display-run: "Commande";
  drun-display-format: "{name}";
  font: "JetBrainsMono Nerd Font 12";
}
@theme "theme.rasi"
EOF

cat > "$CONFIG_HOME/rofi/theme.rasi" <<'EOF'
* {
  fond:       #11111bee;
  panneau:    #1e1e2eff;
  bordure:    #45475aff;
  texte:      #cdd6f4ff;
  secondaire: #bac2deff;
  bleu:       #89b4faff;
  mauve:      #cba6f7ff;
  contraste:  #11111bff;
}

window {
  width: 44%;
  border: 2px;
  border-color: @mauve;
  border-radius: 18px;
  background-color: @fond;
  padding: 20px;
}

mainbox {
  spacing: 16px;
  background-color: transparent;
}

inputbar {
  padding: 13px;
  border: 1px;
  border-color: @bordure;
  border-radius: 12px;
  background-color: @panneau;
  text-color: @texte;
}

prompt {
  text-color: @bleu;
}

entry {
  text-color: @texte;
}

listview {
  lines: 8;
  columns: 1;
  spacing: 8px;
  scrollbar: false;
  background-color: transparent;
}

element {
  padding: 11px;
  border-radius: 11px;
  text-color: @texte;
  background-color: transparent;
}

element selected {
  background-color: @mauve;
  text-color: @contraste;
}

element-icon {
  size: 26px;
  margin: 0 12px 0 0;
}

element-text {
  text-color: inherit;
}
EOF

cat > "$CONFIG_HOME/kitty/kitty.conf" <<'EOF'
# Aucun shell particulier n'est imposé.
shell .
font_family JetBrainsMono Nerd Font
font_size 11.0
background_opacity 0.90
dynamic_background_opacity yes
window_padding_width 10
confirm_os_window_close 0
enable_audio_bell no
cursor_shape beam

foreground            #cdd6f4
background            #11111b
selection_foreground  #11111b
selection_background  #f5e0dc
cursor                #f5e0dc
cursor_text_color     #11111b
url_color             #89b4fa

color0  #45475a
color1  #f38ba8
color2  #a6e3a1
color3  #f9e2af
color4  #89b4fa
color5  #f5c2e7
color6  #94e2d5
color7  #bac2de
color8  #585b70
color9  #f38ba8
color10 #a6e3a1
color11 #f9e2af
color12 #89b4fa
color13 #f5c2e7
color14 #94e2d5
color15 #cdd6f4
EOF

cat > "$CONFIG_HOME/dunst/dunstrc" <<'EOF'
[global]
    monitor = 0
    follow = mouse
    width = 370
    height = 130
    origin = top-right
    offset = 18x58
    notification_limit = 5
    gap_size = 10
    padding = 15
    horizontal_padding = 15
    frame_width = 2
    frame_color = "#cba6f7"
    separator_color = frame
    corner_radius = 14
    font = JetBrainsMono Nerd Font 10
    foreground = "#cdd6f4"
    background = "#1e1e2e"
    timeout = 6
    markup = full
    format = "<b>%s</b>\n%b"

[urgency_low]
    frame_color = "#94e2d5"

[urgency_normal]
    frame_color = "#89b4fa"

[urgency_critical]
    frame_color = "#f38ba8"
    timeout = 0
EOF

for app in waybar dunst; do
  if ! grep -Eq "^[[:space:]]*exec-once[[:space:]]*=.*\b${app}\b" "$MAIN"; then
    printf 'exec-once = %s\n' "$app" >> "$MAIN"
  fi
done

if ! grep -Eq '^[[:space:]]*bind[[:space:]]*=.*SUPER.*RETURN.*kitty' "$MAIN"; then
  printf 'bind = SUPER, RETURN, exec, kitty\n' >> "$MAIN"
fi

if ! grep -Eq '^[[:space:]]*bind[[:space:]]*=.*SUPER.*D.*rofi' "$MAIN"; then
  printf 'bind = SUPER, D, exec, rofi -show drun\n' >> "$MAIN"
fi

missing=()
for cmd in kitty waybar rofi dunst; do
  command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done

printf '\nInstallation visuelle terminée.\n'
printf 'Sauvegarde : %s\n' "$BACKUP"
printf 'Raccourcis ajoutés si absents : Super+Entrée (Kitty), Super+D (Rofi).\n'

if ((${#missing[@]})); then
  warn "Commandes absentes : ${missing[*]}"
  warn "Installe les paquets correspondants dans configuration.nix."
fi

if command -v hyprctl >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 || true
fi
