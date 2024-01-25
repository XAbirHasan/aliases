# Define your mimir path
MIMIR_PATH="$HOME/Project/mimir"

# Define your error messsage
MIMIR_WRONG_PATH_MESSAGE="Mimir is not available (wrong folder path)"

function mimir() {
  if [ -d "$MIMIR_PATH" ]; then
    case "$1" in
      # go to mimir path in terminal
      --go | --find | -f)
        cd "$MIMIR_PATH"
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
        cd "$MIMIR_PATH" && npm run serve2
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

      ## Set local ip for kelda dev tool
      --set-local-ip | -s-lip)
        LOCALIP_WITHOUT_SPACE=$(echo `hostname -I` | tr -d ' ')
        export LOCALIP=$LOCALIP_WITHOUT_SPACE
        echo "'The LOCALIP=$LOCALIP'"
        ;;

      ## View local ip for kelda dev tool
      --view-local-ip | -v-lip)
        echo LOCALIP=$LOCALIP
        ;;
      
      ## Set git root for kelda dev tool
      --set-git-root | -s-git)
        export MIMIR_GIT_ROOT_DIR=$MIMIR_PATH
        echo "Your git root set to:$MIMIR_GIT_ROOT_DIR"
        ;;
      
      ## View git root for kelda dev tool
      --view-git-root | -v-git)
        echo "Your git root is:$MIMIR_GIT_ROOT_DIR"
        ;;

      # Help option
      --help | -h)
        echo "Usage: mimir [options]"
        echo
        echo "Options:"
        echo "--------------------------mimir development--------------------------"
        echo "  --go, --find, -f               Go to mimir path in terminal"
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
        echo ""
        echo "--------------------------kelda dev tools--------------------------"
        echo "  --set-local-ip, -s-lip         Set the LOCALIP to current host ip"
        echo "  --view-local-ip, -v-lip        View the LOCALIP"
        echo "  --set-git-root, -s-git         Set the MIMIR_GIT_ROOT_DIR to current mimir git root folder path"
        echo "  --view-git-root, -v-git        View the MIMIR_GIT_ROOT_DIR"
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
