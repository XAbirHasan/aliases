# ============================================================
# Mimir configuration
# ============================================================
# Update these two paths to match your local checkouts.
MIMIR_PATH="$HOME/mimir-stuff/mimir"
MIMIR_KELDA_PATH="$HOME/mimir-stuff/kelda"

# ---------------- internal helpers (not meant to be called directly) ----------------

_mimir_clean_pnpm_cache() {
  echo "Cleaning pnpm cache..."
  rm -rf .build .pnpm-lock.yaml "$HOME/.cache/pnpm" "$HOME/.local/share/pnpm"
}

_clean_directories() {
  local dir_name="$1"
  echo "Removing all '$dir_name' directories..."
  find . -type d -name "$dir_name" -prune -exec rm -rf '{}' +
}

# Detects this machine's LAN IP (used by mimir's local dev servers so other
# devices/containers on the network can reach them).
_mimir_detect_local_ip() {
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    hostname -I | awk '{print $1}'
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    local ip
    ip=$(ipconfig getifaddr en0 2>/dev/null)
    # Fall back to the first active interface if en0 isn't it (e.g. on Wi-Fi vs. Ethernet)
    if [ -z "$ip" ]; then
      ip=$(/sbin/ifconfig -l | xargs -n1 ipconfig getifaddr 2>/dev/null | head -n1)
    fi
    echo "$ip"
  fi
}

_mimir_set_local_ip() {
  local ip
  ip=$(_mimir_detect_local_ip)
  if [ -z "$ip" ]; then
    echo "[mimir] Could not detect a local IP (are you connected to a network?)"
    return 1
  fi
  export LOCALIP="$ip"
  echo "LOCALIP=$LOCALIP"
}

_mimir_set_git_root() {
  export MIMIR_GIT_ROOT_DIR="$MIMIR_PATH"
  echo "MIMIR_GIT_ROOT_DIR=$MIMIR_GIT_ROOT_DIR"
}

