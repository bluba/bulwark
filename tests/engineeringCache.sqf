/* Disposable idle server/editor only: [] execVM "tests\engineeringCache.sqf";
   Normal mission loop stopped, neither cache active, living WEST human on land.
   Uses real manifests/workers/cargo. Finds two real safe sites first, then swaps
   the position selector and transport for deterministic stock/lifecycle tests.
   See docs/SUPPLY_CACHES.md for required multiplayer and native-tool checks.
*/
if (!isServer || {isRemoteExecuted} || {!canSuspend}) exitWith {};
if (missionNamespace getVariable ["runMissionLoop", false] ||
    {count (missionNamespace getVariable ["BW_SUPPLY_CACHE", createHashMap]) > 0} ||
    {count (missionNamespace getVariable ["BW_ENGINEERING_CACHE", createHashMap]) > 0}) exitWith {
    diag_log "ENGINEERING test requires an idle mission and no cache workers";
};
private _players = [] call bulwark_fnc_readyVoters;
if (_players isEqualTo []) exitWith {diag_log "ENGINEERING test requires a living WEST human"};
private _origin = getPosATL (_players select 0);
private _siteA = [_origin] call loot_fnc_findSupplySite;
if (_siteA isEqualTo []) exitWith {diag_log "ENGINEERING test: no first safe site"};
private _siteB = [_origin, [_siteA]] call loot_fnc_findSupplySite;
if (_siteB isEqualTo []) exitWith {diag_log "ENGINEERING test: no second separated safe site"};
private _names = ["BW_SUPPLY_CACHE", "BW_SUPPLY_SERIAL", "BW_SUPPLY_LAST_ATTEMPT", "BW_SUPPLY_LAST_RESULT", "BW_SUPPLY_STATUS",
    "BW_ENGINEERING_CACHE", "BW_ENGINEERING_LAST_ATTEMPT", "BW_ENGINEERING_LAST_RESULT", "BW_ENGINEERING_STATUS",
    "BW_SUPPLY_ENABLED", "BW_SUPPLY_CHANCE", "BW_SUPPLY_CLASS", "BW_SUPPLY_STOCK", "BW_SUPPLY_LIFETIME", "BW_SUPPLY_RELOCATION",
    "BW_ENGINEERING_ENABLED", "BW_ENGINEERING_CHANCE", "BW_ENGINEERING_CLASS", "BW_ENGINEERING_AP_POOL", "BW_ENGINEERING_AT_POOL",
    "BW_ENGINEERING_GRENADE_POOL", "BW_ENGINEERING_SMOKE_POOL", "BW_ENGINEERING_TOOLS", "BW_ENGINEERING_AP_COUNT", "BW_ENGINEERING_AT_COUNT", "BW_ENGINEERING_GRENADE_COUNT",
    "LOOT_WHITELIST_MODE", "LOOT_WHITELIST_ITEM", "LOOT_WHITELIST_EXPLOSIVE", "LOOT_BLACKLIST",
    "runMissionLoop", "missionExtract", "buildPhase", "attkWave", "bulwarkBox", "loot_fnc_deliverSupplyCache", "BW_SUPPLY_DELIVERY_STATUS", "BW_ENGINEERING_DELIVERY_STATUS", "loot_fnc_findSupplySite", "loot_fnc_supplyManifest",
    "BW_engineeringTestSites"];
