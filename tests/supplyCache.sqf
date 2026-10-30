/* Isolated idle server/editor only: [] execVM "tests\supplyCache.sqf";
   Requires a WEST human on land with a valid supply site nearby and normal loop
   stopped. Exercises real workers/cargo; temporarily replaces delivery and the placement
   function for deterministic lifecycle/failure cases. Calls ordinary loot cleanup:
   nearby loose loot will be deleted. Run only in a disposable mission copy.
*/
if (!isServer || {isRemoteExecuted} || {!canSuspend}) exitWith {};
if (missionNamespace getVariable ["runMissionLoop", false] ||
    {count (missionNamespace getVariable ["BW_ENGINEERING_CACHE", createHashMap]) > 0} ||
    {count (missionNamespace getVariable ["BW_SUPPLY_CACHE", createHashMap]) > 0}) exitWith {
    diag_log "SUPPLY test requires an idle mission and no supply worker/cache";
};
private _players = [] call bulwark_fnc_readyVoters;
if (_players isEqualTo []) exitWith {diag_log "SUPPLY test requires a living WEST human"};
private _origin = getPosATL (_players select 0);
private _site = [_origin] call loot_fnc_findSupplySite;
if (_site isEqualTo []) exitWith {diag_log "SUPPLY test: no valid fixture site; move to another land location"};
private _names = ["BW_SUPPLY_CACHE", "BW_SUPPLY_SERIAL", "BW_SUPPLY_LAST_ATTEMPT", "BW_SUPPLY_LAST_RESULT", "BW_SUPPLY_STATUS",
    "BW_SUPPLY_ENABLED", "BW_SUPPLY_CHANCE", "BW_SUPPLY_CLASS", "BW_SUPPLY_STOCK",
    "BW_SUPPLY_LIFETIME", "BW_SUPPLY_RELOCATION", "LOOT_WHITELIST_MODE", "LOOT_WHITELIST_ITEM", "LOOT_BLACKLIST",
    "runMissionLoop", "missionExtract", "buildPhase", "attkWave", "bulwarkBox", "BULWARK_RADIUS",
    "loot_fnc_deliverSupplyCache", "BW_SUPPLY_DELIVERY_STATUS", "BW_ENGINEERING_DELIVERY_STATUS", "loot_fnc_findSupplySite", "BW_supplyTestSite", "objects"];
private _saved = _names apply {[!isNil _x, missionNamespace getVariable [_x, false]]};
private _failures = [];
private _check = {
    params ["_ok", "_label"];
    if (!_ok) then {_failures pushBack _label; diag_log ("SUPPLY FAIL: " + _label)};
};
private _wait = {
    params ["_condition"];
    private _until = diag_tickTime + 5;
    waitUntil {sleep 0.1; call _condition || {diag_tickTime >= _until}};
    call _condition
};
private _anchor = createVehicle ["Land_HelipadEmpty_F", _origin, [], 0, "CAN_COLLIDE"];
bulwarkBox = _anchor;
BW_SUPPLY_CACHE = createHashMap; BW_SUPPLY_SERIAL = 0; BW_SUPPLY_LAST_ATTEMPT = -1;
BW_SUPPLY_ENABLED = true; BW_SUPPLY_CHANCE = 1;
BW_SUPPLY_CLASS = "Box_NATO_Equip_F"; BW_SUPPLY_LIFETIME = 180; BW_SUPPLY_RELOCATION = 75;
BW_SUPPLY_STOCK = [["FirstAidKit", 6], ["Medikit", 1]];
LOOT_BLACKLIST = []; LOOT_WHITELIST_ITEM = []; LOOT_WHITELIST_MODE = 0;
runMissionLoop = true; missionExtract = false; buildPhase = false; attkWave = 1;
BW_supplyTestSite = _site;
loot_fnc_findSupplySite = {+BW_supplyTestSite};

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
private _manifest = [] call loot_fnc_supplyManifest;
private _expected = BW_SUPPLY_STOCK apply {["item", _x select 0, _x select 1]};
[_manifest isEqualTo _expected, "default medical manifest"] call _check;
LOOT_WHITELIST_MODE = 1;
[(call loot_fnc_supplyManifest) isEqualTo [], "empty strict whitelist skips"] call _check;
LOOT_WHITELIST_ITEM = ["Medikit"];
[(call loot_fnc_supplyManifest) isEqualTo [["item","Medikit",1]], "strict whitelist intersects profile"] call _check;
LOOT_BLACKLIST = ["Medikit"];
[(call loot_fnc_supplyManifest) isEqualTo [], "blacklist takes priority"] call _check;
LOOT_BLACKLIST = []; LOOT_WHITELIST_MODE = 2;
[(call loot_fnc_supplyManifest) isEqualTo _expected, "augmented mode preserves curated family"] call _check;
LOOT_WHITELIST_MODE = 0;
BW_SUPPLY_STOCK = [["FirstAidKit",7], ["Medikit",1.5], ["MissingMedicalClass",1], ["FirstAidKit",-1], ["Medikit","bad"]];
[(call loot_fnc_supplyManifest) isEqualTo [], "reject invalid classes, quantities and caps"] call _check;
BW_SUPPLY_STOCK = [["FirstAidKit",6], ["FirstAidKit",6], ["Medikit",1]];
[(call loot_fnc_supplyManifest) isEqualTo _manifest, "duplicates do not multiply stock"] call _check;
BW_SUPPLY_STOCK = _manifest apply {[_x select 1, _x select 2]};
[[[-1,1,0], _origin, 100, 300] call loot_fnc_supplySiteClear isEqualTo [], "site rejects map bounds"] call _check;
[[["bad",1,0], _origin, 100, 300] call loot_fnc_supplySiteClear isEqualTo [], "site rejects malformed coordinates"] call _check;
BW_SUPPLY_ENABLED = false;
[!([1] call loot_fnc_startSupplyCache) && {BW_SUPPLY_LAST_ATTEMPT == -1}, "disabled feature does not consume roll"] call _check;
BW_SUPPLY_ENABLED = true; BW_SUPPLY_CHANCE = 0;
[!([1] call loot_fnc_startSupplyCache) && {BW_SUPPLY_LAST_ATTEMPT == 1} && {count BW_SUPPLY_CACHE == 0} &&
    {BW_SUPPLY_SERIAL == 0}, "zero chance misses without worker, including wave one"] call _check;
