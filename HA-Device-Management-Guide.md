# Home Assistant Device Management Guide

## Table of Contents
1. [Device Integration Overview](#device-integration-overview)
2. [Entity Organization & Customization](#entity-organization--customization)
3. [Advanced Automation Patterns](#advanced-automation-patterns)
4. [Template Sensors & Advanced Templating](#template-sensors--advanced-templating)
5. [Custom Integrations & APIs](#custom-integrations--apis)
6. [Zigbee/Z-Wave Management](#zigbeez-wave-management)
7. [Network Device Troubleshooting](#network-device-troubleshooting)
8. [Performance Optimization](#performance-optimization)
9. [Lifecycle Management](#lifecycle-management)

---

## Device Integration Overview

### Integration Methods

```yaml
# Device discovery hierarchy
discovery_methods:
  automatic:
    - mdns_zeroconf: "Network service discovery"
    - ssdp_upnp: "UPnP device discovery"
    - dhcp: "DHCP lease monitoring"
    - usb: "USB device detection"
    
  manual:
    - config_flow: "UI-based setup wizard"
    - yaml_config: "Manual YAML configuration"
    - api_integration: "Direct API configuration"
    
  hybrid:
    - discovered_then_configured: "Auto-discover, manual setup"
    - periodic_scanning: "Scheduled network scanning"
```

### Your Current Setup Analysis
Based on your configuration, you have:

```yaml
current_integrations:
  media_players:
    yamaha_musiccast:
      host: "192.168.1.158"
      port: 5005
      discovery_method: "manual_yaml"
      entity_pattern: "media_player.living_room_main"
      
  notifications:
    pushbullet:
      api_key: "secured_in_secrets"
      monitored_conditions: ["body"]
      entity_pattern: "sensor.pushbullet_*"
      
  motion_sensors:
    xiaomi_miio:
      device_pattern: "binary_sensor.lumi_lumi_sensor_motion_*"
      device_class: "motion"
      integration_method: "config_flow"
      
  custom_components:
    alexa_media:
      version: "4.9.2"
      entities: ["media_player.*", "sensor.alexa_*"]
    hacs:
      component_manager: true
```

### Integration Configuration Patterns

#### 1. Network-Based Devices
```yaml
# Best practices for network devices
network_device_config:
  yamaha_musiccast:
    scan_interval: 30        # Seconds between updates
    timeout: 10              # Connection timeout
    retry_attempts: 3        # Failed connection retries
    
    # Advanced configuration
    zone_ignore:             # Zones to exclude
      - "Zone_3"
      - "Zone_4"
    features:
      - power_control
      - volume_control
      - source_selection
      - playback_control

# Configuration validation
network_device_schema:
  required:
    - host
    - platform
  optional:
    - port: {default: 5005, range: [1, 65535]}
    - name: {pattern: "^[a-zA-Z0-9_]+$"}
    - timeout: {default: 10, range: [1, 60]}
```

#### 2. Cloud Service Integrations
```python
# Pushbullet integration example
PUSHBULLET_CONFIG = {
    "api_key": "!secret pushbullet_api_key",
    "monitored_conditions": ["body"],
    "update_interval": 300,  # 5 minutes
    "rate_limit": {
        "requests_per_minute": 100,
        "burst_allowance": 20
    },
    "error_handling": {
        "retry_on_failure": True,
        "max_retries": 3,
        "backoff_multiplier": 2
    }
}
```

---

## Entity Organization & Customization

### Entity Registry Management
```python
# Entity customization patterns
entity_customization = {
    "sensor.lumi_lumi_weather_humidity": {
        "friendly_name": "Bookshelf Humidity Sensor",
        "icon": "mdi:water-percent", 
        "device_class": "humidity",
        "unit_of_measurement": "%",
        "state_class": "measurement"
    },
    
    "binary_sensor.lumi_lumi_sensor_motion_aq2_occupancy": {
        "friendly_name": "Office Motion Sensor",
        "device_class": "motion",
        "icon": "mdi:motion-sensor",
        "area_id": "office"
    },
    
    "light.office_spot_lights": {
        "friendly_name": "Office Ceiling Lights",
        "icon": "mdi:ceiling-light",
        "supported_color_modes": ["brightness"],
        "area_id": "office"
    }
}
```

### Area-Based Organization
```yaml
# areas.yaml
areas:
  office:
    name: "Office"
    entities:
      - light.office_spot_lights
      - light.office_stand
      - light.wall
      - binary_sensor.lumi_lumi_sensor_motion_aq2_occupancy
    automations:
      - automation.office_light_off
      - automation.office_motion_detection
      
  living_room:
    name: "Living Room"
    entities:
      - media_player.living_room_main
      - light.living_room_main
    scripts:
      - script.living_room_movie_mode
      - script.living_room_music_mode
```

### Advanced Entity Customization
```yaml
# customize.yaml
homeassistant:
  customize:
    # Sensor customization
    sensor.lumi_lumi_weather_humidity:
      templates:
        friendly_name_template: >
          {% if states(entity_id) | float > 60 %}
            🔴 {{ state_attr(entity_id, 'friendly_name') }}
          {% elif states(entity_id) | float > 45 %}
            🟡 {{ state_attr(entity_id, 'friendly_name') }}
          {% else %}
            🟢 {{ state_attr(entity_id, 'friendly_name') }}
          {% endif %}
      
    # Motion sensor enhancements
    binary_sensor.lumi_lumi_sensor_motion_aq2_occupancy:
      custom_attributes:
        last_motion: >
          {{ (now() - states.binary_sensor.lumi_lumi_sensor_motion_aq2_occupancy.last_changed).total_seconds() / 60 }} minutes ago
        motion_frequency: >
          {{ states('counter.office_motion_events') | int }} times today
```

### Entity Grouping Strategies
```yaml
# groups.yaml
office_devices:
  name: "Office Devices"
  entities:
    - light.office_spot_lights
    - light.office_stand 
    - light.wall
    - binary_sensor.lumi_lumi_sensor_motion_aq2_occupancy
    - sensor.office_temperature
    - sensor.office_humidity

office_lighting:
  name: "Office Lighting"
  entities:
    - light.office_spot_lights
    - light.office_stand
    - light.wall

all_motion_sensors:
  name: "Motion Sensors"
  entities:
    - binary_sensor.lumi_lumi_sensor_motion_aq2_occupancy
    - binary_sensor.living_room_motion
    - binary_sensor.bedroom_motion

humidity_monitors:
  name: "Humidity Monitors"
  entities:
    - sensor.lumi_lumi_weather_humidity
    - sensor.bathroom_humidity
    - sensor.kitchen_humidity
```

---

## Advanced Automation Patterns

### State-Based Automation Framework
```yaml
# Enhanced motion-based lighting
automation:
  - id: 'advanced_office_lighting'
    alias: "Advanced Office Lighting Control"
    mode: single
    max_exceeded: silent
    
    trigger:
      - platform: state
        entity_id: binary_sensor.lumi_lumi_sensor_motion_aq2_occupancy
        to: 'on'
        id: 'motion_detected'
        
      - platform: state
        entity_id: binary_sensor.lumi_lumi_sensor_motion_aq2_occupancy
        to: 'off'
        for:
          minutes: 20
        id: 'motion_cleared'
        
      - platform: numeric_state
        entity_id: sensor.office_illuminance
        below: 100
        id: 'low_light'
        
    condition:
      - condition: template
        value_template: >
          {% set time_of_day = now().hour %}
          {% set is_workday = now().weekday() < 5 %}
          {% set someone_home = is_state('person.john', 'home') %}
          
          {# Only trigger during reasonable hours #}
          {{ 6 <= time_of_day <= 23 and someone_home }}
          
    action:
      - choose:
          # Motion detected
          - conditions:
              - condition: trigger
                id: 'motion_detected'
            sequence:
              - service: script.turn_on
                target:
                  entity_id: script.office_lights_on
                data:
                  variables:
                    brightness_pct: >
                      {% set hour = now().hour %}
                      {% if hour <= 7 or hour >= 22 %}
                        30  # Night mode
                      {% elif hour <= 9 or hour >= 18 %}
                        70  # Dawn/dusk
                      {% else %}
                        100  # Daytime
                      {% endif %}
                    
          # Motion cleared 
          - conditions:
              - condition: trigger
                id: 'motion_cleared'
            sequence:
              - service: light.turn_off
                target:
                  entity_id: 
                    - light.office_spot_lights
                    - light.office_stand
                    - light.wall
                data:
                  transition: 5
```

### Multi-Condition Automation Templates
```yaml
# Intelligent climate control
automation:
  - alias: "Smart Climate Response"
    trigger:
      - platform: numeric_state
        entity_id: sensor.lumi_lumi_weather_humidity  
        above: 55
        for:
          minutes: 15
        
    condition:
      - condition: template
        value_template: >
          {% set current_hour = now().hour %}
          {% set humidity = states('sensor.lumi_lumi_weather_humidity') | float %}
          {% set outdoor_humidity = states('sensor.outdoor_humidity') | float(0) %}
          {% set last_notification = states('input_datetime.last_humidity_alert') %}
          
          {# Complex decision logic #}
          {% set humidity_threshold_exceeded = humidity > 55 %}
          {% set significant_difference = (humidity - outdoor_humidity) > 10 %}
          {% set daytime_hours = 8 <= current_hour <= 20 %}
          {% set not_recently_notified = (now() - strptime(last_notification, '%Y-%m-%d %H:%M:%S')).total_seconds() > 7200 %}
          
          {{ humidity_threshold_exceeded and significant_difference and daytime_hours and not_recently_notified }}
    
    action:
      - parallel:
          # Send notification
          - service: notify.mobile_app_sm_n986u
            data:
              title: "High Humidity Alert"
              message: >
                Humidity at {{ states('sensor.lumi_lumi_weather_humidity') }}% 
                in bookshelf area. Consider ventilation.
              data:
                tag: humidity_alert
                group: environmental
                
          # Log the event
          - service: logbook.log
            data:
              name: "Humidity Monitor"
              message: >
                High humidity detected: {{ states('sensor.lumi_lumi_weather_humidity') }}%
              domain: automation
              
          # Update last notification time
          - service: input_datetime.set_datetime
            target:
              entity_id: input_datetime.last_humidity_alert
            data:
              datetime: "{{ now().strftime('%Y-%m-%d %H:%M:%S') }}"
```

### Event-Driven Automation
```python
# Advanced event handling
@callback
def advanced_automation_handler(hass):
    """Advanced automation event handler."""
    
    @callback
    def handle_state_change(event):
        """Handle state change events with advanced logic."""
        entity_id = event.data.get("entity_id")
        new_state = event.data.get("new_state")
        old_state = event.data.get("old_state")
        
        if not new_state or not old_state:
            return
        
        # Pattern matching for different device types
        if entity_id.startswith("binary_sensor") and "motion" in entity_id:
            handle_motion_event(entity_id, new_state, old_state)
        elif entity_id.startswith("sensor") and "humidity" in entity_id:
            handle_humidity_event(entity_id, new_state, old_state)
        elif entity_id.startswith("media_player"):
            handle_media_event(entity_id, new_state, old_state)
    
    def handle_motion_event(entity_id, new_state, old_state):
        """Handle motion sensor events."""
        if new_state.state == "on" and old_state.state == "off":
            # Motion detected
            area = get_entity_area(entity_id)
            current_hour = datetime.now().hour
            
            # Determine appropriate lighting response
            if area == "office" and 6 <= current_hour <= 23:
                brightness = calculate_brightness(current_hour)
                hass.async_create_task(
                    turn_on_area_lights(area, brightness)
                )
    
    # Register event listener
    hass.bus.async_listen(EVENT_STATE_CHANGED, handle_state_change)
```

---

## Template Sensors & Advanced Templating

### Advanced Template Sensors
```yaml
# template.yaml
template:
  - sensor:
      # Office occupancy intelligence
      - name: "Office Occupancy Score"
        unique_id: office_occupancy_score
        state: >
          {% set motion = states('binary_sensor.lumi_lumi_sensor_motion_aq2_occupancy') %}
          {% set lights_on = states('light.office_spot_lights') == 'on' %}
          {% set computer_active = states('binary_sensor.office_computer') == 'on' %}
          {% set last_motion_minutes = (now() - states.binary_sensor.lumi_lumi_sensor_motion_aq2_occupancy.last_changed).total_seconds() / 60 %}
          
          {% set score = 0 %}
          {% if motion == 'on' %}
            {% set score = score + 40 %}
          {% elif last_motion_minutes < 30 %}
            {% set score = score + 20 %}
          {% endif %}
          
          {% if lights_on %}
            {% set score = score + 30 %}
          {% endif %}
          
          {% if computer_active %}
            {% set score = score + 30 %}
          {% endif %}
          
          {{ score }}
        unit_of_measurement: "%"
        device_class: measurement
        
      # Environmental comfort index
      - name: "Bookshelf Comfort Index"
        unique_id: bookshelf_comfort_index
        state: >
          {% set humidity = states('sensor.lumi_lumi_weather_humidity') | float(50) %}
          {% set temp = states('sensor.bookshelf_temperature') | float(22) %}
          
          {% set humidity_score = 100 - (humidity - 45) * 2 if humidity > 45 else 100 %}
          {% set temp_score = 100 - abs(temp - 22) * 5 %}
          
          {% set comfort = (humidity_score + temp_score) / 2 %}
          {{ comfort | round(1) }}
        unit_of_measurement: "%"
        attributes:
          humidity_level: >
            {% set h = states('sensor.lumi_lumi_weather_humidity') | float %}
            {% if h > 60 %}High
            {% elif h > 45 %}Normal  
            {% else %}Low
            {% endif %}
          comfort_rating: >
            {% set score = states('sensor.bookshelf_comfort_index') | float %}
            {% if score > 80 %}Excellent
            {% elif score > 60 %}Good
            {% elif score > 40 %}Fair
            {% else %}Poor
            {% endif %}

  - binary_sensor:
      # Intelligent occupancy detection
      - name: "Office Actually Occupied"
        unique_id: office_actually_occupied
        state: >
          {% set occupancy_score = states('sensor.office_occupancy_score') | int(0) %}
          {% set time_appropriate = 6 <= now().hour <= 23 %}
          {% set workday = now().weekday() < 5 %}
          
          {{ occupancy_score > 50 and time_appropriate }}
        attributes:
          confidence: "{{ states('sensor.office_occupancy_score') }}%"
          factors: >
            {% set factors = [] %}
            {% if states('binary_sensor.lumi_lumi_sensor_motion_aq2_occupancy') == 'on' %}
              {% set factors = factors + ['motion_detected'] %}
            {% endif %}
            {% if states('light.office_spot_lights') == 'on' %}
              {% set factors = factors + ['lights_on'] %}
            {% endif %}
            {{ factors | join(', ') }}
```

### Dynamic Template Creation
```python
# Dynamic template sensor creation
class DynamicTemplateSensor:
    """Create template sensors dynamically based on device patterns."""
    
    def __init__(self, hass):
        self.hass = hass
        
    def create_device_summary_sensors(self):
        """Create summary sensors for device groups."""
        templates = []
        
        # Find all motion sensors
        motion_sensors = [
            entity.entity_id for entity in self.hass.states.async_all()
            if entity.domain == 'binary_sensor' and 
            entity.attributes.get('device_class') == 'motion'
        ]
        
        if motion_sensors:
            templates.append({
                'name': 'Motion Sensors Active',
                'state': f'''
                {{{{ 
                    [{', '.join([f'states("{sensor}")' for sensor in motion_sensors])}]
                    | select('eq', 'on') | list | length 
                }}}}
                ''',
                'attributes': {
                    'active_sensors': f'''
                    {{{{ 
                        [{', '.join([f'"{sensor}" if states("{sensor}") == "on"' for sensor in motion_sensors])}]
                        | select('ne', '') | list 
                    }}}}
                    ''',
                    'total_sensors': str(len(motion_sensors))
                }
            })
        
        return templates
```

### Advanced Templating Functions
```yaml
# Advanced template functions
template_functions:
  time_based:
    - name: "time_of_day_factor"
      template: >
        {% macro time_of_day_factor() %}
          {% set hour = now().hour %}
          {% if 6 <= hour <= 9 %}morning
          {% elif 10 <= hour <= 17 %}day  
          {% elif 18 <= hour <= 22 %}evening
          {% else %}night
          {% endif %}
        {% endmacro %}
        
    - name: "daylight_factor"
      template: >
        {% macro daylight_factor() %}
          {% set sun_elevation = state_attr('sun.sun', 'elevation') | float(0) %}
          {% if sun_elevation > 10 %}bright
          {% elif sun_elevation > 0 %}dim
          {% else %}dark
          {% endif %}
        {% endmacro %}
        
  device_specific:
    - name: "yamaha_status_summary"
      template: >
        {% macro yamaha_status() %}
          {% set player = 'media_player.living_room_main' %}
          {% set state = states(player) %}
          {% set source = state_attr(player, 'source') %}
          {% set volume = state_attr(player, 'volume_level') | float(0) * 100 %}
          
          {% if state == 'on' %}
            Playing {{ source }} at {{ volume | round }}% volume
          {% elif state == 'off' %}
            Off
          {% else %}
            {{ state | title }}
          {% endif %}
        {% endmacro %}
```

---

## Custom Integrations & APIs

### REST API Integration Template
```python
# Custom REST API integration
import aiohttp
import asyncio
from homeassistant.helpers.entity import Entity
from homeassistant.helpers.update_coordinator import DataUpdateCoordinator

class CustomAPIIntegration:
    """Template for custom API integrations."""
    
    def __init__(self, hass, api_url, api_key):
        self.hass = hass
        self.api_url = api_url
        self.api_key = api_key
        
        # Setup data coordinator for efficient updates
        self.coordinator = DataUpdateCoordinator(
            hass,
            _LOGGER,
            name="custom_api",
            update_method=self.async_update_data,
            update_interval=timedelta(minutes=5),
        )
    
    async def async_update_data(self):
        """Fetch data from API."""
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
        
        async with aiohttp.ClientSession() as session:
            try:
                async with session.get(
                    f"{self.api_url}/status",
                    headers=headers,
                    timeout=10
                ) as response:
                    if response.status == 200:
                        return await response.json()
                    else:
                        raise Exception(f"API returned {response.status}")
            except Exception as err:
                raise UpdateFailed(f"Error fetching data: {err}")

class CustomAPISensor(Entity):
    """Sensor for custom API data."""
    
    def __init__(self, coordinator, sensor_type):
        self.coordinator = coordinator
        self.sensor_type = sensor_type
        self._attr_name = f"Custom API {sensor_type.title()}"
        self._attr_unique_id = f"custom_api_{sensor_type}"
    
    @property 
    def state(self):
        """Return sensor state."""
        if self.coordinator.data:
            return self.coordinator.data.get(self.sensor_type)
        return None
    
    @property
    def extra_state_attributes(self):
        """Return additional attributes."""
        if self.coordinator.data:
            return {
                "last_update": self.coordinator.last_update_success,
                "data_age": (datetime.now() - self.coordinator.last_update_success).total_seconds()
            }
        return {}
    
    async def async_update(self):
        """Update sensor."""
        await self.coordinator.async_request_refresh()
```

### Webhook Integration
```python
# Custom webhook handler
from aiohttp import web
from homeassistant.components.http import HomeAssistantView

class CustomWebhookView(HomeAssistantView):
    """Handle webhook callbacks."""
    
    url = '/api/webhook/custom_device'
    name = 'api:webhook:custom_device'
    
    def __init__(self, hass):
        self.hass = hass
    
    async def post(self, request):
        """Handle POST webhook."""
        try:
            data = await request.json()
            
            # Validate webhook data
            if not self.validate_webhook_data(data):
                return web.Response(status=400, text="Invalid data")
            
            # Process the webhook
            await self.process_webhook_data(data)
            
            return web.Response(status=200, text="OK")
            
        except Exception as e:
            _LOGGER.error(f"Webhook error: {e}")
            return web.Response(status=500, text="Internal error")
    
    def validate_webhook_data(self, data):
        """Validate incoming webhook data."""
        required_fields = ['device_id', 'timestamp', 'data']
        return all(field in data for field in required_fields)
    
    async def process_webhook_data(self, data):
        """Process webhook data and update entities."""
        device_id = data['device_id']
        device_data = data['data']
        
        # Update device state
        entity_id = f"sensor.custom_{device_id}"
        
        self.hass.states.async_set(
            entity_id,
            device_data.get('value'),
            {
                'device_id': device_id,
                'last_update': data['timestamp'],
                'raw_data': device_data
            }
        )
        
        # Fire event for automations
        self.hass.bus.async_fire('custom_device_update', {
            'device_id': device_id,
            'data': device_data
        })

# Register webhook in integration setup
async def async_setup(hass, config):
    """Set up custom webhook integration."""
    webhook_view = CustomWebhookView(hass)
    hass.http.register_view(webhook_view)
    return True
```

---

## Zigbee/Z-Wave Management

### Zigbee Coordinator Optimization
```yaml
# ZHA configuration optimization
zha:
  zigpy_config:
    ota:
      ikea_provider: true
      ledvance_provider: true
      
  custom_quirks_path: /config/custom_zha_quirks/
  
  device_config:
    # Xiaomi motion sensor optimization
    "00:15:8d:00:02:af:95:dd-1":
      type: "binary_sensor"
      occupancy_timeout: 90  # Extended timeout
      sensitivity: "high"
      
    # Light optimization for better response
    "cc:cc:cc:ff:fe:12:34:56-1":
      type: "light" 
      transition: 0.5        # Faster transitions
      min_brightness: 1      # Minimum brightness level
```

### Zigbee Network Health Monitoring
```python
class ZigbeeNetworkMonitor:
    """Monitor Zigbee network health and performance."""
    
    def __init__(self, hass):
        self.hass = hass
        
    async def analyze_network_health(self):
        """Analyze Zigbee network health."""
        zha = self.hass.data.get('zha')
        if not zha:
            return {"error": "ZHA not available"}
        
        analysis = {
            "timestamp": datetime.now().isoformat(),
            "coordinator_info": {},
            "device_analysis": {},
            "network_metrics": {},
            "recommendations": []
        }
        
        # Get coordinator info
        app_controller = zha.application_controller
        analysis["coordinator_info"] = {
            "ieee": str(app_controller.ieee),
            "nwk": app_controller.nwk,
            "manufacturer": app_controller.manufacturer,
            "model": app_controller.model
        }
        
        # Analyze devices
        devices = zha.devices
        analysis["device_analysis"] = await self.analyze_devices(devices)
        
        # Network metrics
        analysis["network_metrics"] = {
            "total_devices": len(devices),
            "online_devices": sum(1 for d in devices.values() if d.available),
            "battery_devices": sum(1 for d in devices.values() if d.power_source == 'Battery'),
            "router_devices": sum(1 for d in devices.values() if d.node_descriptor.logical_type == 1)
        }
        
        # Generate recommendations
        analysis["recommendations"] = self.generate_network_recommendations(analysis)
        
        return analysis
    
    async def analyze_devices(self, devices):
        """Analyze individual device status."""
        device_analysis = {}
        
        for ieee, device in devices.items():
            device_info = {
                "name": device.name,
                "manufacturer": device.manufacturer,
                "model": device.model,
                "available": device.available,
                "lqi": device.lqi if hasattr(device, 'lqi') else None,
                "rssi": device.rssi if hasattr(device, 'rssi') else None,
                "last_seen": device.last_seen.isoformat() if device.last_seen else None,
                "power_source": device.power_source,
                "logical_type": device.node_descriptor.logical_type if device.node_descriptor else None
            }
            
            # Flag problematic devices
            if not device.available:
                device_info["issues"] = ["device_unavailable"]
            elif device.lqi and device.lqi < 50:
                device_info["issues"] = ["poor_signal_quality"]
            elif device.last_seen:
                hours_since_seen = (datetime.now() - device.last_seen).total_seconds() / 3600
                if hours_since_seen > 24:
                    device_info["issues"] = ["not_recently_seen"]
            
            device_analysis[str(ieee)] = device_info
        
        return device_analysis
```

### Device Pairing Automation
```python
# Automated device pairing assistant
class DevicePairingAssistant:
    """Assist with device pairing and configuration."""
    
    def __init__(self, hass):
        self.hass = hass
        
    async def start_pairing_mode(self, device_type=None):
        """Start pairing mode with device-specific instructions."""
        zha = self.hass.data.get('zha')
        if not zha:
            return False
            
        # Start permit joining
        await zha.application_controller.permit_joining(60)
        
        # Provide device-specific instructions
        instructions = self.get_pairing_instructions(device_type)
        
        await self.hass.services.async_call(
            'persistent_notification', 'create',
            {
                'title': 'Device Pairing Mode Active',
                'message': instructions,
                'notification_id': 'device_pairing'
            }
        )
        
        # Schedule pairing timeout
        self.hass.async_create_task(
            self.pairing_timeout_handler()
        )
        
        return True
    
    def get_pairing_instructions(self, device_type):
        """Get device-specific pairing instructions."""
        instructions = {
            'xiaomi_motion': """
                Xiaomi Motion Sensor Pairing:
                1. Remove the sensor from its mount
                2. Press and hold the button for 3 seconds
                3. LED should blink indicating pairing mode
                4. Wait for discovery (up to 60 seconds)
            """,
            'xiaomi_temperature': """
                Xiaomi Temperature/Humidity Sensor:
                1. Press and hold the button for 3 seconds  
                2. LED will blink blue indicating pairing mode
                3. Device should appear within 30 seconds
            """,
            'generic': """
                Generic Device Pairing:
                1. Put device into pairing mode (check manual)
                2. Device should auto-discover within 60 seconds
                3. Check ZHA integration for new devices
            """
        }
        
        return instructions.get(device_type, instructions['generic'])
```

---

## Network Device Troubleshooting

### Comprehensive Network Diagnostics
```python
class NetworkDeviceDiagnostic:
    """Comprehensive network device diagnostics."""
    
    def __init__(self, device_ip, device_type="generic"):
        self.device_ip = device_ip
        self.device_type = device_type
        
    async def run_full_diagnostic(self):
        """Run complete diagnostic suite."""
        results = {
            "device_ip": self.device_ip,
            "device_type": self.device_type,
            "timestamp": datetime.now().isoformat(),
            "tests": {}
        }
        
        # Basic connectivity tests
        results["tests"]["connectivity"] = await self.test_connectivity()
        
        # Service-specific tests
        if self.device_type == "yamaha_musiccast":
            results["tests"]["musiccast"] = await self.test_yamaha_musiccast()
        
        # Network performance tests
        results["tests"]["performance"] = await self.test_network_performance()
        
        # Generate diagnosis
        results["diagnosis"] = self.analyze_results(results["tests"])
        results["recommendations"] = self.generate_recommendations(results["diagnosis"])
        
        return results
    
    async def test_connectivity(self):
        """Test basic network connectivity."""
        tests = {}
        
        # Ping test
        try:
            import subprocess
            ping_result = subprocess.run(
                ['ping', '-c', '4', '-W', '3', self.device_ip],
                capture_output=True, text=True, timeout=15
            )
            tests["ping"] = {
                "status": "success" if ping_result.returncode == 0 else "failed",
                "packet_loss": self.extract_packet_loss(ping_result.stdout),
                "avg_time": self.extract_avg_time(ping_result.stdout)
            }
        except Exception as e:
            tests["ping"] = {"status": "error", "error": str(e)}
        
        # Port scan for common services
        common_ports = [80, 443, 22, 23, 8080, 5005]  # Include Yamaha's 5005
        tests["port_scan"] = {}
        
        for port in common_ports:
            try:
                import socket
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                sock.settimeout(3)
                result = sock.connect_ex((self.device_ip, port))
                tests["port_scan"][port] = "open" if result == 0 else "closed"
                sock.close()
            except Exception as e:
                tests["port_scan"][port] = f"error: {e}"
        
        return tests
    
    async def test_yamaha_musiccast(self):
        """Test Yamaha MusicCast specific functionality."""
        tests = {}
        
        try:
            async with aiohttp.ClientSession() as session:
                # Test device info endpoint
                async with session.get(
                    f"http://{self.device_ip}:5005/YamahaExtendedControl/v1/system/getDeviceInfo",
                    timeout=10
                ) as response:
                    if response.status == 200:
                        device_info = await response.json()
                        tests["device_info"] = {
                            "status": "success",
                            "model": device_info.get("model_name"),
                            "version": device_info.get("system_version"),
                            "api_version": device_info.get("api_version")
                        }
                    else:
                        tests["device_info"] = {"status": "failed", "http_status": response.status}
                
                # Test features endpoint
                async with session.get(
                    f"http://{self.device_ip}:5005/YamahaExtendedControl/v1/system/getFeatures",
                    timeout=10
                ) as response:
                    if response.status == 200:
                        features = await response.json()
                        tests["features"] = {
                            "status": "success",
                            "supported_functions": features.get("system", {}).get("func_list", []),
                            "zones": len(features.get("zone", []))
                        }
                    else:
                        tests["features"] = {"status": "failed", "http_status": response.status}
                        
        except Exception as e:
            tests["connection_error"] = {"status": "error", "error": str(e)}
            
        return tests
    
    def generate_recommendations(self, diagnosis):
        """Generate actionable recommendations."""
        recommendations = []
        
        if diagnosis.get("connectivity_score", 0) < 50:
            recommendations.append({
                "priority": "HIGH",
                "category": "connectivity",
                "action": "Check network cable connections and WiFi signal strength",
                "details": "Poor network connectivity detected"
            })
        
        if diagnosis.get("service_availability_score", 0) < 70:
            recommendations.append({
                "priority": "MEDIUM", 
                "category": "service",
                "action": "Restart device or check service configuration",
                "details": "Device services not fully responding"
            })
        
        if self.device_type == "yamaha_musiccast" and diagnosis.get("api_functionality_score", 0) < 80:
            recommendations.append({
                "priority": "MEDIUM",
                "category": "yamaha_specific",
                "action": "Check Yamaha MusicCast app connectivity and device firmware",
                "details": "MusicCast API not fully functional"
            })
        
        return recommendations
```

### Automated Network Issue Resolution
```python
class NetworkIssueResolver:
    """Automatically resolve common network device issues."""
    
    def __init__(self, hass):
        self.hass = hass
        
    async def resolve_device_issues(self, device_ip, device_type):
        """Attempt to resolve device connectivity issues."""
        resolution_steps = [
            self.retry_connection,
            self.refresh_dns_cache, 
            self.restart_integration,
            self.network_discovery_refresh
        ]
        
        for step in resolution_steps:
            try:
                success = await step(device_ip, device_type)
                if success:
                    await self.log_successful_resolution(device_ip, step.__name__)
                    return True
                await asyncio.sleep(5)  # Wait between attempts
            except Exception as e:
                await self.log_resolution_failure(device_ip, step.__name__, str(e))
        
        return False
    
    async def retry_connection(self, device_ip, device_type):
        """Retry device connection with backoff."""
        for attempt in range(3):
            try:
                if device_type == "yamaha_musiccast":
                    success = await self.test_yamaha_connection(device_ip)
                else:
                    success = await self.test_generic_connection(device_ip)
                
                if success:
                    return True
                    
                await asyncio.sleep(2 ** attempt)  # Exponential backoff
                
            except Exception:
                continue
        
        return False
```

---

## Performance Optimization

### Entity Performance Monitoring
```python
class EntityPerformanceMonitor:
    """Monitor entity update performance and identify bottlenecks."""
    
    def __init__(self, hass):
        self.hass = hass
        self.update_times = {}
        self.slow_entities = set()
        
    @callback
    def track_entity_updates(self):
        """Track entity update performance."""
        
        @callback 
        def state_changed_listener(event):
            entity_id = event.data.get("entity_id")
            if not entity_id:
                return
                
            # Track update frequency
            now = time.time()
            if entity_id not in self.update_times:
                self.update_times[entity_id] = []
            
            self.update_times[entity_id].append(now)
            
            # Keep only last 100 updates
            if len(self.update_times[entity_id]) > 100:
                self.update_times[entity_id] = self.update_times[entity_id][-100:]
            
            # Check for performance issues
            self.analyze_entity_performance(entity_id)
        
        self.hass.bus.async_listen(EVENT_STATE_CHANGED, state_changed_listener)
    
    def analyze_entity_performance(self, entity_id):
        """Analyze entity performance metrics."""
        if len(self.update_times[entity_id]) < 10:
            return
            
        updates = self.update_times[entity_id]
        intervals = [updates[i] - updates[i-1] for i in range(1, len(updates))]
        
        avg_interval = sum(intervals) / len(intervals)
        
        # Flag entities updating too frequently (more than once per second)
        if avg_interval < 1:
            self.slow_entities.add(entity_id)
            self.hass.async_create_task(
                self.handle_performance_issue(entity_id, "high_frequency", avg_interval)
            )
    
    async def handle_performance_issue(self, entity_id, issue_type, metric):
        """Handle detected performance issues."""
        if issue_type == "high_frequency":
            await self.hass.services.async_call(
                'system_log', 'write',
                {
                    'message': f'Performance issue: {entity_id} updating every {metric:.2f} seconds',
                    'level': 'warning',
                    'logger': 'performance_monitor'
                }
            )
```

### Database Optimization
```yaml
# Recorder optimization for your setup
recorder:
  db_url: sqlite:////config/home-assistant_v2.db
  purge_keep_days: 7
  commit_interval: 1
  auto_purge: true
  auto_repack: true
  
  # Exclude frequently updating entities
  exclude:
    entities:
      # System entities that update frequently
      - sensor.time
      - sensor.uptime
      - sensor.date_time
      
      # High-frequency sensors
      - sensor.processor_use
      - sensor.memory_use_percent
      - sensor.cpu_temperature
      
    entity_globs:
      # Exclude all unavailable sensors
      - sensor.*_unavailable
      
    domains:
      # Exclude automation triggers (noisy)
      - automation
      
  include:
    domains:
      # Include important domains
      - binary_sensor
      - light
      - media_player
      - sensor
      - switch
      
    entities:
      # Specifically include your devices
      - binary_sensor.lumi_lumi_sensor_motion_aq2_occupancy
      - sensor.lumi_lumi_weather_humidity
      - media_player.living_room_main
      - light.office_spot_lights
      - light.office_stand
      - light.wall
```

### Resource Usage Optimization
```python
# Resource monitoring and optimization
class ResourceOptimizer:
    """Optimize Home Assistant resource usage."""
    
    def __init__(self, hass):
        self.hass = hass
        
    async def optimize_integrations(self):
        """Optimize integration configurations."""
        optimizations = {
            "scan_intervals": {
                "media_player.living_room_main": 30,  # Yamaha MusicCast
                "sensor.lumi_lumi_weather_humidity": 300,  # Humidity sensor
                "binary_sensor.lumi_lumi_sensor_motion_aq2_occupancy": 1  # Motion sensor
            },
            
            "timeout_adjustments": {
                "yamaha_musiccast": {"timeout": 10, "retries": 2},
                "pushbullet": {"timeout": 15, "retries": 3}
            }
        }
        
        return optimizations
    
    async def monitor_memory_usage(self):
        """Monitor memory usage and suggest optimizations."""
        import psutil
        
        process = psutil.Process()
        memory_info = process.memory_info()
        
        usage_report = {
            "timestamp": datetime.now().isoformat(),
            "memory_mb": memory_info.rss / 1024 / 1024,
            "peak_memory_mb": memory_info.peak_wss / 1024 / 1024 if hasattr(memory_info, 'peak_wss') else 0,
            "cpu_percent": process.cpu_percent(),
            "open_files": len(process.open_files()),
            "connections": len(process.connections())
        }
        
        # Generate optimization suggestions
        suggestions = []
        
        if usage_report["memory_mb"] > 500:
            suggestions.append("Consider reducing recorder keep_days or excluding more entities")
            
        if usage_report["open_files"] > 100:
            suggestions.append("High number of open files - check for integration issues")
            
        usage_report["suggestions"] = suggestions
        
        return usage_report
```

---

## Lifecycle Management

### Device Lifecycle Tracking
```python
class DeviceLifecycleManager:
    """Manage device lifecycle from discovery to retirement."""
    
    def __init__(self, hass):
        self.hass = hass
        self.device_registry = hass.data.get("device_registry")
        
    async def track_device_lifecycle(self, device_id):
        """Track complete device lifecycle."""
        device = self.device_registry.async_get(device_id)
        if not device:
            return None
            
        lifecycle_data = {
            "device_id": device_id,
            "name": device.name,
            "manufacturer": device.manufacturer,
            "model": device.model,
            "first_seen": device.created_at.isoformat(),
            "last_seen": await self.get_last_activity(device_id),
            "total_entities": len(device.config_entries),
            "lifecycle_stage": await self.determine_lifecycle_stage(device),
            "health_score": await self.calculate_device_health(device),
            "maintenance_recommendations": await self.get_maintenance_recommendations(device)
        }
        
        return lifecycle_data
    
    async def determine_lifecycle_stage(self, device):
        """Determine current lifecycle stage."""
        last_activity = await self.get_last_activity(device.id)
        if not last_activity:
            return "inactive"
            
        days_since_activity = (datetime.now() - last_activity).days
        
        if days_since_activity < 1:
            return "active"
        elif days_since_activity < 7:
            return "recent"
        elif days_since_activity < 30:
            return "dormant"
        else:
            return "inactive"
    
    async def calculate_device_health(self, device):
        """Calculate device health score."""
        health_factors = {
            "availability": 0,
            "responsiveness": 0,
            "error_rate": 0,
            "battery_level": 0,
            "signal_quality": 0
        }
        
        # Get device entities
        entity_registry = self.hass.data.get("entity_registry")
        device_entities = entity_registry.async_entries_for_device(device.id)
        
        if not device_entities:
            return 0
        
        available_entities = 0
        total_entities = len(device_entities)
        
        for entity_entry in device_entities:
            state = self.hass.states.get(entity_entry.entity_id)
            if state and state.state != "unavailable":
                available_entities += 1
                
                # Check battery level if available
                if state.attributes.get("battery_level"):
                    health_factors["battery_level"] = state.attributes["battery_level"]
        
        health_factors["availability"] = (available_entities / total_entities) * 100
        
        # Calculate overall health score
        weights = {
            "availability": 0.4,
            "battery_level": 0.3,
            "responsiveness": 0.2,
            "signal_quality": 0.1
        }
        
        health_score = sum(
            health_factors[factor] * weight
            for factor, weight in weights.items()
        )
        
        return min(health_score, 100)
```

### Maintenance Scheduling
```yaml
# Maintenance automation
automation:
  - alias: "Weekly Device Health Check"
    trigger:
      - platform: time
        at: "02:00:00"
      - platform: time_pattern
        hours: 2
        minutes: 0
        seconds: 0
    condition:
      - condition: time
        weekday: "sun"
    action:
      - service: script.device_health_check
      - service: script.database_maintenance
      - service: script.integration_status_report

script:
  device_health_check:
    sequence:
      - service: python_script.device_health_analysis
        data:
          generate_report: true
          notify_issues: true
          
  database_maintenance:
    sequence:
      - service: recorder.purge
        data:
          keep_days: 7
          repack: true
      - service: system_log.clear
        
  integration_status_report:
    sequence:
      - service: python_script.integration_status
        data:
          include_performance_metrics: true
          generate_summary: true
```

### Automated Maintenance Tasks
```python
class MaintenanceScheduler:
    """Schedule and execute automated maintenance tasks."""
    
    def __init__(self, hass):
        self.hass = hass
        self.maintenance_tasks = {
            "daily": [
                self.check_device_availability,
                self.analyze_error_logs,
                self.update_device_health_scores
            ],
            "weekly": [
                self.database_maintenance,
                self.integration_health_check,
                self.network_performance_analysis
            ],
            "monthly": [
                self.full_system_health_check,
                self.device_lifecycle_review,
                self.performance_optimization_review
            ]
        }
    
    async def run_scheduled_maintenance(self, schedule_type):
        """Run maintenance tasks for specified schedule."""
        tasks = self.maintenance_tasks.get(schedule_type, [])
        results = []
        
        for task in tasks:
            try:
                result = await task()
                results.append({
                    "task": task.__name__,
                    "status": "success",
                    "result": result
                })
            except Exception as e:
                results.append({
                    "task": task.__name__,
                    "status": "failed",
                    "error": str(e)
                })
        
        # Generate maintenance report
        await self.generate_maintenance_report(schedule_type, results)
        
        return results
    
    async def check_device_availability(self):
        """Check availability of all configured devices."""
        unavailable_devices = []
        
        for state in self.hass.states.async_all():
            if state.state == "unavailable":
                unavailable_devices.append({
                    "entity_id": state.entity_id,
                    "friendly_name": state.attributes.get("friendly_name"),
                    "last_changed": state.last_changed.isoformat()
                })
        
        if unavailable_devices:
            await self.hass.services.async_call(
                'persistent_notification', 'create',
                {
                    'title': f'{len(unavailable_devices)} Unavailable Devices',
                    'message': f'Devices requiring attention:\n' + 
                              '\n'.join([d["friendly_name"] or d["entity_id"] for d in unavailable_devices[:5]]),
                    'notification_id': 'device_availability_check'
                }
            )
        
        return {
            "unavailable_count": len(unavailable_devices),
            "devices": unavailable_devices[:10]  # Limit for report
        }
```

---

*Last Updated: December 28, 2025*
*Home Assistant Version: 2024.12.x*
*Documentation Version: 1.0*