#!/usr/bin/env bash

set -euo pipefail

# ENV
: "${KUBECONFIG_CONTEXT:?}"
: "${BBL_STATE_DIR:?}"

function install() {
  workspace=${PWD}
  export KUBECONFIG="${workspace}/kubeconfig/config"
  kubectl config use-context ${KUBECONFIG_CONTEXT}

  tmp_dir="$(mktemp -d /tmp/values.XXXXXXXX)"
  values_yml="${tmp_dir}/values.yaml"

  echo 'Fetching environment variables for credhub...'
  pushd "bbl-state/${BBL_STATE_DIR}" > /dev/null
    eval "$(bbl print-env)"
  popd

  ./cf-k8s-networking/config/scripts/generate_values.rb "bbl-state/${BBL_STATE_DIR}/bbl-state.json" > ${values_yml}

  pushd cf-k8s-networking > /dev/null
    git_sha="$(cat .git/ref)"
  popd
  image_repo="gcr.io/cf-networking-images/cf-k8s-networking/cfroutesync:${git_sha}"

  echo "Deploying image '${image_repo}' to ☸️ Kubernetes..."

  prometheus_file="$(mktemp -u).yml"
  kubectl get -n istio-system cm prometheus -o yaml > ${prometheus_file}

  ytt \
    -f cf-k8s-networking/config/cfroutesync/ \
    -f "${prometheus_file}" \
    -f cf-k8s-networking/cfroutesync/crds/routebulksync.yaml \
    -f "${values_yml}" \
    --data-value-yaml cfroutesync.image=${image_repo} \
    | kapp deploy -a cfroutesync -y -f -

  echo "Restart Prometheus pods with new config..."
  kubectl delete pods -n istio-system -l app=prometheus

  echo "Done! 🎉"
}

function main() {
  install
}

main