BW_SUPPLY_CHANCE = 1;
[!([1] call loot_fnc_startSupplyCache), "missed roll cannot be retried in same wave"] call _check;
attkWave = 2;
{
    BW_SUPPLY_CHANCE = _x;
    [!([2] call loot_fnc_startSupplyCache) && {BW_SUPPLY_LAST_ATTEMPT == 1}, "invalid chance rejected without consuming roll"] call _check;
} forEach [-0.1, 1.1, "bad"];
BW_SUPPLY_CHANCE = 1;

private _deploy = {
    attkWave = attkWave + 1;
    buildPhase = false; missionExtract = false; runMissionLoop = true;
    _anchor setPosATL _origin; bulwarkBox = _anchor;
    private _ok = [attkWave] call loot_fnc_startSupplyCache;
    [_ok, "deployment reserved"] call _check;
    private _ready = [{count (missionNamespace getVariable ["BW_SUPPLY_STATUS", []]) == 5}] call _wait;
    [_ready, "real worker publishes crate"] call _check;
    BW_SUPPLY_CACHE getOrDefault ["crate", objNull]
};
private _gone = {
    private _ok = [{count BW_SUPPLY_CACHE == 0 && {(missionNamespace getVariable ["BW_SUPPLY_STATUS", []]) isEqualTo []}}] call _wait;
    [_ok, "terminal cleanup clears record and snapshot"] call _check;
};
private _crate = call _deploy;
private _id = BW_SUPPLY_CACHE getOrDefault ["id", -1];
[!([attkWave] call loot_fnc_startSupplyCache), "duplicate deployment rejected"] call _check;
if (!isNull _crate) then {
    private _cargo = getItemCargo _crate;
    private _classes = _cargo select 0;
    private _counts = _cargo select 1;
    [count _classes == 2 && {_classes find "FirstAidKit" >= 0} && {_classes find "Medikit" >= 0} &&
        {_counts select (_classes find "FirstAidKit") == 6} && {_counts select (_classes find "Medikit") == 1}, "exact finite cargo"] call _check;
    [weaponCargo _crate isEqualTo [] && {magazineCargo _crate isEqualTo []} && {backpackCargo _crate isEqualTo []}, "no default crate cargo"] call _check;
    buildPhase = true; sleep 1.2;
    [alive _crate && {count BW_SUPPLY_STATUS == 5}, "cache survives preparation"] call _check;
    [_id - 1, "stale"] call loot_fnc_endSupplyCache;
    [alive _crate, "stale cleanup cannot delete current instance"] call _check;
    clearItemCargoGlobal _crate;
    _crate addMagazineCargoGlobal ["SmokeShell", 1];
    sleep 1.2;
    [alive _crate, "deposited cargo prevents empty cleanup without refill"] call _check;
    clearMagazineCargoGlobal _crate;
    call _gone;
    [isNull _crate, "empty crate deleted"] call _check;
};
[!([attkWave] call loot_fnc_startSupplyCache), "no repeat attempt in same wave"] call _check;
[_id, "repeat"] call loot_fnc_endSupplyCache;
[count BW_SUPPLY_CACHE == 0, "repeat cleanup is harmless"] call _check;

