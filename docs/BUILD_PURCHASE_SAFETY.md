# Build purchase collision fix

Build purchases previously created physics-active objects directly in front of the buyer using CAN_COLLIDE. Crowded shops could therefore spawn a vehicle inside another vehicle or structure before the placement callback arrived. Only supply crates used remote staging and disabled collisions during carrying. Build placement also bypassed the supply-only overlap guard.

All build purchases now stage away from the shop with simulation and physics collisions disabled before delivery. Pickup applies the same collision protection to every object, including repeat pickups. Drop/place restore collisions and global simulation after positioning. Floating placement no longer invokes ground snapping. Placement and move checks now cover all build objects against vehicles, players, structures, props and terrain obstacles, excluding the object's own crew.

The shared guard deliberately uses conservative horizontal bounding boxes, including for floating placement, to prevent ground-snap overlap. Construction pieces now ignore scenery and other construction, allowing intentional stacking and interlocking. They still check vehicles and characters, excluding their carrier. Vehicles, NPCs and supply crates retain the full clearance check. It is not an exact geometry or slope solver.

Source checks cover SQF delimiters and the changed lifecycle paths. Arma runtime and dedicated-server physics have not been tested here. Run `tests\buildPurchase.sqf` in a disposable hosted session at Bulwark, plus the existing `tests\supplyShop.sqf`. The new harness checks real build transactions, remote staging, disabled physics, and overlap rejection for a vehicle, crate and fence.

Dedicated-server acceptance: buy empty and crewed vehicles, static weapons, crates and defenses beside a crowded Bulwark; carry through obstacles; verify blocked placement keeps the holding actions; place in clear space and confirm simulation and crew behavior resume; repeat pickup/drop; check two simultaneous buyers and a late-joining client. Check slopes separately. Floating placement preserves the selected initial position; physics-enabled vehicles and crates can still fall under gravity after release.

Engine references: [setPhysicsCollisionFlag](https://community.bistudio.com/wiki/setPhysicsCollisionFlag), [enableSimulationGlobal](https://community.bistudio.com/wiki/enableSimulationGlobal), [attachTo](https://community.bistudio.com/wiki/attachTo).