private _saved = _names apply {[!isNil _x, missionNamespace getVariable [_x, false]]};
private _failures = [];
private _check = {params ["_ok", "_label"]; if (!_ok) then {_failures pushBack _label; diag_log ("ENGINEERING FAIL: " + _label)}};
private _wait = {
    params ["_condition"];
    private _deadline = diag_tickTime + 5;
    waitUntil {sleep 0.1; call _condition || {diag_tickTime >= _deadline}};
    call _condition
};
private _anchor = createVehicle ["Land_HelipadEmpty_F", _origin, [], 0, "CAN_COLLIDE"];
bulwarkBox = _anchor;
BW_SUPPLY_CACHE = createHashMap; BW_ENGINEERING_CACHE = createHashMap;
BW_SUPPLY_LAST_ATTEMPT = -1; BW_ENGINEERING_LAST_ATTEMPT = -1; BW_SUPPLY_SERIAL = 0;
BW_SUPPLY_STATUS = []; BW_ENGINEERING_STATUS = [];
BW_SUPPLY_ENABLED = true; BW_ENGINEERING_ENABLED = true;
BW_SUPPLY_CHANCE = 1; BW_ENGINEERING_CHANCE = 1;
BW_SUPPLY_CLASS = "Box_NATO_Equip_F"; BW_ENGINEERING_CLASS = "Box_NATO_Equip_F";
BW_SUPPLY_STOCK = [["FirstAidKit",6],["Medikit",1]]; BW_SUPPLY_LIFETIME = 180; BW_SUPPLY_RELOCATION = 75;
BW_ENGINEERING_AP_POOL = ["APERSMine_Range_Mag", "APERSBoundingMine_Range_Mag", "APERSTripMine_Wire_Mag"];
BW_ENGINEERING_AT_POOL = ["ATMine_Range_Mag", "SLAMDirectionalMine_Wire_Mag"];
BW_ENGINEERING_GRENADE_POOL = ["HandGrenade", "MiniGrenade"];
BW_ENGINEERING_SMOKE_POOL = ["SmokeShell"]; BW_ENGINEERING_TOOLS = ["MineDetector", "ToolKit"];
BW_ENGINEERING_AP_COUNT = [1,2]; BW_ENGINEERING_AT_COUNT = [1,2]; BW_ENGINEERING_GRENADE_COUNT = [1,3];
LOOT_BLACKLIST = []; LOOT_WHITELIST_MODE = 0; LOOT_WHITELIST_ITEM = []; LOOT_WHITELIST_EXPLOSIVE = [];
runMissionLoop = true; missionExtract = false; buildPhase = false; attkWave = 1;
BW_engineeringTestSites = [_siteA, _siteB];
loot_fnc_findSupplySite = {
    params ["_anchor", ["_exclude", []]];
    +(BW_engineeringTestSites select (if (_exclude isEqualTo []) then {0} else {1}))
};

