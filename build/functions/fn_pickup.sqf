// Temporary F15 supplies never enter the construction/pickup lifecycle.
if (((_this select 0) getVariable ["bw_supplyCacheId", -1]) >= 0) exitWith {};
_object = _this select 0;
_caller = _this select 1;
_pos = _this param [2, []];

_playerArr = [_caller];

if (!(player getVariable ["buildItemHeld", false])) then {

		if (_pos isEqualTo []) then {
			[_object, _caller] call BIS_fnc_attachToRelative ;
		} else {
			_object attachTo [_caller, _pos, "Pelvis"];
			_playerDir = _caller getRelDir _object;
			_dir = _this param [3, 0];
			_holdDir = _playerDir + _dir;
			_object setdir _holdDir;
		};

		{
			[_object, _x] remoteExec ["disableCollisionWith", 0];
		} forEach playableUnits;

		[_object] remoteExec ["removeAllActions", 0];

		private _dropActionId = _caller addAction [
			"<t color='#00ffff'>Drop Object (Snap To Ground)</t>",
			'[_this select 3, _this select 1, _this select 2] call build_fnc_drop;',
			_object
		];

		private _placeActionId = _caller addAction [
			"<t color='#00ffff'>Place Object (Floating)</t>",
			'[_this select 3, _this select 1, _this select 2] call build_fnc_place;',
			_object
		];

		// Action IDs belong to this client; never broadcast them to other machines.
		_caller setVariable ["bw_buildActionIds", [_dropActionId, _placeActionId]];
		 _caller setVariable ["buildItemHeld", true, true];
		 _object setVariable ["buildItemHeld", true, true];

} else {

	[format ["<t size='0.6' color='#ff3300'>You're already carrying an object!</t>"], -0, -0.02, 2, 0.1] call BIS_fnc_dynamicText;

};
