# Catppuccin Mocha — defined once, used by every surface that needs raw hex.
#
# kitty, tmux and nvim carry their own theme files; these exports are for the
# tools configured through environment variables (fzf, bat) and for anything
# machine-local that wants the palette.
# Reference: https://github.com/catppuccin/catppuccin (Mocha)

export CTP_ROSEWATER="#f5e0dc"
export CTP_FLAMINGO="#f2cdcd"
export CTP_PINK="#f5c2e7"
export CTP_MAUVE="#cba6f7"
export CTP_RED="#f38ba8"
export CTP_MAROON="#eba0ac"
export CTP_PEACH="#fab387"
export CTP_YELLOW="#f9e2af"
export CTP_GREEN="#a6e3a1"
export CTP_TEAL="#94e2d5"
export CTP_SKY="#89dceb"
export CTP_SAPPHIRE="#74c7ec"
export CTP_BLUE="#89b4fa"
export CTP_LAVENDER="#b4befe"
export CTP_TEXT="#cdd6f4"
export CTP_SUBTEXT1="#bac2de"
export CTP_SUBTEXT0="#a6adc8"
export CTP_OVERLAY2="#9399b2"
export CTP_OVERLAY1="#7f849c"
export CTP_OVERLAY0="#6c7086"
export CTP_SURFACE2="#585b70"
export CTP_SURFACE1="#45475a"
export CTP_SURFACE0="#313244"
export CTP_BASE="#1e1e2e"
export CTP_MANTLE="#181825"
export CTP_CRUST="#11111b"

# bat ships a Catppuccin theme upstream; fall back silently if the build is old.
export BAT_THEME="Catppuccin Mocha"
