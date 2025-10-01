# Define your mimir path
MIMIR_PATH="$HOME/mimir-stuff/mimir"
MIMIR_KELDA_PATH="$HOME/mimir-stuff/kelda"  

# Define your error messsage
MIMIR_WRONG_PATH_MESSAGE="Mimir is not available (wrong folder path)"


_mimir_clean_pnpm_cache() {
  echo "Cleaning pnpm cache..."
  rm -rf .build .pnpm-lock.yaml $HOME/.cache/pnpm $HOME/.local/share/pnpm
}

_clean_directories() {
  local dir_name="$1"
  echo "Removing all '$dir_name' directories..."
  find . -type d -name "$dir_name" -prune -exec rm -rf '{}' +
}

function mimir() {
  if [ -d "$MIMIR_PATH" ]; then
    case "$1" in
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
      
      # Run mimir app with optimize one
      --run2 | -r2)
        cd "$MIMIR_PATH" && npm run serve2 --no-schedule
        ;;

      # Run mimir check
      --check | -ck)
        cd "$MIMIR_PATH" && npm run check${2:+:}${2} -- --max-parallel ${3:-5}
        ;;

      # Run mimir test
      --test | -t)
        cd "$MIMIR_PATH" && npm run test
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

      # Deploy mimir function
      --deploy-function | -df)
        if [ -z "$2" ]; then
          echo "Missing <functionName> parameter for --deploy-function|-df"
        else
          npx env-cmd -f ../../.env sls deploy -f $2 --verbose
        fi
        ;;
      
      ## Build api doc locally
      --build-doc | -bd)
        cd "$MIMIR_PATH/server/core" && npm run build-doc-local
        ;;
      
      ## install all dependencies
      --install | -i)
        cd "$MIMIR_PATH" && npm ci --unsafe-perm --ignore-scripts && npm run ci-many
        ;;
      
       ## install all dependencies with script
      --install2 | -i2)
        cd "$MIMIR_PATH" && no-dep/install-all
        ;;
      
      ## Build kelda dev tool with local code
      --build-kelda-tool | -bk-t)
        cd "$MIMIR_PATH" && cd clients/kelda && npm run build:tools && npm link
        ;;
      
      ## Build kelda with local code
      --build-kelda | -bk)
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
          echo "Building kelda for linux"
          cd "$MIMIR_PATH" && cd clients/kelda && pnpm build && pnpm build:docker
        elif [[ "$OSTYPE" == "darwin"* ]]; then
          echo "Building kelda for macOS"
          cd "$MIMIR_PATH" && cd clients/kelda && pnpm build && pnpm build:docker-aarch64
        else
          echo "Unsupported OS type: $OSTYPE"
          return 1
        fi
        ;;

      ## Set local ip
      --set-local-ip | -s-lip)
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
          LOCALIP_WITHOUT_SPACE=$(echo `hostname -I` | tr -d ' ')
        elif [[ "$OSTYPE" == "darwin"* ]]; then
          ip=$(ipconfig getifaddr en0)

          # If ip is empty, try fallback method
          if [ -z "$ip" ]; then
            ip=$(/sbin/ifconfig -l | xargs -n1 ipconfig getifaddr 2>/dev/null | head -n1)
          fi
          LOCALIP_WITHOUT_SPACE=$(echo $ip | tr -d ' ')
        else
          echo "Unsupported OS type: $OSTYPE"
          return 1
        fi
        export LOCALIP=$LOCALIP_WITHOUT_SPACE
        echo "'The LOCALIP=$LOCALIP'"
        ;;

      ## View local ip
      --view-local-ip | -v-lip)
        echo LOCALIP=$LOCALIP
        ;;
      
      ## Set mimir git root
      --set-git-root | -s-git)
        export MIMIR_GIT_ROOT_DIR=$MIMIR_PATH
        echo "Your git root set to:$MIMIR_GIT_ROOT_DIR"
        ;;
      
      ## View mimir git root
      --view-git-root | -v-git)
        echo "Your git root is:$MIMIR_GIT_ROOT_DIR"
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

      # Help option
      --help | -h)
        echo "Usage: mimir [options]"
        echo
        echo "Options:"
        echo "--------------------------mimir development--------------------------"
        echo "  --go, --find, -f               Go to mimir path in terminal"
        echo "  --go-kelda, --find-kelda, -fk  Go to kelda path in terminal" 
        echo "  --open, --code, -o             Open mimir in Visual Studio Code"
        echo "  --config, -c, --setting, -s    Configure mimir stacks and sub-system"
        echo "  --run, -r                      Run mimir app"
        echo "  --run2, -r2                    Run mimir app with serve2 (memory optimized)"
        echo "  --hook, -hk                    Run mimir clientHookTestServer"
        echo "  --check, -ck <subsystemName> <max-parallel>"
        echo "                                 Run mimir check (if 'subsystem' is provided then only run check for that)"
        echo "                                 'max-parallel' default to '5'"
        echo "  --test, -t [updateMe]"
        echo "                                 Run mimir test"
        echo "  --deploy-function, -df <functionName>"
        echo "                                 Deploy a specific lambda function (required)"
        echo "  --build-doc, -bd               Build api doc locally"
        echo "  --install, -i                  Install all dependencies"
        echo "  --install2, -i2                Install all dependencies with no-dep script"
        echo "  --eslint-diff, --lint-diff <branch> <max-old-space>"
        echo "                                 Run eslint only diff changes (.ts, .vue files)"
        echo "                                  'branch' default to 'develop'"
        echo "                                  'max-old-space' default to '5120'MB (5GB)"
        echo ""
        echo "--------------------------kelda dev tools--------------------------"
        echo "  --build-kelda , -bk            Build kelda with local code"
        echo "  --build-kelda-tool , -bk-t     Build kelda developer tool with local code"
        echo "  --set-local-ip, -s-lip         Set the LOCALIP to current host ip"
        echo "  --view-local-ip, -v-lip        View the LOCALIP"
        echo "  --set-git-root, -s-git         Set the MIMIR_GIT_ROOT_DIR to current mimir git root folder path"
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
        ;;

      *)
        echo "Invalid option: $1. Need help? Use '--help' or '-h' for usage instructions."
        ;;
    esac
  else
    echo "$MIMIR_WRONG_PATH_MESSAGE"
  fi
}


# Set node max-old-space-size
function node-eat() {
  case "$1" in
    --me | --ram | -m)
      local value="${2:-4096}" # default to 4096
      export NODE_OPTIONS="--max-old-space-size=$value"
      echo "Your NODE_OPTIONS: $NODE_OPTIONS"
      ;;

    --what | -q)
      echo "NODE_OPTIONS: $NODE_OPTIONS"
      ;;

    --help | -h)
      echo "Usage: node-eat [options]"
      echo
      echo "Options:"
      echo "  --me, --ram, -m [value]  Set the NODE_OPTIONS max-old-space-size (default: 4096)"
      echo "  --what, -?               Display the current NODE_OPTIONS value"
      echo "  --help, -h               Show help"
      ;;

    *)
      echo "Invalid option: $1. Need help? Use '--help' or '-h' for usage instructions."
      ;;
  esac
}
