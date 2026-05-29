#!/system/bin/sh
# ============================================================
# RenDro - Android Gaming & Display Tuning Tool
# Creator : Renz
# YouTube : @Renz-Mc
# TikTok  : fsociety_rl
# License : Apache 2.0
# Target  : adb shell / Shizuku-like shell / Brevent-like shell
# Root    : Not required. Some tweaks depend on Android/OEM support.
# ============================================================

VERSION="1.1.0"
CREATOR="Renz"
YOUTUBE="@Renz-Mc"
TIKTOK="fsociety_rl"

WORKDIR="/sdcard/RenDro"
BACKUP_FILE="$WORKDIR/backup.properties"
LOG_FILE="$WORKDIR/rendro.log"
LOCK_DIR="/data/local/tmp/rendro_safe.lock"

MODE="${1:-help}"
ARG2="${2:-}"

if [ "${RENDRO_COLOR:-0}" = "1" ]; then
  ESC="$(printf '\033')"
  RED="${ESC}[31m"; GREEN="${ESC}[32m"; YELLOW="${ESC}[33m"; BLUE="${ESC}[34m"
  MAGENTA="${ESC}[35m"; CYAN="${ESC}[36m"; WHITE="${ESC}[37m"; BOLD="${ESC}[1m"
  DIM="${ESC}[2m"; RESET="${ESC}[0m"; BG_BLUE="${ESC}[44m"; BG_MAGENTA="${ESC}[45m"
else
  RED=""; GREEN=""; YELLOW=""; BLUE=""; MAGENTA=""; CYAN=""; WHITE=""; BOLD=""
  DIM=""; RESET=""; BG_BLUE=""; BG_MAGENTA=""
fi

cleanup() { rmdir "$LOCK_DIR" 2>/dev/null; }
trap cleanup EXIT HUP INT TERM

init_env() {
  mkdir -p "$WORKDIR" 2>/dev/null || true
  if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    printf '%s\n' "${YELLOW}[WARN] RenDro sedang berjalan. Jika tidak, hapus: $LOCK_DIR${RESET}"
    exit 1
  fi
}

log() {
  mkdir -p "$WORKDIR" 2>/dev/null || true
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null)" "$*" >>"$LOG_FILE" 2>/dev/null || true
}

info() { printf '%s\n' "${CYAN}[INFO]${RESET} $*"; log "INFO: $*"; }
ok()   { printf '%s\n' "${GREEN}[ OK ]${RESET} $*"; log "OK: $*"; }
warn() { printf '%s\n' "${YELLOW}[WARN]${RESET} $*"; log "WARN: $*"; }
fail() { printf '%s\n' "${RED}[FAIL]${RESET} $*"; log "FAIL: $*"; }

line() { printf '%s\n' "${DIM}${MAGENTA}============================================================${RESET}"; }
thin() { printf '%s\n' "${DIM}------------------------------------------------------------${RESET}"; }

banner() {
  [ "${RENDRO_CLEAR:-0}" = "1" ] && clear 2>/dev/null || true
  printf '%s\n' "${MAGENTA}${BOLD}"
  cat <<'ART'
 ██▀███  ▓█████  ███▄    █ ▓█████▄  ██▀███   ▒█████
▓██ ▒ ██▒▓█   ▀  ██ ▀█   █ ▒██▀ ██▌▓██ ▒ ██▒▒██▒  ██▒
▓██ ░▄█ ▒▒███   ▓██  ▀█ ██▒░██   █▌▓██ ░▄█ ▒▒██░  ██▒
▒██▀▀█▄  ▒▓█  ▄ ▓██▒  ▐▌██▒░▓█▄   ▌▒██▀▀█▄  ▒██   ██░
░██▓ ▒██▒░▒████▒▒██░   ▓██░░▒████▓ ░██▓ ▒██▒░ ████▓▒░
░ ▒▓ ░▒▓░░░ ▒░ ░░ ▒░   ▒ ▒  ▒▒▓  ▒ ░ ▒▓ ░▒▓░░ ▒░▒░▒░
  ░▒ ░ ▒░ ░ ░  ░░ ░░   ░ ▒░ ░ ▒  ▒   ░▒ ░ ▒░  ░ ▒ ▒░
  ░░   ░    ░      ░   ░ ░  ░ ░  ░   ░░   ░ ░ ░ ░ ▒
   ░        ░  ░         ░    ░       ░         ░ ░
                            ░
ART
  printf '%s\n' "${RESET}${CYAN}${BOLD}      Ultra Android Gaming Tuner - Command Edition${RESET}"
  printf '%s\n' "${WHITE}${BOLD}      Creator:${RESET} ${GREEN}$CREATOR${RESET} | ${WHITE}${BOLD}YouTube:${RESET} ${RED}$YOUTUBE${RESET} | ${WHITE}${BOLD}TikTok:${RESET} ${CYAN}$TIKTOK${RESET}"
  printf '%s\n' "${DIM}      Version $VERSION | Ultra/Balanced tanpa ubah DPI | Custom DPI & Res tetap ada${RESET}"
  line
}

