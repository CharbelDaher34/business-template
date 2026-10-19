#!/usr/bin/env bash
# app-builder: PreToolUse guard for the Bash tool.
#
# Runs before EVERY Bash command in every session of the builder (the server is
# shared, so it is not limited to app projects). It reads the hook JSON on stdin
# and either:
#   - prints a "deny" decision: the command is blocked and Claude is told why,
#   - prints an "ask" decision: the builder must approve the command first,
#   - prints nothing (exit 0): the normal permission flow applies.
#
# Requires jq (preferred) or python3 to read the hook JSON, and GNU realpath.
#
# HOW TO EXTEND (for Charbel):
#   - Block or ask about a whole program: add it to the `case` in check_simple_command.
#   - Block or ask about a subcommand: edit check_docker, check_compose or check_git.
#   - Path rules ("only inside this project"): see check_rm and check_chmod_chown.
# The command line is split into simple commands (on ; && || | & newlines and
# parentheses, respecting quotes and heredocs), and $(...), `...`, `bash -c`
# and `eval` contents are checked too. Each simple command is checked on its own.
set -uo pipefail
export LC_ALL=C # byte-wise string handling: fast, and the same on every server

ASK_CHARBEL="If this is really needed, ask Charbel."

# ---------------------------------------------------------------------------
# Reading the hook input
# ---------------------------------------------------------------------------
input="$(cat)"
if command -v jq >/dev/null 2>&1; then
  COMMAND="$(jq -r '.tool_input.command // empty' <<<"$input")"
  PROJECT_DIR="$(jq -r '.cwd // empty' <<<"$input")"
elif command -v python3 >/dev/null 2>&1; then
  COMMAND="$(python3 -c 'import json, sys; print(json.load(sys.stdin).get("tool_input", {}).get("command", ""))' <<<"$input")"
  PROJECT_DIR="$(python3 -c 'import json, sys; print(json.load(sys.stdin).get("cwd", ""))' <<<"$input")"
else
  echo "app-builder safety check: neither jq nor python3 is installed, so commands can't be checked. Ask Charbel to install jq." >&2
  exit 2
fi
[[ -n "$COMMAND" ]] || exit 0
[[ -n "$PROJECT_DIR" ]] || PROJECT_DIR="$PWD"
PROJECT_DIR="$(realpath -m -- "$PROJECT_DIR")"

# ---------------------------------------------------------------------------
# Decisions
# ---------------------------------------------------------------------------
ASK_REASON=""

emit() { # $1 = deny|ask, $2 = reason
  if command -v jq >/dev/null 2>&1; then
    jq -n --arg d "$1" --arg r "$2" \
      '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: $d, permissionDecisionReason: $r}}'
  else
    python3 -c 'import json, sys; print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": sys.argv[1], "permissionDecisionReason": sys.argv[2]}}))' "$1" "$2"
  fi
}

# A deny ends the check immediately: one blocked part blocks the whole command.
deny() {
  emit deny "Blocked by the app-builder safety check: $1 $ASK_CHARBEL"
  exit 0
}

# An ask is remembered; the rest of the command is still checked for denies.
ask() {
  [[ -n "$ASK_REASON" ]] || ASK_REASON="$1"
}

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
CUR_DIR="$PROJECT_DIR" # follows `cd` inside the command line

