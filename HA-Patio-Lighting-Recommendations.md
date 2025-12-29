# Home Assistant Patio Lighting Research & Recommendations

## Core Concepts and When to Use Them
- **Integrations** bring a platform into Home Assistant (e.g., Philips Hue, Lutron, Ring). Use an integration when you need HA to discover and sync device capabilities and events from that ecosystem.
- **Devices** are the physical or logical things provided by an integration (bridge hubs, dimmers, sensors). They group multiple entities that belong to the same hardware.
- **Entities** are the controllable or readable endpoints in HA (lights, switches, sensors). Use them for day-to-day control, dashboards, and automations.
- **Groups** aggregate multiple entities under a single entity ID. Use a light or switch group to control multiple fixtures together (on/off/brightness if supported by members) and simplify automations.
- **Scenes** capture a target state for one or more entities (color, brightness, on/off). Use them for repeatable “palettes” and mood presets.
- **Automations** tie triggers (time, state, event, webhook) to conditions and actions. Use automations to activate scenes, toggle groups, and respond to sensor/button events.

## Integration/Entity Attribute Differences
- **Common light attributes**: `state` (on/off), `brightness` (0–255), and `color_temp` or `color_temp_kelvin` where supported.
- **Hue lights** typically expose color controls (`hs_color`, `rgb_color`, `xy_color`, and effects) plus color temperature. Hue groups expose aggregated attributes and scene lists.
- **Lutron lights** often provide reliable dimming (`brightness`) and on/off without color; color attributes are absent. Automation YAML should be tolerant of missing color keys by only setting attributes supported by that device class.
- **Recommendation:** Create scenes that set only the attributes shared by all targeted lights (state + brightness) and layer optional color values only on the Hue entities to avoid service call failures.

## What Is Working in the Current Patio Configuration
- **Patio group coverage:** A `group.patio_lights` entity collects the pathway switch, two Hue color bulbs, and the outdoor wall light for whole-patio control; there is also a `patio_color_lights` group for the color-capable fixtures.【F:groups.yaml†L1-L16】
- **Scenes exist for key moods:** `Patio Florida` (warm orange with pathway on, flood off), `Patio Bright`, `Patio Dim`, and `Patio Off` already define palettes and include pathway/flood handling.【F:scenes.yaml†L133-L276】
- **Manual button triggers:** Hall switch button events 1–3 call the patio off/evening/bright scenes for quick control.【F:automations.yaml†L151-L173】
- **Scheduled routines:** Automation turns patio lights on 15 minutes before sunset and off at 23:30 via the group entity, confirming time-based control is in place.【F:automations.yaml†L208-L232】

## Current Gaps / Risks
- The patio UI/card strategy is not defined; there is no documented Lovelace card layout for multi-light control or palette selection.
- Color palettes are fixed in YAML scenes; adding more options (e.g., seasonal colors) will require new scenes unless a helper-driven approach is adopted.
- `Patio Bright` includes three DEWENWILS transformer switch entities marked `unavailable`, so flood/pathway power may be inconsistent until those entities are repaired or removed.【F:scenes.yaml†L219-L244】
- No geo-location or Ring motion triggers are configured for patio scenes, and only button events and scheduled times currently drive scene changes.【F:automations.yaml†L151-L232】

## Recommended Patio Palette & Card Strategy
1. **Create a Light Group (if not already in UI):** Confirm `group.patio_lights` is exposed as a light (via `platform: group` or UI) for unified dimming where supported. If dimming is needed across Hue bulbs only, use `patio_color_lights`.
2. **Build a multi-light Lovelace card:**
   - Use the built-in **Light card** or **Mushroom Light card** with `entity: group.patio_lights` for master on/off and brightness, and add sub-entities for individual Hue bulbs and the flood.
   - Add a **Scene card** or **Mushroom Chips** row that lists `scene.patio_evening`, `scene.patio_bright`, `scene.patio_dim`, and `scene.patio_off` for one-tap palettes.
3. **Stock palette patterns (add as scenes):**
   - *Sunset Social:* Hue colors to warm amber (`xy_color: [0.56, 0.38]`), brightness 180; flood on at 80%; pathway on.
   - *Movie Night:* Hue bulbs dim to 40% cool white, flood off, pathway on at low level.
   - *Party Cycle:* Use Hue `effect: colorloop` on the two color bulbs, flood on at 60%, pathway on.
   - Keep scenes device-specific: set Hue color attributes only on Hue entities, and only `state`/`brightness` on non-color lights.
4. **Parameterize palettes with helpers (optional):** Use **input_select** for palette names and a **Choose** action in a single automation to call the matching scene, so you can expand palettes without new automations.

## Automation Patterns for the Patio
- **Time-based:** Already present (sunset on, 23:30 off). Extend with a pre-dawn off check or weekday/weekend variations by adding more triggers and conditions to the existing time automation.【F:automations.yaml†L208-L232】
- **Geo-location:** Trigger a welcome scene when a person enters a home zone after sunset. Example:
  ```yaml
  trigger:
    - platform: zone
      entity_id: person.you
      zone: zone.home
      event: enter
  condition:
    - condition: sun
      after: sunset
  action:
    - service: scene.turn_on
      target:
        entity_id: scene.patio_evening
  ```
