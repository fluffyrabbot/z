# ZChat Examples

This directory contains example configurations and usage patterns for ZChat.

## Configuration Examples

- `basic-setup.yaml` - Basic user configuration with sensible defaults
- `project-session.yaml` - Project-specific session configuration
- `pin-examples.json` - Example pin configurations for different use cases

## Usage

### Basic Setup
```bash
# Copy basic configuration
cp examples/basic-setup.yaml ~/.config/zchat/user.yaml
```

### Project Session
```bash
# Create a project session with specific configuration
z -n myproject --system-file examples/project-session.yaml --ss
```

### Pin Examples
```bash
# Load example pins
z --pins-file examples/pin-examples.json
z --pins-list  # See what was loaded
```

## Customization

These examples are starting points. Modify them to match your specific needs:

- Adjust pin limits based on your usage patterns
- Change pin modes for different templating approaches
- Add project-specific system prompts
- Create custom pin templates for your workflow

For more information, see:
- [help/pins.md](../help/pins.md) - Pin system documentation
- [PRECEDENCE.md](../PRECEDENCE.md) - Configuration system
- [QUICKSTART.md](../QUICKSTART.md) - Quick start guide