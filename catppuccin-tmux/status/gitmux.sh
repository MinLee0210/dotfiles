show_gitmux() {

  local cwd=$(tmux display-message -p -F "#{pane_current_path}")
  if ! command -v gitmux >/dev/null 2>&1; then
    return
  fi

  local index=$1
  local icon="$(get_tmux_option "@catppuccin_gitmux_icon" "")"
  local color="$(get_tmux_option "@catppuccin_gitmux_color" "$thm_green")"
  # local text="$(get_tmux_option "@catppuccin_gitmux_text" "#(gitmux \"#{pane_current_path}\")")"
  local text="$(get_tmux_option "@catppuccin_gitmux_text" "#(gitmux -cfg $HOME/.config/.gitmux.conf \"#{pane_current_path}\")")"

  local module=$( build_status_module "$index" "$icon" "$color" "$text" )
  echo "$module"
}