function mimir() {
  # Accept GNU-style `--flag=value` in addition to the existing `--flag value` form.
  local opt="${1%%=*}"
  local arg="$2"
  if [[ "$1" == *=* ]]; then
    arg="${1#*=}"
  fi

  # These options don't need the mimir repo to exist locally, so they're
  # handled before the path check below (e.g. `mimir --help` should always work).
  case "$opt" in
    --help | -h)
      echo "Usage: mimir [options]"
      echo
      echo "Options taking a value accept both 'mimir --flag value' and 'mimir --flag=value'."
      echo
      echo "Options:"
      echo "--------------------------mimir development--------------------------"
      echo "  --go, --find, -f               Go to mimir path in terminal"
      echo "  --go-kelda, --find-kelda, -fk  Go to kelda path in terminal"
      echo "  --open, --code, -o             Open mimir in Visual Studio Code"
      echo "  --config, -c, --setting, -s    Configure mimir stacks and sub-system"
      echo "  --run, -r                      Run mimir app"
      echo "  --run2, -r2                    Run mimir app without scheduled background tasks (faster local dev)"
      echo "  --hook, -hk                    Run mimir clientHookTestServer"
      echo "  --lint, -lt                    Run mimir lint (oxlint)"
      echo "  --validate, -vld               Run mimir validate (faster, less noisy incremental check)"
      echo "  --check, -ck <subsystemName>"
      echo "                                 Run mimir check (if 'subsystemName' is provided then only run check for that)"
      echo "  --test, -t                     Run mimir test"
      echo "  --quick-test, -qt              Run mimir quick-test (skips slower fixtures)"
      echo "  --nyc-test, -nt                Run mimir test with coverage (nyc)"
      echo "  --container-start, -cs         Start the docker containers used by tests"
      echo "  --container-stop, -cx          Stop the docker containers used by tests"
      echo "  --branch-check, -bc            Check your branch is up to date / mergeable"
      echo "  --build, -bld                  Build mimir (kelda + mtools)"
      echo "  --deploy-function, -df <functionName>"
      echo "                                 Deploy a specific lambda function (required)."
      echo "                                 Run this from inside the target service directory (e.g. server/core)"
      echo "  --build-doc, -bd               Build api doc locally"
      echo "  --install, -i, --install2, -i2 Install all dependencies (bootstraps pnpm if needed)"
      echo "  --eslint-diff, --lint-diff <branch> <max-old-space>"
      echo "                                 Run eslint only diff changes (.ts, .vue files)"
      echo "                                  'branch' default to 'develop'"
      echo "                                  'max-old-space' default to '5120'MB (5GB)"
      echo ""
      echo "--------------------------kelda dev tools--------------------------"
      echo "  --build-kelda , -bk            Build kelda with local code"
      echo "  --build-kelda-tool , -bk-t     Build kelda developer tool with local code"
      echo "  --serve-kelda, -sv-k           Run kelda locally in docker (built image required, see --build-kelda)"
      echo "  --debug-kelda, -dbg-k          Run kelda locally in docker with the node debugger attached (port 9229)"
      echo "  --set-local-ip, -s-lip         Re-detect and set LOCALIP to this machine's current IP"
      echo "                                 (this already runs automatically in every new terminal)"
      echo "  --view-local-ip, -v-lip        View the LOCALIP"
      echo "  --set-git-root, -s-git         Set MIMIR_GIT_ROOT_DIR to MIMIR_PATH"
      echo "                                 (this already runs automatically in every new terminal)"
      echo "  --view-git-root, -v-git        View the MIMIR_GIT_ROOT_DIR"
      echo ""
      echo "--------------------------cleaning--------------------------"
      echo "  --clean-pnpm-cache, -c-pnpm    Clean pnpm cache and build files"
      echo "  --clean-node-modules, -c-nm    Remove all node_modules directories"
      echo "  --clean-build, -c-b            Remove all .build and .cache directories recursively"
      echo "  --clean-all, -c-all            Clean everything (pnpm cache + node_modules + build files)"
      echo ""
      echo "------------------------------------------------------------------"
      echo "  --help, -h                     Show help"
      return
      ;;

    # Re-run manually if your IP/network changed since the terminal opened
    --set-local-ip | -s-lip)
      _mimir_set_local_ip
      return
      ;;
    --view-local-ip | -v-lip)
      echo "LOCALIP=$LOCALIP"
      return
      ;;
    --set-git-root | -s-git)
      _mimir_set_git_root
      return
      ;;
    --view-git-root | -v-git)
      echo "MIMIR_GIT_ROOT_DIR=$MIMIR_GIT_ROOT_DIR"
      return
      ;;
  esac

  if [ ! -d "$MIMIR_PATH" ]; then
    echo "Mimir path not found: $MIMIR_PATH"
    echo "Update MIMIR_PATH at the top of this file to point at your mimir checkout."
    return 1
  fi

  case "$opt" in
    # go to mimir path in terminal
    --go | --find | -f)
      cd "$MIMIR_PATH"
      ;;
    # go to kelda path in terminal
    --go-kelda | --find-kelda | -fk)
      cd "$MIMIR_KELDA_PATH"
      ;;

    # Open mimir in VS code
    --open | --code | -o)
      cd "$MIMIR_PATH" && code .
      ;;

    # Configure mimir stacks and sub-system
    --config | -c | --setting | -s)
      cd "$MIMIR_PATH" && npm run configure
      ;;

    # Run mimir app
    --run | -r)
      cd "$MIMIR_PATH" && npm run serve
      ;;

    # Run mimir app without scheduled background tasks
    --run2 | -r2)
      cd "$MIMIR_PATH" && npm run serve2 -- --no-schedule
      ;;

    # Run mimir lint
    --lint | -lt)
      cd "$MIMIR_PATH" && npm run lint
      ;;

    # Run mimir validate (faster incremental alternative to --check)
    --validate | -vld)
      cd "$MIMIR_PATH" && pnpm run validate
      ;;

    # Run mimir check
    --check | -ck)
      cd "$MIMIR_PATH" && npm run check${arg:+:}${arg}
      ;;

    # Run mimir test
    --test | -t)
      cd "$MIMIR_PATH" && npm run test
      ;;

    # Run mimir quick-test
    --quick-test | -qt)
      cd "$MIMIR_PATH" && npm run quick-test
      ;;

    # Run mimir test with coverage
    --nyc-test | -nt)
      cd "$MIMIR_PATH" && npm run nyc-test
      ;;

    # Start docker containers used by tests
    --container-start | -cs)
      cd "$MIMIR_PATH" && npm run container-start
      ;;

    # Stop docker containers used by tests
    --container-stop | -cx)
      cd "$MIMIR_PATH" && npm run container-stop
      ;;

    # Check your branch is up to date / mergeable
    --branch-check | -bc)
      cd "$MIMIR_PATH" && npm run branch-check
      ;;

    # Build mimir (kelda + mtools)
    --build | -bld)
      cd "$MIMIR_PATH" && npm run build
      ;;

    # Run clientHookTestServer
    --hook | -hk)
      cd "$MIMIR_PATH" && npm run clientHookTestServer
      ;;

    # Run eslint only diff changes
    --eslint-diff | --lint-diff)
      local branch="${2:-develop}"
      local max_old_space="${3:-5120}"
      cd "$MIMIR_PATH" && NODE_OPTIONS=--max-old-space-size=${max_old_space} npx eslint --format summary -- $(git diff ${branch} --name-only | grep -E '\.ts$|\.vue$')
      ;;

    # Deploy mimir function (run from inside the target service directory, e.g. server/core)
    --deploy-function | -df)
      if [ -z "$arg" ]; then
        echo "Missing <functionName> parameter for --deploy-function|-df"
      elif [ ! -f "../../.env" ]; then
        echo "No .env found at ../../.env from here."
        echo "Run this from inside the service directory you want to deploy (e.g. cd $MIMIR_PATH/server/core), then retry."
      else
        npx env-cmd -f ../../.env sls deploy -f "$arg" --verbose
      fi
      ;;

    ## Build api doc locally
    --build-doc | -bd)
      cd "$MIMIR_PATH/server/core" && npm run build-doc-local
      ;;

    ## install all dependencies (bootstraps pnpm via corepack if needed)
    --install | -i | --install2 | -i2)
      cd "$MIMIR_PATH" && no-dep/install-all
      ;;

    ## build mtools with local code
    --build-mtools | -bm)
      cd "$MIMIR_PATH/clients/mtools" && npm run build && npm link
      ;;

    ## build localstage and link
    --build-localstage | -bls)
      cd "$MIMIR_PATH/environments" && npm run build:tools && npm link
      ;;

    ## Build kelda dev tool with local code
    --build-kelda-tool | -bk-t)
      cd "$MIMIR_PATH/clients/kelda" && npm run build:tools && npm link
      ;;

    ## Build kelda with local code
    --build-kelda | -bk)
      if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "Building kelda for linux"
        cd "$MIMIR_PATH/clients/kelda" && pnpm build && pnpm build:docker
      elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "Building kelda for macOS"
        cd "$MIMIR_PATH/clients/kelda" && pnpm build && pnpm build:docker
      else
        echo "Unsupported OS type: $OSTYPE"
        return 1
      fi
      ;;

    ## Run kelda locally in docker
    --serve-kelda | -sv-k)
      cd "$MIMIR_PATH/clients/kelda" && pnpm run serve:kelda
      ;;

    ## Run kelda locally in docker with the node debugger attached
    --debug-kelda | -dbg-k)
      cd "$MIMIR_PATH/clients/kelda" && pnpm run debug:kelda
      ;;

    ## clean pnpm cache
    --clean-pnpm-cache | -c-pnpm)
      cd "$MIMIR_PATH" && _mimir_clean_pnpm_cache
      ;;

    ## clean node_modules
    --clean-node-modules | -c-nm)
      cd "$MIMIR_PATH" && _clean_directories "node_modules"
      ;;

    ## clean build files
    --clean-build | -c-b)
      cd "$MIMIR_PATH" && \
      _clean_directories ".build" && \
      _clean_directories ".cache"
      ;;

    ## clean all
    --clean-all | -c-all)
      cd "$MIMIR_PATH" && \
      _mimir_clean_pnpm_cache && \
      _clean_directories "node_modules" && \
      _clean_directories ".build" && \
      _clean_directories ".cache" && \
      echo "All cleaned!"
      ;;

    *)
      echo "Invalid option: $1. Need help? Use '--help' or '-h' for usage instructions."
      ;;
  esac
}


