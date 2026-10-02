# Elevator System: High-Level Design

**Asked at:** Amazon, Microsoft, Uber, Bloomberg, Google (mostly as an LLD / object-oriented design question). **Core topics:** the HLD version is a building control system: per-building controllers that must work offline, dispatch algorithms, safety layers, and a cloud fleet for monitoring and maintenance.

Ask early which one the interviewer wants. Most "design an elevator" rounds are LLD; see [LLD.md](LLD.md). This file covers the system around the elevators.

## 1. Clarify the scope

| Question | Assumed answer |
|---|---|
| One building or a fleet? | A vendor operating ~50,000 elevators in ~10,000 buildings, with cloud monitoring. |
| Per building? | 1-20 elevators (a group), up to ~100 floors. |
| Calls? | Hall calls (up/down buttons per floor) and car calls (floor buttons inside); optionally destination dispatch (choose the floor in the lobby, get assigned a car). |
| Goals? | Minimize average wait and journey time; never violate safety; handle peaks (morning up-peak, lunch, evening down-peak). |
| Modes? | Normal, maintenance, fire service, out of service, VIP. |

## 2. Requirements

**Functional:** accept calls, assign hall calls to cars, move cars and open doors, show car positions on floor displays, support special modes, report telemetry and faults.

**Non-functional:**

- **Safety first:** independent of software scheduling (hardware interlocks, brakes, door sensors, overspeed governors).
- **Works without the network:** the cloud is for monitoring, never in the control loop.
- **Low latency:** button press to assignment in well under a second.
- **Reliability:** a failed car must not stop the group.

## 3. Capacity estimates

| Quantity | Math | Result |
|---|---|---|
| Calls per building | a 50-floor office: ~5,000 trips/day, peak ~10/s | tiny for a local controller |
| Telemetry | 50,000 elevators x 1 event/s (position, door state, load, faults) | **~50K events/s** to the cloud |
| Storage | 50K/s x 100 B x 86,400 | **~430 GB/day** of telemetry |

The control problem is local and small; the cloud problem is ordinary IoT telemetry ingestion.

## 4. Architecture

```text
 Building (edge, works offline)
   hall buttons, car buttons, floor displays
            |
   Group controller (dispatcher)  <-- one per elevator group; hot standby
      |  assigns hall calls by cost; adjusts for traffic mode (up-peak, down-peak)
      v
   Car controllers (one per elevator): motion profile, doors, load sensor, stops list
      |
   Safety layer (hardware): door interlocks, brakes, governor, emergency stop   (cannot be overridden by software)
            |
   Gateway --(MQTT, store-and-forward when offline)--> Cloud
                                                        telemetry ingestion (Kafka) --> time-series DB
                                                        fault detection / predictive maintenance
                                                        technician dispatch, dashboards, remote config
```

## 5. Deep dive: dispatching

- **Per-car scheduling (LOOK / elevator algorithm):** keep moving in the current direction while there are stops ahead; reverse when none remain; idle when empty. Avoids starvation and zig-zagging.
- **Group dispatching (which car takes a hall call):** compute a cost per car: distance if the call is ahead in the car's direction and wants the same direction; otherwise distance to the car's turnaround point plus back. Pick the minimum. Real systems add estimated stops in between, load, and energy.
- **Traffic modes:** up-peak (send idle cars to the lobby), down-peak (park cars at upper zones), zoning (cars serve floor ranges in very tall buildings).
- **Destination dispatch:** passengers enter their floor in the lobby; the system groups people going to nearby floors into the same car (fewer stops per trip, higher capacity).
- **Reassignment:** if a car becomes unavailable (fault, overloaded, maintenance), its hall calls go back to the dispatcher.

## 6. Deep dive: safety and modes

- Software decides **where** to go; hardware decides whether it is **safe** to move. Door must be locked to move; overspeed triggers the governor and safety brakes.
- **Fire service:** cars return to a designated floor and open; then only firefighter control.
- **Overload:** doors stay open and a buzzer sounds until the load drops.
- **Maintenance / out of service:** the car leaves the group; calls reassigned.

## 7. Failure modes

| Failure | Behavior |
|---|---|
| Group controller fails | Hot standby takes over; car controllers continue current stops; worst case, each car serves its own car calls and fixed hall calls. |
| Car fault | Car removed from dispatch; passengers released at the nearest floor if safe; alert to the cloud. |
| Network down | No effect on operation; telemetry buffered and sent later. |
| Power failure | Emergency power lowers cars to the nearest floor (rescue operation). |

## 8. What interviewers look for

- Clear separation: control (local, real-time), safety (hardware), monitoring (cloud).
- A real scheduling policy (LOOK) and a dispatch cost function, with reassignment.
- Modes and edge cases (overload, fire, out of service).

## 9. Common mistakes

- Putting the cloud in the control path.
- First-come-first-served scheduling (zig-zagging, terrible wait times).
- Ignoring direction when assigning hall calls.
- Forgetting failures and special modes.

## 10. Follow-ups

1. **Predictive maintenance:** door cycle counts, motor current anomalies, vibration trends.
2. **Energy optimization:** regenerative drives, parking idle cars, fewer starts.
3. **Access control:** badges restrict floors; integrates with the dispatcher.
4. **Simulation:** test dispatch policies against recorded traffic.

See [LLD.md](LLD.md) for the classes: elevators with LOOK scheduling, a cost-based dispatcher, the controller, and out-of-service reassignment.
