#!/usr/bin/env bash
#
# Installe UNIQUEMENT la partie visuelle de :
#   https://github.com/XNM1/linux-nixos-hyprland-config-dotfiles
#
# Ce qui est repris : thème Catppuccin Macchiato Teal (Hyprland, Waybar 3 barres,
# Rofi, Dunst, Kitty, Wlogout, Hyprlock, Hyprpaper, GTK/Qt, curseurs, polices).
#
# Ce qui est volontairement IGNORÉ : IA (aichat, opencode, ollama, searxng,
# open-webui, aider), shell Fish et ses fonctions, Helix, Yazi, Zellij,
# qutebrowser, git/lazygit, moniteurs, raccourcis clavier et scripts perso.
#
# Usage :
#   ./install-xnm-visual.sh              # clone puis installe
#   XNM_SRC=/chemin/vers/clone ./install-xnm-visual.sh
#
set -Eeuo pipefail

REPO_URL="${XNM_REPO:-https://github.com/XNM1/linux-nixos-hyprland-config-dotfiles.git}"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$STATE_HOME/xnm-visual-backups/$STAMP"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NIX_OUT="$SCRIPT_DIR/xnm-visual-packages.nix"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mAttention:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mErreur:\033[0m %s\n' "$*" >&2; exit 1; }

# --------------------------------------------------------------------------
# Source : clone superficiel, ou dossier déjà cloné via XNM_SRC
# --------------------------------------------------------------------------
TMP_CLONE=""
cleanup() { [[ -n "$TMP_CLONE" && -d "$TMP_CLONE" ]] && rm -rf "$TMP_CLONE"; }
trap cleanup EXIT

if [[ -n "${XNM_SRC:-}" ]]; then
  SRC="$XNM_SRC"
  [[ -d "$SRC/home/.config" ]] || die "XNM_SRC=$SRC ne ressemble pas au dépôt XNM1."
else
  command -v git >/dev/null 2>&1 || die "git est requis (ou passe XNM_SRC=/chemin/deja/clone)."
  TMP_CLONE="$(mktemp -d)"
  log "Clone de $REPO_URL…"
  git clone --depth 1 --quiet "$REPO_URL" "$TMP_CLONE/repo"
  SRC="$TMP_CLONE/repo"
fi
UP="$SRC/home"

# --------------------------------------------------------------------------
# Sauvegarde + copie
# --------------------------------------------------------------------------
mkdir -p "$BACKUP"

backup_path() {
  local path="$1"
  [[ -e "$path" || -L "$path" ]] || return 0
  local rel="${path#"$HOME"/}"
  mkdir -p "$BACKUP/$(dirname "$rel")"
  cp -a "$path" "$BACKUP/$(dirname "$rel")/"
}

# copy <source relative à home/> <destination absolue>
copy() {
  local src="$UP/$1" dst="$2"
  [[ -e "$src" ]] || { warn "absent du dépôt amont : $1"; return 0; }
  backup_path "$dst"
  mkdir -p "$(dirname "$dst")"
  rm -rf "$dst"
  cp -a "$src" "$dst"
}

log "Copie des fichiers purement visuels…"

# Palette Hyprland (utilisée par hyprlock et par le thème ci-dessous)
copy .config/hypr/macchiato.conf "$CONFIG_HOME/hypr/macchiato.conf"
copy .config/hypr/hyprlock.conf  "$CONFIG_HOME/hypr/hyprlock.conf"
copy .config/hypr/hyprpaper.conf "$CONFIG_HOME/hypr/hyprpaper.conf"

# Waybar : le style est repris tel quel, la config est nettoyée plus bas
copy .config/waybar/macchiato.css "$CONFIG_HOME/waybar/macchiato.css"
copy .config/waybar/style.css     "$CONFIG_HOME/waybar/style.css"

# Rofi / Dunst / Kitty / Wlogout
copy .config/rofi/config.rasi                        "$CONFIG_HOME/rofi/config.rasi"
copy .config/rofi/themes/catppuccin-macchiato.rasi   "$CONFIG_HOME/rofi/themes/catppuccin-macchiato.rasi"
copy .config/dunst/dunstrc                           "$CONFIG_HOME/dunst/dunstrc"
copy .config/kitty/kitty.conf                        "$CONFIG_HOME/kitty/kitty.conf"
copy .config/wlogout/layout                          "$CONFIG_HOME/wlogout/layout"
copy .config/wlogout/style.css                       "$CONFIG_HOME/wlogout/style.css"
copy .config/wlogout/icons                           "$CONFIG_HOME/wlogout/icons"

