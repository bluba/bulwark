/* Disposable idle server/editor: [] execVM "tests\supplyDelivery.sqf";
   Normal loop stopped, neither family active, living WEST human on land.
   Real delivery/worker/cleanup/parachute code. Replaces aircraft spawning/transit
   with a stationary vanilla helicopter and controlled arrival, not flight AI.
   Real VTOL navigation, wind, natural landing and UI remain multiplayer tests.
*/
if (!isServer || {isRemoteExecuted} || {!canSuspend}) exitWith {};
if (missionNamespace getVariable ["runMissionLoop", false] ||
    {count (missionNamespace getVariable ["BW_SUPPLY_CACHE", createHashMap]) > 0} ||
    {count (missionNamespace getVariable ["BW_ENGINEERING_CACHE", createHashMap]) > 0}) exitWith {diag_log "DELIVERY test needs an idle mission with no caches"};
private _players = [] call bulwark_fnc_readyVoters;
if (_players isEqualTo []) exitWith {diag_log "DELIVERY test needs a living WEST human"};
private _origin = getPosATL (_players select 0);
private _siteA = [_origin] call loot_fnc_findSupplySite;
if (_siteA isEqualTo []) exitWith {diag_log "DELIVERY test has no safe open landing zone"};
private _siteB = [_origin, [_siteA]] call loot_fnc_findSupplySite;
if (_siteB isEqualTo []) exitWith {diag_log "DELIVERY test needs a second separated landing zone"};
private _names = ["BW_SUPPLY_CACHE","BW_SUPPLY_SERIAL","BW_SUPPLY_LAST_ATTEMPT","BW_SUPPLY_LAST_RESULT","BW_SUPPLY_STATUS","BW_SUPPLY_DELIVERY_STATUS",
    "BW_ENGINEERING_CACHE","BW_ENGINEERING_LAST_ATTEMPT","BW_ENGINEERING_LAST_RESULT","BW_ENGINEERING_STATUS","BW_ENGINEERING_DELIVERY_STATUS",
    "BW_SUPPLY_ENABLED","BW_SUPPLY_CHANCE","BW_ENGINEERING_ENABLED","BW_ENGINEERING_CHANCE","BW_SUPPLY_CLASS","BW_ENGINEERING_CLASS",
    "BW_SUPPLY_STOCK","BW_SUPPLY_LIFETIME","BW_SUPPLY_RELOCATION","BW_SUPPLY_AIRCRAFT","BW_SUPPLY_DELIVERY_TIMEOUT","BW_SUPPLY_DESCENT_TIMEOUT",
    "BW_ENGINEERING_AP_POOL","BW_ENGINEERING_AT_POOL","BW_ENGINEERING_GRENADE_POOL","BW_ENGINEERING_SMOKE_POOL","BW_ENGINEERING_TOOLS",
    "BW_ENGINEERING_AP_COUNT","BW_ENGINEERING_AT_COUNT","BW_ENGINEERING_GRENADE_COUNT",
    "LOOT_BLACKLIST","LOOT_WHITELIST_MODE","LOOT_WHITELIST_ITEM","LOOT_WHITELIST_EXPLOSIVE","runMissionLoop","missionExtract","buildPhase","attkWave","bulwarkBox",
    "BIS_fnc_spawnVehicle","bulwark_fnc_waitForAircraft","loot_fnc_findSupplySite","BW_deliveryTestSites","BW_deliveryTestArrival"];
