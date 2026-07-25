#!/usr/bin/env bash
set -Eeuo pipefail

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$STATE_HOME/hypr-visual-fix/$STAMP"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mAttention:\033[0m %s\n' "$*" >&2; }

backup() {
  local p="$1"
  [[ -e "$p" || -L "$p" ]] || return 0
  local rel="${p#$HOME/}"
  mkdir -p "$BACKUP/$(dirname "$rel")"
  cp -a "$p" "$BACKUP/$(dirname "$rel")/"
}

mkdir -p "$CONFIG_HOME"/{hypr,waybar,kitty,rofi,dunst}
mkdir -p "$BACKUP"

for p in \
  "$CONFIG_HOME/hypr/xnm-visual.conf" \
  "$CONFIG_HOME/waybar/config.jsonc" \
  "$CONFIG_HOME/waybar/style.css" \
  "$CONFIG_HOME/kitty/kitty.conf" \
  "$CONFIG_HOME/rofi/config.rasi" \
  "$CONFIG_HOME/rofi/theme.rasi" \
  "$CONFIG_HOME/dunst/dunstrc"
do
  backup "$p"
done

log "Création d'un thème visuel autonome, sans Fish ni scripts externes…"

cat > "$CONFIG_HOME/hypr/xnm-visual.conf" <<'EOF'
# Thème visuel Catppuccin Macchiato.
# Aucun raccourci, écran, shell ou script externe n'est imposé.

general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(c6a0f6ff) rgba(8aadf4ff) 45deg
    col.inactive_border = rgba(5b6078cc)
    layout = dwindle
    resize_on_border = true
}

decoration {
    rounding = 10
    active_opacity = 1.0
    inactive_opacity = 0.97

    shadow {
        enabled = true
        range = 12
        render_power = 3
        color = rgba(18192688)
    }

    blur {
        enabled = true
        size = 5
        passes = 2
        new_optimizations = true
        ignore_opacity = true
    }
}

animations {
    enabled = true
    bezier = fluide, 0.16, 1, 0.3, 1
    animation = windows, 1, 5, fluide
    animation = windowsOut, 1, 4, default, popin 80%
    animation = border, 1, 6, default
    animation = fade, 1, 4, default
    animation = workspaces, 1, 5, fluide, slide
}
EOF

# Retire les anciens blocs fautifs éventuellement ajoutés par la v1/v2.
MAIN="$CONFIG_HOME/hypr/hyprland.conf"
touch "$MAIN"
sed -i \
  -e '/^[[:space:]]*dwindle[[:space:]]*{/,/^[[:space:]]*}/d' \
  -e '/^[[:space:]]*source[[:space:]]*=[[:space:]]*~\/.config\/hypr\/xnm-visual.conf/d' \
  "$MAIN"

{
  printf '\n# Thème visuel autonome\n'
  printf 'source = ~/.config/hypr/xnm-visual.conf\n'
} >> "$MAIN"

cat > "$CONFIG_HOME/kitty/kitty.conf" <<'EOF'
# Kitty utilise le shell de connexion de l'utilisateur.
# Fish n'est pas requis.
shell .
font_family JetBrainsMono Nerd Font
font_size 11.0
background_opacity 0.94
confirm_os_window_close 0
enable_audio_bell no
cursor_shape beam
window_padding_width 8

foreground            #cad3f5
background            #24273a
selection_foreground  #24273a
selection_background  #f4dbd6
cursor                #f4dbd6
cursor_text_color     #24273a
url_color             #8aadf4

color0  #494d64
color1  #ed8796
color2  #a6da95
color3  #eed49f
color4  #8aadf4
color5  #f5bde6
color6  #8bd5ca
color7  #b8c0e0
color8  #5b6078
color9  #ed8796
color10 #a6da95
color11 #eed49f
color12 #8aadf4
color13 #f5bde6
color14 #8bd5ca
color15 #cad3f5
EOF

cat > "$CONFIG_HOME/waybar/config.jsonc" <<'EOF'
{
  "layer": "top",
  "position": "top",
  "height": 34,
  "spacing": 8,

  "modules-left": ["hyprland/workspaces", "hyprland/window"],
  "modules-center": ["clock"],
  "modules-right": ["pulseaudio", "network", "battery", "tray"],

  "hyprland/workspaces": {
    "format": "{name}",
    "on-click": "activate"
  },

  "hyprland/window": {
    "max-length": 45,
    "separate-outputs": true
  },

  "clock": {
    "format": "{:%H:%M}",
    "format-alt": "{:%A %d %B %Y}",
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
    "format-ethernet": "󰈀 Connecté",
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
* {
  border: none;
  border-radius: 0;
  font-family: "JetBrainsMono Nerd Font";
  font-size: 13px;
  min-height: 0;
}

window#waybar {
  background: rgba(36, 39, 58, 0.94);
  color: #cad3f5;
}

#workspaces {
  margin: 5px 0 5px 8px;
  padding: 0 4px;
  border-radius: 10px;
  background: #363a4f;
}

