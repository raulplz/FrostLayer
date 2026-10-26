#!/usr/bin/env bash
# Tema de Omarchy «Frost»: paleta Obsidian Blue, fondo propio e iconos de carpeta Frost.

MODULE_DESC="Tema Frost para Omarchy (colores, fondo e iconos de carpeta)"
MODULE_DEFAULT=1

THEME_SRC="$MODULE_DIR/files/frost"
ICONS_SRC="$MODULE_DIR/files/icons/Frost"
THEME_DST="$HOME/.config/omarchy/themes/frost"
ICONS_DST="$HOME/.local/share/icons/Frost"

module_check() {
  command -v omarchy-theme-set >/dev/null || { echo "falta omarchy-theme-set (¿es Omarchy?)"; return 1; }
}

module_apply() {
  local current
  current=$(omarchy-theme-current 2>/dev/null || true)
  if [[ -n $current && ${current,,} != frost ]]; then
    fl_state_set theme previous "$current"
  fi

  if [[ -e $THEME_DST && ! -e $THEME_DST/.frostlayer ]]; then
    fl_err "Ya existe un tema «frost» que no es de FrostLayer: $THEME_DST"
    return 1
  fi
  fl_run mkdir -p "$(dirname "$THEME_DST")" "$(dirname "$ICONS_DST")"
  fl_run rm -rf "$THEME_DST" "$ICONS_DST"
  fl_run cp -r "$THEME_SRC" "$THEME_DST"
  fl_run cp -r "$ICONS_SRC" "$ICONS_DST"
  fl_run touch "$THEME_DST/.frostlayer" "$ICONS_DST/.frostlayer"

  # Los iconos Frost heredan de Yaru y Breeze para todo lo que no son carpetas.
  local missing=()
  [[ -d /usr/share/icons/Yaru-blue ]] || missing+=(yaru-icon-theme)
  [[ -d /usr/share/icons/breeze-dark ]] || missing+=(breeze-icons)
  if ((${#missing[@]})); then
    fl_info "Instalando iconos base: ${missing[*]}"
    fl_run omarchy-pkg-add "${missing[@]}" || fl_warn "No se pudieron instalar ${missing[*]}; los iconos usarán hicolor"
  fi

  fl_run omarchy-theme-set frost
}

module_revert() {
  local previous
  previous=$(fl_state_get theme previous)
  if [[ -n $previous ]]; then
    fl_run omarchy-theme-set "$previous" || fl_warn "No se pudo volver al tema «$previous»; elígelo en el menú de Omarchy"
  else
    fl_warn "No sé qué tema tenías antes; elige otro en el menú de Omarchy (Super+Alt+Espacio → Estilo → Tema)"
  fi
  [[ -e $THEME_DST/.frostlayer ]] && fl_run rm -rf "$THEME_DST"
  [[ -e $ICONS_DST/.frostlayer ]] && fl_run rm -rf "$ICONS_DST"
  return 0
}
