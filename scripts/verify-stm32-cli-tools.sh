#!/usr/bin/env bash
set -euo pipefail

required_tools=(
    STM32_Programmer_CLI
    STM32_KeyGen_CLI
    STM32_SigningTool_CLI
    STM32TrustedPackageCreator_CLI
)

optional_tools=(
    STM32TrustedPackageCreator
)

fail() {
    echo "ERROR: $*" >&2
    exit 1
}

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || fail "missing required tool: $1"
}

print_tool() {
    local tool="$1"
    printf '%s -> %s\n' "$tool" "$(command -v "$tool")"
}

echo '== required tool inventory =='
for tool in "${required_tools[@]}"; do
    require_cmd "$tool"
    print_tool "$tool"
done

echo '== optional tool inventory =='
for tool in "${optional_tools[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        print_tool "$tool"
    else
        echo "$tool -> not present"
    fi
done

echo '== help probes =='
STM32_Programmer_CLI --help >/tmp/STM32_Programmer_CLI.help 2>&1 || fail 'STM32_Programmer_CLI --help failed'
STM32_KeyGen_CLI --help >/tmp/STM32_KeyGen_CLI.help 2>&1 || fail 'STM32_KeyGen_CLI --help failed'
STM32_SigningTool_CLI --help >/tmp/STM32_SigningTool_CLI.help 2>&1 || fail 'STM32_SigningTool_CLI --help failed'
STM32TrustedPackageCreator_CLI --help >/tmp/STM32TrustedPackageCreator_CLI.help 2>&1 || fail 'STM32TrustedPackageCreator_CLI --help failed'

sed -n '1,12p' /tmp/STM32_Programmer_CLI.help
sed -n '1,12p' /tmp/STM32_KeyGen_CLI.help
sed -n '1,12p' /tmp/STM32_SigningTool_CLI.help
sed -n '1,12p' /tmp/STM32TrustedPackageCreator_CLI.help

echo 'STM32 CLI verification: OK'