is_uint() { case "${1:-}" in ''|*[!0-9]*) return 1 ;; *) return 0 ;; esac; }
is_res() { printf '%s' "${1:-}" | grep -Eq '^[0-9]{3,5}x[0-9]{3,5}$'; }
trim_cr() { tr -d '\r'; }

settings_get() { settings get "$1" "$2" 2>/dev/null | trim_cr; }
settings_put() {
  namespace="$1"
  key="$2"
  value="$3"
  if settings put "$namespace" "$key" "$value" >/dev/null 2>&1; then
    ok "$namespace.$key = $value"
    return 0
  fi
  warn "Skip $namespace.$key -> $value (tidak didukung / dibatasi ROM)."
  return 1
}
settings_delete() { settings delete "$1" "$2" >/dev/null 2>&1 || true; }

save_prop() {
  key="$1"
  value="$2"
  case "$key" in *[!A-Za-z0-9._-]*|'')
    warn "Backup key tidak aman: $key"
    return 1
    ;;
  esac
  printf '%s=%s\n' "$key" "$value" >>"$BACKUP_FILE" 2>/dev/null || true
}

prop_get() {
  key="$1"
  [ -f "$BACKUP_FILE" ] || return 0
  awk -v k="$key" 'BEGIN{FS="="} index($0,k"=")==1 {sub("^[^=]*=", ""); print; exit}' "$BACKUP_FILE" 2>/dev/null
}

backup_setting() {
  value="$(settings_get "$1" "$2")"
  [ -z "$value" ] && value="null"
  save_prop "settings.$1.$2" "$value"
}

get_wm_physical_size() { wm size 2>/dev/null | sed -n 's/.*Physical size: //p' | head -n 1 | trim_cr; }
get_wm_override_size() { wm size 2>/dev/null | sed -n 's/.*Override size: //p' | head -n 1 | trim_cr; }
get_wm_current_size() {
  override="$(get_wm_override_size)"
  if [ -n "$override" ]; then
    printf '%s\n' "$override"
  else
    get_wm_physical_size
  fi
}
get_wm_physical_density() { wm density 2>/dev/null | sed -n 's/.*Physical density: //p' | head -n 1 | trim_cr; }
get_wm_override_density() { wm density 2>/dev/null | sed -n 's/.*Override density: //p' | head -n 1 | trim_cr; }

get_width() { printf '%s' "$1" | awk -Fx '{print $1}'; }
get_height() { printf '%s' "$1" | awk -Fx '{print $2}'; }

min2() {
  if [ "$1" -le "$2" ] 2>/dev/null; then
    printf '%s\n' "$1"
  else
    printf '%s\n' "$2"
  fi
}
max2() {
  if [ "$1" -ge "$2" ] 2>/dev/null; then
    printf '%s\n' "$1"
  else
    printf '%s\n' "$2"
  fi
}

calc_adaptive_dpi() {
  width="$1"
  height="$2"
  short="$width"
  [ "$height" -lt "$width" ] 2>/dev/null && short="$height"

  if [ "$short" -le 800 ] 2>/dev/null; then
    echo 420
  elif [ "$short" -le 1080 ] 2>/dev/null; then
    echo 560
  elif [ "$short" -le 1260 ] 2>/dev/null; then
    echo 600
  elif [ "$short" -le 1440 ] 2>/dev/null; then
    echo 640
  else
    echo 680
  fi
}