# Thèmes GTK / Qt / XSettings + invite Starship
copy .config/gtk-3.0/settings.ini        "$CONFIG_HOME/gtk-3.0/settings.ini"
copy .config/gtk-3.0/gtk.css             "$CONFIG_HOME/gtk-3.0/gtk.css"
copy .config/gtk-4.0/settings.ini        "$CONFIG_HOME/gtk-4.0/settings.ini"
copy .config/gtk-4.0/gtk.css             "$CONFIG_HOME/gtk-4.0/gtk.css"
copy .config/xsettingsd/xsettingsd.conf  "$CONFIG_HOME/xsettingsd/xsettingsd.conf"
copy .config/starship.toml               "$CONFIG_HOME/starship.toml"
copy .gtkrc-2.0                          "$HOME/.gtkrc-2.0"

# Qt : le dépôt amont livre une copie « theme# » sans le .svg, donc inutilisable.
# On pointe directement sur le thème fourni par le paquet catppuccin-kvantum.
backup_path "$CONFIG_HOME/Kvantum/kvantum.kvconfig"
mkdir -p "$CONFIG_HOME/Kvantum"
cat > "$CONFIG_HOME/Kvantum/kvantum.kvconfig" <<'EOF'
[General]
theme=catppuccin-macchiato-teal
EOF

# Les noms de thème de .gtkrc-2.0 datent d'anciennes versions des paquets ;
# on les aligne sur ce que produisent catppuccin-gtk et Colloid aujourd'hui.
sed -i \
  -e 's/^gtk-theme-name=.*/gtk-theme-name="catppuccin-macchiato-teal-standard"/' \
  -e 's/^gtk-icon-theme-name=.*/gtk-icon-theme-name="Colloid-Teal-Dark"/' \
  "$HOME/.gtkrc-2.0"

# Curseurs Catppuccin Macchiato Teal (fournis dans le dépôt, aucun paquet requis)
copy .icons "$HOME/.icons"

# --------------------------------------------------------------------------
# Waybar : on retire les modules qui dépendent des fonctions Fish de XNM1
# (webcam, enregistrement, geo, media, mode avion, mode nuit, dunst) et la
# disposition clavier perso. Le reste (3 barres + style) est identique.
# --------------------------------------------------------------------------
log "Nettoyage de la config Waybar (suppression des dépendances Fish)…"

DROP='custom/webcam,custom/recording,custom/geo,custom/media,custom/airplane_mode,custom/night_mode,custom/dunst,hyprland/language'

backup_path "$CONFIG_HOME/waybar/config"
awk -v DROP="$DROP" '
function nb(s, c,   i, n) { n = 0; for (i = 1; i <= length(s); i++) if (substr(s, i, 1) == c) n++; return n }
BEGIN { n = split(DROP, a, ","); for (i = 1; i <= n; i++) drop[a[i]] = 1 }
{
  if (skip) {
    depth += nb($0, "{") - nb($0, "}")
    if (depth <= 0) skip = 0
    next
  }
  key = ""
  if ($0 ~ /^[[:space:]]*"[^"]+"[[:space:]]*:[[:space:]]*\{/) {
    key = $0
    sub(/^[[:space:]]*"/, "", key)
    sub(/".*$/, "", key)
  }
  if (key != "" && (key in drop)) {
    depth = nb($0, "{") - nb($0, "}")
    if (depth > 0) skip = 1
    next
  }
  print
}
' "$UP/.config/waybar/config" > "$CONFIG_HOME/waybar/config.tmp"

sed -E -i \
  -e '/^[[:space:]]*"custom\/(webcam|recording|geo|media|airplane_mode|night_mode|dunst)",?[[:space:]]*$/d' \
  -e '/^[[:space:]]*"hyprland\/language",?[[:space:]]*$/d' \
  -e 's/"custom\/(webcam|recording|geo|media|airplane_mode|night_mode|dunst)", *//g' \
  -e 's/, *"hyprland\/language"//g' \
  -e 's/"hyprland\/language", *//g' \
  -e 's/fish -c wlogout_uniqe/wlogout -p layer-shell/' \
  -e '/fish -c /d' \
  -e '/overskride|iwgtk/d' \
  -e 's/wezterm start /kitty /g' \
  -e '/"thermal-zone"/d' \
  "$CONFIG_HOME/waybar/config.tmp"

mv "$CONFIG_HOME/waybar/config.tmp" "$CONFIG_HOME/waybar/config"

# --------------------------------------------------------------------------
# Kitty : on garde les couleurs et la police, pas le shell ni l'éditeur perso
# --------------------------------------------------------------------------
sed -E -i \
  -e 's/^shell fish$/# shell fish  # retiré : ton shell par défaut est conservé/' \
  -e 's/^editor hx$/# editor hx  # retiré/' \
  -e '/kitten search\.py/s/^/# /' \
  "$CONFIG_HOME/kitty/kitty.conf"

# Rofi : wezterm n'est pas installé ici
sed -i 's/terminal: "wezterm"/terminal: "kitty"/' "$CONFIG_HOME/rofi/config.rasi"

# Hyprpaper : les moniteurs de XNM1 (eDP-1 / HDMI-A-1) sont remplacés par « tous »
cat > "$CONFIG_HOME/hypr/hyprpaper.conf" <<'EOF'
# Fond d'écran : place ton image dans ~/background
preload = ~/background

wallpaper = , ~/background

ipc = false
splash = false
EOF

# --------------------------------------------------------------------------
# Hyprland : uniquement les sections visuelles du hyprland.conf amont.
# Ni moniteurs, ni raccourcis, ni exec-once Fish, ni disposition clavier.
# --------------------------------------------------------------------------
log "Écriture du thème Hyprland (~/.config/hypr/xnm-visual.conf)…"

backup_path "$CONFIG_HOME/hypr/xnm-visual.conf"
cat > "$CONFIG_HOME/hypr/xnm-visual.conf" <<'EOF'
# Visuel repris de XNM1/linux-nixos-hyprland-config-dotfiles.
# Aucun moniteur, raccourci, shell ou script externe n'est imposé ici.

# La palette est chargée ici même : l'ordre des « source » dans
# hyprland.conf n'a donc aucune importance ($teal, $surface1, etc.).
source = ~/.config/hypr/macchiato.conf

# Curseurs : hyprcursor lit le nom du manifest, XCursor le nom du dossier
env = HYPRCURSOR_THEME,Catppuccin-Macchiato-Teal
env = HYPRCURSOR_SIZE,24
env = XCURSOR_THEME,Catppuccin-Macchiato-Teal-Cursors
env = XCURSOR_SIZE,24

general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = $teal
    col.inactive_border = $surface1
    col.nogroup_border_active = $teal
    col.nogroup_border = $surface1

    layout = dwindle
}

