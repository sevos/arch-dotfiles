# Arch Wiki Navigation Guide for Claude Code

AI agent reference for efficiently using the Arch Wiki via WebFetch tool to find accurate Arch Linux solutions.

## WebFetch Usage for Arch Wiki

### Direct Page Access (Preferred Method)
Use WebFetch with specific wiki URLs when you know the topic:
```
WebFetch URL: https://wiki.archlinux.org/title/Page_Name
Prompt: "Extract information about [specific question]"
```

### Problem-to-URL Mapping
For common issues, fetch these pages directly:

**Package Management Issues**:
- `https://wiki.archlinux.org/title/Pacman` - Package manager problems
- `https://wiki.archlinux.org/title/Arch_User_Repository` - AUR issues
- `https://wiki.archlinux.org/title/Makepkg` - Package building

**Boot/Installation Issues**:
- `https://wiki.archlinux.org/title/Installation_guide` - Installation problems
- `https://wiki.archlinux.org/title/GRUB` - GRUB bootloader
- `https://wiki.archlinux.org/title/Systemd-boot` - systemd-boot issues

**System Services**:
- `https://wiki.archlinux.org/title/Systemd` - Service management
- `https://wiki.archlinux.org/title/Network_configuration` - Networking

**Hardware Configuration**:
- `https://wiki.archlinux.org/title/Xorg` - Display server
- `https://wiki.archlinux.org/title/NVIDIA` - NVIDIA graphics
- `https://wiki.archlinux.org/title/PulseAudio` - Audio system

## Wiki Structure & Organization

### Main Categories
1. **About Arch** - Community, installation, teams
2. **Development** - Programming, IDEs, text editors, VCS
3. **Hardware** - Bluetooth, CPU, displays, graphics, laptops, networking, sound, storage
4. **Networking** - Email, firewalls, protocols, servers, wireless
5. **Software** - Applications, command-line tools, file formats
6. **System Administration** - Backup, boot, config, filesystems, GUI, kernel, localization, monitoring, packages, power, security, virtualization

### Essential Navigation Pages for WebFetch
- **Main Page**: `https://wiki.archlinux.org/title/Main_page`
- **Table of Contents**: `https://wiki.archlinux.org/title/Table_of_contents`
- **Installation Guide**: `https://wiki.archlinux.org/title/Installation_guide`
- **General Recommendations**: `https://wiki.archlinux.org/title/General_recommendations`

## AI Problem-Solving Strategy

### Decision Tree for WebFetch Usage
1. **Known Topic**: Use direct URL from mapping tables below
2. **Unknown Topic**: Start with General Recommendations or Table of Contents
3. **Complex Issue**: Chain multiple WebFetch calls (general → specific)

### Multi-Step Research Pattern
For complex problems, use sequential WebFetch calls:
```
1. WebFetch: General Recommendations → identify relevant section
2. WebFetch: Specific category page → find exact solution page
3. WebFetch: Solution page → extract detailed implementation
```

### Response Integration
When using WebFetch results:
- Extract exact commands and configuration snippets
- Note package names and dependencies
- Identify potential conflicts or prerequisites
- Reference the source wiki page in responses

## URL Reference Tables for WebFetch

### System Administration URLs
- **Package Management**: `https://wiki.archlinux.org/title/Pacman`
- **AUR Management**: `https://wiki.archlinux.org/title/Arch_User_Repository`
- **Package Building**: `https://wiki.archlinux.org/title/Makepkg`
- **Boot Process**: `https://wiki.archlinux.org/title/Arch_boot_process`
- **GRUB Bootloader**: `https://wiki.archlinux.org/title/GRUB`
- **systemd Boot**: `https://wiki.archlinux.org/title/Systemd-boot`
- **Service Management**: `https://wiki.archlinux.org/title/Systemd`
- **Network Config**: `https://wiki.archlinux.org/title/Network_configuration`
- **Security Guide**: `https://wiki.archlinux.org/title/Security`
- **SSH Setup**: `https://wiki.archlinux.org/title/OpenSSH`