# Print the absolute path a command argument points to, or nothing if it uses
# a variable we can't know (like $DIR).
resolve() {
  local p="$1"
  case "$p" in
    "~" | "~/"*) p="$HOME${p:1}" ;;
    '$HOME' | '$HOME/'*) p="$HOME${p:5}" ;;
    '${HOME}' | '${HOME}/'*) p="$HOME${p:7}" ;;
  esac
  [[ "$p" == *'$'* || "$p" == *'`'* ]] && return 0
  [[ "$p" == /* ]] || p="$CUR_DIR/$p"
  realpath -m -- "$p"
}

# True if the path is the project folder or inside it.
inside_project() {
  [[ "$1" == "$PROJECT_DIR" || "$1" == "$PROJECT_DIR"/* ]]
}

# ---------------------------------------------------------------------------
# Rules for one simple command. "$@" = the command's words, quotes removed.
# ---------------------------------------------------------------------------
check_simple_command() {
  local word cmd
  # Skip variable assignments and wrappers that run another command.
  while (($#)); do
    word="$1"
    case "$word" in
      [A-Za-z_]*=*) shift ;;
      "{" | "!" | if | then | else | elif | do | while | until | time | nohup | command | builtin | exec) shift ;;
      env)
        shift
        while (($#)) && [[ "$1" == -* || "$1" == [A-Za-z_]*=* ]]; do shift; done
        ;;
      nice | timeout | stdbuf | xargs)
        [[ "$word" == xargs ]] && XARGS=1
        shift
        while (($#)) && [[ "$1" == -* ]]; do
          case "$1" in -n | -I | -P | -L | -d | -s | -a | -E | -k | -s | -i | -o | -e) shift ;; esac
          shift
        done
        [[ "$word" == timeout ]] && (($#)) && shift # the duration
        ;;
      *) break ;;
    esac
  done
  (($#)) || return 0
  cmd="${1##*/}"
  shift

  # The reset script can be started in many ways (./scripts/..., bash scripts/...).
  local arg
  for arg in "$cmd" "$@"; do
    [[ "${arg##*/}" == reset-db.sh ]] &&
      ask "This deletes ALL data in this app's database and starts it fresh. Only approve if you're sure."
  done

  case "$cmd" in
    # --- Whole-server administration -----------------------------------
    sudo | su | doas)
      deny "\`$cmd\` runs commands as the server administrator. Apps on this shared server never need that." ;;
    systemctl | service)
      deny "\`$cmd\` starts and stops services for the whole shared server." ;;
    apt | apt-get | aptitude | dpkg | yum | dnf | apk | pacman | zypper)
      deny "Installing system packages changes the shared server for everyone. Add what the app needs inside its Docker containers instead." ;;
    snap)
      [[ "${1:-}" == install || "${1:-}" == remove ]] &&
        deny "Installing system packages changes the shared server for everyone." ;;
    # --- Processes -------------------------------------------------------
    kill | pkill | killall)
      deny "\`$cmd\` can stop other people's programs on the shared server. Use \`docker compose stop\` or \`docker compose restart <service>\` for this app." ;;
    # --- Docker, git, files ---------------------------------------------
    docker) check_docker "$@" ;;
    docker-compose) check_compose "$@" ;;
    git) check_git "$@" ;;
    rm) check_rm "$@" ;;
    chmod | chown | chgrp) check_chmod_chown "$cmd" "$@" ;;
    # --- Other things to follow -----------------------------------------
    cd | pushd)
      local target
      target="$(resolve "${1:-$HOME}")"
      [[ -n "$target" ]] && CUR_DIR="$target"
      ;;
    bash | sh | zsh | dash)
      # `bash -c "..."`: check the inner command too.
      while (($#)); do
        if [[ "$1" == -*c* && "$1" != --* ]]; then
          (($# >= 2)) && QUEUE+=("$2")
          break
        fi
        shift
      done
      ;;
    eval) QUEUE+=("$*") ;;
  esac
}

check_docker() {
  # Skip global options, e.g. `docker --context x ps`.
  while (($#)) && [[ "$1" == -* ]]; do
    case "$1" in -c | --context | -H | --host | --config | -l | --log-level | --tlscacert | --tlscert | --tlskey) shift ;; esac
    shift
  done
  local sub="${1:-}"
  (($#)) && shift
  case "$sub" in
    compose) check_compose "$@" ;;
    system | volume | network | image | container | builder | buildx)
      case "${1:-}" in
        prune)
          deny "\`docker $sub prune\` deletes Docker data of every app on the shared server, not just this one." ;;
        rm | remove | stop | kill | restart)
          deny "\`docker $sub ${1}\` acts on Docker objects directly and can hit other apps on the shared server. Use \`docker compose\` from this app's folder (or ./scripts/reset-db.sh for the database)." ;;
      esac
      ;;
    rm | rmi | stop | kill | restart | exec)
      deny "\`docker $sub\` acts on containers directly and can hit other apps on the shared server. Use \`docker compose $sub\` from this app's folder instead." ;;
  esac
}

check_compose() {
  inside_project "$CUR_DIR" ||
    deny "\`docker compose\` must run from this app's own folder ($PROJECT_DIR), not from $CUR_DIR, so it only touches this app."
  local opt value path
  while (($#)) && [[ "$1" == -* ]]; do
    opt="${1%%=*}"
    if [[ "$1" == *=* ]]; then value="${1#*=}"; else value="${2:-}"; fi
    case "$opt" in
      -p | --project-name)
        deny "\`docker compose $opt\` points at a different Docker project, which could be another app on the shared server." ;;
      -f | --file | --project-directory | --env-file)
        path="$(resolve "$value")"
        if [[ -z "$path" ]] || ! inside_project "$path"; then
          deny "\`docker compose $opt $value\` uses files from outside this app's folder, which could control another app."
        fi
        ;;
    esac
    case "$opt" in
      -f | --file | -p | --project-name | --project-directory | --env-file | --profile | --ansi | --parallel | --progress)
        [[ "$1" == *=* ]] || shift ;;
    esac
    shift
  done
  if [[ "${1:-}" == down ]]; then
    shift
    local a
    for a in "$@"; do
      if [[ "$a" == -v || "$a" == --volumes || "$a" == --volumes=true || "$a" =~ ^-[a-zA-Z]*v[a-zA-Z]*$ ]]; then
        ask "This deletes all data in this app's database (and its other storage). Only approve if you're sure."
      fi
    done
  fi
}

