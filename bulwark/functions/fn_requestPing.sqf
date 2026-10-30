// Manual reports only; never resolves or tracks an enemy object.
params [["_player", objNull, [objNull]], ["_kind", -1, [0]], ["_pos", [], [[]]]];
if (!([_player] call bulwark_fnc_validCaller)) exitWith {};
if (!alive _player || {lifeState _player == "INCAPACITATED"} || {side group _player != west} ||
    {missionNamespace getVariable ["missionExtract", false]} ||
    {!(missionNamespace getVariable ["runMissionLoop", false])}) exitWith {};
if !(_kind in [0, 1, 2, 3]) exitWith {};
if (count _pos != 3 || {(_pos findIf {!(_x isEqualType 0) || {!finite _x}}) >= 0}) exitWith {};
if ((_pos select 0) < 0 || {(_pos select 1) < 0} || {(_pos select 0) > worldSize} ||
    {(_pos select 1) > worldSize} || {_player distance2D _pos > 1000}) exitWith {};
private _uid = getPlayerUID _player;
if (_uid == "") exitWith {};
if (isNil "BW_PING_TIMES") then {BW_PING_TIMES = createHashMap};
if (serverTime < (BW_PING_TIMES getOrDefault [_uid, -10]) + 5) exitWith {};
BW_PING_TIMES set [_uid, serverTime];
private _pings = (missionNamespace getVariable ["BW_TACTICAL_PINGS", []]) select {
    (_x select 0) != _uid && {(_x select 5) > serverTime} && {alive (_x select 1)}
};
// One per author, at most 16 across the team; newest report replaces oldest.
if (count _pings >= 16) then {_pings deleteAt 0};
_pings pushBack [_uid, _player, _kind, [_pos select 0, _pos select 1, 0], name _player, serverTime + 45];
missionNamespace setVariable ["BW_TACTICAL_PINGS", _pings, true];