validate_dpi() {
  dpi="$1"
  is_uint "$dpi" || return 1
  [ "$dpi" -ge 240 ] 2>/dev/null && [ "$dpi" -le 900 ] 2>/dev/null
}

validate_resolution_safe() {
  res="$1"
  phys="$2"
  is_res "$res" || return 1
  is_res "$phys" || return 1

  w="$(get_width "$res")"
  h="$(get_height "$res")"
  pw="$(get_width "$phys")"
  ph="$(get_height "$phys")"

  short="$(min2 "$w" "$h")"
  long="$(max2 "$w" "$h")"
  pshort="$(min2 "$pw" "$ph")"
  plong="$(max2 "$pw" "$ph")"

  min_short=$((pshort * 60 / 100))
  min_long=$((plong * 60 / 100))
  max_short=$((pshort * 120 / 100))
  max_long=$((plong * 120 / 100))

  [ "$min_short" -lt 480 ] && min_short=480
  [ "$min_long" -lt 800 ] && min_long=800
  [ "$max_short" -gt 2160 ] && max_short=2160
  [ "$max_long" -gt 3840 ] && max_long=3840

  [ "$short" -ge "$min_short" ] 2>/dev/null &&
  [ "$long" -ge "$min_long" ] 2>/dev/null &&
  [ "$short" -le "$max_short" ] 2>/dev/null &&
  [ "$long" -le "$max_long" ] 2>/dev/null
}

print_resolution_limits() {
  phys="$1"
  pw="$(get_width "$phys")"
  ph="$(get_height "$phys")"
  pshort="$(min2 "$pw" "$ph")"
  plong="$(max2 "$pw" "$ph")"

  min_short=$((pshort * 60 / 100))
  min_long=$((plong * 60 / 100))
  max_short=$((pshort * 120 / 100))
  max_long=$((plong * 120 / 100))

  [ "$min_short" -lt 480 ] && min_short=480
  [ "$min_long" -lt 800 ] && min_long=800
  [ "$max_short" -gt 2160 ] && max_short=2160
  [ "$max_long" -gt 3840 ] && max_long=3840

  info "Batas aman layar fisik $phys: sisi pendek $min_short-$max_short, sisi panjang $min_long-$max_long."
}

find_max_refresh_rate() {
  rate="$(dumpsys display 2>/dev/null | grep -Eo '([0-9]{2,3})(\.[0-9]+)?Hz|fps=[0-9]{2,3}(\.[0-9]+)?|refreshRate[ =][0-9]{2,3}(\.[0-9]+)?' | grep -Eo '[0-9]{2,3}(\.[0-9]+)?' | sort -nr | head -n 1)"
  [ -n "$rate" ] && echo "$rate" || echo 120
}

backup_wm() {
  save_prop "wm.physical_density" "$(get_wm_physical_density | sed 's/^$/null/')"
  save_prop "wm.override_density" "$(get_wm_override_density | sed 's/^$/null/')"
  save_prop "wm.physical_size" "$(get_wm_physical_size | sed 's/^$/null/')"
  save_prop "wm.override_size" "$(get_wm_override_size | sed 's/^$/null/')"
}