check_git() {
  # Skip global options, e.g. `git -C dir push`.
  while (($#)) && [[ "$1" == -* ]]; do
    case "$1" in -C | -c | --git-dir | --work-tree | --namespace) shift ;; esac
    shift
  done
  local sub="${1:-}" a
  (($#)) && shift
  case "$sub" in
    push)
      for a in "$@"; do
        if [[ "$a" == -f || "$a" == --force || "$a" == --force-with-lease* || "$a" == --force-if-includes || "$a" == +* || "$a" =~ ^-[a-zA-Z]*f[a-zA-Z]*$ ]]; then
          deny "\`git push --force\` can permanently erase saved history on the shared copy."
        fi
      done
      ;;
    reset)
      for a in "$@"; do
        [[ "$a" == --hard ]] &&
          ask "This throws away all changes since the last save point (commit). They can't be recovered. Only approve if you're sure."
      done
      ;;
    clean)
      ask "This permanently deletes files that were never saved in git (new files, uploads, notes). Only approve if you're sure." ;;
  esac
}

check_rm() {
  local recursive=0 a path targets=()
  while (($#)); do
    a="$1"
    shift
    case "$a" in
      --) targets+=("$@"); break ;;
      --recursive) recursive=1 ;;
      --*) ;;
      -*) [[ "$a" == *[rR]* ]] && recursive=1 ;;
      *) targets+=("$a") ;;
    esac
  done
  ((recursive)) || return 0
  ((XARGS)) &&
    ask "This deletes folders chosen by another command, so the safety check can't see which. Only approve if you're sure."
  for a in "${targets[@]}"; do
    path="$(resolve "$a")"
    if [[ -z "$path" ]]; then
      ask "This deletes \`$a\`, and the safety check can't tell where that points. Only approve if you're sure."
    elif [[ "$path" == "$PROJECT_DIR" ]] || ! inside_project "$path"; then
      deny "\`rm -r $a\` would delete $path, which is outside this app's folder (or the whole app folder)."
    fi
  done
}

check_chmod_chown() {
  local cmd="$1" recursive=0 a path args=()
  shift
  for a in "$@"; do
    case "$a" in
      -R | --recursive) recursive=1 ;;
      --*) ;;
      -*) [[ "$a" == *R* ]] && recursive=1 ;;
      *) args+=("$a") ;;
    esac
  done
  # chmod -R only; chown/chgrp always. The first argument is the mode/owner.
  [[ "$cmd" == chmod ]] && ((!recursive)) && return 0
  for a in "${args[@]:1}"; do
    path="$(resolve "$a")"
    if [[ -z "$path" ]] || ! inside_project "$path"; then
      deny "\`$cmd\` on $a changes files outside this app's folder."
    fi
  done
}

# ---------------------------------------------------------------------------
# Splitting a command line into simple commands
# ---------------------------------------------------------------------------

# Print each simple command of $1, NUL-separated. Splits on unquoted ; & | ( )
# and newlines, and skips heredoc bodies (the text between <<EOF and EOF).
DELIM_END='[[:space:];&|<>()]' # characters that end a heredoc marker
# Runs of ordinary characters, copied in one go (much faster than char by char).
RE_PLAIN_CHUNK="^[^'\"\\;&|()<"$'\n'"]+"
RE_SQ_CHUNK="^[^']+"
RE_DQ_CHUNK='^[^"\\]+'
RE_WORD_CHUNK="^[^'\"\\ "$'\t\n'"]+"

# Set CHUNK to the start of $2 matched by regex $1 (empty if none).
chunk() {
  if [[ "$2" =~ $1 ]]; then CHUNK="${BASH_REMATCH[0]}"; else CHUNK=""; fi
}

