if (((_this select 0) getVariable ["bw_supplyCacheId", -1]) >= 0) exitWith {};
if (((_this select 0) getVariable ["bw_fpvId", -1]) >= 0) exitWith {};
_object = _this select 0;
_movePos = _this select 1;
_caller = _this select 2;

_callerPos = getPosATL (_caller);
_objectPos = getPosATL (_object);
private _targetPos = _objectPos vectorAdd _movePos;
if (!([_object, _targetPos] call build_fnc_supplyPlacementClear)) exitWith {
    hint "Move the object clear of players, vehicles and structures before placing it.";
};
[_object, false] remoteExec ["enableSimulation", 0];
[_object, [
	(_objectPos select 0) + (_movePos select 0),
	(_objectPos select 1) + (_movePos select 1),
	(_objectPos select 2) + (_movePos select 2)
]] remoteExec ["setPosATL", 0];
[_object, true] remoteExec ["enableSimulation", 0];
sleep 0.1;
_newCallerPos = getPosATL (_caller);
if ((_newCallerPos select 2) > (_callerPos select 2)) then {
	[_object, _objectPos] remoteExec ["setPosATL", 0];
};