create_backup() {
  mkdir -p "$WORKDIR" 2>/dev/null || true
  [ -f "$BACKUP_FILE" ] && cp "$BACKUP_FILE" "$BACKUP_FILE.prev" 2>/dev/null || true
  : >"$BACKUP_FILE" || {
    fail "Tidak bisa menulis backup: $BACKUP_FILE"
    return 1
  }

  save_prop "rendro.version" "$VERSION"
  save_prop "rendro.creator" "$CREATOR"
  save_prop "backup.date" "$(date '+%Y-%m-%d_%H:%M:%S' 2>/dev/null)"
  backup_wm

  backup_setting global window_animation_scale
  backup_setting global transition_animation_scale
  backup_setting global animator_duration_scale
  backup_setting global force_gpu_rendering
  backup_setting global force_msaa
  backup_setting global disable_hw_overlays
  backup_setting global hardware_overlays_disabled
  backup_setting global development_settings_enabled
  backup_setting global show_hw_screen_updates
  backup_setting global show_hw_layers_updates
  backup_setting global debug.hwui.profile
  backup_setting global debug.hwui.renderer
  backup_setting system peak_refresh_rate
  backup_setting system min_refresh_rate
  backup_setting system user_refresh_rate
  backup_setting system refresh_rate_mode
  backup_setting system screen_refresh_rate
  backup_setting secure refresh_rate_mode
  backup_setting global low_power
  backup_setting global mobile_data_always_on
  backup_setting global wifi_scan_always_enabled
  backup_setting global cached_apps_freezer
  backup_setting global app_standby_enabled
  backup_setting global adaptive_battery_management_enabled
  backup_setting global sem_enhanced_cpu_responsiveness
  backup_setting global activity_manager_constants
  backup_setting global fstrim_mandatory_interval
  backup_setting system pointer_speed
  backup_setting system haptic_feedback_enabled
  backup_setting system sound_effects_enabled

  ok "Backup dibuat: $BACKUP_FILE"
}

apply_dpi_value() {
  dpi="$1"
  if validate_dpi "$dpi"; then
    if wm density "$dpi" >/dev/null 2>&1; then
      ok "DPI diset ke $dpi"
    else
      warn "Gagal set DPI ke $dpi"
    fi
  else
    warn "DPI '$dpi' tidak valid. Range aman: 240-900."
  fi
}

apply_adaptive_dpi() {
  res="$(get_wm_current_size)"
  [ -z "$res" ] && {
    warn "Resolusi tidak terdeteksi; DPI diskip."
    return 0
  }

  width="$(get_width "$res")"
  height="$(get_height "$res")"
  dpi="$(calc_adaptive_dpi "$width" "$height")"
  info "Resolusi aktif: ${width}x${height}; target DPI adaptive: $dpi"
  apply_dpi_value "$dpi"
}

apply_refresh_rate() {
  hz="$(find_max_refresh_rate)"
  info "Refresh target terdeteksi/fallback: ${hz}Hz"
  settings_put system peak_refresh_rate "$hz"
  settings_put system min_refresh_rate "$hz"
  settings_put system user_refresh_rate "$hz"
  settings_put system screen_refresh_rate "$hz"
  settings_put system refresh_rate_mode 1
  settings_put secure refresh_rate_mode 1
  if cmd display set-user-preferred-display-mode 0 "$hz" >/dev/null 2>&1; then
    ok "Preferred display mode dicoba via cmd display."
  fi
}

apply_animation_fast() {
  settings_put global window_animation_scale 0.5
  settings_put global transition_animation_scale 0.5
  settings_put global animator_duration_scale 0.5
}

apply_animation_zero() {
  settings_put global window_animation_scale 0
  settings_put global transition_animation_scale 0
  settings_put global animator_duration_scale 0
}

apply_rendering_balanced() {
  settings_put global development_settings_enabled 1
  settings_put global force_gpu_rendering 1
  settings_put global force_msaa 1
  settings_put global disable_hw_overlays 1
  settings_put global hardware_overlays_disabled 1
  settings_put global show_hw_screen_updates 0
  settings_put global show_hw_layers_updates 0
  settings_put global debug.hwui.profile false
  if service call SurfaceFlinger 1008 i32 1 >/dev/null 2>&1; then
    ok "SurfaceFlinger overlay toggle dicoba."
  fi
}

apply_rendering_ultra() {
  apply_rendering_balanced
  settings_put global debug.hwui.renderer skiagl
}

apply_power_latency() {
  settings_put global low_power 0
  settings_put global mobile_data_always_on 1
  settings_put global wifi_scan_always_enabled 0
  settings_put global cached_apps_freezer disabled
  settings_put global app_standby_enabled 0
  settings_put global adaptive_battery_management_enabled 0
  settings_put global sem_enhanced_cpu_responsiveness 1
  settings_put global activity_manager_constants "max_cached_processes=16,background_settle_time=0,fgservice_min_shown_time=0,fgservice_min_report_time=0"
  settings_put global fstrim_mandatory_interval 86400000
}

