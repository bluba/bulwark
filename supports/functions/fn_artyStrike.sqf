params ["_player", ["_target", []]];
private _position = [_player, _target] call supports_fnc_strikeTarget;
if (_position isEqualTo []) exitWith {
    ["Select a target or place your own map marker."] remoteExecCall ["hint", _player];
    [_player, "artyStrike"] remoteExecCall ["BIS_fnc_addCommMenuItem", _player];
};
for "_i" from 1 to 3 do {
    if (!(missionNamespace getVariable ["runMissionLoop", true]) || {missionNamespace getVariable ["missionExtract", false]}) exitWith {};
    private _impact = [_position, 0, 25, 1, 0] call BIS_fnc_findSafePos;
    private _shell = createVehicle ["Sh_155mm_AMOS", [_impact select 0, _impact select 1, 500], [], 0, "CAN_COLLIDE"];
    _shell setVelocity [0, 0, -50];
    sleep (0.5 + random 1);
};
