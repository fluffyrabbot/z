#!/bin/bash
# ZChat Dependencies Configuration v0.8b

# Core dependencies
CORE_MODULES=(
    "Mojo::UserAgent"
    "JSON::XS"
    "YAML::XS"
    "Text::Xslate"
    "Clipboard"
    "Getopt::Long::Descriptive"
    "URI::Escape"
    "Data::Dumper"
    "String::ShellQuote"
    "File::Slurper"
    "File::Copy"
    "File::Temp"
    "File::Compare"
    "Carp"
    "Term::ReadLine"
    "Term::ReadLine::Gnu"
    "Capture::Tiny"
    "LWP::UserAgent"
    "Term::Size"
)

# Optional dependencies (enhanced functionality)
OPTIONAL_MODULES=(
    "Image::Magick"
)

# All dependencies (core + optional)
ALL_MODULES=(
    "${CORE_MODULES[@]}"
    "${OPTIONAL_MODULES[@]}"
)

# Critical modules (must be present for ZChat to work)
CRITICAL_MODULES=(
    "Mojo::UserAgent"
    "JSON::XS"
    "YAML::XS"
    "Text::Xslate"
    "Clipboard"
)

# Export functions for use by other scripts
export_core_modules() {
    echo "${CORE_MODULES[@]}"
}

export_all_modules() {
    echo "${ALL_MODULES[@]}"
}

export_critical_modules() {
    echo "${CRITICAL_MODULES[@]}"
}

export_optional_modules() {
    echo "${OPTIONAL_MODULES[@]}"
}

# If script is run directly, show module lists
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    echo "ZChat Dependencies Configuration v0.8b"
    echo "========================================"
    echo ""
    echo "Core modules (${#CORE_MODULES[@]}):"
    printf "  %s\n" "${CORE_MODULES[@]}"
    echo ""
    echo "Optional modules (${#OPTIONAL_MODULES[@]}):"
    printf "  %s\n" "${OPTIONAL_MODULES[@]}"
    echo ""
    echo "Critical modules (${#CRITICAL_MODULES[@]}):"
    printf "  %s\n" "${CRITICAL_MODULES[@]}"
    echo ""
    echo "Total modules: ${#ALL_MODULES[@]}"
fi