apply_input_gaming() {
  settings_put system pointer_speed 7
  settings_put system haptic_feedback_enabled 0
  settings_put system sound_effects_enabled 0
}

apply_maintenance() {
  if cmd activity idle-maintenance >/dev/null 2>&1; then
    ok "Idle maintenance dipicu."
  fi
  if cmd package bg-dexopt-job >/dev/null 2>&1; then
    ok "Dexopt background job dipicu jika didukung."
  fi
  if cmd jobscheduler run -f android 800 >/dev/null 2>&1; then
    ok "JobScheduler maintenance dicoba."
  fi
}

confirm_preview_5s() {
  printf '\n%s\n' "${YELLOW}[WARN]${RESET} Preview aktif. Ketik ${GREEN}Y${RESET} lalu Enter dalam 5 detik untuk simpan."
  printf '%s\n' "Kalau tidak, otomatis rollback."
  printf '%s' "Konfirmasi [Y/N] 5s: "
  ans=""
  if read -r -t 5 ans 2>/dev/null; then :; else ans=""; fi
  case "$ans" in Y|y|YES|yes) return 0 ;; *) return 1 ;; esac
}

rollback_resolution_to() {
  old="$1"
  if [ -n "$old" ] && [ "$old" != "null" ]; then
    if wm size "$old" >/dev/null 2>&1; then
      ok "Resolusi dikembalikan ke $old"
    else
      warn "Gagal rollback ke $old"
    fi
  else
    if wm size reset >/dev/null 2>&1; then
      ok "Resolusi direset ke default fisik"
    else
      warn "Gagal reset resolusi"
    fi
  fi
}

apply_custom_resolution_value() {
  target="$1"
  phys="$(get_wm_physical_size)"
  current_override="$(get_wm_override_size)"
  current="$(get_wm_current_size)"

  [ -z "$phys" ] && {
    fail "Resolusi fisik tidak terdeteksi. Fitur dibatalkan demi keamanan."
    return 1
  }

  print_resolution_limits "$phys"

  if ! validate_resolution_safe "$target" "$phys"; then
    fail "Resolusi '$target' di luar batas aman untuk layar fisik $phys."
    return 1
  fi

  old="$current_override"
  [ -z "$old" ] && old="null"

  info "Resolusi aktif sekarang: ${current:-unknown}; target preview: $target"
  if wm size "$target" >/dev/null 2>&1; then
    ok "Preview resolusi diterapkan: $target"
  else
    fail "Gagal menerapkan resolusi preview."
    return 1
  fi

  if confirm_preview_5s; then
    ok "Resolusi custom disimpan: $target"
    save_prop "rendro.last_custom_size" "$target"
    return 0
  fi

  warn "Tidak dikonfirmasi. Rollback otomatis."
  rollback_resolution_to "$old"
}

restore_setting() {
  namespace="$1"
  key="$2"
  prop="settings.$namespace.$key"
  value="$(prop_get "$prop")"
  [ -z "$value" ] && return 0

  if [ "$value" = "null" ]; then
    settings_delete "$namespace" "$key"
    ok "Restore: hapus $namespace.$key"
  else
    settings_put "$namespace" "$key" "$value" >/dev/null
    ok "Restore: $namespace.$key = $value"
  fi
}

restore_wm() {
  od="$(prop_get wm.override_density)"
  os="$(prop_get wm.override_size)"

  if [ -n "$os" ] && [ "$os" != "null" ]; then
    wm size "$os" >/dev/null 2>&1 && ok "Resolusi override direstore ke $os"
  else
    wm size reset >/dev/null 2>&1 && ok "Resolusi direset ke default fisik"
  fi

  if [ -n "$od" ] && [ "$od" != "null" ]; then
    wm density "$od" >/dev/null 2>&1 && ok "DPI override direstore ke $od"
  else
    wm density reset >/dev/null 2>&1 && ok "DPI direset ke default fisik"
  fi
}