// Stock/lifecycle harness: delivery itself is exercised by tests/supplyDelivery.sqf.
loot_fnc_deliverSupplyCache = {
    params ["_id", ["_family", "medical"]];
    private _keys = [_family] call loot_fnc_supplyFamily;
    private _record = missionNamespace getVariable [_keys select 0, createHashMap];
    if ((_record getOrDefault ["id", -1]) != _id) exitWith {"fixtureCancelled"};
    private _crate = createVehicle [_record get "class", _record get "site", [], 0, "CAN_COLLIDE"];
    _record set ["crate", _crate];
    _record set ["state", "landed"];
    _crate setVariable ["bw_supplyCacheId", _id, true];
    _crate setVariable ["bw_supplyFamily", _family, true];
    ""
};
private _quantity = {params ["_manifest", "_pool"]; private _total = 0; {if ((_x select 1) in _pool) then {_total = _total + (_x select 2)}} forEach _manifest; _total};
[(call loot_fnc_supplyManifest) isEqualTo [["item","FirstAidKit",6],["item","Medikit",1]], "medical manifest unchanged"] call _check;
for "_i" from 1 to 100 do {
    private _manifest = ["engineering"] call loot_fnc_supplyManifest;
    private _ap = [_manifest, BW_ENGINEERING_AP_POOL] call _quantity;
    private _at = [_manifest, BW_ENGINEERING_AT_POOL] call _quantity;
    private _frag = [_manifest, BW_ENGINEERING_GRENADE_POOL] call _quantity;
    [_ap >= 1 && {_ap <= 2} && {_at >= 1} && {_at <= 2} && {_frag >= 1} && {_frag <= 3}, "random category caps"] call _check;
    [[_manifest, ["SmokeShell"]] call _quantity == 2 && {[_manifest, ["ToolKit"]] call _quantity == 1} &&
        {[_manifest, ["MineDetector"]] call _quantity == 1}, "fixed smoke and tool stock"] call _check;
    [(_manifest findIf {!( (_x select 0) in ["item","magazine"]) || {(_x select 2) < 1}}) < 0, "normalized cargo tags/counts"] call _check;
};
LOOT_WHITELIST_MODE = 1; LOOT_WHITELIST_ITEM = ["ToolKit"];
[( ["engineering"] call loot_fnc_supplyManifest) isEqualTo [], "no permitted mines means no engineering cache"] call _check;
LOOT_WHITELIST_EXPLOSIVE = ["APERSMine_Range_Mag", "SmokeShell"];
private _restricted = ["engineering"] call loot_fnc_supplyManifest;
[(_restricted findIf {!((_x select 1) in ["ToolKit","APERSMine_Range_Mag","SmokeShell"])}) < 0 && {count _restricted > 0}, "typed strict whitelists"] call _check;
LOOT_BLACKLIST = ["APERSMine_Range_Mag"];
[( ["engineering"] call loot_fnc_supplyManifest) isEqualTo [], "blacklist overrides whitelist"] call _check;
LOOT_BLACKLIST = []; LOOT_WHITELIST_MODE = 0;
BW_ENGINEERING_AP_COUNT = [1,100];
[( ["engineering"] call loot_fnc_supplyManifest) isEqualTo [], "oversized range rejected"] call _check;
BW_ENGINEERING_AP_COUNT = [1,2];
[!([attkWave,"unknown"] call loot_fnc_startSupplyCache) && {BW_SUPPLY_SERIAL == 0}, "unknown family cannot reserve state"] call _check;
private _cleanup = {
    [BW_SUPPLY_CACHE getOrDefault ["id",-1], "test"] call loot_fnc_endSupplyCache;
    [BW_ENGINEERING_CACHE getOrDefault ["id",-1], "test", "engineering"] call loot_fnc_endSupplyCache;
};
private _deploy = {
    attkWave = attkWave + 1; buildPhase = false; missionExtract = false; runMissionLoop = true;
    private _med = [attkWave] call loot_fnc_startSupplyCache;
    if (_med) then {[[{count BW_SUPPLY_STATUS == 5}] call _wait, "medical publication"] call _check};
    private _eng = [attkWave, "engineering"] call loot_fnc_startSupplyCache;
    if (_eng) then {[[{count BW_ENGINEERING_STATUS == 5}] call _wait, "engineering publication"] call _check};
    [_med,_eng]
};
// 0/1 endpoints make independent chance assertions deterministic.
{
    _x params ["_medChance", "_engChance"];
    BW_SUPPLY_CHANCE = _medChance; BW_ENGINEERING_CHANCE = _engChance;
    private _started = call _deploy;
    [_started isEqualTo [_medChance == 1, _engChance == 1], "independent chance combinations"] call _check;
    [BW_SUPPLY_LAST_ATTEMPT == attkWave && {BW_ENGINEERING_LAST_ATTEMPT == attkWave}, "both families consume their own roll"] call _check;
    call _cleanup;
    [!([attkWave] call loot_fnc_startSupplyCache) && {!([attkWave,"engineering"] call loot_fnc_startSupplyCache)}, "neither family may reroll"] call _check;
} forEach [[0,0],[1,0],[0,1],[1,1]];
BW_SUPPLY_CHANCE = 1; BW_ENGINEERING_CHANCE = 1;
// A disabled/invalid engineering roll must not disturb a published medical cache.
attkWave = attkWave + 1;
[attkWave] call loot_fnc_startSupplyCache;
[[{count BW_SUPPLY_STATUS == 5}] call _wait, "medical ready for isolation checks"] call _check;
BW_ENGINEERING_ENABLED = false;
[!([attkWave,"engineering"] call loot_fnc_startSupplyCache) && {count BW_SUPPLY_STATUS == 5}, "disabled engineering preserves medical"] call _check;
BW_ENGINEERING_ENABLED = true;
{
    BW_ENGINEERING_CHANCE = _x;
    [!([attkWave,"engineering"] call loot_fnc_startSupplyCache) && {count BW_SUPPLY_STATUS == 5}, "invalid engineering chance preserves medical"] call _check;
} forEach [-0.1,1.1,"bad"];
BW_ENGINEERING_CHANCE = 1;
call _cleanup;
call _deploy;
private _medCrate = BW_SUPPLY_CACHE getOrDefault ["crate",objNull];
private _engCrate = BW_ENGINEERING_CACHE getOrDefault ["crate",objNull];
private _medId = BW_SUPPLY_CACHE getOrDefault ["id",-1];
private _engId = BW_ENGINEERING_CACHE getOrDefault ["id",-1];
[!isNull _medCrate && {!isNull _engCrate} && {_medId != _engId} && {_medCrate distance2D _engCrate >= 20}, "unique IDs and separated crates"] call _check;
if (!isNull _engCrate) then {
    private _manifest = BW_ENGINEERING_CACHE get "manifest";
    private _actual = getMagazineCargo _engCrate;
    {
        _x params ["_tag","_class","_count"];
        private _cargo = if (_tag == "item") then {getItemCargo _engCrate} else {_actual};
        private _index = (_cargo select 0) find _class;
        [_index >= 0 && {(_cargo select 1 select _index) == _count}, "real item/magazine cargo matches manifest"] call _check;
    } forEach _manifest;
    buildPhase = true; clearItemCargoGlobal _engCrate; sleep 1.2;
    [alive _engCrate && {alive _medCrate}, "magazines prevent depletion; both survive preparation"] call _check;
    [_medId,"wrongFamily","engineering"] call loot_fnc_endSupplyCache;
    [alive _engCrate, "medical ID cannot delete engineering record"] call _check;
    [_engId,"test","engineering"] call loot_fnc_endSupplyCache;
    [_engId,"repeat","engineering"] call loot_fnc_endSupplyCache;
    [alive _medCrate && {count BW_SUPPLY_STATUS == 5} && {BW_ENGINEERING_STATUS isEqualTo []}, "cleanup isolates family snapshot and crate"] call _check;
};
call _cleanup;
// Force both workers to select the same site: final publication must reject one.
loot_fnc_findSupplySite = {sleep 0.2; +(BW_engineeringTestSites select 0)};
attkWave = attkWave + 1; buildPhase = false;
[attkWave] call loot_fnc_startSupplyCache;
[attkWave,"engineering"] call loot_fnc_startSupplyCache;
[[{count BW_SUPPLY_STATUS + count BW_ENGINEERING_STATUS == 5 &&
    {count BW_SUPPLY_CACHE == 0 || {count BW_ENGINEERING_CACHE == 0}}}] call _wait,
    "concurrent same-site publication limited to one crate"] call _check;
