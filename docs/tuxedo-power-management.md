# Power management configurations for Tuxedo InfinityBook Gen9 on Arch Linux

The Tuxedo InfinityBook Gen9 laptop employs a sophisticated multi-layer power management architecture that combines proprietary hardware control interfaces with optimized Linux kernel configurations. This report provides comprehensive technical details for replicating Tuxedo OS's power management system on Arch Linux, covering all seven requested aspects with implementation-ready configurations.

## Tuxedo Control Center architecture and power profiles

The Tuxedo Control Center (TCC) represents the cornerstone of Tuxedo's power management strategy. Built as an Electron-based GUI frontend communicating with a Node.js backend daemon (`tccd`) via DBus, TCC provides **four customizable power profiles**: Powersave Extreme, Quiet, Office & Multimedia, and TUXEDO Defaults. Each profile independently configures AC and battery states through JSON configuration files stored in `/etc/tcc/profiles`.

The technical implementation relies on the `tuxedo-io` kernel module for hardware communication, manipulating sysfs interfaces directly for CPU frequency scaling, fan control, and power state management. Profile configurations control **CPU governors**, **frequency limits** (800MHz-4.6GHz for Intel variants), **turbo boost states**, **online CPU cores**, and **energy performance preferences**. The system automatically switches profiles based on power source detection, with state persistence managed through `/etc/tcc/autosave`.

For Arch Linux implementation, you'll need to compile TCC from source after installing the tuxedo-drivers DKMS modules. The DBus service configuration at `/usr/share/dbus-1/system.d/com.tuxedocomputers.tccd.conf` enables system-wide hardware control, while systemd services `tccd.service` and `tccd-sleep.service` handle runtime management and sleep state transitions.

## Essential kernel parameters and modules

The InfinityBook Gen9 requires specific kernel parameters that vary between Intel and AMD variants. For **Intel Core Ultra 7 155H models**, the critical GRUB configuration includes `acpi.ec_no_wakeup=1 mem_sleep_default=deep i915.enable_guc=2 i915.enable_psr=0 i915.enable_fbc=1 i915.fastboot=1`. The `i915.enable_guc=2` parameter specifically addresses hard reboot issues by enabling HuC firmware, while `i915.enable_psr=0` prevents display flickering common with Panel Self Refresh.

**AMD Ryzen 7 8845HS variants** require fewer workarounds, needing primarily `acpi.ec_no_wakeup=1 mem_sleep_default=deep`. The EC wakeup parameter prevents spurious wake events from suspend, while deep sleep ensures proper S3 suspend instead of the less efficient s2idle state.

The unified tuxedo-drivers package (v4.12.0+) provides essential kernel modules including `tuxedo_keyboard` for RGB backlight control, `tuxedo_io` for hardware I/O interface, and platform-specific modules like `clevo_wmi`, `uniwill_wmi`, and various ITE controller drivers. These modules load automatically via `/etc/modules-load.d/tuxedo.conf` and configure through modprobe options in `/etc/modprobe.d/`.

## Power management tool configurations

While Tuxedo OS defaults to TCC for power management, users can alternatively configure TLP for more granular control. The system uses `power-profiles-daemon` by default, which **conflicts with TLP** and must be masked if switching to TLP-based management.

For AMD processors, the `amd-pstate-epp` driver provides optimal efficiency with hardware-managed P-states. The driver supports performance and powersave governors, with energy performance preferences ranging from "power" to "balance_performance". Intel variants utilize `intel_pstate` with similar governor options but require additional thermal management through TCC's TDP controls.

Key TLP optimizations for the InfinityBook Gen9 include platform-specific settings: `PLATFORM_PROFILE_ON_AC=balanced`, `CPU_ENERGY_PERF_POLICY_ON_BAT=power`, `PCIE_ASPM_ON_BAT=powersupersave`, and `USB_AUTOSUSPEND=1`. The configuration carefully balances power savings with hardware compatibility, avoiding aggressive settings that might impact stability.

## CPU governor and frequency scaling implementation

The CPU frequency scaling implementation differs significantly between AMD and Intel variants. **AMD systems** leverage the `amd-pstate` driver in either active or guided mode, with the kernel parameter `amd_pstate=active` enabling full hardware control. The Ryzen 7 8845HS operates between 3.3GHz base and 5.1GHz boost frequencies, with 54W configurable TDP managed through TCC interfaces.