# ============================================================
# node-eat: set/view Node's --max-old-space-size
# ============================================================
function node-eat() {
  # Accept GNU-style `--flag=value` in addition to the existing `--flag value` form.
  local opt="${1%%=*}"
  local arg="$2"
  if [[ "$1" == *=* ]]; then
    arg="${1#*=}"
  fi

  case "$opt" in
    --me | --ram | -m)
      local value="${arg:-4096}" # default to 4096
      export NODE_OPTIONS="--max-old-space-size=$value"
      echo "Your NODE_OPTIONS: $NODE_OPTIONS"
      ;;

    --what | -q)
      echo "NODE_OPTIONS: $NODE_OPTIONS"
      ;;

    --help | -h)
      echo "Usage: node-eat [options]"
      echo
      echo "Options taking a value accept both 'node-eat --flag value' and 'node-eat --flag=value'."
      echo
      echo "Options:"
      echo "  --me, --ram, -m [value]  Set the NODE_OPTIONS max-old-space-size (default: 4096)"
      echo "  --what, -q               Display the current NODE_OPTIONS value"
      echo "  --help, -h               Show help"
      ;;

    *)
      echo "Invalid option: $1. Need help? Use '--help' or '-h' for usage instructions."
      ;;
  esac
}

# ============================================================
# Auto-set per-session env vars
#
# LOCALIP and MIMIR_GIT_ROOT_DIR are needed whenever you run mimir or kelda
# locally, so we set them here instead of having to run
# `mimir --set-local-ip` / `mimir --set-git-root` by hand in every new terminal.
# ============================================================
_mimir_set_local_ip
_mimir_set_git_root
