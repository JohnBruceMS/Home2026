# Home Assistant Zone Design Reference

*Template and reference for implementing comprehensive lighting zones across multiple interfaces*

## Design Philosophy

Each lighting zone follows a **5-layer architecture** that ensures consistent control across physical switches, voice commands, dashboards, and automation triggers:

1. **Devices** → Individual hardware components
2. **Groups** → Logical device collections  
3. **Scenes** → Predefined lighting states
4. **Automation** → Triggers and scheduling
5. **Interfaces** → UI, physical, and voice control

---

## **PATIO ZONE** ✅ *[Reference Implementation]*

### **Layer 1: Devices**
| Device | Entity ID | Type | Capabilities |
|--------|-----------|------|--------------|
| Pathway Switch | `switch.patio_pathway_lights` | On/Off Switch | Binary only |
| Patio Left Bulb | `light.hue_color_lamp_1` | Hue Color | RGB + Brightness + Color Temp |
| Patio Right Bulb | `light.bedroom1` | Hue Color | RGB + Brightness + Color Temp |
| Flood Light | `light.hue_outdoor_wall_1` | Hue Outdoor | Brightness only |

### **Layer 2: Groups** 📍*[groups.yaml]*
```yaml
# All devices for zone control
patio_lights:
  name: All Patio
  entities:
    - switch.patio_pathway_lights
    - light.hue_color_lamp_1
    - light.bedroom1  
    - light.hue_outdoor_wall_1

# Color-capable subset for advanced scenes
patio_color_lights:
  name: Patio Color Lights
  entities:
    - light.hue_color_lamp_1
    - light.bedroom1
```

### **Layer 3: Scenes** 📍*[scenes.yaml]*

| Scene ID | Name | Use Case | Pathway | Color Bulbs | Flood | 
|----------|------|----------|---------|-------------|--------|
| `patio_all_off` | Patio All Off | End of evening | OFF | OFF | OFF |
| `patio_normal` | Patio Normal | Standard evening | ON | 75% warm white | OFF |
| `patio_grill_max` | Patio Grill / Max | Cooking/tasks | ON | 100% bright white | ON 100% |
| `patio_florida_dimmed` | Patio Florida Dimmed | Wildlife-safe | ON | 47% amber turtle-safe | OFF |

**Scene Implementation Pattern:**
```yaml
- id: patio_normal
  name: Patio Normal
  entities:
    switch.patio_pathway_lights:
      state: 'on'
    light.hue_color_lamp_1:
      state: 'on'
      brightness: 191  # ~75%
      color_temp: 370  # warm tint
    light.bedroom1:
      state: 'on'
      brightness: 191  # ~75%
      color_temp: 370  # warm tint
    light.hue_outdoor_wall_1:
      state: 'off'
  icon: mdi:lightbulb-on-outline
```

### **Layer 4: Automation** 📍*[automations.yaml]*

#### **Physical Switch Integration**
- **Hall Switch Button 1** → `scene.patio_all_off` *(shutdown)*
- **Hall Switch Button 2** → `scene.patio_florida_dimmed` *(wildlife mode)*  
- **Hall Switch Button 3** → `scene.patio_grill_max` *(task lighting)*
- **Hall Switch Button 4** → `scene.patio_normal` *(standard)*

#### **Scheduled Automation**
- **Sunset -15 min** → Turn on `group.patio_lights` *(basic activation)*
- **11:30 PM** → Turn off `group.patio_lights` *(bedtime shutdown)*

```yaml
# Physical switch example
- id: '1632861074337'
  alias: Patio All Off Scene
  description: 'Button 1: Turn off all patio lights'
  trigger:
  - platform: state
    entity_id: event.hall_switch_button_1
  action:
  - service: scene.turn_on
    target:
      entity_id: scene.patio_all_off
```

### **Layer 5: Interfaces**

#### **Physical Control** ✅
- Hall switch with 4-button scene mapping
- Individual device wall switches

#### **Dashboard/UI** ✅  
- Group controls for zone-wide on/off
- Individual scene buttons for mood selection
- Entity cards for device-level control

#### **Voice Control** 🔄 *(Ready - needs testing)*
- "Alexa, turn on patio normal"
- "Alexa, activate patio grill max" 
- "Alexa, turn off patio lights"

#### **Steam Deck/Mobile** 🔄 *(Ready via HA Companion)*
- Full scene access through mobile app
- Same interface as desktop dashboard

---

## **OFFICE ZONE** ✅ *[FULLY DEPLOYED & OPERATIONAL]*