restore_all() {
  banner
  printf '%s\n' "${BG_MAGENTA}${WHITE}${BOLD} RESTORE MODE ${RESET}"
  [ -f "$BACKUP_FILE" ] || {
    fail "Backup tidak ditemukan: $BACKUP_FILE"
    warn "Manual emergency: wm size reset ; wm density reset"
    exit 1
  }

  restore_wm
  restore_setting global window_animation_scale
  restore_setting global transition_animation_scale
  restore_setting global animator_duration_scale
  restore_setting global force_gpu_rendering
  restore_setting global force_msaa
  restore_setting global disable_hw_overlays
  restore_setting global hardware_overlays_disabled
  restore_setting global development_settings_enabled
  restore_setting global show_hw_screen_updates
  restore_setting global show_hw_layers_updates
  restore_setting global debug.hwui.profile
  restore_setting global debug.hwui.renderer
  restore_setting system peak_refresh_rate
  restore_setting system min_refresh_rate
  restore_setting system user_refresh_rate
  restore_setting system refresh_rate_mode
  restore_setting system screen_refresh_rate
  restore_setting secure refresh_rate_mode
  restore_setting global low_power
  restore_setting global mobile_data_always_on
  restore_setting global wifi_scan_always_enabled
  restore_setting global cached_apps_freezer
  restore_setting global app_standby_enabled
  restore_setting global adaptive_battery_management_enabled
  restore_setting global sem_enhanced_cpu_responsiveness
  restore_setting global activity_manager_constants
  restore_setting global fstrim_mandatory_interval
  restore_setting system pointer_speed
  restore_setting system haptic_feedback_enabled
  restore_setting system sound_effects_enabled

  ok "Restore selesai. Reboot disarankan kalau ada setting yang belum balik."
}

reset_dpi_only() {
  banner
  printf '%s\n' "${BG_BLUE}${WHITE}${BOLD} RESET DPI ONLY ${RESET}"
  if wm density reset >/dev/null 2>&1; then
    ok "DPI direset ke default."
  else
    warn "Gagal reset DPI."
  fi
}

reset_resolution_only() {
  banner
  printf '%s\n' "${BG_BLUE}${WHITE}${BOLD} RESET RESOLUTION ONLY ${RESET}"
  if wm size reset >/dev/null 2>&1; then
    ok "Resolusi direset ke default fisik."
  else
    warn "Gagal reset resolusi."
  fi
}

reset_display_all() {
  banner
  printf '%s\n' "${BG_BLUE}${WHITE}${BOLD} RESET DISPLAY ${RESET}"
  wm size reset >/dev/null 2>&1 && ok "Resolusi reset."
  wm density reset >/dev/null 2>&1 && ok "DPI reset."
}

apply_balanced() {
  banner
  printf '%s\n' "${BG_BLUE}${WHITE}${BOLD} BALANCED GAMING MODE ${RESET}"
  info "Mode smooth harian + gaming. DPI tidak diubah."
  create_backup
  apply_refresh_rate
  apply_animation_fast
  apply_rendering_balanced
  apply_power_latency
  apply_input_gaming
  apply_maintenance
  line
  ok "Balanced Gaming Mode aktif."
}

apply_ultra() {
  banner
  printf '%s\n' "${BG_BLUE}${WHITE}${BOLD} ULTRA MAX GAMING MODE ${RESET}"
  warn "Ultra Mode agresif. DPI tidak diubah, tapi tuning lain lebih nendang."
  create_backup
  apply_refresh_rate
  apply_animation_zero
  apply_rendering_ultra
  apply_power_latency
  apply_input_gaming
  apply_maintenance
  line
  ok "RenDro Ultra Max Gaming Mode aktif."
}

apply_custom_dpi_mode() {
  banner
  printf '%s\n' "${BG_BLUE}${WHITE}${BOLD} CUSTOM DPI MODE ${RESET}"
  create_backup
  if [ -n "$ARG2" ]; then
    apply_dpi_value "$ARG2"
  else
    fail "Pakai: sh RenDro.sh custom-dpi 600"
    exit 1
  fi
}

apply_custom_resolution_mode() {
  banner
  printf '%s\n' "${BG_BLUE}${WHITE}${BOLD} CUSTOM RESOLUTION MODE ${RESET}"
  create_backup
  if [ -n "$ARG2" ]; then
    apply_custom_resolution_value "$ARG2"
  else
    fail "Pakai: sh RenDro.sh custom-res 1080x2400"
    exit 1
  fi
}