call _cleanup;
loot_fnc_findSupplySite = {params ["_anchor",["_exclude",[]]]; +(BW_engineeringTestSites select (if (_exclude isEqualTo []) then {0} else {1}))};
call _deploy;
if (count BW_ENGINEERING_CACHE > 0) then {BW_ENGINEERING_CACHE set ["expiresAt", serverTime - 1]};
[[{count BW_ENGINEERING_CACHE == 0}] call _wait, "engineering expiry cleanup"] call _check;
[count BW_SUPPLY_STATUS == 5 && {alive (BW_SUPPLY_CACHE getOrDefault ["crate",objNull])}, "engineering expiry preserves medical"] call _check;
call _cleanup;
// Endings and relocation must clear both records, regardless of family order.
{
    call _deploy;
    switch (_x) do {
        case "extraction": {missionExtract = true};
        case "nextWave": {attkWave = attkWave + 1};
        case "relocation": {_anchor setPosATL (_origin vectorAdd [80,0,0])};
        case "ending": {runMissionLoop = false};
    };
    [[{count BW_SUPPLY_CACHE == 0 && {count BW_ENGINEERING_CACHE == 0}}] call _wait, "both-family terminal cleanup"] call _check;
    call _cleanup; _anchor setPosATL _origin;
} forEach ["extraction","nextWave","relocation","ending"];
// Wrong manifest tags/roots must never create either kind of cargo.
private _realManifest = loot_fnc_supplyManifest;
{
    private _bad = _x;
    loot_fnc_supplyManifest = compile str _bad;
    attkWave = attkWave + 1; buildPhase = false; runMissionLoop = true; missionExtract = false;
    [attkWave,"engineering"] call loot_fnc_startSupplyCache;
    [[{count BW_ENGINEERING_CACHE == 0}] call _wait, "invalid mixed cargo rejected"] call _check;
    [BW_ENGINEERING_STATUS isEqualTo [], "bad cargo has no public crate"] call _check;
} forEach [[["weapon","ToolKit",1]], [["magazine","ToolKit",1]], [["magazine","ATMine_Range_Mag",100000]]];
loot_fnc_supplyManifest = _realManifest;
call _cleanup;
deleteVehicle _anchor;
{
    private _value = _saved select _forEachIndex;
    private _public = _x in ["BW_SUPPLY_STATUS","BW_ENGINEERING_STATUS","BW_SUPPLY_DELIVERY_STATUS","BW_ENGINEERING_DELIVERY_STATUS"];
    if (_value select 0) then {missionNamespace setVariable [_x,_value select 1,_public]}
    else {missionNamespace setVariable [_x,nil,_public]};
} forEach _names;
diag_log format ["ENGINEERING tests complete: %1 failures %2", count _failures, _failures];
