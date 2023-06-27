#!/usr/bin/env bash

# The absolute directory of the script
ROOT=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
CONTEXT="$ROOT/contexts/$1"

KUBECTL_BIN="$CONTEXT/bin/kubectl"
HELM_BIN="$CONTEXT/bin/helm"
KUBECONFIG="$CONTEXT/kubeconfig"

# kubeconfig for a session
mkdir -p "$ROOT/session"
ss_kubeconfig=$(mktemp "$ROOT/session/kubeconfig.XXXXXX")
cp "$KUBECONFIG" "$ss_kubeconfig"


# From now on, print out the script to source

# Prepend the binary directory so that it is searched first
echo 'export PATH='"$CONTEXT"'/bin:$PATH'
# Delete cache entries
echo 'hash kubectl'
echo 'hash helm'

cat <<\EOF
if [ -z "$BASH" ]; then
  echo "ABORT: Please use bash to source this script"
  return
fi
EOF

# environment variables
cat <<EOF
export KUBECONFIG="$ss_kubeconfig"
export HELM_CACHE_HOME="$CONTEXT/helm/cache"
export HELM_CONFIG_HOME="$CONTEXT/helm/config"
export HELM_DATA_HOME="$CONTEXT/helm/data"
export HELM_PLUGINS="$CONTEXT/helm/plugins"
export HELM_REGISTRY_CONFIG="$CONTEXT/helm/registry/config.json"
export HELM_REPOSITORY_CACHE="$CONTEXT/helm/repository"
export HELM_REPOSITORY_CONFIG="$CONTEXT/helm/repositories.yaml"
EOF

# switch to a given namespace if specified
echo 'if [ "$1" ]; then kubens "$1"; fi'

# bash completions
"$KUBECTL_BIN" completion bash
"$HELM_BIN" completion bash