_crate = call _deploy;
if (!isNull _crate) then {BW_SUPPLY_CACHE set ["expiresAt", serverTime - 1]; call _gone; [isNull _crate, "expiry deletes stock"] call _check};
_crate = call _deploy;
if (!isNull _crate) then {deleteVehicle _crate; call _gone};
_crate = call _deploy;
if (!isNull _crate) then {_anchor setPosATL (_origin vectorAdd [80,0,0]); call _gone; [isNull _crate, "truck relocation cleanup"] call _check};
_crate = call _deploy;
if (!isNull _crate) then {bulwarkBox = objNull; call _gone; [isNull _crate, "truck replacement cleanup"] call _check};
_crate = call _deploy;
if (!isNull _crate) then {_crate setPosATL (_site vectorAdd [3,0,0]); call _gone; [isNull _crate, "cache movement cleanup"] call _check};
_crate = call _deploy;
if (!isNull _crate) then {missionExtract = true; call _gone; [isNull _crate, "extraction cleanup"] call _check};
_crate = call _deploy;
if (!isNull _crate) then {runMissionLoop = false; call _gone; [isNull _crate, "mission end cleanup"] call _check};
_crate = call _deploy;
if (!isNull _crate) then {attkWave = attkWave + 1; call _gone; [isNull _crate, "next combat wave cleanup"] call _check};
// Invalid site: failed deployment cannot be retried in that wave.
attkWave = 101; buildPhase = false; runMissionLoop = true; missionExtract = false;
_anchor setPosATL _origin; bulwarkBox = _anchor; BW_supplyTestSite = [];
[[101] call loot_fnc_startSupplyCache, "failed-site attempt reserved"] call _check;
call _gone;
[!([101] call loot_fnc_startSupplyCache), "failed site cannot reroll same wave"] call _check;
BW_supplyTestSite = _site; BW_SUPPLY_CLASS = "MissingCrateClass"; attkWave = 104;
[[104] call loot_fnc_startSupplyCache, "invalid-class attempt reserved"] call _check;
call _gone;
BW_SUPPLY_CLASS = "Box_NATO_Equip_F";
// Hold real placement across a phase change: no late publication is permitted.
loot_fnc_findSupplySite = {sleep 0.3; +BW_supplyTestSite};
attkWave = 107;
[[107] call loot_fnc_startSupplyCache, "pending placement reserved"] call _check;
buildPhase = true; call _gone;
[BW_SUPPLY_STATUS isEqualTo [], "no publication after combat ends"] call _check;
loot_fnc_findSupplySite = {+BW_supplyTestSite};
_crate = call _deploy;
if (!isNull _crate) then {
    // Keep the worker out of this temporary move and broad ordinary-loot cleanup.
    private _loose = objNull;
    isNil {
        private _originalSite = getPosATL _crate;
        _crate setPosATL (_origin vectorAdd [3,0,0]);
        _loose = createVehicle ["WeaponHolderSimulated_Scripted", _origin, [], 0, "CAN_COLLIDE"];
        _loose addItemCargoGlobal ["FirstAidKit",1];
        BULWARK_RADIUS = 300;
        [] call loot_fnc_cleanup;
        _crate setPosATL _originalSite;
    };
    sleep 0.1;
    [alive _crate && {isNull _loose}, "ordinary cleanup deletes loose loot but preserves supply cache"] call _check;
    private _unrelated = createVehicle ["Land_HelipadEmpty_F", _origin, [], 0, "CAN_COLLIDE"];
    [BW_SUPPLY_CACHE get "id", "testComplete"] call loot_fnc_endSupplyCache;
    [!isNull _unrelated, "supply cleanup preserves unrelated objects"] call _check;
    deleteVehicle _unrelated;
};
[(BW_SUPPLY_CACHE getOrDefault ["id", -1]), "testFinalCleanup"] call loot_fnc_endSupplyCache;
deleteVehicle _anchor;
{
    private _value = _saved select _forEachIndex;
    private _public = _x in ["BW_SUPPLY_STATUS","BW_SUPPLY_DELIVERY_STATUS","BW_ENGINEERING_DELIVERY_STATUS"];
    if (_value select 0) then {missionNamespace setVariable [_x, _value select 1, _public]}
    else {missionNamespace setVariable [_x, nil, _public]};
} forEach _names;
diag_log format ["SUPPLY tests complete: %1 failures %2", count _failures, _failures];