split_commands() {
  local s="$1" n=${#1} i=0 c seg="" q="" delim strip line rest
  local -a heredocs=()
  while ((i < n)); do
    case "$q" in
      "'") chunk "$RE_SQ_CHUNK" "${s:i}" ;;
      '"') chunk "$RE_DQ_CHUNK" "${s:i}" ;;
      *) chunk "$RE_PLAIN_CHUNK" "${s:i}" ;;
    esac
    if ((${#CHUNK})); then
      seg+="$CHUNK"; ((i += ${#CHUNK})); continue
    fi
    c="${s:i:1}"
    if [[ -n "$q" ]]; then
      if [[ "$q" == '"' && "$c" == '\' ]]; then
        seg+="${s:i:2}"; ((i += 2)); continue
      fi
      [[ "$c" == "$q" ]] && q=""
      seg+="$c"; ((i++)); continue
    fi
    case "$c" in
      "'" | '"') q="$c"; seg+="$c" ;;
      '\') seg+="${s:i:2}"; ((i++)) ;;
      ';' | '&' | '|' | '(' | ')')
        printf '%s\0' "$seg"; seg="" ;;
      '<')
        if [[ "${s:i:2}" == "<<" && "${s:i+2:1}" != "<" ]]; then
          # Heredoc: remember the end marker, its body is skipped at the newline.
          ((i += 2)); strip=0
          [[ "${s:i:1}" == "-" ]] && { strip=1; ((i++)); }
          while [[ "${s:i:1}" == " " ]]; do ((i++)); done
          delim=""
          while ((i < n)) && [[ ! "${s:i:1}" =~ $DELIM_END ]]; do
            delim+="${s:i:1}"; ((i++))
          done
          delim="${delim//[\'\"\\]/}"
          heredocs+=("$strip:$delim")
          seg+=" <<heredoc "
          continue
        fi
        seg+="$c"
        ;;
      $'\n')
        printf '%s\0' "$seg"; seg=""
        # Skip the bodies of heredocs started on this line.
        for delim in "${heredocs[@]}"; do
          strip="${delim%%:*}"; delim="${delim#*:}"
          while ((i < n)); do
            rest="${s:i+1}"; line="${rest%%$'\n'*}"
            ((i += ${#line} + 1))
            ((strip)) && line="${line#"${line%%[!$'\t']*}"}"
            [[ "$line" == "$delim" ]] && break
          done
        done
        heredocs=()
        ;;
      *) seg+="$c" ;;
    esac
    ((i++))
  done
  printf '%s\0' "$seg"
}

# Print the words of one simple command, NUL-separated, with quotes removed.
split_words() {
  local s="$1" n=${#1} i=0 c word="" q="" has=0
  while ((i < n)); do
    case "$q" in
      "'") chunk "$RE_SQ_CHUNK" "${s:i}" ;;
      '"') chunk "$RE_DQ_CHUNK" "${s:i}" ;;
      *) chunk "$RE_WORD_CHUNK" "${s:i}" ;;
    esac
    if ((${#CHUNK})); then
      word+="$CHUNK"; has=1; ((i += ${#CHUNK})); continue
    fi
    c="${s:i:1}"
    if [[ -n "$q" ]]; then
      if [[ "$c" == "$q" ]]; then q=""
      elif [[ "$q" == '"' && "$c" == '\' ]]; then word+="${s:i+1:1}"; ((i++))
      else word+="$c"; fi
    else
      case "$c" in
        "'" | '"') q="$c"; has=1 ;;
        '\') word+="${s:i+1:1}"; has=1; ((i++)) ;;
        ' ' | $'\t' | $'\n')
          ((has)) && printf '%s\0' "$word"
          word=""; has=0
          ;;
        *) word+="$c"; has=1 ;;
      esac
    fi
    ((i++))
  done
  ((has)) && printf '%s\0' "$word"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
QUEUE=("$COMMAND")
while ((${#QUEUE[@]})); do
  line="${QUEUE[0]}"
  QUEUE=("${QUEUE[@]:1}")

  # Command substitutions run too: check $(...) and `...` contents separately.
  while [[ "$line" =~ \$\(([^()]*)\) ]]; do
    QUEUE+=("${BASH_REMATCH[1]}")
    line="${line/"${BASH_REMATCH[0]}"/ SUBST }"
  done
  while [[ "$line" =~ \`([^\`]*)\` ]]; do
    QUEUE+=("${BASH_REMATCH[1]}")
    line="${line/"${BASH_REMATCH[0]}"/ SUBST }"
  done

  CUR_DIR="$PROJECT_DIR"
  while IFS= read -r -d '' simple; do
    XARGS=0
    words=()
    while IFS= read -r -d '' w; do words+=("$w"); done < <(split_words "$simple")
    ((${#words[@]})) && check_simple_command "${words[@]}"
  done < <(split_commands "$line")
done

[[ -n "$ASK_REASON" ]] && emit ask "$ASK_REASON"
exit 0