decoration {
    rounding = 10

    blur {
        size = 8
        passes = 2
    }

    shadow {
        enabled = true
        range = 8
        render_power = 3
        offset = 0, 0
        color = $teal
        color_inactive = 0xff$baseAlpha
    }

    active_opacity = 0.7
    inactive_opacity = 0.7
    fullscreen_opacity = 0.7
}

layerrule = blur on, match:namespace logout_dialog

animations {
    enabled = yes

    bezier = myBezier, 0.05, 0.9, 0.1, 1.05

    animation = windows, 1, 2, myBezier
    animation = windowsOut, 1, 2, default, popin 80%
    animation = windowsMove, 1, 2, myBezier, slide
    animation = border, 1, 3, default
    animation = fade, 1, 2, default
    animation = workspaces, 1, 1, default
}

dwindle {
    preserve_split = yes
    smart_split = true
}

master {
    new_status = master
}

misc {
    disable_hyprland_logo = true
    disable_splash_rendering = true
    background_color = 0x24273a
}

# Fenêtres flottantes opaques et centrées, comme en amont
windowrule = float on, match:title .*mpv$
windowrule = opaque on, match:title .*mpv$
windowrule = size 50% 50%, match:title .*mpv$

windowrule = float on, match:title .*imv.*
windowrule = opaque on, match:title .*imv.*
windowrule = size 70% 70%, match:title .*imv.*

windowrule = float on, match:title .*\.pdf$
windowrule = opaque on, match:title .*\.pdf$
windowrule = maximize on, match:title .*\.pdf$
EOF

# --------------------------------------------------------------------------
# Branchement dans le hyprland.conf existant (créé s'il n'existe pas)
# --------------------------------------------------------------------------
MAIN="$CONFIG_HOME/hypr/hyprland.conf"
backup_path "$MAIN"

if [[ ! -f "$MAIN" ]]; then
  log "Aucun hyprland.conf : création d'un fichier minimal."
  cat > "$MAIN" <<'EOF'
# Configuration minimale. Adapte moniteurs et raccourcis à ton matériel.
monitor = , preferred, auto, 1

source = ~/.config/hypr/xnm-visual.conf

exec-once = waybar
exec-once = dunst
exec-once = hyprpaper
exec-once = xsettingsd