#workspaces button {
  padding: 0 8px;
  color: #b8c0e0;
  background: transparent;
  border-radius: 8px;
}

#workspaces button.active {
  color: #24273a;
  background: #8aadf4;
}

#workspaces button:hover {
  color: #24273a;
  background: #c6a0f6;
}

#window {
  margin-left: 8px;
  color: #cad3f5;
}

#clock,
#pulseaudio,
#network,
#battery,
#tray {
  margin: 5px 4px;
  padding: 0 11px;
  border-radius: 10px;
  background: #363a4f;
  color: #cad3f5;
}

#clock {
  color: #24273a;
  background: #c6a0f6;
  font-weight: bold;
}

#pulseaudio {
  color: #8aadf4;
}

#network {
  color: #8bd5ca;
}

#battery {
  color: #a6da95;
}

#battery.warning {
  color: #eed49f;
}

#battery.critical {
  color: #ed8796;
}

tooltip {
  background: #24273a;
  color: #cad3f5;
  border: 1px solid #5b6078;
  border-radius: 8px;
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
  fond:       #24273aee;
  panneau:    #363a4fff;
  texte:      #cad3f5ff;
  discret:    #a5adcbff;
  accent:     #8aadf4ff;
  selection:  #c6a0f6ff;
  contraste:  #24273aff;
}

window {
  width: 42%;
  border: 2px;
  border-color: @accent;
  border-radius: 14px;
  background-color: @fond;
  padding: 18px;
}

mainbox {
  spacing: 14px;
  background-color: transparent;
}

inputbar {
  padding: 12px;
  border-radius: 10px;
  background-color: @panneau;
  text-color: @texte;
}

prompt {
  text-color: @accent;
}

entry {
  text-color: @texte;
}

listview {
  lines: 8;
  columns: 1;
  spacing: 7px;
  scrollbar: false;
  background-color: transparent;
}

element {
  padding: 10px;
  border-radius: 9px;
  text-color: @texte;
  background-color: transparent;
}

element selected {
  background-color: @selection;
  text-color: @contraste;
}

element-icon {
  size: 24px;
  margin: 0 10px 0 0;
}

element-text {
  text-color: inherit;
}
EOF

cat > "$CONFIG_HOME/dunst/dunstrc" <<'EOF'
[global]
    monitor = 0
    follow = mouse
    width = 360
    height = 120
    origin = top-right
    offset = 14x48
    notification_limit = 5
    gap_size = 8
    padding = 14
    horizontal_padding = 14
    frame_width = 2
    frame_color = "#8aadf4"
    separator_color = frame
    corner_radius = 10
    font = JetBrainsMono Nerd Font 10
    foreground = "#cad3f5"
    background = "#24273a"
    timeout = 6
    markup = full
    format = "<b>%s</b>\n%b"

[urgency_low]
    frame_color = "#8bd5ca"

[urgency_normal]
    frame_color = "#8aadf4"

[urgency_critical]
    frame_color = "#ed8796"
    timeout = 0
EOF

# Évite les doublons d'autostart.
for app in waybar dunst; do
  if ! grep -Eq "^[[:space:]]*exec-once[[:space:]]*=.*\\b$app\\b" "$MAIN"; then
    printf 'exec-once = %s\n' "$app" >> "$MAIN"
  fi
done

log "Vérification des dépendances visibles…"
missing=()
for cmd in kitty waybar rofi dunst; do
  command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done

if ((${#missing[@]})); then
  warn "Commandes absentes : ${missing[*]}"
  warn "Ajoute les paquets correspondants dans configuration.nix puis lance sudo nixos-rebuild switch."
fi

if command -v hyprctl >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 || true
fi

printf '\nCorrection terminée.\n'
printf 'Sauvegarde : %s\n' "$BACKUP"
printf 'Fish n’est plus requis. Kitty utilise ton shell de connexion.\n'
printf 'Le bloc dwindle/pseudotile fautif a été retiré.\n'
printf 'Les textes de Waybar et Rofi sont en français avec un contraste lisible.\n'
