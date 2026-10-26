#!/usr/bin/env bash
# Instalador de FrostLayer:
#   curl -fsSL https://raw.githubusercontent.com/raulplz/FrostLayer/main/install.sh | bash
# Sin preguntas (módulos por defecto):
#   curl -fsSL https://raw.githubusercontent.com/raulplz/FrostLayer/main/install.sh | bash -s -- --yes

set -euo pipefail

REPO=${FROSTLAYER_REPO:-https://github.com/raulplz/FrostLayer.git}
DIR=${FROSTLAYER_DIR:-$HOME/.local/share/frostlayer}

say() { printf '\e[38;2;77;163;255m❄\e[0m %s\n' "$*"; }
die() { printf '\e[38;2;239;113;128m✗\e[0m %s\n' "$*" >&2; exit 1; }

[[ $EUID -ne 0 ]] || die "No lo ejecutes como root: FrostLayer pide sudo solo cuando lo necesita."
command -v git >/dev/null || die "Falta git."
if ! command -v omarchy >/dev/null && [[ ${FROSTLAYER_FORCE:-0} != 1 ]]; then
  die "FrostLayer está hecho para Omarchy (https://omarchy.org). Para probar igualmente: FROSTLAYER_FORCE=1"
fi

if [[ -d $DIR/.git ]]; then
  say "Actualizando FrostLayer en $DIR"
  git -C "$DIR" pull --ff-only --quiet
else
  say "Descargando FrostLayer en $DIR"
  git clone --depth 1 --quiet "$REPO" "$DIR"
fi

mkdir -p "$HOME/.local/bin"
ln -sf "$DIR/bin/frostlayer" "$HOME/.local/bin/frostlayer"

# Con «curl | bash» la entrada es el propio script: el menú lee del terminal.
if [[ -r /dev/tty ]] && { : </dev/tty; } 2>/dev/null; then
  exec "$DIR/bin/frostlayer" install "$@" </dev/tty
else
  exec "$DIR/bin/frostlayer" install --yes "$@"
fi