status_all() {
  banner
  printf '%s\n' "${BG_BLUE}${WHITE}${BOLD} DEVICE STATUS ${RESET}"
  printf '%s\n' "${WHITE}Device${DIM}:${RESET} $(getprop ro.product.manufacturer 2>/dev/null) $(getprop ro.product.model 2>/dev/null)"
  printf '%s\n' "${WHITE}Android${DIM}:${RESET} $(getprop ro.build.version.release 2>/dev/null) / SDK $(getprop ro.build.version.sdk 2>/dev/null)"
  printf '%s\n' "${WHITE}Kernel ${DIM}:${RESET} $(uname -r 2>/dev/null)"
  printf '%s\n' "${WHITE}Size   ${DIM}:${RESET} $(wm size 2>/dev/null | tr '\n' '; ')"
  printf '%s\n' "${WHITE}Density${DIM}:${RESET} $(wm density 2>/dev/null | tr '\n' '; ')"
  thin
  printf '%s\n' "${GREEN}Refresh${RESET} peak=$(settings_get system peak_refresh_rate), min=$(settings_get system min_refresh_rate), user=$(settings_get system user_refresh_rate)"
  printf '%s\n' "${CYAN}Anim   ${RESET} W=$(settings_get global window_animation_scale), T=$(settings_get global transition_animation_scale), A=$(settings_get global animator_duration_scale)"
  printf '%s\n' "${MAGENTA}GPU    ${RESET} force=$(settings_get global force_gpu_rendering), msaa=$(settings_get global force_msaa), overlays=$(settings_get global disable_hw_overlays)/$(settings_get global hardware_overlays_disabled)"
  printf '%s\n' "${YELLOW}Power  ${RESET} low_power=$(settings_get global low_power), freezer=$(settings_get global cached_apps_freezer), standby=$(settings_get global app_standby_enabled)"
  thin
  info "Backup: $BACKUP_FILE"
  info "Log   : $LOG_FILE"
}

usage() {
  banner
  cat <<HELP
${BOLD}Command mode:${RESET}
  sh RenDro.sh help
  sh RenDro.sh ultra
  sh RenDro.sh balanced
  sh RenDro.sh adaptive-dpi
  sh RenDro.sh custom-dpi 600
  sh RenDro.sh custom-res 1080x2400
  sh RenDro.sh restore
  sh RenDro.sh reset-dpi
  sh RenDro.sh reset-res
  sh RenDro.sh reset-display
  sh RenDro.sh status

${YELLOW}Catatan:${RESET}
  - Ultra dan Balanced tidak mengubah DPI.
  - DPI hanya berubah di adaptive-dpi atau custom-dpi.
  - Custom resolusi selalu preview dulu, lalu rollback kalau tidak dikonfirmasi dalam 5 detik.
  - Emergency manual:
      wm size reset
      wm density reset
HELP
}

main() {
  init_env
  case "$MODE" in
    help|--help|-h|"")
      usage
      ;;
    ultra|--ultra|-u)
      apply_ultra
      ;;
    balanced|balance|--balanced|-b)
      apply_balanced
      ;;
    adaptive-dpi|dpi-auto|--adaptive-dpi)
      banner
      printf '%s\n' "${BG_BLUE}${WHITE}${BOLD} ADAPTIVE DPI ONLY ${RESET}"
      create_backup
      apply_adaptive_dpi
      ;;
    custom-dpi|dpi|--custom-dpi)
      apply_custom_dpi_mode
      ;;
    custom-res|resolution|res|--custom-res)
      apply_custom_resolution_mode
      ;;
    restore|--restore|-r)
      restore_all
      ;;
    reset-dpi|--reset-dpi)
      reset_dpi_only
      ;;
    reset-res|--reset-res)
      reset_resolution_only
      ;;
    reset-display|--reset-display)
      reset_display_all
      ;;
    status|--status|-s)
      status_all
      ;;
    *)
      warn "Mode tidak dikenal: $MODE"
      usage
      exit 1
      ;;
  esac
}

main "$@"
