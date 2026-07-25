#!/usr/bin/env bash
set -Eeuo pipefail

UPSTREAM_REPO="${UPSTREAM_REPO:-https://github.com/XNM1/linux-nixos-hyprland-config-dotfiles.git}"
WORKDIR="${XDG_CACHE_HOME:-$HOME/.cache}/xnm-visual-source"
BACKUP_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/xnm-visual-backups"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
SCRIPT_PATH="$(readlink -f "$0")"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mAttention:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mErreur:\033[0m %s\n' "$*" >&2; exit 1; }

# Installe temporairement les outils nécessaires sans modifier le système.
if ! command -v git >/dev/null 2>&1 || ! command -v rsync >/dev/null 2>&1; then
  command -v nix-shell >/dev/null 2>&1 ||
    die "git/rsync manquent et nix-shell est introuvable."
  log "Ouverture d'un environnement temporaire avec git et rsync…"
  exec nix-shell -p git rsync gnused --run "bash '$SCRIPT_PATH'"
fi

mkdir -p "$CONFIG_DIR" "$BACKUP_DIR" "$(dirname "$WORKDIR")"

log "Téléchargement de la configuration visuelle XNM1…"
if [[ -d "$WORKDIR/.git" ]]; then
  git -C "$WORKDIR" fetch --depth 1 origin main
  git -C "$WORKDIR" reset --hard origin/main
else
  rm -rf "$WORKDIR"
  git clone --depth 1 "$UPSTREAM_REPO" "$WORKDIR"
fi

SOURCE_HOME="$WORKDIR/home"
[[ -d "$SOURCE_HOME/.config" ]] ||
  die "La structure du dépôt a changé : home/.config est introuvable."

# Uniquement les composants essentiellement visuels.
CONFIG_COMPONENTS=(
  waybar
  rofi
  dunst
  kitty
  wlogout
  hyprpaper
  gtk-3.0
  gtk-4.0
  Kvantum
)

backup_path() {
  local source="$1"
  local relative="${source#$HOME/}"
  if [[ -e "$source" || -L "$source" ]]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$relative")"
    rsync -a "$source" "$BACKUP_DIR/$(dirname "$relative")/"
  fi
}

copy_component() {
  local name="$1"
  local source="$SOURCE_HOME/.config/$name"
  local target="$CONFIG_DIR/$name"

  if [[ ! -e "$source" ]]; then
    warn "$name absent du dépôt actuel, composant ignoré."
    return
  fi

  backup_path "$target"
  mkdir -p "$target"
  rsync -a --delete "$source/" "$target/"
  log "Copié : ~/.config/$name"
}

log "Sauvegarde des configurations remplacées dans : $BACKUP_DIR"
for component in "${CONFIG_COMPONENTS[@]}"; do
  copy_component "$component"
done

# Fonds d’écran et icônes, sans toucher aux autres fichiers personnels du dépôt.
for item in background .icons; do
  source="$SOURCE_HOME/$item"
  target="$HOME/$item"

  if [[ -d "$source" ]]; then
    backup_path "$target"
    mkdir -p "$target"
    rsync -a "$source/" "$target/"
    log "Copié : ~/$item"
  elif [[ -f "$source" || -L "$source" ]]; then
    backup_path "$target"
    mkdir -p "$(dirname "$target")"
    rsync -a "$source" "$target"
    log "Copié : ~/$item"
  else
    warn "$item absent du dépôt actuel, élément ignoré."
  fi
done

# Corrige les chemins personnels codés en dur dans les seuls fichiers copiés.
log "Adaptation des chemins /home/xnm vers $HOME…"
SEARCH_PATHS=()
for component in "${CONFIG_COMPONENTS[@]}"; do
  [[ -d "$CONFIG_DIR/$component" ]] && SEARCH_PATHS+=("$CONFIG_DIR/$component")
done
[[ -d "$HOME/background" ]] && SEARCH_PATHS+=("$HOME/background")

if ((${#SEARCH_PATHS[@]})); then
  while IFS= read -r -d '' file; do
    sed -i \
      -e "s#/home/xnm#$HOME#g" \
      -e "s#~xnm#$HOME#g" \
      "$file" || true
  done < <(grep -IRIlZ --exclude='*.png' --exclude='*.jpg' --exclude='*.jpeg' \
           --exclude='*.webp' --exclude='*.gif' '/home/xnm\|~xnm' \
           "${SEARCH_PATHS[@]}" 2>/dev/null || true)
fi

# Ne remplace pas les raccourcis ni les règles personnelles de Hyprland.
# Ce fichier ne contient que le rendu visuel.
mkdir -p "$CONFIG_DIR/hypr"
VISUAL_CONF="$CONFIG_DIR/hypr/xnm-visual.conf"
backup_path "$VISUAL_CONF"

cat > "$VISUAL_CONF" <<'HYPR'
# Aspect inspiré de XNM1, sans importer ses raccourcis, écrans ou scripts.
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(c6a0f6ff) rgba(8aadf4ff) 45deg
    col.inactive_border = rgba(494d64aa)
    layout = dwindle
    resize_on_border = true
}

decoration {
    rounding = 10

    active_opacity = 1.0
    inactive_opacity = 0.96

    shadow {
        enabled = true
        range = 12
        render_power = 3
        color = rgba(181926aa)
    }

    blur {
        enabled = true
        size = 6
        passes = 2
        new_optimizations = true
        ignore_opacity = true
        xray = false
    }
}

animations {
    enabled = true

    bezier = emphasized, 0.16, 1, 0.3, 1
    animation = windows, 1, 5, emphasized
    animation = windowsOut, 1, 4, default, popin 80%
    animation = border, 1, 6, default
    animation = borderangle, 1, 8, default
    animation = fade, 1, 4, default
    animation = workspaces, 1, 5, emphasized, slide
}

dwindle {
    pseudotile = true
    preserve_split = true
}
HYPR

MAIN_HYPR="$CONFIG_DIR/hypr/hyprland.conf"
touch "$MAIN_HYPR"
SOURCE_LINE='source = ~/.config/hypr/xnm-visual.conf'
if ! grep -Fqx "$SOURCE_LINE" "$MAIN_HYPR"; then
  backup_path "$MAIN_HYPR"
  {
    printf '\n# Thème visuel XNM1\n'
    printf '%s\n' "$SOURCE_LINE"
  } >> "$MAIN_HYPR"
fi

# Ajoute les démarrages visuels seulement s'ils ne sont pas déjà présents.
declare -a AUTOSTART_LINES=(
  "exec-once = waybar"
  "exec-once = dunst"
  "exec-once = hyprpaper"
  "exec-once = nm-applet"
)
for line in "${AUTOSTART_LINES[@]}"; do
  command_name="${line#exec-once = }"
  if ! grep -Eq "^[[:space:]]*exec-once[[:space:]]*=.*\b${command_name%% *}\b" "$MAIN_HYPR"; then
    printf '%s\n' "$line" >> "$MAIN_HYPR"
  fi
done

# Module NixOS séparé : facile à retirer et ne remplace pas configuration.nix.
NIX_MODULE_TMP="$(mktemp)"
cat > "$NIX_MODULE_TMP" <<'NIX'
{ pkgs, ... }:

{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  environment.systemPackages = with pkgs; [
    waybar
    rofi-wayland
    dunst
    kitty
    hyprpaper
    hyprlock
    hypridle
    wlogout

    grim
    slurp
    swappy
    wl-clipboard
    cliphist
    hyprpicker

    networkmanagerapplet
    pavucontrol
    brightnessctl
    playerctl
    numix-icon-theme-circle
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];
}
NIX

INSTALL_SYSTEM=1
[[ "${1:-}" == "--user-only" ]] && INSTALL_SYSTEM=0

if ((INSTALL_SYSTEM)); then
  [[ -f /etc/nixos/configuration.nix ]] ||
    die "/etc/nixos/configuration.nix est introuvable."

  log "Installation du module /etc/nixos/hyprland-visual.nix…"
  sudo cp "$NIX_MODULE_TMP" /etc/nixos/hyprland-visual.nix
  sudo chown root:root /etc/nixos/hyprland-visual.nix

  if ! grep -Eq '\./hyprland-visual\.nix' /etc/nixos/configuration.nix; then
    log "Ajout du module à imports dans configuration.nix…"
    sudo cp /etc/nixos/configuration.nix \
      "/etc/nixos/configuration.nix.backup-$TIMESTAMP"

    if grep -Eq '^[[:space:]]*imports[[:space:]]*=[[:space:]]*\[' /etc/nixos/configuration.nix; then
      sudo sed -i \
        '/^[[:space:]]*imports[[:space:]]*=[[:space:]]*\[/a\    ./hyprland-visual.nix' \
        /etc/nixos/configuration.nix
    else
      die "Bloc imports introuvable. Ajoute manuellement ./hyprland-visual.nix à imports."
    fi
  fi

  log "Vérification et reconstruction de NixOS…"
  sudo nixos-rebuild switch
else
  warn "Mode --user-only : le module NixOS n'a pas été installé."
  printf 'Ajoute toi-même les paquets requis avant de lancer Hyprland.\n'
fi

rm -f "$NIX_MODULE_TMP"

log "Installation terminée."
printf '\n'
printf 'Sauvegarde : %s\n' "$BACKUP_DIR"
printf 'Configuration visuelle : %s\n' "$VISUAL_CONF"
printf 'Recharge Hyprland avec : hyprctl reload\n'
printf 'En cas de souci, restaure les fichiers depuis la sauvegarde ci-dessus.\n'