private _saved = _names apply {[!isNil _x, missionNamespace getVariable [_x,false]]};
private _failures = [];
private _check = {params ["_ok","_label"]; if (!_ok) then {_failures pushBack _label; diag_log ("DELIVERY FAIL: " + _label)}};
private _wait = {params ["_condition"]; private _deadline = diag_tickTime + 6; waitUntil {sleep 0.05; call _condition || {diag_tickTime >= _deadline}}; call _condition};
private _anchor = createVehicle ["Land_HelipadEmpty_F",_origin,[],0,"CAN_COLLIDE"];
bulwarkBox = _anchor;
BW_SUPPLY_CACHE = createHashMap; BW_ENGINEERING_CACHE = createHashMap; BW_SUPPLY_SERIAL = 0;
BW_SUPPLY_LAST_ATTEMPT = -1; BW_ENGINEERING_LAST_ATTEMPT = -1;
BW_SUPPLY_STATUS = []; BW_ENGINEERING_STATUS = []; BW_SUPPLY_DELIVERY_STATUS = []; BW_ENGINEERING_DELIVERY_STATUS = [];
BW_SUPPLY_ENABLED = true; BW_ENGINEERING_ENABLED = true; BW_SUPPLY_CHANCE = 1; BW_ENGINEERING_CHANCE = 1;
BW_SUPPLY_CLASS = "Box_NATO_Equip_F"; BW_ENGINEERING_CLASS = "Box_NATO_Equip_F";
BW_SUPPLY_STOCK = [["FirstAidKit",6],["Medikit",1]]; BW_SUPPLY_LIFETIME = 30; BW_SUPPLY_RELOCATION = 75;
BW_SUPPLY_AIRCRAFT = "B_Heli_Light_01_F"; BW_SUPPLY_DELIVERY_TIMEOUT = 5; BW_SUPPLY_DESCENT_TIMEOUT = 10;
BW_ENGINEERING_AP_POOL = ["APERSMine_Range_Mag"]; BW_ENGINEERING_AT_POOL = ["ATMine_Range_Mag"];
BW_ENGINEERING_GRENADE_POOL = ["HandGrenade"]; BW_ENGINEERING_SMOKE_POOL = ["SmokeShell"]; BW_ENGINEERING_TOOLS = ["ToolKit","MineDetector"];
BW_ENGINEERING_AP_COUNT = [1,2]; BW_ENGINEERING_AT_COUNT = [1,2]; BW_ENGINEERING_GRENADE_COUNT = [1,3];
LOOT_BLACKLIST = []; LOOT_WHITELIST_MODE = 0; LOOT_WHITELIST_ITEM = []; LOOT_WHITELIST_EXPLOSIVE = [];
runMissionLoop = true; missionExtract = false; buildPhase = false; attkWave = 1;
BW_deliveryTestSites = [_siteA,_siteB]; BW_deliveryTestArrival = false;
loot_fnc_findSupplySite = {params ["_anchor",["_exclude",[]]]; +(BW_deliveryTestSites select (if (_exclude isEqualTo []) then {0} else {1}))};
BIS_fnc_spawnVehicle = {
    params ["_position","_direction","_class","_side"];
    private _fixturePos = +(BW_deliveryTestSites select 0); _fixturePos set [2,40];
    private _fixtureAir = createVehicle [_class,_fixturePos,[],0,"FLY"];
    _fixtureAir setPosATL _fixturePos;
    _fixtureAir enableSimulationGlobal false;
    private _fixtureGroup = createGroup [west,true];
    private _fixturePilot = _fixtureGroup createUnit ["B_Helipilot_F",_fixturePos,[],0,"NONE"];
    _fixturePilot moveInDriver _fixtureAir;
    [_fixtureAir,[_fixturePilot],_fixtureGroup]
};
private _realTransit = bulwark_fnc_waitForAircraft;
bulwark_fnc_waitForAircraft = {
    params ["_aircraft","_target","_radius",["_timeout",120],["_wave",-1],["_condition",{true}]];
    private _limit = time + _timeout;
    waitUntil {sleep 0.05; BW_deliveryTestArrival || {!alive _aircraft} || {!(call _condition)} || {time >= _limit}};
    BW_deliveryTestArrival && {alive _aircraft} && {call _condition} && {time < _limit}
};
private _launch = {
    params [["_family","medical"]];
    attkWave = attkWave + 1; runMissionLoop = true; missionExtract = false; buildPhase = false;
    _anchor setPosATL _origin; bulwarkBox = _anchor; BW_deliveryTestArrival = false;
    private _keys = [_family] call loot_fnc_supplyFamily;
    [[attkWave,_family] call loot_fnc_startSupplyCache,"delivery reservation"] call _check;
    [[{!isNull ((missionNamespace getVariable [_keys select 0,createHashMap]) getOrDefault ["aircraft",objNull])}] call _wait,"inbound aircraft registered"] call _check;
    [_keys,missionNamespace getVariable [_keys select 0,createHashMap]]
};
private _gone = {
    params ["_keys"];
    [[{count (missionNamespace getVariable [_keys select 0,createHashMap]) == 0}] call _wait,"record released"] call _check;
    [(missionNamespace getVariable [_keys select 3,[]]) isEqualTo [] &&
        {(missionNamespace getVariable [_keys select 7,[]]) isEqualTo []},"stock and delivery snapshots cleared"] call _check;
};
// Cancellation and loss while inbound must remove the registered aircraft/crew.
{
    private _job = ["medical"] call _launch;
    _job params ["_keys","_record"];
    private _air = _record getOrDefault ["aircraft",objNull];
    private _crew = +(_record getOrDefault ["crew",[]]);
    private _group = _record getOrDefault ["group",grpNull];
    private _worker = _record get "worker";
    [BW_SUPPLY_STATUS isEqualTo [] && {count BW_SUPPLY_DELIVERY_STATUS == 5},"inbound has no collectible stock"] call _check;
    if (_x == "extraction") then {
        [!([_air,_siteA,100,1,-1,{false}] call _realTransit),"shared wait honors added cancellation predicate"] call _check;
        [[_air,_siteA,100,1] call _realTransit,"shared wait preserves old default behavior"] call _check;
    };
    switch (_x) do {
        case "extraction": {missionExtract = true};
        case "relocation": {_anchor setPosATL (_origin vectorAdd [80,0,0])};
        case "loss": {deleteVehicle _air};
    };
    [_keys] call _gone;
    [isNull _air && {(_crew findIf {!isNull _x}) < 0} && {isNull _group} && {scriptDone _worker},"inbound assets and worker cleaned"] call _check;
} forEach ["extraction","loss","relocation"];
BW_SUPPLY_DELIVERY_TIMEOUT = 0.3;
private _job = ["medical"] call _launch; [_job select 0] call _gone;
[(BW_SUPPLY_LAST_RESULT select 1) == "aircraftLostOrTimeout","bounded arrival timeout"] call _check;
BW_SUPPLY_DELIVERY_TIMEOUT = 5;
// Real chute/crate with controlled low altitude; full stock lifetime starts on landing.
_job = ["engineering"] call _launch;
_job params ["_keys","_record"];
private _air = _record get "aircraft";
BW_deliveryTestArrival = true;
[[{(_record getOrDefault ["state",""]) == "descending"}] call _wait,"parachute descent registered"] call _check;
private _crate = _record getOrDefault ["crate",objNull];
private _chute = _record getOrDefault ["parachute",objNull];
if (!isNull _crate && {!isNull _chute}) then {
    [itemCargo _crate isEqualTo [] && {magazineCargo _crate isEqualTo []} &&
        {BW_ENGINEERING_STATUS isEqualTo []} && {(_record getOrDefault ["expiresAt",-1]) == -1},"no airborne stock or stock lifetime"] call _check;
    _chute setPosATL [_siteA select 0,_siteA select 1,3];
    [[{count BW_ENGINEERING_STATUS == 5}] call _wait,"safe landing publishes engineering stock"] call _check;
    [!isNull _crate && {isNull _chute} && {isNull _air} && {isNull (attachedTo _crate)},"landing detaches crate and clears flight assets"] call _check;
    [!((magazineCargo _crate) isEqualTo []) && {(_record getOrDefault ["expiresAt",0]) - serverTime > 28},"finite stock and full post-landing lifetime"] call _check;
    private _smoke = _record getOrDefault ["smoke",objNull];
    [!isNull _smoke && {BW_ENGINEERING_DELIVERY_STATUS isEqualTo []},"blue smoke and delivery status transition"] call _check;
    [_record get "id","test","engineering"] call loot_fnc_endSupplyCache;
    [_keys] call _gone;
    [isNull _crate && {isNull _smoke},"landed cargo and smoke owned by cleanup"] call _check;
} else {[_record get "id","testFailed","engineering"] call loot_fnc_endSupplyCache};
// Phase cancellation, timeout and unsafe drift while descending never publish stock.
{
    BW_SUPPLY_DESCENT_TIMEOUT = if (_x == "timeout") then {0.5} else {10};
    _job = ["medical"] call _launch;
    _job params ["_keys","_record"];
    BW_deliveryTestArrival = true;
    [[{(_record getOrDefault ["state",""]) == "descending"}] call _wait,"descent fixture ready"] call _check;
    private _crate = _record getOrDefault ["crate",objNull];
    private _chute = _record getOrDefault ["parachute",objNull];
    switch (_x) do {
        case "phase": {buildPhase = true};
        case "drift": {if (!isNull _chute) then {_chute setPosATL [(_siteA select 0) + 90,_siteA select 1,3]}};
        case "chuteLost": {deleteVehicle _chute};
        case "explicit": {[_record get "id","testCancel"] call loot_fnc_endSupplyCache};
    };
    [_keys] call _gone;
    [isNull _crate && {isNull _chute},"failed descent removes chute and crate"] call _check;
    if (_x == "timeout") then {[(BW_SUPPLY_LAST_RESULT select 1) == "descentTimeout","bounded descent timeout"] call _check};
    if (_x == "drift") then {[(BW_SUPPLY_LAST_RESULT select 1) == "unsafeLanding","unsafe landing rejected without teleport"] call _check};
    if (_x == "chuteLost") then {[(BW_SUPPLY_LAST_RESULT select 1) == "descentLost","lost chute cancels delivery"] call _check};
} forEach ["phase","timeout","drift","chuteLost","explicit"];
BW_SUPPLY_DESCENT_TIMEOUT = 10;
// Two in-flight families: cancelling one cannot delete the other's aircraft/worker.
_job = ["medical"] call _launch;
private _medRecord = _job select 1;
[attkWave,"engineering"] call loot_fnc_startSupplyCache;
[[{!isNull (BW_ENGINEERING_CACHE getOrDefault ["aircraft",objNull])}] call _wait,"second-family aircraft registered"] call _check;
private _engAir = BW_ENGINEERING_CACHE getOrDefault ["aircraft",objNull];
[_medRecord get "id","testIsolation"] call loot_fnc_endSupplyCache;
sleep 0.1;
[alive _engAir && {count BW_ENGINEERING_DELIVERY_STATUS == 5} && {!(scriptDone (BW_ENGINEERING_CACHE get "worker"))},"in-flight cleanup isolated by family"] call _check;
[(BW_ENGINEERING_CACHE getOrDefault ["id",-1]),"testComplete","engineering"] call loot_fnc_endSupplyCache;
[(BW_SUPPLY_CACHE getOrDefault ["id",-1]),"testFinal"] call loot_fnc_endSupplyCache;
deleteVehicle _anchor;
{
    private _value = _saved select _forEachIndex;
    private _public = _x in ["BW_SUPPLY_STATUS","BW_ENGINEERING_STATUS","BW_SUPPLY_DELIVERY_STATUS","BW_ENGINEERING_DELIVERY_STATUS"];
    if (_value select 0) then {missionNamespace setVariable [_x,_value select 1,_public]} else {missionNamespace setVariable [_x,nil,_public]};
} forEach _names;
diag_log format ["DELIVERY tests complete: %1 failures %2",count _failures,_failures];