### **Layer 1: Devices**
| Device | Entity ID | Type | Capabilities |
|--------|-----------|------|--------------|  
| Spot Lights | `light.office_spot_lights` | Track Lighting | Brightness only |
| Desk Stand | `light.office_stand` | Hue Color | RGB + Brightness + Color Temp |
| Wall Light | `light.wall` | Hue Color | RGB + Brightness + Color Temp |
| Office Shade | `cover.office_shade` | Lutron Caséta Shade | Position control (open/close/%) |
| Motion Sensor | `binary_sensor.lumi_lumi_sensor_motion_aq2_occupancy` | Xiaomi Motion | Motion detection |
| Hue Group | `light.office` | Hue Room Group | Controls stand + wall together |

### **Layer 2: Groups** 📍*[groups.yaml - ✅ UPDATED]*
```yaml
# All office lighting devices
office_lights:
  name: All Office
  entities:
    - light.office_spot_lights
    - light.office_stand
    - light.wall

# Color-capable lights for advanced scenes
office_color_lights:
  name: Office Color Lights
  entities:
    - light.office_stand
    - light.wall

# Complete environment control (lights + shade)
office_environment:
  name: Office Environment
  entities:
    - light.office_spot_lights
    - light.office_stand  
    - light.wall
    - cover.office_shade
```

### **Layer 3: Scenes** 📍*[scenes.yaml - ✅ UPDATED]*

**Voice-Friendly Scene Design Based on Actual Use Cases:**

| Scene ID | Voice Name | Use Case | Spot Lights | Desk Stand | Wall Light |
|----------|------------|----------|-------------|------------|------------|
| `office_off` | "Office Off" | Complete shutdown | OFF | OFF | OFF |
| `office_work_mode` | "Office Work Mode" | Productive work (6am-6pm) | **100% primary** | 100% warm white | 100% warm white |
| `office_gaming_mode` | "Office Gaming Mode" | Gaming/entertainment (6pm-6am) | **OFF** | 70% **orange tint** | 70% **orange tint** |

**2-Mode System Design:**
- **Work Mode (6am-6pm)**: Spot lights provide primary task lighting + Hue devices complement with warm bright
- **Gaming Mode (6pm-6am)**: No spot lights + Orange ambient lighting for all entertainment (gaming, TV, reading)
- **Voice Commands**: "Alexa, turn on office work mode" / "Alexa, activate office gaming mode"

### **Layer 4: Automation** 📍*[automations.yaml - ✅ COMPLETED & DEPLOYED]*

**✅ ACTIVE: 2-Mode Scene-Based Motion System**

#### **Implemented Smart Motion Automation**
**Time-Aware Scene Selection:**
- **Work Hours (6am-6pm)** → Motion triggers `scene.office_work_mode`
- **Gaming Hours (6pm-6am)** → Motion triggers `scene.office_gaming_mode` 
- **No Motion (15 min timeout)** → `scene.office_off`

**Active Automation IDs:**
- `1735519800000`: Office Smart Motion - Work & Gaming Modes
- `1735519800001`: Office Motion Off - 15 Minute Timer

**Achieved Benefits:**
- **✅ Consistent**: Same lighting whether motion, voice, or dashboard triggered
- **✅ Simple**: Clean time-based logic with scene integration
- **✅ Reliable**: 15-minute timeout tested and optimized
- **✅ Maintainable**: Scene changes automatically apply to motion system
            - condition: time
              after: '06:00:00'
              before: '18:00:00'
          sequence:
            - service: scene.turn_on
              target:
                entity_id: scene.office_work_mode
        # Evening gaming - ambient lighting  
        - conditions:
            - condition: time
              after: '18:00:00'
              before: '23:00:00'
          sequence:
            - service: scene.turn_on
              target:
                entity_id: scene.office_gaming_mode
        # Late night - minimal TV lighting
        default:
          - service: scene.turn_on
            target:
              entity_id: scene.office_tv_mode
