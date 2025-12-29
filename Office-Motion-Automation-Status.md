# Office Motion Automation Status Report

## Current Implementation ✅ **ACTIVE IN LIVE SYSTEM**

### **Motion ON Automation** (`id: 1625582030181`)
**Trigger**: Motion detected on `binary_sensor.lumi_lumi_sensor_motion_aq2_occupancy`  
**Condition**: Only if spot lights are currently OFF  

**Time-Based Behavior:**
- **Day Mode (3am-7pm)**:
  - Spot Lights: 75% brightness
  - Desk Stand: 100% brightness  
  - Wall Light: 100% brightness

- **Evening Mode (7pm-3am)**:
  - Spot Lights: 15% brightness (dim ambient)
  - Desk Stand: 25% brightness (minimal)
  - Wall Light: Not specified (likely full brightness)

### **Motion OFF Automation** (`id: 1624577180319`)
**Trigger**: No motion for 20 minutes  
**Action**: Turn OFF all office lights (spot + desk + wall)

---

## Issues with Current System 🔄

1. **Complexity**: Time-based brightness calculations in automation
2. **Inconsistent**: Evening mode doesn't control wall light properly
3. **Not Voice-Friendly**: No connection to scene system
4. **Hard to Override**: Complex conditional logic difficult to modify
5. **Maintenance**: Device IDs make it brittle for device changes

---

## Recommended Upgrade: Scene-Based Motion System 🎯

### **Proposed Simple Automation**
Replace complex brightness calculations with clean scene triggers:

```yaml
- alias: "Office Smart Motion - Scene Based"
  trigger:
    - platform: state
      entity_id: binary_sensor.lumi_lumi_sensor_motion_aq2_occupancy
      to: 'on'
  condition:
    - condition: state
      entity_id: light.office_spot_lights
      state: 'off'
  action:
    - choose:
        # Work hours - full productivity lighting
        - conditions:
            - condition: time
              after: '06:00:00'
              before: '18:00:00'
          sequence:
            - service: scene.turn_on
              target:
                entity_id: scene.office_work_mode

        # Entertainment hours - ambient lighting  
        - conditions:
            - condition: time
              after: '18:00:00'
              before: '23:00:00'
          sequence:
            - service: scene.turn_on
              target:
                entity_id: scene.office_gaming_mode

        # Late night - minimal lighting
        - conditions:
            - condition: time
              after: '23:00:00'
              before: '06:00:00'
          sequence:
            - service: scene.turn_on
              target:
                entity_id: scene.office_tv_mode

# OFF automation remains the same - works well
- alias: "Office Motion Off"
  trigger:
    - platform: state
      entity_id: binary_sensor.lumi_lumi_sensor_motion_aq2_occupancy
      to: 'off'
      for:
        minutes: 20
  action:
    - service: scene.turn_on
      target:
        entity_id: scene.office_off
```

### **Benefits of Upgrade**
- **Consistency**: Same lighting whether triggered by motion, voice, or dashboard
- **Maintainability**: Scene changes automatically apply to motion system
- **Voice Integration**: Motion system uses same scenes as "Alexa, office work mode"
- **Flexibility**: Easy to adjust scenes without touching automation logic
- **Reliability**: Entity IDs instead of device IDs for better stability

---

## Implementation Options

### **Option 1: Full Replacement** 
- Disable current automations
- Implement new scene-based system
- **Risk**: Motion control temporarily offline during transition

### **Option 2: Parallel Testing** 
- Keep current system active
- Add new automation with different entity trigger
- Test thoroughly before switching over
- **Safer**: Motion continues working during testing

### **Option 3: Gradual Migration**
- Modify existing automation to call scenes instead of direct device control
- Keep same time logic, replace actions with scene calls
- **Hybrid**: Minimal disruption, easier rollback

---

## Current Status: **READY FOR IMPLEMENTATION**

✅ **Office scenes created and tested**  
✅ **Dashboard integration confirmed working**  
✅ **Current automation analyzed and documented**  
🔄 **Awaiting decision on implementation approach**

**Recommendation**: Start with **Option 2 (Parallel Testing)** to validate scene-based approach before replacing current working system.