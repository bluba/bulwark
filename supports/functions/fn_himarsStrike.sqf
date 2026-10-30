_player = _this select 0;

last = "";
{ 
	_type = _x select [0,15];
	_playerMark = _x select [15,1];
	if( _type == "_USER_DEFINED #" && getPlayerId _player == _playerMark) then
	{
		 last = _x; 
	};
} forEach allMapMarkers;

if(last == "") then {
	["SpecialWarning",["Place map marker"]] remoteExec ["BIS_fnc_showNotification", _player];
	[_player, "mortarStrike"] remoteExec ["BIS_fnc_addCommMenuItem", _player];
}
else
{	
	_pos = [getPos _player, 3000,3500,20,0] call BIS_fnc_findSafePos;

	_createdVehFnc = [_pos, 0, "rhsusf_M142_usarmy_D", west] call bis_fnc_spawnvehicle;
	_v = _createdVehFnc select 0;
	mainZeus addCuratorEditableObjects [[_v], true];

	_pos = [getMarkerPos last, 0, 75,1,0] call BIS_fnc_findSafePos; 
	_v commandArtilleryFire [[_pos select 0, _pos select 1, getTerrainHeightASL _pos], getArtilleryAmmo [_v] select 0, 1];

	sleep 30;
	_v setDamage 1;
};