bind = SUPER, RETURN, exec, kitty
bind = SUPER, D, exec, rofi -show drun
bind = SUPER, ESCAPE, exec, wlogout -p layer-shell
bind = SUPER SHIFT, L, exec, hyprlock
bind = SUPER SHIFT, Q, killactive
EOF
else
  # xnm-visual.conf charge lui-même la palette : l'ordre est indifférent.
  if ! grep -q 'hypr/xnm-visual.conf' "$MAIN"; then
    printf '\nsource = ~/.config/hypr/xnm-visual.conf\n' >> "$MAIN"
  fi
  # Une ligne « source = …/macchiato.conf » ajoutée par une version
  # précédente de ce script devient inutile : on la neutralise pour éviter
  # un double chargement de la palette.
  sed -i 's|^\([[:space:]]*source[[:space:]]*=[[:space:]]*~/\.config/hypr/macchiato\.conf\)|# \1|' "$MAIN"

  if grep -q 'ilyamiro-visual' "$MAIN"; then
    warn "hyprland.conf référence encore ilyamiro-visual.conf : retire cette ligne, les deux thèmes se marcheraient dessus."
  fi
  for app in waybar dunst hyprpaper xsettingsd; do
    if ! grep -Eq "^[[:space:]]*exec-once[[:space:]]*=.*\b${app}\b" "$MAIN"; then
      printf 'exec-once = %s\n' "$app" >> "$MAIN"
    fi
  done
fi

# --------------------------------------------------------------------------
# Paquets nécessaires (module NixOS prêt à importer)
# --------------------------------------------------------------------------
cat > "$NIX_OUT" <<'EOF'
# Généré par install-xnm-visual.sh — paquets nécessaires au visuel de XNM1.
# À importer depuis configuration.nix :
#   imports = [ ./xnm-visual-packages.nix ];
{ pkgs, ... }:

{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    QT_STYLE_OVERRIDE = "kvantum";
  };

  environment.systemPackages = with pkgs; [
    # Barre, lanceur, notifications, terminal, menu de session
    waybar
    rofi-wayland
    dunst
    libnotify
    kitty
    starship
    wlogout

    # Fond d'écran, verrouillage
    hyprpaper
    hyprlock

    # Modules Waybar
    playerctl
    pavucontrol
    # btop bottom  # optionnel : clics CPU / RAM / disque de la barre

    # Thème GTK -> share/themes/catppuccin-macchiato-teal-standard
    (catppuccin-gtk.override {
      accents = [ "teal" ];
      size = "standard";
      variant = "macchiato";
    })

    # Icônes -> share/icons/Colloid-Teal-Dark (sans l'override, seul le bleu
    # est construit) et share/icons/Numix-Circle (taskbar Waybar + Rofi)
    (colloid-icon-theme.override {
      colorVariants = [ "teal" ];
      schemeVariants = [ "default" ];
    })
    numix-icon-theme-circle

    # Qt -> share/Kvantum/catppuccin-macchiato-teal
    (catppuccin-kvantum.override {
      accent = "teal";
      variant = "macchiato";
    })
    qt6Packages.qtstyleplugin-kvantum
    libsForQt5.qtstyleplugin-kvantum

    xsettingsd
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    noto-fonts-color-emoji
  ];
}
EOF

# --------------------------------------------------------------------------
# Rapport
# --------------------------------------------------------------------------
missing=()
for cmd in waybar rofi dunst kitty wlogout hyprpaper hyprlock starship playerctl xsettingsd; do
  command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done

# Les configs GTK/Qt/icônes pointent sur ces dossiers : sans eux, aucun thème
# ne s'applique (paquets absents ou nommés autrement dans ta version nixpkgs).
themes_missing=()
for theme in \
  themes/catppuccin-macchiato-teal-standard \
  icons/Colloid-Teal-Dark \
  icons/Numix-Circle \
  Kvantum/catppuccin-macchiato-teal
do
  found=""
  for root in /run/current-system/sw/share "$HOME/.nix-profile/share" "$HOME/.local/share" /usr/share; do
    [[ -e "$root/$theme" ]] && { found=1; break; }
  done
  [[ -n "$found" ]] || themes_missing+=("$theme")
done

printf '\n\033[1;32mVisuel XNM1 installé.\033[0m\n'
printf 'Sauvegarde des anciens fichiers : %s\n' "$BACKUP"
printf 'Paquets à installer : %s\n' "$NIX_OUT"
printf 'Exclus : IA, Fish, Helix, Yazi, Zellij, qutebrowser, moniteurs, raccourcis.\n'

[[ -e "$HOME/background" ]] || warn "~/background manquant : place-y une image (fond d'écran + hyprlock)."
[[ -e "$HOME/.face" ]]      || warn "~/.face manquant : avatar de hyprlock (image carrée)."

if ((${#missing[@]})); then
  warn "Commandes absentes : ${missing[*]}"
fi

if ((${#themes_missing[@]})); then
  warn "Thèmes absents : ${themes_missing[*]}"
fi

if ((${#missing[@]} || ${#themes_missing[@]})); then
  warn "Importe $NIX_OUT dans configuration.nix puis « sudo nixos-rebuild switch »."
fi

if command -v hyprctl >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 || true
fi