- **Ring motion/doorbell:** Use the Ring integration’s motion or ding events to start a temporary bright scene with a timer to revert:
  ```yaml
  trigger:
    - platform: state
      entity_id: binary_sensor.front_door_motion
      to: 'on'
  action:
    - service: scene.turn_on
      target:
        entity_id: scene.patio_bright
    - delay: '00:05:00'
    - service: scene.turn_on
      target:
        entity_id: scene.patio_dim
  ```
- **Button presses:** Keep existing hall button mappings and add long-press/double-press variants (if supported) to call the new palette scenes using `event` triggers filtered on `event_data` (button, action).

## Color and Brightness Schema Guidance
- Use **brightness_pct** in automations for dimming consistency across mixed devices; for Hue-specific colors, set `xy_color` or `rgb_color` only on Hue entities.
- Avoid setting `color_temp` on lights that don’t advertise `color_temp`/`color_temp_kelvin` in their `supported_color_modes` (e.g., many Lutron dimmers). Scenes should include per-entity attributes exactly as supported to prevent warnings.
- If a scene needs both Hue colors and non-Hue dimming, split entities: apply color values to Hue bulbs, and only on/off/brightness to the others.

## Step-by-Step Patio Example
1. **Define a new palette scene (YAML):**
   ```yaml
   - id: patio_sunset_social
     name: Patio Sunset Social
     entities:
       switch.patio_pathway_lights: {state: 'on'}
       light.hue_color_lamp_1: {state: 'on', brightness: 180, xy_color: [0.56, 0.38]}
       light.bedroom1: {state: 'on', brightness: 180, xy_color: [0.56, 0.38]}
       light.hue_outdoor_wall_1: {state: 'on', brightness: 200}
   ```
2. **Expose scenes on the dashboard:** Add a Scene card listing the patio scenes plus the new palette; optionally use a conditional card to hide color scenes when lights are off.
3. **Automation to follow time + motion:**
   ```yaml
   trigger:
     - platform: sun
       event: sunset
       offset: '-00:30:00'
     - platform: state
       entity_id: binary_sensor.front_door_motion
       to: 'on'
   condition:
     - condition: sun
       after: sunset
   action:
     - choose:
         - conditions:
             - condition: trigger
               id: 'sunset'
           sequence:
             - service: scene.turn_on
               target: {entity_id: scene.patio_sunset_social}
         - conditions:
             - condition: trigger
               id: 'motion'
           sequence:
             - service: scene.turn_on
               target: {entity_id: scene.patio_bright}
             - delay: '00:05:00'
             - service: scene.turn_on
               target: {entity_id: scene.patio_dim}
   ```
4. **Geo + button overrides:** Add a second automation that listens for the hall button double-press to toggle between `Patio Off` and `Patio Bright`, and a zone trigger to call `Patio Florida` when arriving home on weekend evenings.

## Next Steps
- Fix or remove the unavailable DEWENWILS switch entities in `Patio Bright` so the scene reliably controls the flood/patio power feed.【F:scenes.yaml†L219-L244】
- Add the proposed palette scenes to `scenes.yaml`, expose them in a Lovelace Scene card, and wire them to button, Ring, and geo triggers as outlined above.
- Standardize on `patio_color_lights` for color effects and `group.patio_lights` for whole-area on/off to simplify cards and automations.【F:groups.yaml†L2-L16】

## How to Test the New Patio Palettes in Home Assistant
1. **Reload scenes (if you edited YAML):** In *Developer Tools → YAML*, run *Scene: Reload* (or restart HA) so the new palettes appear.
2. **Verify entities resolve:** Open *Developer Tools → States* and confirm the scene entities (e.g., `scene.patio_all_off`, `scene.patio_normal`, `scene.patio_grill_max`, `scene.patio_florida_dimmed`) exist and are not `unknown`.
3. **One-tap activation:** In *Overview*, add a *Scene* card (or Mushroom Chips) with the four patio palettes and tap each one to ensure lights change on/off/brightness/color as expected.
4. **Spot-check attributes:**
   - Hue bulbs: confirm `state:on`, `brightness` ≈ 75% for *Normal*, 100% for *Grill/Max*, and amber/red tone for *Florida Dimmed*.
   - Pathway switch: on for all except *All Off*.
   - Flood: off for *All Off/Normal/Florida Dimmed*; on for *Grill/Max*.
5. **Automation dry-runs:** From *Developer Tools → Services*, call `scene.turn_on` with each scene target. Watch the *Logbook* to confirm no service errors about unsupported attributes (especially on non-Hue devices).
6. **Button/time triggers (optional):** If you map these palettes to existing button or time automations, temporarily set the trigger to *Run* in the Automation editor to confirm they activate the right scene and return to the expected default afterward.
