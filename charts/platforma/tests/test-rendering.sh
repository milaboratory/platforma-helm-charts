#!/bin/bash

set -o nounset

# Rendering test script for Platforma Helm chart
# This script tests template rendering to verify --runner-enable-docker argument behavior

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "${script_dir}/.."
: "${VERBOSE:=false}"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2
}

log_info() {
    log "INF: $*"
}

log_verbose() {
    [[ "${VERBOSE}" == "true" ]] && log "DBG: $*"
    return 0
}

CHART_PATH="."
TEMP_DIR=$(mktemp -d)
log_verbose "TMP DIR: $TEMP_DIR"

if [ "${VERBOSE}" == "true" ]; then
    log_verbose "debug mode, automatic tmp dir cleanup is disabled"
else
    trap 'rm -rf "$TEMP_DIR"' EXIT
fi

echo "    🧪 Platforma Helm Chart Rendering Tests"
echo "================================================"

# Global test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Common reporting functions
report_ok() {
    local test_name="$1"
    local message="$2"
    echo "✅ PASSED: $test_name - $message"
    : $(( TESTS_PASSED++ ))
}

report_fail() {
    local test_name="$1"
    local message="$2"
    local _manifest="$3"
    echo "❌ FAILED: $test_name - $message"
    : $(( TESTS_FAILED++ ))
    
    if [ -n "$_manifest" ] && [ "${VERBOSE}" == "true" ]; then
        log_verbose "Rendered template content ($(basename "$_manifest")):"
        cat "$_manifest"
    fi

    return 1
}

# Function to render templates with given values and additional arguments
render() {
    local values_file="$1"
    shift  # Remove first argument, rest are additional helm arguments
    local additional_args=("$@")
    
    local _manifest="$(mktemp -u -p $TEMP_DIR).yaml"

    {
        set -o errexit
        helm template test-release "$CHART_PATH" \
            --values "$values_file" \
            "${additional_args[@]}" \
            > "$_manifest"
        set +o errexit
    }

    echo "$_manifest"
}

check_arg() {
    local _manifest="$1"
    local _arg="$2"

    yq -r '.spec.template.spec.containers[0].args[]' "$_manifest" | grep -q -- "$_arg"
}

check_env() {
    local _manifest="$1"
    local _env="$2"

    yq -r '.spec.template.spec.containers[0].env[] | .name + "=" + .value' "$_manifest" | grep -q -- "$_env"
}

# Test case: Docker enabled
test_docker_enabled() {
    local test_name="Docker Enabled"

    # Render with docker.enabled=true
    local _manifest
    _manifest=$(
        render "tests/rendering-values-docker.yaml" \
            --show-only templates/deployment.yaml \
            --set docker.enabled=true
    )

    check_arg "$_manifest" "--runner-enable-docker" &&
      report_ok "$test_name" "found argument '--runner-enable-docker'" ||
      report_fail "$test_name" "argument '--runner-enable-docker' not found" "${_manifest}"
    
    check_arg "$_manifest" "--runner-local-cpu=4" &&
      report_ok "$test_name" "found argument '--runner-local-cpu=4'" ||
      report_fail "$test_name" "argument '--runner-local-cpu=4' not found" "${_manifest}"

    check_arg "$_manifest" "--runner-local-ram=1Gi" &&
      report_ok "$test_name" "found argument '--runner-local-ram=1Gi'" ||
      report_fail "$test_name" "argument '--runner-local-ram=1Gi' not found" "${_manifest}"

    check_env "$_manifest" "DOCKER_HOST=tcp://" &&
      report_ok "$test_name" "'DOCKER_HOST' env variable is set" ||
      report_fail "$test_name" "'DOCKER_HOST' env variable is not set" "${_manifest}"
}

test_docker_gar() {
    local test_name="GAR docker mirror"

    local _manifest
    _manifest=$(
        render "tests/rendering-values-docker.yaml" \
            --show-only templates/deployment.yaml \
            --set gcp.gar="europe-west3-docker.pkg.dev/my-awesome-project/pl-containers"
    )

    check_arg "$_manifest" "--google-artifact-registry=europe-west3-docker.pkg.dev/my-awesome-project/pl-containers" &&
      report_ok "$test_name" "docker GAR authorization is configured" ||
      report_fail "$test_name" "docker GAR authorization is not configured" "${_manifest}"

    check_arg "$_manifest" "--default-docker-registry=europe-west3-docker.pkg.dev/my-awesome-project/pl-containers" &&
      report_ok "$test_name" "docker registry mirror is configured" ||
      report_fail "$test_name" "docker registry mirror is not configured" "${_manifest}"
}

test_gcp_assets() {
    local test_name="Assets mirror for Google Cloud"

    local _manifest
    _manifest=$(
        render "tests/rendering-values-docker.yaml" \
            --show-only templates/deployment.yaml \
            --set assetsRegistry="https://alternative-assets-url/"
    )

    check_arg "$_manifest" "--assets-registry-url=https://alternative-assets-url/" &&
      report_ok "$test_name" "assets registry mirror is configured" ||
      report_fail "$test_name" "assets registry mirror is not configured" "${_manifest}"
}

# Test case: Docker disabled
test_docker_disabled() {
    local test_name="Docker Disabled"

    # Render with docker.enabled=false
    local _manifest
    _manifest=$(
        render "tests/rendering-values-docker.yaml" \
            --show-only templates/deployment.yaml \
            --set docker.enabled=false
    )
    
    check_arg "$_manifest" "--runner-enable-docker" &&
      report_fail "$test_name" "unexpected argument '--runner-enable-docker' found when it should be absent" "${_manifest}" ||
      report_ok "$test_name" "argument '--runner-enable-docker' correctly absent"
}

#
# Run all tests
#
test_docker_enabled
test_docker_disabled
test_docker_gar
test_gcp_assets

# Summary
echo ""
echo "📊 Test Summary"
echo "==============="
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $TESTS_FAILED"

if [ $TESTS_FAILED -eq 0 ]; then
    echo ""
    echo "  🎉 All rendering tests passed successfully!"
    echo "================================================"
    exit 0
else
    echo ""
    echo "💥 Some tests failed!"
    echo "====================="
    exit 1
fi
