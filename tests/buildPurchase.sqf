// Disposable hosted editor session, idle mission, living player at Bulwark.
// Run: [] execVM "tests\buildPurchase.sqf";
// Stubs only the receiving callback so the real server purchase can be inspected.
if (!isServer || {!hasInterface} || {!alive player} ||
    {player getVariable ["buildItemHeld", false]} ||
    {isNil "bulwarkBox"} || {player distance bulwarkBox > 10}) exitWith {
    hint "Requires a living host at Bulwark with a free holding slot.";
};
private _catalogue = BULWARK_BUILDITEMS;
private _callback = bulwark_fnc_receivePurchase;
private _balance = player getVariable ["killPoints", 0];
private _failures = [];
private _check = {
    params ["_ok", "_label"];
    if (!_ok) then {_failures pushBack _label; diag_log ("BUILD PURCHASE FAIL: " + _label)};
};
bulwark_fnc_receivePurchase = {};
private _blocker = createVehicle ["C_Offroad_01_F", [100,100,1000], [], 0, "CAN_COLLIDE"];
_blocker enableSimulationGlobal false;
_blocker setPhysicsCollisionFlag false;
{
    private _class = _x;
    BULWARK_BUILDITEMS = [[10, "Test", _class, 0, 3, false, 0, 99999]];
    player setVariable ["killPoints", 100, true];
    player setVariable ["buildItemHeld", false, true];
    private _before = allMissionObjects _class;
    [player, "build", 99999] call killPoints_fnc_purchase;
    private _created = (allMissionObjects _class) - _before;
    [count _created == 1, _class + " created once"] call _check;
    if (count _created == 1) then {
        private _object = _created select 0;
        [!simulationEnabled _object && {!getPhysicsCollisionFlag _object}, _class + " staged without physics"] call _check;
        [_object distance player > 100, _class + " staged away from buyer"] call _check;
        [player getVariable ["killPoints", 0] == 90, "charged once"] call _check;
        [player getVariable ["buildItemHeld", false], "holding slot reserved"] call _check;
        [!([_object, getPosATL _blocker] call build_fnc_supplyPlacementClear), _class + " vehicle overlap rejected"] call _check;
        [!([_object, (getPosATL _blocker) vectorAdd [0,0,100]] call build_fnc_supplyPlacementClear), "ground-snap overlap rejected"] call _check;
        [_object getVariable ["bw_supplyPurchase", ""] == "", "guard covers non-supply purchases"] call _check;
        deleteVehicle _object;
    };
} forEach ["C_Offroad_01_F", "Box_NATO_Ammo_F", "Land_BagFence_Long_F"];
// Drain queued callbacks before restoring the real attachment handler.
sleep 1;
deleteVehicle _blocker;
BULWARK_BUILDITEMS = _catalogue;
bulwark_fnc_receivePurchase = _callback;
player setVariable ["killPoints", _balance, true];
player setVariable ["buildItemHeld", false, true];
[] call killPoints_fnc_updateHud;
hint format ["Build purchase checks complete: %1 failures. See RPT.", count _failures];
