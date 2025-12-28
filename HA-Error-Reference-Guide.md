# Home Assistant Error Reference Guide

## Table of Contents
1. [Error Classification System](#error-classification-system)
2. [Common Error Patterns](#common-error-patterns)
3. [Diagnostic Procedures](#diagnostic-procedures)
4. [Automated Detection Scripts](#automated-detection-scripts)
5. [Recovery Procedures](#recovery-procedures)
6. [AI-Readable Error Database](#ai-readable-error-database)
7. [Monitoring & Alerting](#monitoring--alerting)

---

## Error Classification System

### Error Severity Levels
```json
{
  "severity_levels": {
    "CRITICAL": {
      "level": 1,
      "description": "System failure, HA unavailable",
      "response_time": "immediate",
      "escalation": "automatic"
    },
    "HIGH": {
      "level": 2, 
      "description": "Core functionality impaired",
      "response_time": "within 5 minutes",
      "escalation": "notification"
    },
    "MEDIUM": {
      "level": 3,
      "description": "Feature degradation",
      "response_time": "within 30 minutes", 
      "escalation": "log_only"
    },
    "LOW": {
      "level": 4,
      "description": "Minor issues, cosmetic",
      "response_time": "next maintenance window",
      "escalation": "batch_report"
    }
  }
}
```

### Error Categories
```yaml
error_categories:
  configuration:
    - yaml_syntax_errors
    - schema_validation_errors
    - missing_dependencies
    - circular_references
    
  integration:
    - connection_failures
    - authentication_errors
    - api_rate_limiting
    - device_unavailable
    
  system:
    - database_errors
    - memory_exhaustion
    - disk_space_issues
    - network_connectivity
    
  automation:
    - trigger_failures
    - condition_evaluation_errors
    - action_execution_failures
    - template_rendering_errors
```

---

## Common Error Patterns

### Configuration Errors

#### 1. YAML Syntax Errors
```yaml
# Error Pattern Recognition
error_patterns:
  yaml_syntax:
    symptoms:
      - "Configuration invalid" in logs
      - Home Assistant fails to start
      - Config check fails
    
    common_causes:
      - Indentation errors
      - Missing quotes around special characters
      - Invalid Unicode characters
      - Malformed lists or dictionaries
    
    detection_regex: |
      "(?i)(yaml.*error|configuration.*invalid|indentation.*error)"
```

**Example Error:**
```
Configuration invalid:
Invalid config for [automation]: invalid_key is not allowed
```

**Diagnostic Script:**
```python
import yaml
import sys

def validate_yaml_file(file_path):
    """Validate YAML file syntax."""
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            yaml.safe_load(file)
        return True, "Valid YAML"
    except yaml.YAMLError as e:
        return False, f"YAML Error: {e}"
    except UnicodeDecodeError as e:
        return False, f"Encoding Error: {e}"

# Usage
is_valid, message = validate_yaml_file('configuration.yaml')
print(f"Status: {message}")
```

#### 2. Schema Validation Errors
```json
{
  "error_type": "schema_validation",
  "pattern": "Invalid config for \\[(.+)\\]: (.+)",
  "severity": "HIGH",
  "auto_fix": false,
  "diagnostic_steps": [
    "Check component documentation",
    "Validate required fields",
    "Check data types",
    "Verify enum values"
  ]
}
```

### Integration Errors

#### 1. Connection Failures
```python
# Connection error patterns
CONNECTION_ERROR_PATTERNS = {
    "timeout": {
        "regex": r"timeout|timed out|connection timeout",
        "severity": "MEDIUM",
        "auto_retry": True,
        "max_retries": 3,
        "backoff_multiplier": 2
    },
    "refused": {
        "regex": r"connection refused|refused to connect",
        "severity": "HIGH", 
        "auto_retry": True,
        "max_retries": 5,
        "check_service_status": True
    },
    "dns_failure": {
        "regex": r"name resolution|dns|hostname",
        "severity": "HIGH",
        "auto_retry": False,
        "check_network": True
    }
}
```

#### 2. Authentication Errors
```yaml
authentication_errors:
  api_key_invalid:
    pattern: "(?i)(api.*key.*invalid|unauthorized|401)"
    severity: HIGH
    solution_steps:
      - Verify API key in secrets.yaml
      - Check key expiration
      - Regenerate API key if needed
      - Update integration configuration
      
  oauth_expired:
    pattern: "(?i)(oauth.*expired|token.*expired|refresh.*failed)"
    severity: MEDIUM
    auto_fix: true
    solution: "Trigger OAuth re-authentication"
```

### Device Connectivity Issues

#### 1. Zigbee/Z-Wave Problems
```json
{
  "zigbee_errors": {
    "coordinator_offline": {
      "symptoms": [
        "ZHA integration unavailable",
        "All Zigbee devices unavailable",
        "Coordinator not responding"
      ],
      "diagnostic_commands": [
        "Check USB device connection",
        "Verify coordinator LED status", 
        "Test USB port with different device",
        "Check system USB logs"
      ],
      "recovery_steps": [
        "Restart Home Assistant",
        "Unplug/replug coordinator",
        "Try different USB port",
        "Check coordinator firmware"
      ]
    },
    "device_unavailable": {
      "symptoms": [
        "Entity unavailable",
        "Last seen timestamp old",
        "No recent activity"
      ],
      "diagnostic_procedure": "device_connectivity_check"
    }
  }
}
```

#### 2. Network Device Issues
```python
# Network device diagnostic
class NetworkDeviceDiagnostic:
    def __init__(self, device_ip):
        self.device_ip = device_ip
        
    async def run_diagnostics(self):
        """Run comprehensive network device diagnostics."""
        results = {
            "timestamp": datetime.now().isoformat(),
            "device_ip": self.device_ip,
            "tests": {}
        }
        
        # Ping test
        results["tests"]["ping"] = await self.ping_test()
        
        # Port connectivity
        results["tests"]["port_scan"] = await self.port_scan()
        
        # HTTP/HTTPS connectivity
        results["tests"]["http_check"] = await self.http_connectivity()
        
        # DNS resolution
        results["tests"]["dns_resolution"] = await self.dns_test()
        
        return results
        
    async def ping_test(self):
        """Test basic connectivity."""
        import subprocess
        try:
            result = subprocess.run(
                ['ping', '-c', '4', self.device_ip],
                capture_output=True, text=True, timeout=10
            )
            return {
                "status": "success" if result.returncode == 0 else "failed",
                "output": result.stdout,
                "error": result.stderr
            }
        except Exception as e:
            return {"status": "error", "message": str(e)}
```

---

## Diagnostic Procedures

### System Health Check
```python
class HomeAssistantHealthCheck:
    def __init__(self, hass):
        self.hass = hass
        
    async def comprehensive_health_check(self):
        """Run comprehensive system health check."""
        health_report = {
            "timestamp": datetime.now().isoformat(),
            "overall_status": "unknown",
            "checks": {}
        }
        
        # Core system checks
        health_report["checks"]["core"] = await self.check_core_system()
        health_report["checks"]["database"] = await self.check_database()
        health_report["checks"]["integrations"] = await self.check_integrations()
        health_report["checks"]["automations"] = await self.check_automations()
        health_report["checks"]["devices"] = await self.check_devices()
        health_report["checks"]["network"] = await self.check_network()
        
        # Determine overall status
        failed_checks = [
            name for name, result in health_report["checks"].items()
            if result.get("status") != "healthy"
        ]
        
        if not failed_checks:
            health_report["overall_status"] = "healthy"
        elif len(failed_checks) <= 2:
            health_report["overall_status"] = "warning"
        else:
            health_report["overall_status"] = "critical"
            
        return health_report
        
    async def check_core_system(self):
        """Check core Home Assistant functionality."""
        try:
            # Check if event bus is responsive
            test_event_fired = False
            
            def test_listener(event):
                nonlocal test_event_fired
                test_event_fired = True
                
            self.hass.bus.async_listen_once("test_event", test_listener)
            self.hass.bus.async_fire("test_event")
            
            await asyncio.sleep(0.1)
            
            return {
                "status": "healthy" if test_event_fired else "unhealthy",
                "event_bus_responsive": test_event_fired,
                "uptime": self.hass.data.get("homeassistant", {}).get("uptime", "unknown")
            }
        except Exception as e:
            return {"status": "error", "message": str(e)}
            
    async def check_database(self):
        """Check database connectivity and performance."""
        try:
            from homeassistant.components.recorder import get_instance
            
            recorder = get_instance(self.hass)
            if not recorder or not recorder.connected:
                return {"status": "unhealthy", "message": "Database not connected"}
            
            # Test database query
            start_time = time.time()
            states_count = await self.hass.async_add_executor_job(
                lambda: self.hass.states.async_entity_ids_count()
            )
            query_time = time.time() - start_time
            
            return {
                "status": "healthy" if query_time < 1.0 else "warning",
                "connected": True,
                "query_time_seconds": query_time,
                "entity_count": states_count
            }
        except Exception as e:
            return {"status": "error", "message": str(e)}
```

### Integration Status Check
```python
async def check_integration_status(hass, domain):
    """Check status of specific integration."""
    config_entries = hass.config_entries.async_entries(domain)
    
    status_report = {
        "domain": domain,
        "config_entries": len(config_entries),
        "entries_status": []
    }
    
    for entry in config_entries:
        entry_status = {
            "entry_id": entry.entry_id,
            "title": entry.title,
            "state": entry.state.value,
            "disabled_by": entry.disabled_by,
            "last_error": str(entry.reason) if entry.reason else None
        }
        
        # Check entity availability
        entities = hass.data.get("entity_registry", {}).async_entries_for_config_entry(entry.entry_id)
        available_entities = sum(
            1 for entity in entities
            if hass.states.get(entity.entity_id) and 
            hass.states.get(entity.entity_id).state != "unavailable"
        )
        
        entry_status["entities"] = {
            "total": len(entities),
            "available": available_entities,
            "unavailable": len(entities) - available_entities
        }
        
        status_report["entries_status"].append(entry_status)
    
    return status_report
```

---

## Automated Detection Scripts

### Log Analysis Script
```python
#!/usr/bin/env python3
"""
Home Assistant Log Analysis Script
Automatically detects and categorizes errors from HA logs.
"""

import re
import json
from datetime import datetime, timedelta
from collections import Counter
import argparse

class LogAnalyzer:
    def __init__(self, log_file_path):
        self.log_file_path = log_file_path
        self.error_patterns = self.load_error_patterns()
        
    def load_error_patterns(self):
        """Load error detection patterns."""
        return {
            "critical": [
                r"CRITICAL.*",
                r"Fatal.*",
                r"HomeAssistant.*failed to start",
                r"Database.*corrupt"
            ],
            "errors": [
                r"ERROR.*",
                r"Exception.*",
                r"Traceback.*",
                r"Failed to.*"
            ],
            "warnings": [
                r"WARNING.*",
                r"deprecated.*",
                r"retry.*failed"
            ],
            "integration_failures": [
                r"Setup failed for (.+): (.+)",
                r"Unable to connect to (.+)",
                r"Integration (.+) not ready yet"
            ],
            "configuration_errors": [
                r"Invalid config for \[(.+)\]: (.+)",
                r"Configuration check failed",
                r"YAML.*error"
            ]
        }
    
    def analyze_logs(self, hours_back=24):
        """Analyze logs for errors and patterns."""
        cutoff_time = datetime.now() - timedelta(hours=hours_back)
        
        results = {
            "analysis_timestamp": datetime.now().isoformat(),
            "time_range_hours": hours_back,
            "error_summary": {},
            "critical_issues": [],
            "frequent_errors": [],
            "integration_issues": {},
            "recommendations": []
        }
        
        try:
            with open(self.log_file_path, 'r') as log_file:
                for line_num, line in enumerate(log_file):
                    if self.is_recent_log_entry(line, cutoff_time):
                        self.analyze_line(line, line_num, results)
                        
        except FileNotFoundError:
            results["error"] = f"Log file not found: {self.log_file_path}"
            return results
        
        # Post-process results
        self.generate_recommendations(results)
        return results
    
    def analyze_line(self, line, line_num, results):
        """Analyze individual log line."""
        
        # Check for critical issues
        for pattern in self.error_patterns["critical"]:
            if re.search(pattern, line, re.IGNORECASE):
                results["critical_issues"].append({
                    "line": line_num,
                    "message": line.strip(),
                    "pattern": pattern
                })
        
        # Check for integration failures
        for pattern in self.error_patterns["integration_failures"]:
            match = re.search(pattern, line, re.IGNORECASE)
            if match:
                integration = match.group(1) if match.groups() else "unknown"
                if integration not in results["integration_issues"]:
                    results["integration_issues"][integration] = []
                results["integration_issues"][integration].append({
                    "line": line_num,
                    "error": match.group(2) if len(match.groups()) > 1 else line.strip()
                })
        
        # Count error types
        for error_type, patterns in self.error_patterns.items():
            for pattern in patterns:
                if re.search(pattern, line, re.IGNORECASE):
                    if error_type not in results["error_summary"]:
                        results["error_summary"][error_type] = 0
                    results["error_summary"][error_type] += 1
                    break
    
    def generate_recommendations(self, results):
        """Generate recommendations based on analysis."""
        recommendations = []
        
        # Check for critical issues
        if results["critical_issues"]:
            recommendations.append({
                "priority": "HIGH",
                "category": "critical",
                "message": f"Found {len(results['critical_issues'])} critical issues requiring immediate attention",
                "action": "Review critical issues and restart Home Assistant if needed"
            })
        
        # Check for integration problems
        if results["integration_issues"]:
            failing_integrations = len(results["integration_issues"])
            recommendations.append({
                "priority": "MEDIUM",
                "category": "integration",
                "message": f"{failing_integrations} integrations have reported errors",
                "action": "Check integration configurations and network connectivity"
            })
        
        # Check error frequency
        total_errors = results["error_summary"].get("errors", 0)
        if total_errors > 50:
            recommendations.append({
                "priority": "MEDIUM",
                "category": "performance",
                "message": f"High error frequency detected: {total_errors} errors",
                "action": "Review system resources and consider optimization"
            })
        
        results["recommendations"] = recommendations

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Analyze Home Assistant logs")
    parser.add_argument("--log-file", default="/config/home-assistant.log", 
                       help="Path to Home Assistant log file")
    parser.add_argument("--hours", type=int, default=24,
                       help="Hours of logs to analyze")
    parser.add_argument("--output", help="Output file for results")
    
    args = parser.parse_args()
    
    analyzer = LogAnalyzer(args.log_file)
    results = analyzer.analyze_logs(args.hours)
    
    if args.output:
        with open(args.output, 'w') as f:
            json.dump(results, f, indent=2)
        print(f"Results saved to {args.output}")
    else:
        print(json.dumps(results, indent=2))
```

### Health Monitoring Script
```python
#!/usr/bin/env python3
"""
Continuous Health Monitoring Script
Monitors Home Assistant health and sends alerts.
"""

import asyncio
import aiohttp
import json
import time
from datetime import datetime
import smtplib
from email.mime.text import MIMEText

class HealthMonitor:
    def __init__(self, ha_url, access_token, config):
        self.ha_url = ha_url.rstrip('/')
        self.access_token = access_token
        self.config = config
        self.last_alert_time = {}
        
    async def monitor_loop(self):
        """Main monitoring loop."""
        while True:
            try:
                health_status = await self.check_system_health()
                await self.process_health_status(health_status)
                
                # Sleep before next check
                await asyncio.sleep(self.config.get("check_interval", 300))
                
            except Exception as e:
                print(f"Monitoring error: {e}")
                await asyncio.sleep(60)  # Short sleep on error
    
    async def check_system_health(self):
        """Check Home Assistant system health."""
        headers = {
            "Authorization": f"Bearer {self.access_token}",
            "Content-Type": "application/json"
        }
        
        health_checks = {
            "api_responsive": False,
            "database_connected": False,
            "integration_errors": [],
            "device_unavailable_count": 0,
            "automation_failures": 0,
            "memory_usage": 0,
            "disk_usage": 0
        }
        
        try:
            async with aiohttp.ClientSession() as session:
                # Check API responsiveness
                start_time = time.time()
                async with session.get(
                    f"{self.ha_url}/api/", headers=headers
                ) as response:
                    if response.status == 200:
                        health_checks["api_responsive"] = True
                        health_checks["api_response_time"] = time.time() - start_time
                
                # Check system info
                async with session.get(
                    f"{self.ha_url}/api/hassio/supervisor/info", headers=headers
                ) as response:
                    if response.status == 200:
                        supervisor_info = await response.json()
                        health_checks["memory_usage"] = supervisor_info.get("data", {}).get("memory_usage", 0)
                
                # Check integration errors
                async with session.get(
                    f"{self.ha_url}/api/config_entries", headers=headers
                ) as response:
                    if response.status == 200:
                        entries = await response.json()
                        health_checks["integration_errors"] = [
                            entry for entry in entries 
                            if entry.get("state") != "loaded"
                        ]
                
                # Check device availability
                async with session.get(
                    f"{self.ha_url}/api/states", headers=headers
                ) as response:
                    if response.status == 200:
                        states = await response.json()
                        unavailable_count = sum(
                            1 for state in states 
                            if state.get("state") == "unavailable"
                        )
                        health_checks["device_unavailable_count"] = unavailable_count
                        
        except Exception as e:
            health_checks["error"] = str(e)
        
        return health_checks
    
    async def process_health_status(self, health_status):
        """Process health status and send alerts if needed."""
        alerts = []
        
        # Check API responsiveness
        if not health_status.get("api_responsive"):
            alerts.append({
                "severity": "CRITICAL",
                "message": "Home Assistant API not responding",
                "category": "api"
            })
        
        # Check response time
        if health_status.get("api_response_time", 0) > 5:
            alerts.append({
                "severity": "WARNING", 
                "message": f"API response time high: {health_status['api_response_time']:.2f}s",
                "category": "performance"
            })
        
        # Check integration errors
        if health_status.get("integration_errors"):
            alerts.append({
                "severity": "HIGH",
                "message": f"{len(health_status['integration_errors'])} integrations have errors",
                "category": "integration",
                "details": health_status["integration_errors"]
            })
        
        # Check device availability
        if health_status.get("device_unavailable_count", 0) > 5:
            alerts.append({
                "severity": "MEDIUM",
                "message": f"{health_status['device_unavailable_count']} devices unavailable",
                "category": "device"
            })
        
        # Send alerts
        for alert in alerts:
            await self.send_alert(alert)
    
    async def send_alert(self, alert):
        """Send alert notification."""
        alert_key = f"{alert['category']}_{alert['severity']}"
        now = time.time()
        
        # Check if we've sent this alert recently
        if alert_key in self.last_alert_time:
            time_since_last = now - self.last_alert_time[alert_key]
            min_interval = self.config.get("alert_intervals", {}).get(alert["severity"], 3600)
            
            if time_since_last < min_interval:
                return  # Skip alert due to rate limiting
        
        self.last_alert_time[alert_key] = now
        
        # Send notification
        if self.config.get("email"):
            await self.send_email_alert(alert)
        
        if self.config.get("webhook"):
            await self.send_webhook_alert(alert)
    
    async def send_email_alert(self, alert):
        """Send email alert."""
        try:
            email_config = self.config["email"]
            
            msg = MIMEText(
                f"Home Assistant Alert\n\n"
                f"Severity: {alert['severity']}\n"
                f"Category: {alert['category']}\n"
                f"Message: {alert['message']}\n"
                f"Time: {datetime.now().isoformat()}\n"
            )
            
            msg['Subject'] = f"HA Alert: {alert['severity']} - {alert['message'][:50]}"
            msg['From'] = email_config['from']
            msg['To'] = email_config['to']
            
            server = smtplib.SMTP(email_config['smtp_server'], email_config['smtp_port'])
            server.starttls()
            server.login(email_config['username'], email_config['password'])
            server.send_message(msg)
            server.quit()
            
        except Exception as e:
            print(f"Failed to send email alert: {e}")

# Configuration
MONITOR_CONFIG = {
    "ha_url": "http://homeassistant.local:8123",
    "access_token": "YOUR_LONG_LIVED_ACCESS_TOKEN",
    "check_interval": 300,  # 5 minutes
    "alert_intervals": {
        "CRITICAL": 300,    # 5 minutes
        "HIGH": 900,        # 15 minutes  
        "MEDIUM": 3600,     # 1 hour
        "LOW": 7200         # 2 hours
    },
    "email": {
        "smtp_server": "smtp.gmail.com",
        "smtp_port": 587,
        "username": "your_email@gmail.com",
        "password": "your_password",
        "from": "homeassistant@yourdomain.com",
        "to": "admin@yourdomain.com"
    }
}

if __name__ == "__main__":
    monitor = HealthMonitor(
        MONITOR_CONFIG["ha_url"],
        MONITOR_CONFIG["access_token"], 
        MONITOR_CONFIG
    )
    
    asyncio.run(monitor.monitor_loop())
```

---

## Recovery Procedures

### Automated Recovery Scripts
```python
class AutoRecovery:
    """Automated recovery procedures for common issues."""
    
    def __init__(self, hass):
        self.hass = hass
        
    async def handle_integration_failure(self, domain):
        """Handle integration failure automatically."""
        recovery_steps = [
            self.restart_integration,
            self.reset_integration_config,
            self.reload_integration,
            self.disable_integration_temporarily
        ]
        
        for step in recovery_steps:
            try:
                success = await step(domain)
                if success:
                    await self.log_recovery_success(domain, step.__name__)
                    return True
            except Exception as e:
                await self.log_recovery_failure(domain, step.__name__, str(e))
                continue
        
        # All recovery steps failed
        await self.escalate_to_admin(domain)
        return False
    
    async def restart_integration(self, domain):
        """Restart a failed integration."""
        config_entries = self.hass.config_entries.async_entries(domain)
        
        for entry in config_entries:
            if entry.state != config_entries.ConfigEntryState.LOADED:
                await self.hass.config_entries.async_reload(entry.entry_id)
                await asyncio.sleep(5)  # Wait for reload
                
                # Check if reload was successful
                if entry.state == config_entries.ConfigEntryState.LOADED:
                    return True
        
        return False
```

### Database Recovery
```python
class DatabaseRecovery:
    """Database recovery and maintenance procedures."""
    
    async def recover_corrupted_database(self, hass):
        """Attempt to recover from database corruption."""
        from homeassistant.components.recorder import get_instance
        
        recorder = get_instance(hass)
        if not recorder:
            return False
        
        recovery_steps = [
            self.vacuum_database,
            self.repair_database_integrity,
            self.restore_from_backup,
            self.create_new_database
        ]
        
        for step in recovery_steps:
            try:
                if await step(recorder):
                    return True
            except Exception as e:
                _LOGGER.error(f"Database recovery step {step.__name__} failed: {e}")
        
        return False
    
    async def vacuum_database(self, recorder):
        """Vacuum database to fix minor corruption."""
        try:
            await hass.async_add_executor_job(
                recorder.engine.execute, "VACUUM;"
            )
            return True
        except Exception:
            return False
```

---

## AI-Readable Error Database

### JSON Error Database Structure
```json
{
  "error_database": {
    "version": "1.0",
    "last_updated": "2025-12-28T00:00:00Z",
    "errors": {
      "CONFIG_001": {
        "id": "CONFIG_001",
        "category": "configuration",
        "severity": "HIGH",
        "title": "YAML Syntax Error",
        "description": "Invalid YAML syntax in configuration file",
        "patterns": [
          "(?i)yaml.*error",
          "(?i)configuration.*invalid",
          "(?i)mapping values are not allowed here"
        ],
        "common_causes": [
          "Incorrect indentation",
          "Missing quotes around strings with special characters",
          "Invalid UTF-8 characters",
          "Malformed lists or dictionaries"
        ],
        "diagnostic_steps": [
          {
            "step": 1,
            "action": "validate_yaml_syntax",
            "command": "ha core check",
            "expected_result": "Configuration valid"
          },
          {
            "step": 2, 
            "action": "check_file_encoding",
            "command": "file -bi configuration.yaml",
            "expected_result": "charset=utf-8"
          }
        ],
        "automated_fixes": [
          {
            "condition": "indentation_error",
            "script": "fix_yaml_indentation.py",
            "confidence": 0.8
          }
        ],
        "recovery_procedures": [
          "Restore from backup configuration",
          "Use YAML validator to identify exact error location", 
          "Manually fix syntax errors",
          "Test configuration with 'ha core check'"
        ],
        "prevention_measures": [
          "Use YAML-aware editor",
          "Enable syntax highlighting",
          "Regular configuration backups",
          "Use configuration check before restarts"
        ]
      },
      
      "INTEGRATION_001": {
        "id": "INTEGRATION_001", 
        "category": "integration",
        "severity": "MEDIUM",
        "title": "Device Connection Timeout",
        "description": "Integration unable to connect to device within timeout period",
        "patterns": [
          "(?i)connection.*timeout",
          "(?i)timed out.*connecting",
          "(?i)device.*not responding"
        ],
        "affected_integrations": [
          "xiaomi_miio",
          "yamaha_musiccast", 
          "hue",
          "tuya"
        ],
        "diagnostic_steps": [
          {
            "step": 1,
            "action": "ping_device",
            "command": "ping -c 4 {device_ip}",
            "success_criteria": "0% packet loss"
          },
          {
            "step": 2,
            "action": "check_port_connectivity",
            "command": "nc -zv {device_ip} {device_port}",
            "success_criteria": "Connection succeeded"
          },
          {
            "step": 3,
            "action": "verify_device_status",
            "description": "Check device LED indicators and power status"
          }
        ],
        "automated_recovery": {
          "enabled": true,
          "max_retries": 3,
          "retry_interval": 60,
          "escalation_threshold": 3
        }
      },
      
      "SYSTEM_001": {
        "id": "SYSTEM_001",
        "category": "system",
        "severity": "CRITICAL", 
        "title": "Database Connection Failed",
        "description": "Unable to connect to Home Assistant database",
        "patterns": [
          "(?i)database.*connection.*failed",
          "(?i)sqlite.*error",
          "(?i)recorder.*unavailable"
        ],
        "immediate_actions": [
          "Check database file permissions",
          "Verify disk space availability", 
          "Test database file integrity",
          "Restart Home Assistant service"
        ],
        "diagnostic_commands": {
          "check_db_file": "ls -la home-assistant_v2.db",
          "check_disk_space": "df -h /config",
          "test_db_integrity": "sqlite3 home-assistant_v2.db 'PRAGMA integrity_check;'"
        },
        "recovery_priority": 1,
        "auto_escalate": true
      }
    }
  }
}
```

### AI Query Interface
```python
class ErrorDatabaseQuery:
    """AI-friendly interface for error database queries."""
    
    def __init__(self, error_database_path):
        with open(error_database_path, 'r') as f:
            self.db = json.load(f)['error_database']
    
    def find_errors_by_pattern(self, log_message):
        """Find matching errors by log message pattern."""
        matches = []
        
        for error_id, error_data in self.db['errors'].items():
            for pattern in error_data.get('patterns', []):
                if re.search(pattern, log_message, re.IGNORECASE):
                    matches.append({
                        'error_id': error_id,
                        'confidence': self.calculate_confidence(pattern, log_message),
                        'error_data': error_data
                    })
        
        return sorted(matches, key=lambda x: x['confidence'], reverse=True)
    
    def get_diagnostic_procedure(self, error_id):
        """Get diagnostic procedure for specific error."""
        error = self.db['errors'].get(error_id)
        if not error:
            return None
        
        return {
            'error_id': error_id,
            'diagnostic_steps': error.get('diagnostic_steps', []),
            'automated_fixes': error.get('automated_fixes', []),
            'recovery_procedures': error.get('recovery_procedures', [])
        }
    
    def calculate_confidence(self, pattern, message):
        """Calculate confidence score for pattern match."""
        # Simple confidence calculation based on pattern specificity
        specificity_score = len(pattern) / 100  # More specific = higher confidence
        match_quality = len(re.findall(pattern, message, re.IGNORECASE)) / len(message.split())
        
        return min(specificity_score + match_quality, 1.0)
```

---

## Monitoring & Alerting

### Alert Configuration
```yaml
# alerts.yaml
alert_rules:
  critical_system_failure:
    severity: CRITICAL
    conditions:
      - api_unresponsive_minutes > 5
      - database_connection_failed = true
    actions:
      - send_immediate_notification
      - trigger_automatic_restart
      - escalate_to_admin
    
  integration_failure:
    severity: HIGH
    conditions:
      - failed_integrations_count > 3
      - integration_down_minutes > 10
    actions:
      - send_notification
      - attempt_auto_recovery
      - log_failure_details
    
  device_connectivity_issues:
    severity: MEDIUM
    conditions:
      - unavailable_devices_percentage > 20
      - device_down_minutes > 30
    actions:
      - send_notification
      - run_connectivity_diagnostics
      - generate_device_report
    
  performance_degradation:
    severity: LOW
    conditions:
      - api_response_time_seconds > 3
      - memory_usage_percentage > 85
      - error_rate_per_hour > 100
    actions:
      - log_performance_metrics
      - send_daily_summary
      - schedule_maintenance_check
```

### Alerting Script
```python
class AlertManager:
    """Manage alerts and notifications for Home Assistant."""
    
    def __init__(self, hass, config):
        self.hass = hass
        self.config = config
        self.alert_history = {}
        
    async def process_alert(self, alert_type, data):
        """Process and potentially send an alert."""
        alert_config = self.config.get(alert_type)
        if not alert_config:
            return
        
        # Check if conditions are met
        if not self.evaluate_conditions(alert_config['conditions'], data):
            return
        
        # Check rate limiting
        if self.is_rate_limited(alert_type):
            return
        
        # Execute alert actions
        for action in alert_config['actions']:
            await self.execute_action(action, alert_type, data)
        
        # Record alert
        self.record_alert(alert_type, data)
    
    def evaluate_conditions(self, conditions, data):
        """Evaluate alert conditions."""
        for condition in conditions:
            if not self.evaluate_single_condition(condition, data):
                return False
        return True
    
    async def execute_action(self, action, alert_type, data):
        """Execute alert action."""
        if action == "send_immediate_notification":
            await self.send_notification(alert_type, data, priority="high")
        elif action == "trigger_automatic_restart":
            await self.trigger_restart()
        elif action == "attempt_auto_recovery":
            await self.attempt_recovery(alert_type, data)
        elif action == "run_connectivity_diagnostics":
            await self.run_diagnostics(data)
```

---

*Last Updated: December 28, 2025*
*Home Assistant Version: 2024.12.x*
*Documentation Version: 1.0*