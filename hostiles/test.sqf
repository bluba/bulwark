_pos = [getPos bulwarkBox, 9000,9500,20,0] call BIS_fnc_findSafePos;
for "_i" from 0 to 3 do {
	[_pos] spawn {
		
		_pos = [_this select 0, 0,50,20,0] call BIS_fnc_findSafePos;
		_createdVehFnc = [_pos, 0, "RHS_BM21_MSV_01", west] call bis_fnc_spawnvehicle;
		_v = _createdVehFnc select 0;
		mainZeus addCuratorEditableObjects [[_v], true];

		diag_log getArtilleryAmmo [_v];

		_pos = [getPos bulwarkBox, 0,100,20,0] call BIS_fnc_findSafePos;
		_v commandArtilleryFire [[_pos select 0, _pos select 1, getTerrainHeightASL _pos], getArtilleryAmmo [_v] select 0, 99];

		sleep 30;
		_v setDamage 1;
		//_allTurrets = "rhsusf_M142_usarmy_D" call BIS_fnc_allTurrets;
	};
};
