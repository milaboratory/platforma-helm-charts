# Platforma Helm Chart Tests

This directory contains tests for the Platforma Helm chart that verify the correct rendering of templates based on different configuration values.

## Test Scripts
- `test-rendering.sh` - validates template rendering. Does not install any serices into kubernetes cluster.

## Running the Tests

### Prerequisites
- Helm 3.x installed

### Execute Tests
```bash
./tests/test-rendering.sh
```

## Adding New Tests

To add new rendering tests:

1. Create a new test function in `test-rendering.sh` (e.g., `test_new_feature()`)
3. Use the `render()` function with the base values file and any additional `--set` arguments
4. Use the `report_ok()` and `report_fail()` functions for consistent reporting
5. Add the new test function call to the "Run all tests" section

Example:
```bash
test_new_feature() {
    local test_name="New Feature Test"
    echo ""
    echo "🔧 Test: ${test_name}"
    echo "----------------------------------------"

    # Render with custom settings
    local _manifest
    _manifest=$(
        render "tests/rendering-values-docker.yaml" --set newFeature.enabled=true
    )

    grep -q "expected-pattern" "${_manifest}" &&
        report_ok "${test_name}" "Found expected pattern" ||
        report_fail "${test_name}" "Expected pattern not found" "${_manifest}"
}
```