```

### **Layer 5: Interfaces**

#### **Physical Control** ✅ *[MOTION ACTIVE, STREAM DECK READY]*
- ✅ Motion sensor: 15-min timeout, 2-mode time-based scenes
- 🔄 Stream Deck: Ready for 3 scene buttons (Work/Gaming/Off)
- ✅ Individual wall switches: Available for manual override

#### **Dashboard/UI** ✅ *[INTEGRATED & TESTED]*
- Individual device controls integrated in lovelace_overlook1
- Scene grid with 4 clean scene buttons (Work/Gaming/TV/Off)
- Horizontal layout matching patio zone pattern
- **Testing Status**: User confirmed "they look good" after live testing

#### **Voice Control** ✅ *[READY]*
- "Alexa, turn on office work mode"
- "Alexa, activate office gaming mode" 
- "Alexa, turn off office lights"

---

## **ZONE DESIGN TEMPLATE**

Use this template for implementing **2-3 remaining zones**:

### **Step 1: Device Inventory**
```yaml
# Device audit checklist
- [ ] List all physical devices in zone
- [ ] Identify entity IDs in HA
- [ ] Document capabilities (on/off, brightness, color, temperature)
- [ ] Test individual device control
- [ ] Note any unavailable/problematic entities
```

### **Step 2: Group Creation** 📍*[groups.yaml]*
```yaml
# Zone group template
[zone_name]_lights:
  name: All [Zone Name]
  entities:
    - [device_entity_1]
    - [device_entity_2]
    - [device_entity_3]

# Optional: Capability-specific subgroups
[zone_name]_color_lights:
  name: [Zone Name] Color Lights  
  entities:
    - [color_capable_entity_1]
    - [color_capable_entity_2]
```

### **Step 3: Scene Design** 📍*[scenes.yaml]*

**Standard Scene Set:**
- `[zone]_all_off` - Complete shutdown
- `[zone]_normal` - Default evening mode  
- `[zone]_bright` - Task/activity lighting
- `[zone]_dim` - Low-level ambient

**Specialized Scenes** *(as needed)*:
- Wildlife/security considerations
- Entertainment modes
- Sleep/wake cycles

### **Step 4: Automation Planning** 📍*[automations.yaml]*

**Physical Triggers:**
- Wall switch button mappings
- Motion sensor activation
- Door/window sensors

**Scheduled Triggers:**
- Sunset/sunrise offsets
- Bedtime routines  
- Wake schedules

**Conditional Logic:**
- Occupancy detection
- Time-of-day restrictions
- Weather/season adjustments

### **Step 5: Interface Implementation**

**Dashboard Integration:**
- Zone group cards
- Scene selection buttons
- Individual device controls

**Voice Optimization:**
- Test natural language commands
- Consider scene name clarity
- Add aliases if needed

**Physical Control:**
- Map available switches/buttons
- Ensure scene consistency across interfaces
- Test automation reliability

---

## **IMPLEMENTATION CHECKLIST**

### **Per Zone:**
- [ ] **Device audit** - All entities identified and working
- [ ] **Group creation** - Logical device collections defined
- [ ] **Scene design** - 4+ mood presets implemented  
- [ ] **Automation setup** - Physical + scheduled triggers
- [ ] **Interface testing** - Dashboard, voice, physical controls
- [ ] **Documentation** - Zone details added to this reference

### **System-Wide:**
- [ ] **Naming consistency** - Voice-friendly scene names
- [ ] **Icon standardization** - Meaningful visual cues
- [ ] **Performance testing** - All triggers respond quickly
- [ ] **Backup configuration** - All changes committed to Git
- [ ] **User training** - Family members know how to use controls

---

## **LESSONS LEARNED** *(Patio Implementation)*

### **✅ What Worked Well**
- **Scene-based design**: Consistent experience across all interfaces
- **Group abstractions**: Easy zone-wide control and automation
- **Physical + digital sync**: Same scenes available everywhere
- **Descriptive naming**: Clear purpose for each scene
- **Layered complexity**: Simple on/off → advanced color scenes

### **⚠️ Challenges Encountered**  
- **Entity availability**: Some devices show `unavailable` in scenes
- **Device naming**: Entity IDs don't match physical location (`bedroom1` → Patio Right)
- **Voice compatibility**: Long scene names may be awkward for voice commands
- **Automation complexity**: Multiple trigger types require careful testing

### **🔧 Best Practices**
- **Test each layer independently** before combining
- **Use consistent naming patterns** across zones
- **Document entity mappings** for future maintenance  
- **Keep scenes simple and focused** on specific use cases
- **Always include an "all off" scene** for each zone
- **Group automation by trigger type** for easier maintenance

---

## **FUTURE ZONE TARGETS**

1. **Office Zone** - ✅ *In Progress* - Desk lighting + ambient + spot lights + Stream Deck control
2. **Living Room Zone** - Entertainment + ambient + task lighting  
3. **Bedroom Zone** - Wake/sleep cycles + reading + security
4. **Kitchen Zone** - Task + ambient + cabinet lighting

Each zone will follow this same 5-layer architecture for consistent operation and maintenance.