**Intel systems** use a fixed performance governor with `intel_pstate`, relying on hardware-managed frequency scaling. TCC manipulates scaling through sysfs interfaces: `/sys/devices/system/cpu/cpu*/cpufreq/scaling_governor` for governor selection, `scaling_min_freq` and `scaling_max_freq` for frequency limits, and `energy_performance_preference` for power/performance balance.

Both platforms support turbo boost control via the `noTurbo` flag in TCC profiles or `/sys/devices/system/cpu/intel_pstate/no_turbo` for manual configuration. The system monitors thermal states and adjusts frequencies dynamically, with critical temperature thresholds at 80°C (30% minimum fan speed) and 90°C (40% minimum fan speed).

## GPU power management strategies

The InfinityBook Gen9's integrated graphics require platform-specific power management approaches. **Intel Arc graphics** utilize RC6 power states enabled by default in modern kernels, with runtime power management configured via `echo 'auto' > /sys/bus/pci/devices/0000:00:02.0/power/control`. Additional optimizations include framebuffer compression (`i915.enable_fbc=1`) and GuC firmware management for media acceleration.

**AMD Radeon 780M** graphics support multiple power profiles accessible through `/sys/class/drm/card0/device/pp_power_profile_mode`, with options for 3D_FULL_SCREEN, POWER_SAVING, VIDEO, VR, and COMPUTE workloads. The integrated GPU's 12 compute units can scale up to 2.7GHz, with power states managed through the amdgpu driver's runtime PM infrastructure.

Display power saving features include DPMS timeouts configurable via `xset dpms 300 600 900` for X11 or gsettings for Wayland environments. Panel Self Refresh, while available, remains disabled by default on Intel variants due to flickering issues specific to the InfinityBook Gen9's display panel.

## ACPI patches and hardware workarounds

The most critical ACPI workaround addresses wake-from-suspend issues through `acpi.ec_no_wakeup=1`, preventing the embedded controller from generating spurious wake events. This parameter proves essential for both Intel and AMD variants, resolving a fundamental hardware behavior that would otherwise result in immediate wake after suspend.

Additional workarounds include disabling certain ACPI features that conflict with modern power management. The `mem_sleep_default=deep` parameter forces traditional S3 suspend instead of Windows-preferred s2idle, significantly improving battery life during sleep states. Some users report success with custom DSDT patches for enhanced battery reporting accuracy, though these remain optional.

Hardware-specific quirks addressed through udev rules include touchpad power management fixes (`SUBSYSTEM=="i2c", ATTRS{name}=="ELAN*", ATTR{power/control}="on"`) and webcam privacy LED control through BIOS-level interfaces where supported.

## Systemd services and optimization scripts

The power management infrastructure relies on several systemd services working in concert. The primary `tccd.service` manages the TCC daemon, while `tccd-sleep.service` handles power state transitions during suspend/resume cycles. These services integrate with systemd's power management framework through dependencies on `multi-user.target` and `sleep.target`.

Custom optimization includes PCIe ASPM configuration through `/etc/udev/rules.d/50-pcie-power.rules`, enabling aggressive power saving for PCIe devices. NVMe storage benefits from Autonomous Power State Transitions (APST) enabled via `nvme_core.default_ps_max_latency_us=5500`, allowing drives to enter low-power states during idle periods.

Network adapter power saving utilizes interface-specific configurations: Intel WiFi modules load with `options iwlwifi power_save=1 power_level=5`, while ethernet interfaces disable Wake-on-LAN through ethtool commands in udev rules. Audio codecs implement 10-second idle timeouts via `options snd_hda_intel power_save=10 power_save_controller=Y`, significantly reducing idle power consumption.

USB autosuspend applies selectively through udev rules, enabling power saving for most devices while excluding HID devices and known-problematic peripherals. The configuration uses device-specific rules based on vendor/product IDs to maintain compatibility while maximizing power efficiency.

## Conclusion

Replicating Tuxedo OS's power management on Arch Linux requires a three-pronged approach: installing tuxedo-drivers for hardware interface access, configuring appropriate kernel parameters for your specific variant, and choosing between TCC's integrated profiles or manual TLP configuration. The Intel variant demands more workarounds but provides robust power management once properly configured, while AMD systems offer superior out-of-box efficiency with fewer required modifications.

Success depends on correctly identifying your hardware variant and applying the appropriate combination of kernel parameters, driver configurations, and userspace tools. The modular nature of these configurations allows selective implementation based on specific needs, whether prioritizing battery life, performance, or thermal management. Regular monitoring through powertop and tlp-stat helps verify proper operation and identify opportunities for further optimization specific to individual usage patterns.