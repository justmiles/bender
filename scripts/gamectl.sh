#!/usr/bin/env bash

# gamectl.sh
# gamectl.sh list
# gamectl.sh stop --game <id>
# gamectl.sh start --game <id>
# gamectl.sh status --game <id>
# gamectl.sh restart --game <id>

function no-color() {
  sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g"
}

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    -e|--game)
      GAME="$2"
      shift # past argument
      shift # past value
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters
case $1 in
  list)
    nomad job status -namespace=games | grep -v "^ID" | while read GAME_ID GAME_TYPE GAME_PRIORITY GAME_STATUS GAME_LAUNCH_DATE; do
      if [ "$GAME_STATUS" == "dead" ]; then
        GAME_STATUS=off
        echo "$GAME_ID ($GAME_STATUS)"
        continue
      fi

      ALLOC_ID=$(nomad job status -namespace=games "$GAME_ID" | grep -A3 Allocations | tail -1 | awk '{print $1}')
      RUN_TIME=$(nomad alloc status --namespace=games $ALLOC_ID | grep "^Modified" | awk '{print $3}')
      echo "$GAME_ID (running for $RUN_TIME)"
    done
    ;;
  stop)
    nomad job scale -namespace=games "$GAME" "$GAME" 0
    ;;
  start)
    nomad job scale -namespace=games -detach "$GAME" "$GAME" 1 && echo "Job is starting"
    ;;
  status)
    SHORT="-$2"
    nomad job status "$SHORT" -namespace=games "$GAME"
    case "$GAME" in
      ark)
        nomad exec -namespace games -job ark arkmanager status | no-color
        ;;
    esac
    ;;
  restart)
    ALLOC_ID=$(nomad job status -namespace=games "$GAME" | grep -A3 Allocations | tail -1 | awk '{print $1}')
    [ -z ALLOC_ID ] && (echo "could not find allocation for $GAME"; exit 1)
    echo "Restarting $GAME ($ALLOC_ID)"
    nomad alloc restart -namespace=games $ALLOC_ID
    nomad job status -namespace=games "$GAME"
    ;;
  *)
    POSITIONAL_ARGS+=("$1") # save positional arg
    shift # past argument
    ;;
esac

