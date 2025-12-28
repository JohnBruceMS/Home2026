# Home Assistant Architecture Guide

## Table of Contents
1. [Core Architecture Overview](#core-architecture-overview)
2. [Entity Model & State Management](#entity-model--state-management)
3. [Integration Ecosystem](#integration-ecosystem)
4. [Configuration Systems](#configuration-systems)
5. [Database & Storage Architecture](#database--storage-architecture)
6. [Security Architecture](#security-architecture)
7. [Performance Considerations](#performance-considerations)
8. [Best Practices](#best-practices)

---

## Core Architecture Overview

### System Architecture
Home Assistant follows a modular, event-driven architecture built on Python's asyncio framework:

```
┌─────────────────────────────────────────────────────────┐
│                    Home Assistant Core                   │
├─────────────────────────────────────────────────────────┤
│  Frontend (Lovelace UI) │  API Layer  │  WebSocket API   │
├─────────────────────────────────────────────────────────┤
│           Event Bus & State Manager                     │
├─────────────────────────────────────────────────────────┤
│  Integrations │  Components │  Platforms │  Services    │
├─────────────────────────────────────────────────────────┤
│           Device Registry & Entity Registry             │
├─────────────────────────────────────────────────────────┤
│  Database (SQLite/PostgreSQL) │ File System (Config)    │
└─────────────────────────────────────────────────────────┘
```

### Core Components

#### 1. Home Assistant Core (`homeassistant.core`)
- **HomeAssistant Class**: Central coordinator managing all components
- **Event Bus**: Asynchronous event dispatcher using asyncio
- **State Manager**: Central state storage and change tracking
- **Service Registry**: Service call management and routing
- **Configuration Manager**: Config loading and validation

#### 2. Component Hierarchy
```python
# Component Types
- Domain Components: Core functionality (light, sensor, switch)
- Platform Components: Implementation for specific brands/protocols
- Integration Components: Complete device/service integrations
- Helper Components: Utility functions and data processing
```

### Startup Sequence
1. **Core Initialization**: Load core components and event bus
2. **Configuration Loading**: Parse YAML files and validate structure
3. **Integration Discovery**: Auto-discover and load integrations
4. **Entity Registration**: Register all discovered entities
5. **Service Activation**: Start all configured services
6. **Frontend Launch**: Initialize web server and UI

---

## Entity Model & State Management

### Entity Lifecycle
```python
# Entity State Lifecycle
UNKNOWN → UNAVAILABLE → ACTIVE → IDLE → OFF/ON → UNAVAILABLE
```

### State Object Structure
```python
{
    "entity_id": "light.living_room_main",
    "state": "on",
    "attributes": {
        "brightness": 255,
        "color_mode": "hs",
        "friendly_name": "Living Room Main Light",
        "supported_color_modes": ["hs", "xy"],
        "device_class": "light"
    },
    "last_changed": "2025-12-28T10:30:00.000000+00:00",
    "last_updated": "2025-12-28T10:30:00.000000+00:00",
    "context": {
        "id": "01HMQR8XYZ123456789",
        "parent_id": None,
        "user_id": "user_123"
    }
}
```

### Event System
```python
# Core Event Types
EVENT_HOMEASSISTANT_START = "homeassistant_start"
EVENT_HOMEASSISTANT_STOP = "homeassistant_stop" 
EVENT_STATE_CHANGED = "state_changed"
EVENT_SERVICE_EXECUTED = "service_executed"
EVENT_AUTOMATION_TRIGGERED = "automation_triggered"
EVENT_LOGBOOK_ENTRY = "logbook_entry"
```

### Entity Registry Schema
```python
{
    "entity_id": "sensor.temperature_sensor",
    "unique_id": "xiaomi_sensor_12345_temperature",
    "platform": "xiaomi_miio",
    "device_id": "device_registry_id_123",
    "config_entry_id": "config_entry_456",
    "disabled_by": None,
    "entity_category": "diagnostic",
    "hidden_by": None,
    "name": "Temperature Sensor",
    "original_name": "Temperature",
    "capabilities": {},
    "supported_features": 0,
    "device_class": "temperature",
    "unit_of_measurement": "°C"
}
```

---

## Integration Ecosystem

### Integration Types

#### 1. Core Integrations
Built into Home Assistant core:
- `default_config`: Basic HA functionality
- `http`: Web server and API
- `websocket_api`: Real-time communication
- `api`: REST API endpoints
- `frontend`: Web interface
- `history`: State history tracking
- `logbook`: Event logging

#### 2. Custom Components
Located in `custom_components/`:
```
custom_components/
├── alexa_media/
│   ├── __init__.py
│   ├── manifest.json
│   ├── config_flow.py
│   └── [component files]
└── hacs/
    ├── __init__.py
    ├── manifest.json
    └── [component files]
```

#### 3. Integration Manifest Structure
```json
{
    "domain": "alexa_media",
    "name": "Alexa Media Player", 
    "codeowners": ["@alandtse"],
    "config_flow": true,
    "dependencies": ["persistent_notification", "http"],
    "documentation": "https://github.com/alandtse/alexa_media_player/wiki",
    "iot_class": "cloud_polling",
    "requirements": ["alexapy==1.27.10"],
    "version": "4.9.2"
}
```

### Device Discovery Methods

#### 1. Network Discovery
- **mDNS/Zeroconf**: Automatic device detection
- **SSDP**: UPnP device discovery
- **Network Scanning**: IP range scanning for known protocols

#### 2. USB/Serial Discovery
- **USB Device Detection**: Zigbee/Z-Wave controllers
- **Serial Port Scanning**: Direct device connections

#### 3. Cloud API Discovery
- **OAuth Integration**: Cloud service authentication
- **API Polling**: Regular status updates
- **Webhook Registration**: Real-time notifications

---

## Configuration Systems

### Configuration Hierarchy
```yaml
# configuration.yaml - Main configuration
default_config:

# Include external files
automation: !include automations.yaml
script: !include scripts.yaml
scene: !include scenes.yaml
group: !include groups.yaml

# Integration configurations
media_player:
  - platform: yamaha_musiccast
    host: 192.168.1.158
    port: 5005

sensor:
  - platform: pushbullet
    api_key: !secret pushbullet_api_key
    monitored_conditions:
      - body
```

### Configuration Methods

#### 1. YAML Configuration
- **Main Config**: `configuration.yaml`
- **Split Configs**: Separate files for automations, scripts, etc.
- **Packages**: Grouped configuration bundles
- **Secrets**: Sensitive data isolation

#### 2. UI Configuration
- **Integration Setup**: Config flow wizards
- **Device Configuration**: Entity customization
- **Automation Builder**: Visual automation creation
- **Dashboard Editor**: UI customization

#### 3. Config Flow System
```python
class YamahaConfigFlow(config_entries.ConfigFlow, domain=DOMAIN):
    """Handle Yamaha MusicCast config flow."""
    
    async def async_step_user(self, user_input=None):
        """Handle user initiated configuration."""
        if user_input is not None:
            return await self.async_step_discovery()
        
        return self.async_show_form(
            step_id="user",
            data_schema=vol.Schema({
                vol.Required("host"): str,
                vol.Optional("port", default=5005): int,
            })
        )
```

### Configuration Validation
```python
# Schema validation example
MEDIA_PLAYER_SCHEMA = vol.Schema({
    vol.Required(CONF_PLATFORM): "yamaha_musiccast",
    vol.Required(CONF_HOST): cv.string,
    vol.Optional(CONF_PORT, default=5005): cv.port,
    vol.Optional(CONF_NAME): cv.string,
    vol.Optional(CONF_ZONE_IGNORE): vol.All(cv.ensure_list, [cv.string]),
})
```

---

## Database & Storage Architecture

### Database Schema
Home Assistant uses SQLite by default, with PostgreSQL support for larger deployments.

#### Core Tables
```sql
-- States table (primary data storage)
CREATE TABLE states (
    state_id INTEGER PRIMARY KEY AUTOINCREMENT,
    domain VARCHAR(64),
    entity_id VARCHAR(255),
    state VARCHAR(255),
    attributes TEXT,
    event_id INTEGER,
    last_changed DATETIME,
    last_updated DATETIME,
    created DATETIME,
    old_state_id INTEGER
);

-- Events table (event history)
CREATE TABLE events (
    event_id INTEGER PRIMARY KEY AUTOINCREMENT,
    event_type VARCHAR(32),
    event_data TEXT,
    origin VARCHAR(32),
    time_fired DATETIME,
    created DATETIME,
    context_id VARCHAR(36),
    context_user_id VARCHAR(36),
    context_parent_id VARCHAR(36)
);

-- Statistics table (long-term data)
CREATE TABLE statistics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    created DATETIME,
    start DATETIME,
    source VARCHAR(32),
    statistic_id VARCHAR(255),
    name VARCHAR(255),
    mean DOUBLE PRECISION,
    min DOUBLE PRECISION,
    max DOUBLE PRECISION,
    last_reset DATETIME,
    state DOUBLE PRECISION,
    sum DOUBLE PRECISION
);
```

### Storage Configuration
```yaml
# recorder configuration
recorder:
  db_url: sqlite:///home-assistant_v2.db
  # db_url: postgresql://user:password@localhost/hass
  purge_keep_days: 10
  commit_interval: 1
  include:
    entities:
      - sensor.temperature
      - light.living_room
  exclude:
    entities:
      - sensor.uptime
    domains:
      - automation
```

### Data Retention Policies
```python
# Automatic purge configuration
PURGE_SETTINGS = {
    "keep_days": 10,           # Keep 10 days of detailed history
    "repack": True,            # Optimize database after purge
    "auto_purge": True,        # Enable automatic purging
    "auto_repack": True        # Enable automatic repacking
}
```

---

## Security Architecture

### Authentication System
```yaml
# HTTP component security
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 192.168.1.0/24
    - 127.0.0.1
  cors_allowed_origins:
    - https://mydomain.com
  ip_ban_enabled: true
  login_attempts_threshold: 5
```

### Access Control
```python
# User permissions
USER_PERMISSIONS = {
    "admin": ["read", "write", "execute", "configure"],
    "user": ["read", "write", "execute"],
    "viewer": ["read"]
}
```

### API Security
```python
# Bearer token authentication
headers = {
    "Authorization": "Bearer YOUR_LONG_LIVED_ACCESS_TOKEN",
    "Content-Type": "application/json"
}
```

### Network Security
```yaml
# Firewall considerations
# Allow only necessary ports:
# 8123: Home Assistant web interface
# 1883: MQTT (if used)
# 5353: mDNS discovery
# 21063: HomeKit (if used)
```

---

## Performance Considerations

### Resource Optimization
```python
# Memory usage optimization
OPTIMIZE_MEMORY = {
    "purge_interval_days": 7,
    "history_stats_max_age": "7d", 
    "statistics_keep_days": 365,
    "event_cache_size": 1024,
    "state_cache_size": 2048
}
```

### Database Performance
```yaml
recorder:
  commit_interval: 1          # Commit frequency (seconds)
  auto_purge: true           # Enable automatic cleanup
  auto_repack: true          # Database optimization
  exclude:                   # Reduce data volume
    entities:
      - sun.sun
      - sensor.time
```

### Integration Performance
```python
# Polling intervals
UPDATE_INTERVALS = {
    "fast_sensors": 30,        # Temperature, motion (seconds)
    "medium_sensors": 300,     # Energy, weather (seconds) 
    "slow_sensors": 3600,      # System info (seconds)
    "cloud_services": 900      # External APIs (seconds)
}
```

---

## Best Practices

### Configuration Organization
```yaml
# Use packages for logical grouping
homeassistant:
  packages: !include_dir_named packages/

# packages/lighting.yaml
lighting:
  light:
    - platform: hue
  automation:
    - alias: "Living Room Motion Light"
      # automation config
```

### Entity Naming Conventions
```python
# Consistent naming patterns
NAMING_CONVENTIONS = {
    "sensors": "sensor.location_type_description",
    "lights": "light.location_description", 
    "switches": "switch.location_device_description",
    "automations": "Location - Action Description"
}

# Examples:
# sensor.living_room_temperature
# light.office_desk_lamp
# switch.bedroom_fan
# "Living Room - Motion Light Control"
```

### Error Handling
```python
# Robust automation design
try:
    await hass.services.async_call(
        "light", "turn_on",
        {"entity_id": "light.living_room"},
        blocking=True,
        timeout=10
    )
except ServiceNotFound:
    _LOGGER.error("Light service not available")
except asyncio.TimeoutError:
    _LOGGER.error("Light service timeout")
```

### Backup Strategy
```bash
#!/bin/bash
# Complete backup script
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backup/homeassistant_$DATE"

# Stop Home Assistant
systemctl stop home-assistant@homeassistant

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup configuration
cp -r /home/homeassistant/.homeassistant/ $BACKUP_DIR/config/

# Backup database  
cp /home/homeassistant/.homeassistant/home-assistant_v2.db $BACKUP_DIR/

# Backup custom components
cp -r /home/homeassistant/.homeassistant/custom_components/ $BACKUP_DIR/

# Start Home Assistant
systemctl start home-assistant@homeassistant

# Compress backup
tar -czf "$BACKUP_DIR.tar.gz" -C /backup "homeassistant_$DATE"
rm -rf $BACKUP_DIR
```

---

## Version Compatibility Matrix

| HA Version | Python | Key Changes |
|------------|--------|-------------|
| 2024.12.x  | 3.12+  | New dashboard features, energy management |
| 2024.6.x   | 3.11+  | UI improvements, integration updates |
| 2024.1.x   | 3.11+  | Voice assistant improvements |
| 2023.12.x  | 3.11+  | Matter support, performance improvements |

---

*Last Updated: December 28, 2025*
*Home Assistant Version: 2024.12.x*
*Documentation Version: 1.0*