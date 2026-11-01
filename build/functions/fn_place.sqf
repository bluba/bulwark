_object = _this select 0;
_caller = _this select 1;
_action = _this select 2;

if (!([_object, getPosATL _object] call build_fnc_supplyPlacementClear)) exitWith {
    hint "Move the crate clear of vehicles before placing it.";
};

_objectPos = getPosATL (_object);
detach _object;
[_object, false] remoteExec ["enableSimulation", 0];
[_object, _objectPos] remoteExec ["setPosATL", 0];
[_object, true] remoteExec ["enableSimulation", 0];

{
	[_object, _x] remoteExec ['enableCollisionWith', 0];
} forEach playableUnits;

{_caller removeAction _x} forEach (_caller getVariable ["bw_buildActionIds", []]);
_caller setVariable ["bw_buildActionIds", nil];

_object setVehiclePosition [_object, [], 0, 'CAN_COLLIDE'];

[
	_object,
	[
		'<t color="#ff0000">Remove Object</t>',
		'[_this select 0, _this select 1] call build_fnc_sell;',
		'', 1, false, false, 'true', 'true', 5
	]
] remoteExec ['addAction', 0];

[
	_object,
	[
		'<t color="#00ffff">Move Up</t>',
		'[_this select 0, _this select 3, _this select 1] call build_fnc_move;',
		[0,0,0.5],2,false,false,'true','true',5
	]
] remoteExec ['addAction', 0];

[
	_object,
	[
		'<t color="#00ff00">Move Down</t>',
		'[_this select 0, _this select 3, _this select 1] call build_fnc_move;',
		[0,0,-0.5],2,false,false,'true','true',5
	]
] remoteExec ['addAction', 0];

[
	_object,
	[
		'<t color="#ffffff">Pickup</t>',
		'[_this select 0, _this select 1] call build_fnc_pickup;',
		[0,0,0.5],2,false,false,'true','true',5
	]
] remoteExec ['addAction', 0];

[
	_object,
	[
		'<t color="#ffff00">Reset Rotation</t>',
		'[_this select 0, _this select 1] call build_fnc_reset;',
		[0,0,0.5],2,false,false,'true','true',5
	]
] remoteExec ['addAction', 0];

if ((_object getVariable ["bw_supplyPurchase", ""]) != "") then {
    _object setVelocity [0,0,0];
    _object setPhysicsCollisionFlag true;
    [_object, true] remoteExecCall ["setPhysicsCollisionFlag", 0, _object];
    [_object, true] remoteExecCall ["enableSimulationGlobal", 2];
};

_caller setVariable ["buildItemHeld", false, true];
_object setVariable ["buildItemHeld", false, true];
[mainZeus, [[_object], true]] remoteExec ["addCuratorEditableObjects", 0, true];
PLAYER_OBJECT_LIST pushBack _object;
sleep 0.1;
[[_object], 'bulwark\solidObject.sqf'] remoteExec ['execVM', 2];
//[_object] execVM "bulwark\solidObject.sqf";

[_object, _caller] remoteExecCall ["bulwark_fnc_activateAlly", 2];
