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

## **ZONE DESIGN TEMPLATE**

Use this template for implementing **3-4 remaining zones**:

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

1. **Office Zone** - Desk lighting + ambient + spot lights
2. **Living Room Zone** - Entertainment + ambient + task lighting  
3. **Bedroom Zone** - Wake/sleep cycles + reading + security
4. **Kitchen Zone** - Task + ambient + cabinet lighting

Each zone will follow this same 5-layer architecture for consistent operation and maintenance.