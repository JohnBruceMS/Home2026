# Home Assistant AI Script Integration API

## Table of Contents
1. [API Overview](#api-overview)
2. [Authentication & Security](#authentication--security)
3. [REST API Reference](#rest-api-reference)
4. [WebSocket API](#websocket-api)
5. [Event-Driven Integration](#event-driven-integration)
6. [State Management API](#state-management-api)
7. [Service Call Interface](#service-call-interface)
8. [Real-time Monitoring](#real-time-monitoring)
9. [AI Script Examples](#ai-script-examples)
10. [Rate Limiting & Performance](#rate-limiting--performance)

---

## API Overview

Home Assistant provides multiple APIs for AI script integration:

```
┌─────────────────────────────────────────────────────────┐
│                AI Script Integration APIs                │
├─────────────────────────────────────────────────────────┤
│  REST API │ WebSocket │ Server-Sent Events │ Webhooks   │
├─────────────────────────────────────────────────────────┤
│  Authentication │ Rate Limiting │ Error Handling       │
├─────────────────────────────────────────────────────────┤
│  State Manager │ Event Bus │ Service Registry          │
├─────────────────────────────────────────────────────────┤
│          Home Assistant Core & Entity System           │
└─────────────────────────────────────────────────────────┘
```

### API Endpoints Base Structure
```
Base URL: http://homeassistant.local:8123/api
WebSocket: ws://homeassistant.local:8123/api/websocket
```

### Supported Integration Methods
1. **REST API**: Standard HTTP requests for state and service calls
2. **WebSocket API**: Real-time bidirectional communication
3. **Server-Sent Events**: One-way real-time updates
4. **Webhooks**: External system notifications
5. **Custom Components**: Python-based integrations

---

## Authentication & Security

### Long-Lived Access Tokens
```python
# Generate and use access tokens
import requests

# Configuration
HA_URL = "http://homeassistant.local:8123"
ACCESS_TOKEN = "your_long_lived_access_token_here"

# Headers for all API requests
HEADERS = {
    "Authorization": f"Bearer {ACCESS_TOKEN}",
    "Content-Type": "application/json"
}

# Test authentication
def test_authentication():
    """Test API authentication."""
    response = requests.get(f"{HA_URL}/api/", headers=HEADERS)
    if response.status_code == 200:
        return True, "Authentication successful"
    else:
        return False, f"Authentication failed: {response.status_code}"
```

### Authentication Best Practices
```python
class HAAuthManager:
    """Secure authentication manager for HA API access."""
    
    def __init__(self, ha_url, token_file_path):
        self.ha_url = ha_url.rstrip('/')
        self.token_file_path = token_file_path
        self._token = None
        self._token_expires = None
        
    def get_token(self):
        """Get access token with automatic refresh."""
        if self._token and not self.is_token_expired():
            return self._token
            
        # Load token from secure file
        try:
            with open(self.token_file_path, 'r') as f:
                token_data = json.load(f)
                self._token = token_data['access_token']
                self._token_expires = datetime.fromisoformat(token_data.get('expires_at', '2099-12-31'))
                return self._token
        except Exception as e:
            raise AuthenticationError(f"Failed to load token: {e}")
    
    def get_headers(self):
        """Get headers with current token."""
        return {
            "Authorization": f"Bearer {self.get_token()}",
            "Content-Type": "application/json"
        }
    
    def is_token_expired(self):
        """Check if token is expired."""
        if not self._token_expires:
            return False
        return datetime.now() >= self._token_expires
```

### API Security Configuration
```yaml
# HTTP security configuration
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 192.168.1.0/24
    - 127.0.0.1
  ip_ban_enabled: true
  login_attempts_threshold: 5
  
# API rate limiting (configure in custom component)
api_rate_limiting:
  requests_per_minute: 300
  burst_limit: 50
  whitelist_ips:
    - 192.168.1.100  # AI script server
```

---

## REST API Reference

### Core API Endpoints

#### 1. System Information
```python
# Get Home Assistant configuration
def get_ha_config():
    """Get Home Assistant configuration."""
    response = requests.get(f"{HA_URL}/api/config", headers=HEADERS)
    if response.status_code == 200:
        return response.json()
    raise APIError(f"Failed to get config: {response.status_code}")

# Response structure
{
    "latitude": 40.7128,
    "longitude": -74.0060, 
    "elevation": 0,
    "unit_system": {
        "length": "km",
        "mass": "kg",
        "temperature": "°C",
        "volume": "L"
    },
    "location_name": "Home",
    "time_zone": "America/New_York",
    "components": ["automation", "light", "sensor", ...],
    "config_dir": "/config",
    "whitelist_external_dirs": [],
    "allowlist_external_dirs": [],
    "allowlist_external_urls": [],
    "version": "2024.12.0",
    "config_source": "storage",
    "safe_mode": false,
    "state": "RUNNING"
}
```

#### 2. State Management
```python
# Get all states
def get_all_states():
    """Get all entity states."""
    response = requests.get(f"{HA_URL}/api/states", headers=HEADERS)
    return response.json()

# Get specific entity state
def get_entity_state(entity_id):
    """Get state of specific entity."""
    response = requests.get(f"{HA_URL}/api/states/{entity_id}", headers=HEADERS)
    if response.status_code == 200:
        return response.json()
    elif response.status_code == 404:
        return None
    raise APIError(f"Failed to get state: {response.status_code}")

# Set entity state
def set_entity_state(entity_id, state, attributes=None):
    """Set entity state with attributes."""
    data = {
        "state": state
    }
    if attributes:
        data["attributes"] = attributes
        
    response = requests.post(
        f"{HA_URL}/api/states/{entity_id}", 
        headers=HEADERS,
        json=data
    )
    return response.json()

# Example: Set custom sensor state
set_entity_state(
    "sensor.ai_analysis_result",
    "analyzing",
    {
        "friendly_name": "AI Analysis Status",
        "progress": 45,
        "last_update": datetime.now().isoformat()
    }
)
```

#### 3. Service Calls
```python
# Call Home Assistant service
def call_service(domain, service, service_data=None, target=None):
    """Call Home Assistant service."""
    data = {}
    
    if service_data:
        data.update(service_data)
    
    if target:
        data["target"] = target
    
    response = requests.post(
        f"{HA_URL}/api/services/{domain}/{service}",
        headers=HEADERS,
        json=data
    )
    
    if response.status_code == 200:
        return response.json()
    raise APIError(f"Service call failed: {response.status_code} - {response.text}")

# Example service calls for your setup
def control_office_lights(action, brightness=None):
    """Control office lights based on current setup."""
    entities = [
        "light.office_spot_lights",
        "light.office_stand", 
        "light.wall"
    ]
    
    if action == "turn_on":
        service_data = {"entity_id": entities}
        if brightness:
            service_data["brightness_pct"] = brightness
        return call_service("light", "turn_on", service_data)
    
    elif action == "turn_off":
        return call_service("light", "turn_off", {"entity_id": entities})

def send_notification(message, title="AI Script Notification"):
    """Send notification to mobile device."""
    return call_service(
        "notify", 
        "mobile_app_sm_n986u",
        {
            "message": message,
            "title": title,
            "data": {
                "tag": "ai_script",
                "group": "ai_notifications"
            }
        }
    )

def control_yamaha_player(action, **kwargs):
    """Control Yamaha MusicCast player."""
    entity_id = "media_player.living_room_main"
    
    if action == "turn_on":
        return call_service("media_player", "turn_on", {"entity_id": entity_id})
    elif action == "play_media":
        return call_service(
            "media_player", 
            "play_media",
            {
                "entity_id": entity_id,
                "media_content_id": kwargs.get("content_id"),
                "media_content_type": kwargs.get("content_type", "music")
            }
        )
    elif action == "set_volume":
        return call_service(
            "media_player",
            "volume_set", 
            {
                "entity_id": entity_id,
                "volume_level": kwargs.get("volume_level", 0.5)
            }
        )
```

#### 4. Event Handling
```python
# Get event log
def get_events(event_type=None, limit=100):
    """Get recent events from Home Assistant."""
    params = {"limit": limit}
    if event_type:
        params["event_type"] = event_type
        
    response = requests.get(
        f"{HA_URL}/api/events",
        headers=HEADERS,
        params=params
    )
    return response.json()

# Fire custom event
def fire_event(event_type, event_data):
    """Fire custom event."""
    response = requests.post(
        f"{HA_URL}/api/events/{event_type}",
        headers=HEADERS,
        json=event_data
    )
    return response.json()

# Example: Fire AI analysis complete event
fire_event("ai_analysis_complete", {
    "analysis_type": "device_performance",
    "results": {
        "total_devices": 15,
        "healthy_devices": 12,
        "issues_found": 3
    },
    "timestamp": datetime.now().isoformat()
})
```

---

## WebSocket API

### WebSocket Connection Setup
```python
import asyncio
import websockets
import json
from datetime import datetime

class HAWebSocketClient:
    """Home Assistant WebSocket API client."""
    
    def __init__(self, url, access_token):
        self.url = url
        self.access_token = access_token
        self.websocket = None
        self.message_id = 1
        self.subscriptions = {}
        
    async def connect(self):
        """Connect to Home Assistant WebSocket API."""
        self.websocket = await websockets.connect(self.url)
        
        # Receive auth_required message
        auth_msg = await self.websocket.recv()
        auth_data = json.loads(auth_msg)
        
        if auth_data["type"] == "auth_required":
            # Send authentication
            auth_response = {
                "type": "auth",
                "access_token": self.access_token
            }
            await self.websocket.send(json.dumps(auth_response))
            
            # Wait for auth confirmation
            auth_result = await self.websocket.recv()
            auth_result_data = json.loads(auth_result)
            
            if auth_result_data["type"] != "auth_ok":
                raise Exception("Authentication failed")
                
    async def send_message(self, message_type, **kwargs):
        """Send message to Home Assistant."""
        message = {
            "id": self.message_id,
            "type": message_type,
            **kwargs
        }
        
        await self.websocket.send(json.dumps(message))
        self.message_id += 1
        
        return self.message_id - 1
    
    async def subscribe_to_events(self, event_type=None):
        """Subscribe to Home Assistant events."""
        message_id = await self.send_message(
            "subscribe_events",
            event_type=event_type
        )
        
        self.subscriptions[message_id] = {
            "type": "events",
            "event_type": event_type
        }
        
        return message_id
    
    async def get_states(self):
        """Get all states via WebSocket."""
        message_id = await self.send_message("get_states")
        
        # Wait for response
        while True:
            response = await self.websocket.recv()
            data = json.loads(response)
            
            if data.get("id") == message_id:
                if data["success"]:
                    return data["result"]
                else:
                    raise Exception(f"Get states failed: {data.get('error')}")
    
    async def call_service(self, domain, service, service_data=None, target=None):
        """Call service via WebSocket."""
        call_data = {
            "domain": domain,
            "service": service
        }
        
        if service_data:
            call_data["service_data"] = service_data
        if target:
            call_data["target"] = target
            
        message_id = await self.send_message("call_service", **call_data)
        
        # Wait for response
        while True:
            response = await self.websocket.recv()
            data = json.loads(response)
            
            if data.get("id") == message_id:
                return data
    
    async def listen_for_messages(self, handler):
        """Listen for messages and handle them."""
        try:
            async for message in self.websocket:
                data = json.loads(message)
                await handler(data)
        except websockets.exceptions.ConnectionClosed:
            print("WebSocket connection closed")

# Example usage
async def websocket_ai_integration():
    """Example WebSocket integration for AI scripts."""
    client = HAWebSocketClient(
        "ws://homeassistant.local:8123/api/websocket",
        ACCESS_TOKEN
    )
    
    await client.connect()
    
    # Subscribe to state changes
    await client.subscribe_to_events("state_changed")
    
    # Message handler
    async def handle_message(data):
        if data.get("type") == "event":
            event = data["event"]
            
            if event["event_type"] == "state_changed":
                entity_id = event["data"]["entity_id"]
                new_state = event["data"]["new_state"]["state"]
                
                # AI script logic here
                if entity_id == "binary_sensor.lumi_lumi_sensor_motion_aq2_occupancy":
                    if new_state == "on":
                        await handle_motion_detected(client)
                        
                elif entity_id.startswith("sensor.lumi_lumi_weather"):
                    if "humidity" in entity_id:
                        await handle_humidity_change(client, new_state)
    
    # Start listening
    await client.listen_for_messages(handle_message)

async def handle_motion_detected(client):
    """Handle motion detection via WebSocket."""
    # Turn on office lights
    await client.call_service(
        "light", 
        "turn_on",
        service_data={
            "entity_id": [
                "light.office_spot_lights",
                "light.office_stand",
                "light.wall"
            ],
            "brightness_pct": 75
        }
    )
    
    print("Motion detected - lights turned on")

async def handle_humidity_change(client, humidity_value):
    """Handle humidity sensor changes."""
    try:
        humidity = float(humidity_value)
        if humidity > 55:
            # Send notification
            await client.call_service(
                "notify",
                "mobile_app_sm_n986u",
                service_data={
                    "message": f"High humidity detected: {humidity}%",
                    "title": "Environmental Alert"
                }
            )
            print(f"High humidity alert sent: {humidity}%")
    except ValueError:
        pass  # Ignore non-numeric values
```

---

## Event-Driven Integration

### Event Listener Framework
```python
class HAEventListener:
    """Advanced event listener for AI script integration."""
    
    def __init__(self, ha_url, access_token):
        self.ha_url = ha_url
        self.access_token = access_token
        self.event_handlers = {}
        self.filters = {}
        
    def register_handler(self, event_type, handler, filters=None):
        """Register event handler with optional filters."""
        if event_type not in self.event_handlers:
            self.event_handlers[event_type] = []
            
        self.event_handlers[event_type].append(handler)
        
        if filters:
            self.filters[event_type] = filters
    
    async def start_listening(self):
        """Start event listening loop."""
        client = HAWebSocketClient(
            f"ws://{self.ha_url.split('//')[1]}/api/websocket",
            self.access_token
        )
        
        await client.connect()
        
        # Subscribe to all relevant events
        for event_type in self.event_handlers.keys():
            await client.subscribe_to_events(event_type)
        
        # Handle messages
        async def message_handler(data):
            await self.process_event(data)
        
        await client.listen_for_messages(message_handler)
    
    async def process_event(self, data):
        """Process incoming event data."""
        if data.get("type") != "event":
            return
            
        event = data["event"]
        event_type = event["event_type"]
        
        if event_type not in self.event_handlers:
            return
        
        # Apply filters
        if event_type in self.filters:
            if not self.apply_filters(event, self.filters[event_type]):
                return
        
        # Execute handlers
        for handler in self.event_handlers[event_type]:
            try:
                await handler(event)
            except Exception as e:
                print(f"Error in event handler: {e}")
    
    def apply_filters(self, event, filters):
        """Apply event filters."""
        for filter_key, filter_value in filters.items():
            if filter_key == "entity_id":
                # Entity ID filter
                entity_id = event["data"].get("entity_id")
                if isinstance(filter_value, str):
                    if entity_id != filter_value:
                        return False
                elif isinstance(filter_value, list):
                    if entity_id not in filter_value:
                        return False
                elif hasattr(filter_value, 'match'):
                    # Regex pattern
                    if not filter_value.match(entity_id):
                        return False
            
            elif filter_key == "state_change":
                # State change filter
                old_state = event["data"].get("old_state", {}).get("state")
                new_state = event["data"].get("new_state", {}).get("state")
                
                if filter_value.get("from") and old_state != filter_value["from"]:
                    return False
                if filter_value.get("to") and new_state != filter_value["to"]:
                    return False
        
        return True

# Example usage for your setup
async def setup_ai_event_listeners():
    """Setup AI event listeners for your Home Assistant setup."""
    listener = HAEventListener("http://homeassistant.local:8123", ACCESS_TOKEN)
    
    # Motion sensor events
    listener.register_handler(
        "state_changed",
        handle_motion_events,
        filters={
            "entity_id": "binary_sensor.lumi_lumi_sensor_motion_aq2_occupancy",
            "state_change": {"to": "on"}
        }
    )
    
    # Humidity sensor events  
    listener.register_handler(
        "state_changed", 
        handle_humidity_events,
        filters={
            "entity_id": "sensor.lumi_lumi_weather_humidity"
        }
    )
    
    # Media player events
    listener.register_handler(
        "state_changed",
        handle_media_events,
        filters={
            "entity_id": "media_player.living_room_main"
        }
    )
    
    # Custom AI events
    listener.register_handler("ai_analysis_request", handle_ai_analysis_request)
    listener.register_handler("automation_triggered", log_automation_events)
    
    await listener.start_listening()

async def handle_motion_events(event):
    """Handle motion sensor events."""
    entity_data = event["data"]
    new_state = entity_data["new_state"]["state"]
    
    if new_state == "on":
        # Motion detected - intelligent lighting response
        current_hour = datetime.now().hour
        
        # Calculate appropriate brightness
        if 22 <= current_hour or current_hour <= 6:
            brightness = 30  # Night mode
        elif 6 < current_hour <= 9 or 18 <= current_hour < 22:
            brightness = 70  # Dawn/dusk
        else:
            brightness = 100  # Daytime
        
        # Turn on lights
        await call_service(
            "light", 
            "turn_on",
            {
                "entity_id": [
                    "light.office_spot_lights",
                    "light.office_stand", 
                    "light.wall"
                ],
                "brightness_pct": brightness,
                "transition": 1
            }
        )
        
        # Log the action
        await fire_event("ai_motion_response", {
            "trigger_entity": entity_data["entity_id"],
            "action": "lights_on",
            "brightness": brightness,
            "timestamp": datetime.now().isoformat()
        })

async def handle_humidity_events(event):
    """Handle humidity sensor events."""
    entity_data = event["data"]
    new_state = entity_data["new_state"]["state"]
    
    try:
        humidity = float(new_state)
        
        # AI-driven humidity analysis
        if humidity > 60:
            severity = "high"
            action_required = True
        elif humidity > 45:
            severity = "normal"
            action_required = False
        else:
            severity = "low" 
            action_required = True
        
        # Store analysis result
        await set_entity_state(
            "sensor.ai_humidity_analysis",
            severity,
            {
                "humidity_value": humidity,
                "action_required": action_required,
                "last_analysis": datetime.now().isoformat(),
                "recommendations": get_humidity_recommendations(humidity)
            }
        )
        
        # Send notification if action required
        if action_required:
            message = get_humidity_alert_message(humidity, severity)
            await send_notification(message, "Environmental Alert")
            
    except ValueError:
        pass  # Ignore non-numeric humidity values

def get_humidity_recommendations(humidity):
    """Get AI recommendations for humidity levels."""
    if humidity > 60:
        return [
            "Consider improving ventilation",
            "Check for moisture sources", 
            "Monitor for mold risk"
        ]
    elif humidity < 30:
        return [
            "Consider using humidifier",
            "Check heating system",
            "Monitor comfort levels"
        ]
    else:
        return ["Humidity levels are optimal"]

async def handle_media_events(event):
    """Handle media player events."""
    entity_data = event["data"]
    new_state = entity_data["new_state"]["state"]
    old_state = entity_data.get("old_state", {}).get("state", "unknown")
    
    # Log media state changes for AI analysis
    media_event_data = {
        "entity_id": entity_data["entity_id"],
        "state_change": f"{old_state} -> {new_state}",
        "attributes": entity_data["new_state"]["attributes"],
        "timestamp": datetime.now().isoformat()
    }
    
    await fire_event("ai_media_state_change", media_event_data)
    
    # Intelligent scene control
    if new_state == "playing":
        # Dim lights for media consumption
        await call_service(
            "light",
            "turn_on",
            {
                "entity_id": ["light.living_room_main"],
                "brightness_pct": 20,
                "transition": 2
            }
        )
    elif new_state == "off" and old_state == "playing":
        # Restore normal lighting
        await call_service(
            "light",
            "turn_on", 
            {
                "entity_id": ["light.living_room_main"],
                "brightness_pct": 80,
                "transition": 2
            }
        )
```

---

## State Management API

### Advanced State Queries
```python
class HAStateManager:
    """Advanced state management for AI scripts."""
    
    def __init__(self, ha_url, access_token):
        self.ha_url = ha_url
        self.access_token = access_token
        self.headers = {"Authorization": f"Bearer {access_token}"}
        
    async def get_states_by_domain(self, domain):
        """Get all states for specific domain."""
        all_states = await self.get_all_states()
        return [state for state in all_states if state["entity_id"].startswith(f"{domain}.")]
    
    async def get_states_by_pattern(self, pattern):
        """Get states matching regex pattern."""
        import re
        all_states = await self.get_all_states()
        regex = re.compile(pattern)
        return [state for state in all_states if regex.match(state["entity_id"])]
    
    async def get_device_states(self, device_name):
        """Get all states for entities belonging to a device."""
        # This requires device registry access
        all_states = await self.get_all_states()
        return [
            state for state in all_states
            if device_name.lower() in state.get("attributes", {}).get("friendly_name", "").lower()
        ]
    
    async def query_states(self, filters):
        """Query states with complex filters."""
        all_states = await self.get_all_states()
        filtered_states = all_states
        
        for filter_key, filter_value in filters.items():
            if filter_key == "domain":
                filtered_states = [s for s in filtered_states if s["entity_id"].startswith(f"{filter_value}.")]
            elif filter_key == "state":
                filtered_states = [s for s in filtered_states if s["state"] == filter_value]
            elif filter_key == "attribute":
                attr_key, attr_value = filter_value
                filtered_states = [
                    s for s in filtered_states 
                    if s.get("attributes", {}).get(attr_key) == attr_value
                ]
            elif filter_key == "last_changed_within":
                # Filter by entities changed within X minutes
                from datetime import datetime, timedelta
                cutoff = datetime.now() - timedelta(minutes=filter_value)
                filtered_states = [
                    s for s in filtered_states
                    if datetime.fromisoformat(s["last_changed"]) > cutoff
                ]
        
        return filtered_states
    
    async def get_historical_states(self, entity_id, hours_back=24):
        """Get historical states for entity."""
        from datetime import datetime, timedelta
        
        end_time = datetime.now()
        start_time = end_time - timedelta(hours=hours_back)
        
        params = {
            "filter_entity_id": entity_id,
            "start_time": start_time.isoformat(),
            "end_time": end_time.isoformat()
        }
        
        response = requests.get(
            f"{self.ha_url}/api/history/period",
            headers=self.headers,
            params=params
        )
        
        if response.status_code == 200:
            return response.json()
        else:
            raise APIError(f"Failed to get history: {response.status_code}")

# Example queries for your setup
async def analyze_current_environment():
    """Analyze current environmental conditions."""
    state_mgr = HAStateManager(HA_URL, ACCESS_TOKEN)
    
    # Get all motion sensor states
    motion_sensors = await state_mgr.get_states_by_pattern(r"binary_sensor\..*motion.*")
    
    # Get all light states
    lights = await state_mgr.get_states_by_domain("light")
    
    # Get environmental sensors
    env_sensors = await state_mgr.query_states({
        "domain": "sensor",
        "attribute": ("device_class", "humidity")
    })
    
    # Analyze occupancy
    active_motion = [s for s in motion_sensors if s["state"] == "on"]
    active_lights = [s for s in lights if s["state"] == "on"]
    
    analysis = {
        "timestamp": datetime.now().isoformat(),
        "occupancy_indicators": {
            "motion_detected": len(active_motion) > 0,
            "lights_on": len(active_lights) > 0,
            "occupied_areas": [
                extract_area_from_entity(s["entity_id"]) 
                for s in active_motion
            ]
        },
        "environmental_conditions": {
            sensor["entity_id"]: {
                "value": sensor["state"],
                "unit": sensor["attributes"].get("unit_of_measurement"),
                "device_class": sensor["attributes"].get("device_class")
            }
            for sensor in env_sensors
        }
    }
    
    return analysis

def extract_area_from_entity(entity_id):
    """Extract area name from entity ID."""
    # Simple pattern matching for your setup
    if "office" in entity_id:
        return "office"
    elif "living_room" in entity_id:
        return "living_room"
    elif "bedroom" in entity_id:
        return "bedroom"
    else:
        return "unknown"
```

---

## Service Call Interface

### Batch Service Operations
```python
class HAServiceManager:
    """Advanced service management for batch operations."""
    
    def __init__(self, ha_url, access_token):
        self.ha_url = ha_url
        self.access_token = access_token
        self.headers = {"Authorization": f"Bearer {access_token}"}
    
    async def batch_service_calls(self, service_calls, max_concurrent=5):
        """Execute multiple service calls concurrently."""
        import asyncio
        import aiohttp
        
        semaphore = asyncio.Semaphore(max_concurrent)
        
        async def execute_service_call(call_data):
            async with semaphore:
                domain, service = call_data["service"].split(".")
                
                async with aiohttp.ClientSession() as session:
                    async with session.post(
                        f"{self.ha_url}/api/services/{domain}/{service}",
                        headers=self.headers,
                        json=call_data.get("data", {})
                    ) as response:
                        return {
                            "service": call_data["service"],
                            "status_code": response.status,
                            "success": response.status == 200,
                            "response": await response.json() if response.status == 200 else None
                        }
        
        tasks = [execute_service_call(call) for call in service_calls]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        return results
    
    async def scene_activation(self, scene_name, entity_configs):
        """Create and activate a dynamic scene."""
        service_calls = []
        
        for entity_id, config in entity_configs.items():
            domain = entity_id.split(".")[0]
            
            if domain == "light":
                service_calls.append({
                    "service": "light.turn_on",
                    "data": {
                        "entity_id": entity_id,
                        **config
                    }
                })
            elif domain == "media_player":
                service_calls.append({
                    "service": "media_player.turn_on",
                    "data": {
                        "entity_id": entity_id,
                        **config
                    }
                })
            elif domain == "switch":
                service_calls.append({
                    "service": f"switch.{config.get('action', 'turn_on')}",
                    "data": {
                        "entity_id": entity_id
                    }
                })
        
        results = await self.batch_service_calls(service_calls)
        
        # Log scene activation
        await self.log_scene_activation(scene_name, results)
        
        return results
    
    async def log_scene_activation(self, scene_name, results):
        """Log scene activation results."""
        success_count = sum(1 for r in results if r.get("success", False))
        
        await self.call_service(
            "logbook", "log",
            {
                "name": "AI Scene Controller",
                "message": f"Activated scene '{scene_name}': {success_count}/{len(results)} successful",
                "domain": "ai_script"
            }
        )

# Predefined scenes for your setup
OFFICE_WORK_SCENE = {
    "light.office_spot_lights": {
        "brightness_pct": 90,
        "color_temp": 4000
    },
    "light.office_stand": {
        "brightness_pct": 70,
        "color_temp": 4000
    },
    "light.wall": {
        "brightness_pct": 50,
        "color_temp": 3000
    }
}

EVENING_RELAXATION_SCENE = {
    "light.office_spot_lights": {
        "brightness_pct": 30,
        "color_temp": 2700
    },
    "light.office_stand": {
        "brightness_pct": 40,
        "color_temp": 2700
    },
    "media_player.living_room_main": {
        "source": "Spotify"
    }
}

# Usage example
async def activate_intelligent_scene():
    """Activate scene based on current conditions."""
    service_mgr = HAServiceManager(HA_URL, ACCESS_TOKEN)
    state_mgr = HAStateManager(HA_URL, ACCESS_TOKEN)
    
    # Analyze current conditions
    current_hour = datetime.now().hour
    motion_detected = await state_mgr.get_entity_state("binary_sensor.lumi_lumi_sensor_motion_aq2_occupancy")
    
    # Choose appropriate scene
    if 9 <= current_hour <= 17 and motion_detected["state"] == "on":
        # Work hours with motion - activate work scene
        await service_mgr.scene_activation("office_work", OFFICE_WORK_SCENE)
    elif 18 <= current_hour <= 22:
        # Evening - activate relaxation scene
        await service_mgr.scene_activation("evening_relaxation", EVENING_RELAXATION_SCENE)
    else:
        # Default - turn off unnecessary lights
        await service_mgr.batch_service_calls([
            {"service": "light.turn_off", "data": {"entity_id": "light.office_spot_lights"}},
            {"service": "light.turn_off", "data": {"entity_id": "light.wall"}}
        ])
```

---

## Real-time Monitoring

### Performance Monitoring
```python
class HAPerformanceMonitor:
    """Monitor Home Assistant performance for AI scripts."""
    
    def __init__(self, ha_url, access_token):
        self.ha_url = ha_url
        self.access_token = access_token
        self.metrics = {
            "api_response_times": [],
            "service_call_times": [],
            "websocket_latency": [],
            "error_rates": {}
        }
    
    async def monitor_api_performance(self, duration_minutes=60):
        """Monitor API performance over time."""
        import asyncio
        import time
        
        end_time = time.time() + (duration_minutes * 60)
        
        while time.time() < end_time:
            # Test API response time
            start_time = time.time()
            try:
                response = requests.get(f"{self.ha_url}/api/", headers=self.headers, timeout=10)
                response_time = time.time() - start_time
                
                self.metrics["api_response_times"].append({
                    "timestamp": datetime.now().isoformat(),
                    "response_time": response_time,
                    "status_code": response.status_code
                })
                
                if response.status_code != 200:
                    domain = "api_error"
                    if domain not in self.metrics["error_rates"]:
                        self.metrics["error_rates"][domain] = 0
                    self.metrics["error_rates"][domain] += 1
                    
            except Exception as e:
                self.metrics["api_response_times"].append({
                    "timestamp": datetime.now().isoformat(),
                    "response_time": -1,
                    "error": str(e)
                })
            
            await asyncio.sleep(30)  # Check every 30 seconds
    
    def get_performance_summary(self):
        """Get performance summary."""
        api_times = [m["response_time"] for m in self.metrics["api_response_times"] if m["response_time"] > 0]
        
        if not api_times:
            return {"error": "No performance data available"}
        
        return {
            "api_performance": {
                "avg_response_time": sum(api_times) / len(api_times),
                "max_response_time": max(api_times),
                "min_response_time": min(api_times),
                "total_requests": len(self.metrics["api_response_times"]),
                "error_rate": len([m for m in self.metrics["api_response_times"] if m["response_time"] < 0]) / len(self.metrics["api_response_times"])
            },
            "error_summary": self.metrics["error_rates"],
            "recommendations": self.generate_performance_recommendations()
        }
    
    def generate_performance_recommendations(self):
        """Generate performance optimization recommendations."""
        recommendations = []
        
        api_times = [m["response_time"] for m in self.metrics["api_response_times"] if m["response_time"] > 0]
        
        if api_times:
            avg_time = sum(api_times) / len(api_times)
            
            if avg_time > 2.0:
                recommendations.append("API response time is high - consider reducing polling frequency")
            
            if max(api_times) > 10.0:
                recommendations.append("Detected very slow API responses - check Home Assistant performance")
        
        error_rate = len([m for m in self.metrics["api_response_times"] if m["response_time"] < 0]) / len(self.metrics["api_response_times"]) if self.metrics["api_response_times"] else 0
        
        if error_rate > 0.05:
            recommendations.append(f"High error rate detected: {error_rate:.1%} - check network connectivity")
        
        return recommendations

# System health monitoring
class HAHealthMonitor:
    """Monitor overall Home Assistant system health."""
    
    def __init__(self, ha_url, access_token):
        self.ha_url = ha_url
        self.access_token = access_token
        
    async def get_system_health(self):
        """Get comprehensive system health information."""
        health_data = {
            "timestamp": datetime.now().isoformat(),
            "core_status": await self.check_core_status(),
            "integration_status": await self.check_integration_status(),
            "device_availability": await self.check_device_availability(),
            "automation_status": await self.check_automation_status(),
            "performance_metrics": await self.get_performance_metrics()
        }
        
        # Calculate overall health score
        health_data["overall_health_score"] = self.calculate_health_score(health_data)
        health_data["recommendations"] = self.generate_health_recommendations(health_data)
        
        return health_data
    
    async def check_integration_status(self):
        """Check status of key integrations."""
        integrations_to_check = [
            "alexa_media",
            "hacs", 
            "pushbullet",
            "yamaha_musiccast"
        ]
        
        integration_status = {}
        
        for integration in integrations_to_check:
            try:
                # Get config entries for integration
                response = requests.get(f"{self.ha_url}/api/config_entries", headers=self.headers)
                if response.status_code == 200:
                    entries = response.json()
                    integration_entries = [e for e in entries if e["domain"] == integration]
                    
                    integration_status[integration] = {
                        "configured": len(integration_entries) > 0,
                        "entries": len(integration_entries),
                        "loaded": all(e["state"] == "loaded" for e in integration_entries),
                        "entries_data": integration_entries
                    }
                else:
                    integration_status[integration] = {"error": f"HTTP {response.status_code}"}
                    
            except Exception as e:
                integration_status[integration] = {"error": str(e)}
        
        return integration_status
    
    async def check_device_availability(self):
        """Check availability of your specific devices."""
        key_devices = [
            "binary_sensor.lumi_lumi_sensor_motion_aq2_occupancy",
            "sensor.lumi_lumi_weather_humidity", 
            "media_player.living_room_main",
            "light.office_spot_lights",
            "light.office_stand",
            "light.wall"
        ]
        
        device_status = {}
        
        for device in key_devices:
            try:
                state = await get_entity_state(device)
                if state:
                    device_status[device] = {
                        "available": state["state"] != "unavailable",
                        "state": state["state"],
                        "last_changed": state["last_changed"],
                        "attributes": state["attributes"]
                    }
                else:
                    device_status[device] = {"available": False, "error": "Entity not found"}
            except Exception as e:
                device_status[device] = {"available": False, "error": str(e)}
        
        return device_status
```

---

## AI Script Examples

### Complete AI Automation Script
```python
#!/usr/bin/env python3
"""
Complete AI Home Assistant Integration Script
Monitors your specific HA setup and provides intelligent automation.
"""

import asyncio
import logging
import json
from datetime import datetime, timedelta
import requests
import websockets

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class IntelligentHomeAutomation:
    """AI-powered home automation for your specific HA setup."""
    
    def __init__(self, ha_url, access_token):
        self.ha_url = ha_url
        self.access_token = access_token
        self.headers = {"Authorization": f"Bearer {access_token}"}
        
        # Your specific entity mappings
        self.entities = {
            "motion_sensor": "binary_sensor.lumi_lumi_sensor_motion_aq2_occupancy",
            "humidity_sensor": "sensor.lumi_lumi_weather_humidity",
            "media_player": "media_player.living_room_main",
            "office_lights": [
                "light.office_spot_lights",
                "light.office_stand",
                "light.wall"
            ]
        }
        
        # AI learning data
        self.learning_data = {
            "occupancy_patterns": {},
            "lighting_preferences": {},
            "environmental_thresholds": {}
        }
    
    async def start_intelligent_monitoring(self):
        """Start the main AI monitoring loop."""
        logger.info("Starting intelligent home automation...")
        
        # Initialize learning data
        await self.load_historical_patterns()
        
        # Start WebSocket connection for real-time monitoring
        await self.connect_websocket()
    
    async def load_historical_patterns(self):
        """Load historical data to learn patterns."""
        try:
            # Get motion sensor history
            motion_history = await self.get_entity_history(
                self.entities["motion_sensor"], 
                hours_back=168  # 7 days
            )
            
            # Analyze occupancy patterns
            self.learning_data["occupancy_patterns"] = self.analyze_occupancy_patterns(motion_history)
            
            # Get lighting usage history
            for light in self.entities["office_lights"]:
                light_history = await self.get_entity_history(light, hours_back=168)
                self.learning_data["lighting_preferences"][light] = self.analyze_lighting_patterns(light_history)
            
            logger.info("Historical pattern analysis complete")
            
        except Exception as e:
            logger.error(f"Error loading historical patterns: {e}")
    
    def analyze_occupancy_patterns(self, motion_history):
        """Analyze occupancy patterns from motion sensor data."""
        patterns = {
            "hourly_activity": [0] * 24,
            "daily_activity": [0] * 7,
            "typical_durations": []
        }
        
        if not motion_history or not motion_history[0]:
            return patterns
        
        for state_change in motion_history[0]:  # motion_history is nested
            timestamp = datetime.fromisoformat(state_change["last_changed"])
            hour = timestamp.hour
            day = timestamp.weekday()
            
            if state_change["state"] == "on":
                patterns["hourly_activity"][hour] += 1
                patterns["daily_activity"][day] += 1
        
        return patterns
    
    async def connect_websocket(self):
        """Connect to Home Assistant WebSocket for real-time monitoring."""
        ws_url = f"ws://{self.ha_url.split('//')[1]}/api/websocket"
        
        try:
            async with websockets.connect(ws_url) as websocket:
                # Authenticate
                auth_msg = await websocket.recv()
                await websocket.send(json.dumps({
                    "type": "auth",
                    "access_token": self.access_token
                }))
                
                auth_result = await websocket.recv()
                auth_data = json.loads(auth_result)
                
                if auth_data["type"] != "auth_ok":
                    logger.error("WebSocket authentication failed")
                    return
                
                logger.info("WebSocket connected and authenticated")
                
                # Subscribe to state changes
                await websocket.send(json.dumps({
                    "id": 1,
                    "type": "subscribe_events",
                    "event_type": "state_changed"
                }))
                
                # Listen for events
                async for message in websocket:
                    data = json.loads(message)
                    if data.get("type") == "event":
                        await self.process_state_change(data["event"])
                        
        except Exception as e:
            logger.error(f"WebSocket error: {e}")
    
    async def process_state_change(self, event):
        """Process state change events with AI logic."""
        if event["event_type"] != "state_changed":
            return
        
        entity_id = event["data"]["entity_id"]
        new_state = event["data"]["new_state"]
        old_state = event["data"]["old_state"]
        
        # Motion sensor intelligence
        if entity_id == self.entities["motion_sensor"]:
            await self.handle_motion_intelligence(new_state, old_state)
        
        # Humidity sensor intelligence
        elif entity_id == self.entities["humidity_sensor"]:
            await self.handle_humidity_intelligence(new_state)
        
        # Media player intelligence
        elif entity_id == self.entities["media_player"]:
            await self.handle_media_intelligence(new_state, old_state)
    
    async def handle_motion_intelligence(self, new_state, old_state):
        """Intelligent motion sensor handling."""
        if new_state["state"] == "on" and old_state and old_state["state"] == "off":
            logger.info("Motion detected - applying intelligent lighting")
            
            # AI decision making
            current_hour = datetime.now().hour
            current_day = datetime.now().weekday()
            
            # Check if this is typical activity time
            occupancy_patterns = self.learning_data["occupancy_patterns"]
            typical_activity = occupancy_patterns["hourly_activity"][current_hour] > 5
            
            if typical_activity or (8 <= current_hour <= 22):
                # Calculate optimal brightness
                brightness = self.calculate_optimal_brightness(current_hour)
                
                # Turn on lights with AI-determined settings
                await self.intelligent_light_control("on", brightness)
                
                # Log for learning
                self.log_automation_decision("motion_lighting", {
                    "hour": current_hour,
                    "day": current_day,
                    "brightness": brightness,
                    "typical_activity": typical_activity
                })
    
    def calculate_optimal_brightness(self, hour):
        """Calculate optimal brightness based on time and learned preferences."""
        if 22 <= hour or hour <= 6:
            return 25  # Night mode
        elif 6 < hour <= 8 or 19 <= hour < 22:
            return 60  # Dawn/dusk
        else:
            return 85  # Daytime
    
    async def intelligent_light_control(self, action, brightness=None):
        """Control office lights intelligently."""
        service_calls = []
        
        for light in self.entities["office_lights"]:
            if action == "on":
                service_data = {
                    "entity_id": light,
                    "transition": 1
                }
                if brightness:
                    service_data["brightness_pct"] = brightness
                
                service_calls.append({
                    "domain": "light",
                    "service": "turn_on",
                    "data": service_data
                })
            elif action == "off":
                service_calls.append({
                    "domain": "light", 
                    "service": "turn_off",
                    "data": {
                        "entity_id": light,
                        "transition": 2
                    }
                })
        
        # Execute service calls
        for call in service_calls:
            try:
                response = requests.post(
                    f"{self.ha_url}/api/services/{call['domain']}/{call['service']}",
                    headers=self.headers,
                    json=call["data"]
                )
                
                if response.status_code != 200:
                    logger.error(f"Service call failed: {response.status_code}")
                    
            except Exception as e:
                logger.error(f"Error calling service: {e}")
    
    async def handle_humidity_intelligence(self, new_state):
        """Intelligent humidity monitoring."""
        try:
            humidity = float(new_state["state"])
            
            # AI threshold learning
            thresholds = self.learning_data.get("environmental_thresholds", {})
            high_threshold = thresholds.get("humidity_high", 55)
            
            if humidity > high_threshold:
                logger.info(f"High humidity detected: {humidity}%")
                
                # Send intelligent notification
                await self.send_smart_notification(
                    f"High humidity detected: {humidity}%",
                    "Environmental Alert",
                    priority="high"
                )
                
                # Log for learning
                self.log_automation_decision("humidity_alert", {
                    "value": humidity,
                    "threshold": high_threshold,
                    "timestamp": datetime.now().isoformat()
                })
                
        except ValueError:
            pass  # Ignore non-numeric values
    
    async def send_smart_notification(self, message, title, priority="normal"):
        """Send notification with smart delivery."""
        try:
            notification_data = {
                "message": message,
                "title": title,
                "data": {
                    "tag": "ai_automation",
                    "group": "environmental",
                    "priority": priority
                }
            }
            
            response = requests.post(
                f"{self.ha_url}/api/services/notify/mobile_app_sm_n986u",
                headers=self.headers,
                json=notification_data
            )
            
            if response.status_code == 200:
                logger.info(f"Notification sent: {title}")
            else:
                logger.error(f"Notification failed: {response.status_code}")
                
        except Exception as e:
            logger.error(f"Error sending notification: {e}")
    
    def log_automation_decision(self, decision_type, data):
        """Log automation decisions for learning."""
        log_entry = {
            "timestamp": datetime.now().isoformat(),
            "decision_type": decision_type,
            "data": data
        }
        
        # In a real implementation, you'd store this in a database
        logger.info(f"Decision logged: {decision_type} - {data}")
    
    async def get_entity_history(self, entity_id, hours_back=24):
        """Get historical data for entity."""
        end_time = datetime.now()
        start_time = end_time - timedelta(hours=hours_back)
        
        try:
            params = {
                "filter_entity_id": entity_id,
                "start_time": start_time.isoformat(),
                "end_time": end_time.isoformat()
            }
            
            response = requests.get(
                f"{self.ha_url}/api/history/period",
                headers=self.headers,
                params=params
            )
            
            if response.status_code == 200:
                return response.json()
            else:
                logger.error(f"History request failed: {response.status_code}")
                return []
                
        except Exception as e:
            logger.error(f"Error getting history: {e}")
            return []

# Main execution
async def main():
    """Main function to run the AI automation."""
    # Configuration
    HA_URL = "http://homeassistant.local:8123"
    ACCESS_TOKEN = "your_long_lived_access_token_here"
    
    # Create and start AI automation
    ai_home = IntelligentHomeAutomation(HA_URL, ACCESS_TOKEN)
    
    try:
        await ai_home.start_intelligent_monitoring()
    except KeyboardInterrupt:
        logger.info("AI automation stopped by user")
    except Exception as e:
        logger.error(f"AI automation error: {e}")

if __name__ == "__main__":
    asyncio.run(main())
```

---

## Rate Limiting & Performance

### API Rate Limiting
```python
class RateLimitedAPIClient:
    """API client with built-in rate limiting."""
    
    def __init__(self, ha_url, access_token, requests_per_minute=300):
        self.ha_url = ha_url
        self.access_token = access_token
        self.requests_per_minute = requests_per_minute
        self.request_times = []
        self.headers = {"Authorization": f"Bearer {access_token}"}
    
    async def make_request(self, method, endpoint, **kwargs):
        """Make rate-limited API request."""
        # Check rate limit
        await self.check_rate_limit()
        
        # Make request
        import aiohttp
        async with aiohttp.ClientSession() as session:
            url = f"{self.ha_url}{endpoint}"
            
            async with session.request(method, url, headers=self.headers, **kwargs) as response:
                # Record request time
                self.request_times.append(time.time())
                
                # Handle response
                if response.status == 429:  # Too Many Requests
                    retry_after = int(response.headers.get('Retry-After', 60))
                    logger.warning(f"Rate limited, waiting {retry_after} seconds")
                    await asyncio.sleep(retry_after)
                    return await self.make_request(method, endpoint, **kwargs)
                
                return response
    
    async def check_rate_limit(self):
        """Check and enforce rate limiting."""
        now = time.time()
        
        # Remove requests older than 1 minute
        self.request_times = [t for t in self.request_times if now - t < 60]
        
        # Check if we're at the limit
        if len(self.request_times) >= self.requests_per_minute:
            # Calculate sleep time
            oldest_request = min(self.request_times)
            sleep_time = 60 - (now - oldest_request)
            
            if sleep_time > 0:
                logger.info(f"Rate limit reached, sleeping {sleep_time:.1f} seconds")
                await asyncio.sleep(sleep_time)

# Performance optimization configuration
PERFORMANCE_CONFIG = {
    "api_timeouts": {
        "default": 10,
        "service_calls": 15,
        "history_queries": 30
    },
    
    "batch_sizes": {
        "service_calls": 10,
        "state_queries": 50,
        "event_processing": 100
    },
    
    "cache_settings": {
        "state_cache_ttl": 5,
        "config_cache_ttl": 300,
        "history_cache_ttl": 60
    },
    
    "retry_settings": {
        "max_retries": 3,
        "retry_delay": 1,
        "backoff_multiplier": 2
    }
}
```

### Connection Management
```python
class HAConnectionManager:
    """Manage Home Assistant connections efficiently."""
    
    def __init__(self, ha_url, access_token):
        self.ha_url = ha_url
        self.access_token = access_token
        self.session = None
        self.websocket = None
        self.connection_healthy = False
        
    async def ensure_connection(self):
        """Ensure connection is healthy."""
        if not self.session:
            import aiohttp
            self.session = aiohttp.ClientSession(
                timeout=aiohttp.ClientTimeout(total=30),
                headers={"Authorization": f"Bearer {self.access_token}"}
            )
        
        # Test connection health
        try:
            async with self.session.get(f"{self.ha_url}/api/") as response:
                self.connection_healthy = response.status == 200
        except Exception:
            self.connection_healthy = False
            await self.reconnect()
    
    async def reconnect(self):
        """Reconnect to Home Assistant."""
        if self.session:
            await self.session.close()
            self.session = None
        
        if self.websocket:
            await self.websocket.close()
            self.websocket = None
        
        # Wait before reconnecting
        await asyncio.sleep(5)
        
        # Recreate connections
        await self.ensure_connection()
```

---

*Last Updated: December 28, 2025*
*Home Assistant Version: 2024.12.x*
*Documentation Version: 1.0*

**Note**: Replace `your_long_lived_access_token_here` and `homeassistant.local:8123` with your actual Home Assistant URL and access token. Ensure your mobile notification service name matches your device (currently configured for `mobile_app_sm_n986u`).