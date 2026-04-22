#!/usr/bin/env bash
# Cheat sheet de keybindings en wofi (solo visualización)

printf '%s\n' \
    "── VENTANAS ──────────────────────────────" \
    "  Super + Enter          Terminal (kitty)" \
    "  Super + Q              Cerrar ventana" \
    "  Super + V              Float toggle" \
    "  Super + J              Split toggle" \
    "  Super + ←→↑↓           Mover foco" \
    "  Super + Shift + ←→↑↓   Mover ventana" \
    "" \
    "── WORKSPACES ────────────────────────────" \
    "  Super + 1-9/0          Ir a workspace" \
    "  Super + Shift + 1-9/0  Mover ventana" \
    "  Super + Scroll         Workspace prev/next" \
    "" \
    "── SCRATCHPAD ────────────────────────────" \
    "  Super + S              Mostrar scratchpad" \
    "  Super + Shift + S      Enviar al scratchpad" \
    "" \
    "── APPS ──────────────────────────────────" \
    "  Super + Space          Launcher (wofi)" \
    "  Super + E              Explorador (thunar)" \
    "  Super + /              Este cheat sheet" \
    "" \
    "── SISTEMA ───────────────────────────────" \
    "  Super + L              Bloquear pantalla" \
    "  Super + M              Power menu" \
    "  Super + Ctrl+Shift+R   Recargar config" \
    "  Super + Shift + I      Toggle idle/sleep" \
    "" \
    "── MULTIMEDIA ────────────────────────────" \
    "  XF86AudioRaise/Lower   Volumen" \
    "  XF86AudioMute          Silenciar" \
    "  XF86Brightness Up/Down Brillo" \
    "  XF86Audio Next/Prev    Siguiente/Anterior" \
    "  XF86AudioPlay/Pause    Play/Pausa" \
    "" \
    "── CAPTURAS ──────────────────────────────" \
    "  Print                  Captura área" \
    "  Shift + Print          Captura pantalla" \
    | wofi --dmenu \
           --prompt "Keybindings" \
           --width 700 \
           --height 760 \
           --no-actions \
           --hide-search \
           --insensitive \
           --define=key_expand=none
