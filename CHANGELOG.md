# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-14

### Added

#### Live Streaming
- Real-time WebRTC video streaming with two quality modes:
  - Normal Mode: 640x480 at 30 FPS (~675 MB/hour)
  - Power-Saving Mode: 426x240 at 15 FPS (~180 MB/hour)
- WebRTC streaming service (`webrtc_streaming_service.dart`)
- Socket.IO signaling service (`signaling_service.dart`)
- Real-time viewer count display
- Limit of 10 simultaneous viewers per stream

#### GPS Tracking
- Real-time GPS tracking every 1-3 seconds
- Automatic route statistics calculation:
  - Total distance traveled
  - Current, average, and maximum speed
  - Trip duration
- Location service (`location_service.dart`)
- Metadata service for route statistics (`metadata_service.dart`)

#### Route Management
- Route history with detailed information
- Route export in multiple formats:
  - GPX (GPS Exchange Format)
  - KML (Keyhole Markup Language)
  - JSON
- Route anonymization feature (0-1000m offset)
- Routes history controller (`routes_history_controller.dart`)

#### Network and Power Optimization
- Power-saving mode with automatic adjustment of:
  - Video bitrate
  - Frames per second (FPS)
  - GPS update frequency
- Real-time network monitoring (`network_monitor_service.dart`):
  - Connection type detection (WiFi/4G/5G)
  - Latency and quality measurement
  - Dynamic adjustments based on network conditions
- Battery monitoring with Battery Plus
- Screen lock with Wakelock Plus
- Data usage management with estimates per mode

#### Authentication and Security
- JWT authentication with 7-day token duration
- Secure credential storage with SharedPreferences
- Authentication service (`auth_service.dart`)
- Login screen (`login_view.dart`)
- Demo user: `demo` / `demo123`

#### Automatic Reconnection
- 30-second grace period to recover connection
- Automatic reconnection on network failures
- Stream state maintenance during reconnection

#### User Interface
- GetX MVC architecture for reactive state management
- Main screen with verification of:
  - Network and connectivity status
  - Battery level
  - Camera and location permissions
- Live streaming view (`streaming_view.dart`)
- Home view (`home_view.dart`)
- Visual streaming status indicators
- Real-time statistics during streaming

#### Permission Management
- Camera permission management with Permission Handler
- Location permission management
- Runtime permission verification and requests

#### Configuration
- Persistent settings service (`settings_service.dart`)
- Centralized API configuration (`api_config.dart`)
- Configurable server parameters

### Main Dependencies
- **State & Navigation**: GetX (^4.6.6)
- **Streaming**: flutter_webrtc (^0.11.7), socket_io_client (^2.0.3)
- **Location**: geolocator (^13.0.2), flutter_map (^7.0.2), latlong2 (^0.9.1)
- **Network**: connectivity_plus (^5.0.0), http (^1.2.0)
- **Storage**: shared_preferences (^2.3.4), path_provider (^2.1.5)
- **Permissions**: permission_handler (^11.3.1)
- **Power**: wakelock_plus (^1.2.10), battery_plus (^6.2.1)
- **Utilities**: uuid (^4.5.1), intl (^0.20.2), xml (^6.5.0), share_plus (^10.1.4)

### Supported Platforms
- Android >= 6.0 (API 23)
- iOS >= 12.0
- Multi-platform support (Android, iOS, Web, Linux, macOS, Windows)

### Technical
- Flutter SDK >= 3.10.1
- MVC architecture with GetX
- Bindings for dependency injection
- Named routes with navigation system
- Clear separation of concerns (models, services, controllers, views)

### Documentation
- Complete README.md with installation and usage instructions
- GetX MVC architecture documentation
- Troubleshooting guide
- Data usage comparison table
- Configuration instructions for emulator and physical devices

---

[1.0.0]: https://github.com/kevindels/transmission_routes/releases/tag/v1.0.0
