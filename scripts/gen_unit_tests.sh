#!/usr/bin/env bash
# Wrapper for AI-assisted unit test generation.
#
# Usage:
#   bash scripts/gen_unit_tests.sh <module>
#   make ai-unit-tests MODULE=<module>
#
# Looks for includes/libs/<module>.h and src/**/*<module>.c, then builds a
# prompt that includes both files and a description of the project conventions.
#
# Either pipes the prompt to your configured AI agent via $MACMINI_AGENT_CMD,
# or prints it to stdout for manual use.
#
# To configure an agent, set MACMINI_AGENT_CMD before running make:
#
#   export MACMINI_AGENT_CMD="claude"
#   export MACMINI_AGENT_CMD="aider --message-file -"
#   export MACMINI_AGENT_CMD="tee /tmp/prompt.txt"
#
# Without MACMINI_AGENT_CMD set, the prompt is printed and you paste it
# into your AI tool, then save the response to tests/unit/test_<module>.c.

set -euo pipefail

MODULE="${1:-}"
if [[ -z "$MODULE" ]]; then
  echo "Usage: $0 <module>" >&2
  exit 1
fi

HEADER="./includes/libs/${MODULE}.h"
SOURCE="$(find ./src -name "*${MODULE}.c" | head -1)"

if [[ ! -f "$HEADER" ]]; then
  echo "Error: $HEADER not found." >&2
  echo "Create the header in includes/libs/ first." >&2
  exit 1
fi

if [[ -z "$SOURCE" || ! -f "$SOURCE" ]]; then
  echo "Error: no src file matching *${MODULE}.c found under ./src." >&2
  echo "Create the implementation under src/ first." >&2
  exit 1
fi

build_prompt() {
  cat <<PROMPT
You are generating a C unit test file for the MacMini Shell project.

## Project conventions

- Test framework: Unity (single-header, located at tests/unity/unity.h)
- Each test file lives at tests/unit/test_<module>.c
- File header comment format:
    /*
     * tests/unit/test_<module>.c
     *
     * Unit tests for <function>(), declared in includes/libs/<module>.h
     * and implemented in src/...<module>.c.
     *
     * Run with:
     *   make unit
     */
- Includes: "unity.h", then the module header, then standard headers
- setUp() and tearDown() are always defined even if empty
- All test functions are static void, named test_<what>_<expected>()
- main() calls UNITY_BEGIN(), then RUN_TEST() for each, then return UNITY_END()
- No dynamic allocation in tests; use stack buffers
- Test names are snake_case and descriptive — they appear in the output
- Cover the happy path, edge cases, and boundary conditions

## Target module: ${MODULE}

### Header: ${HEADER}
\`\`\`c
$(cat "$HEADER")
\`\`\`

### Implementation: ${SOURCE}
\`\`\`c
$(cat "$SOURCE")
\`\`\`

## Output

Write the complete contents of tests/unit/test_${MODULE}.c — nothing else.
PROMPT
}

AGENT_CMD="${MACMINI_AGENT_CMD:-}"

if [[ -z "$AGENT_CMD" ]]; then
  echo "================================================================" >&2
  echo "MACMINI_AGENT_CMD not set. Printing prompt to stdout." >&2
  echo "Copy everything below and paste it into your AI tool." >&2
  echo "Then save the response to tests/unit/test_${MODULE}.c" >&2
  echo "================================================================" >&2
  echo "" >&2
  build_prompt
  exit 0
fi

build_prompt | eval "$AGENT_CMD"
