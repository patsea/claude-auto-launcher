#!/usr/bin/env bats

setup() {
  # Set up test environment
  export TEST_MODE=1
  SCRIPT_DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )/.." && pwd )"
}

teardown() {
  # Clean up after tests
  unset TEST_MODE
}

@test "claude-auto main script exists and is executable" {
  [ -x "$SCRIPT_DIR/bin/claude-auto" ]
}

@test "claude-auto-status exists and is executable" {
  [ -x "$SCRIPT_DIR/bin/claude-auto-status" ]
}

@test "lib/helpers.sh exists and can be sourced" {
  [ -f "$SCRIPT_DIR/lib/helpers.sh" ]
  run bash -c "source $SCRIPT_DIR/lib/helpers.sh"
  [ "$status" -eq 0 ]
}

@test "install.sh exists and is executable" {
  [ -x "$SCRIPT_DIR/install.sh" ]
}

@test "all bin scripts have valid bash syntax" {
  for script in "$SCRIPT_DIR"/bin/claude-auto*; do
    if [ -f "$script" ] && [[ ! "$script" =~ \.backup$ ]]; then
      run bash -n "$script"
      [ "$status" -eq 0 ]
    fi
  done
}

@test "all lib scripts have valid bash syntax" {
  for script in "$SCRIPT_DIR"/lib/*.sh; do
    if [ -f "$script" ] && [[ ! "$script" =~ \.backup$ ]]; then
      run bash -n "$script"
      [ "$status" -eq 0 ]
    fi
  done
}

@test "no hardcoded sensitive data in scripts" {
  for script in "$SCRIPT_DIR"/bin/* "$SCRIPT_DIR"/lib/*.sh; do
    if [ -f "$script" ]; then
      run grep -iE "(password|secret|api.?key)\s*=\s*['\"][^'\"]+['\"]" "$script"
      [ "$status" -ne 0 ]  # Should NOT find matches
    fi
  done
}

@test "status-helpers.sh exists" {
  [ -f "$SCRIPT_DIR/lib/status-helpers.sh" ]
}