### Hardware Configuration URLs
- **Display Server**: `https://wiki.archlinux.org/title/Xorg`
- **Wayland**: `https://wiki.archlinux.org/title/Wayland`
- **NVIDIA Graphics**: `https://wiki.archlinux.org/title/NVIDIA`
- **AMD Graphics**: `https://wiki.archlinux.org/title/AMDGPU`
- **Intel Graphics**: `https://wiki.archlinux.org/title/Intel_graphics`
- **Audio ALSA**: `https://wiki.archlinux.org/title/Advanced_Linux_Sound_Architecture`
- **Audio PulseAudio**: `https://wiki.archlinux.org/title/PulseAudio`
- **Audio PipeWire**: `https://wiki.archlinux.org/title/PipeWire`
- **Wireless**: `https://wiki.archlinux.org/title/Network_configuration/Wireless`
- **Bluetooth**: `https://wiki.archlinux.org/title/Bluetooth`

### Desktop Environment URLs
- **Window Managers**: `https://wiki.archlinux.org/title/Window_manager`
- **i3 WM**: `https://wiki.archlinux.org/title/I3`
- **bspwm**: `https://wiki.archlinux.org/title/Bspwm`
- **GNOME**: `https://wiki.archlinux.org/title/GNOME`
- **KDE Plasma**: `https://wiki.archlinux.org/title/KDE`
- **Xfce**: `https://wiki.archlinux.org/title/Xfce`
- **Display Managers**: `https://wiki.archlinux.org/title/Display_manager`

## WebFetch Strategy by Problem Type

### Installation/Boot Issues
1. **WebFetch**: `https://wiki.archlinux.org/title/Installation_guide`
2. **Prompt**: "How to solve [specific boot/installation problem]"
3. **Follow-up**: `https://wiki.archlinux.org/title/GRUB` or `https://wiki.archlinux.org/title/Systemd-boot`

### Package Management Problems
1. **WebFetch**: `https://wiki.archlinux.org/title/Pacman`
2. **Prompt**: "How to resolve [specific pacman error/issue]"
3. **Follow-up**: `https://wiki.archlinux.org/title/Arch_User_Repository` for AUR issues

### Hardware Not Working
1. **WebFetch**: Hardware-specific URL from tables above
2. **Prompt**: "Configuration and troubleshooting for [specific hardware]"
3. **Follow-up**: `https://wiki.archlinux.org/title/General_recommendations` for optimization

### Service Configuration
1. **WebFetch**: `https://wiki.archlinux.org/title/Systemd`
2. **Prompt**: "How to configure and manage [specific service]"
3. **Follow-up**: Service-specific wiki page if available

### Performance Issues
1. **WebFetch**: `https://wiki.archlinux.org/title/General_recommendations`
2. **Prompt**: "Performance optimization and tuning recommendations"
3. **Follow-up**: Specific component pages (CPU, disk, memory)

## WebFetch Prompting Best Practices

### Effective Prompts
- **Specific**: "How to configure NVIDIA drivers with Xorg"
- **Problem-focused**: "Troubleshooting PulseAudio no sound issue"
- **Implementation-oriented**: "Step-by-step setup for NetworkManager"

### Information Extraction
When processing WebFetch results, prioritize:
1. **Exact commands** with proper syntax
2. **Package names** and dependencies
3. **Configuration file paths** and content
4. **Troubleshooting steps** and common issues
5. **Prerequisites** and system requirements

## Common Response Patterns

### Always Include
- Exact wiki page URL reference
- Relevant package names
- Configuration file locations
- Potential conflicts or prerequisites

### Arch-Specific Considerations
- Mention rolling release implications
- Note AUR vs official repository differences
- Explain systemd service management
- Reference Arch Linux philosophy when relevant