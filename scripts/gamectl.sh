#!/usr/bin/env bash

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
    nomad job status -namespace=games
    ;;
  stop)
    nomad job stop -namespace=games "$GAME"
    ;;
  status)
    nomad job status -namespace=games "$GAME"
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
