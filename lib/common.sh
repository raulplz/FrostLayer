#!/usr/bin/env bash
# Funciones compartidas por la CLI y los módulos de FrostLayer.

FL_STATE="${FROSTLAYER_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/frostlayer}"
FL_DRY_RUN="${FROSTLAYER_DRY_RUN:-0}"

if [[ -t 1 ]]; then
  FL_C_ICE=$'\e[38;2;156;220;245m' FL_C_BLUE=$'\e[38;2;77;163;255m' FL_C_DIM=$'\e[38;2;130;146;166m'
  FL_C_OK=$'\e[38;2;143;190;160m' FL_C_WARN=$'\e[38;2;230;191;121m' FL_C_ERR=$'\e[38;2;239;113;128m'
  FL_C_RESET=$'\e[0m'
else
  FL_C_ICE='' FL_C_BLUE='' FL_C_DIM='' FL_C_OK='' FL_C_WARN='' FL_C_ERR='' FL_C_RESET=''
fi

fl_info() { printf '%s❄%s %s\n' "$FL_C_BLUE" "$FL_C_RESET" "$*"; }
fl_ok()   { printf '%s✓%s %s\n' "$FL_C_OK" "$FL_C_RESET" "$*"; }
fl_warn() { printf '%s!%s %s\n' "$FL_C_WARN" "$FL_C_RESET" "$*" >&2; }
fl_err()  { printf '%s✗%s %s\n' "$FL_C_ERR" "$FL_C_RESET" "$*" >&2; }
fl_dim()  { printf '%s%s%s\n' "$FL_C_DIM" "$*" "$FL_C_RESET"; }

# Ejecuta un comando, o solo lo muestra en modo de prueba.
fl_run() {
  if [[ $FL_DRY_RUN == 1 ]]; then
    fl_dim "  (prueba) $*"
  else
    "$@"
  fi
}

# Copia un archivo antes de modificarlo, una sola vez por módulo.
# Las copias quedan en $FL_STATE/backups/<módulo>/<ruta relativa a $HOME>.
fl_backup() {
  local module=$1 path=$2
  local rel=${path#"$HOME"/}
  local dest="$FL_STATE/backups/$module/$rel"
  [[ -e $path && ! -e $dest ]] || return 0
  [[ $FL_DRY_RUN == 1 ]] && { fl_dim "  (prueba) copia de $path"; return 0; }
  mkdir -p "$(dirname "$dest")"
  cp -a "$path" "$dest"
}

# Devuelve el archivo a su estado anterior si hay copia.
fl_restore() {
  local module=$1 path=$2
  local rel=${path#"$HOME"/}
  local src="$FL_STATE/backups/$module/$rel"
  [[ -e $src ]] || return 1
  fl_run cp -a "$src" "$path"
}

# Bloques marcados dentro de archivos que no son nuestros:
#   <comentario> >>> FrostLayer:<módulo>
#   ...
#   <comentario> <<< FrostLayer:<módulo>
# fl_block_set reemplaza el bloque si existe o lo añade al final.
fl_block_set() {
  local file=$1 module=$2 comment=$3 content=$4
  local start="$comment >>> FrostLayer:$module" end="$comment <<< FrostLayer:$module"
  [[ $FL_DRY_RUN == 1 ]] && { fl_dim "  (prueba) bloque $module en $file"; return 0; }
  mkdir -p "$(dirname "$file")"
  touch "$file"
  fl_block_remove "$file" "$module" "$comment"
  [[ -s $file && $(tail -c1 "$file") != "" ]] && printf '\n' >>"$file"
  printf '%s\n%s\n%s\n' "$start" "$content" "$end" >>"$file"
}

fl_block_remove() {
  local file=$1 module=$2 comment=$3
  [[ -f $file ]] || return 0
  [[ $FL_DRY_RUN == 1 ]] && { fl_dim "  (prueba) quitar bloque $module de $file"; return 0; }
  local start="$comment >>> FrostLayer:$module" end="$comment <<< FrostLayer:$module"
  awk -v s="$start" -v e="$end" '$0==s{skip=1; next} $0==e{skip=0; next} !skip' "$file" >"$file.frostlayer.tmp"
  mv "$file.frostlayer.tmp" "$file"
}

fl_block_present() {
  local file=$1 module=$2 comment=$3
  [[ -f $file ]] && grep -qxF "$comment >>> FrostLayer:$module" "$file"
}

# Estado de cada módulo instalado: $FL_STATE/installed/<módulo>
fl_mark_installed() {
  [[ $FL_DRY_RUN == 1 ]] && return 0
  mkdir -p "$FL_STATE/installed"
  date '+%Y-%m-%d %H:%M' >"$FL_STATE/installed/$1"
}
fl_unmark_installed() { [[ $FL_DRY_RUN == 1 ]] || rm -f "$FL_STATE/installed/$1"; }
fl_is_installed() { [[ -f $FL_STATE/installed/$1 ]]; }

# Datos pequeños que un módulo necesita para deshacer (p. ej. el tema anterior).
fl_state_set() { [[ $FL_DRY_RUN == 1 ]] || { mkdir -p "$FL_STATE/data"; printf '%s\n' "$3" >"$FL_STATE/data/$1.$2"; }; }
fl_state_get() { cat "$FL_STATE/data/$1.$2" 2>/dev/null; }
