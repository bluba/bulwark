params [["_waveId", attkWave]];
private _strikeCount = 1 + floor random (_waveId / 5);
_pos = [([] call bulwark_fnc_spawnAnchor), 2000, 2500, 5,0] call BIS_fnc_findSafePos;
for "_j" from 1 to _strikeCount do {
    if !([_waveId] call bulwark_fnc_waveActive) exitWith {}; 
	private _flightJob = [_pos, _waveId] spawn
	{
		private _wave = _this select 1;
		_height = 200;
		_players = ([] call bulwark_fnc_humanPlayers) select {alive _x && {lifeState _x != "INCAPACITATED"}};
        if (_players isEqualTo []) exitWith {};
		_player = selectRandom _players;
		_spawnLocationGround = [_this select 0, 25, 100, 0,0] call BIS_fnc_findSafePos;
		_spawnLocationAir = [_spawnLocationGround select 0, _spawnLocationGround select 1, _height];
		_aircraftClass = "CUP_O_Su25_Dyn_RU";
        if (!isClass (configFile >> "CfgVehicles" >> _aircraftClass)) exitWith {};
		_targetlocation = [getpos _player, 75, 125, 5,0] call BIS_fnc_findSafePos;
		_aircraftArr = [[_spawnLocationAir, 0, _aircraftClass, EAST], "vehicle", _wave, false] call bulwark_fnc_spawnLimited;
		_aircraft = _aircraftArr select 0;
        if (isNull _aircraft) exitWith {};	//the aircraft
		_aircraft setPos _spawnLocationAir;
		_reldir = [getPos _aircraft, _targetlocation] call BIS_fnc_dirTo;
		_aircraft setdir _reldir;
		_aircraft setVelocity [200 * (sin (getdir _aircraft)), 200 * (cos (getdir _aircraft )), 1];
		mainZeus addCuratorEditableObjects [[_aircraft], true];
		_crew = _aircraftArr select 1;	//the units that make up the crew
		_group = _aircraftArr select 2;	//the group
		{_x allowFleeing 0} forEach units _group;

		_aircraft flyInHeight _height;
		


		diag_log ["%0",(_aircraft weaponsTurret [-1])];
		_atacks = 0;
		while {alive _aircraft && {[_wave] call bulwark_fnc_waveActive} && _atacks < 16} do
		{
			_atacks = _atacks+1;
			_players = ([] call bulwark_fnc_humanPlayers) select {alive _x && {lifeState _x != "INCAPACITATED"}};
            if (_players isEqualTo []) exitWith {};
            _player = selectRandom _players;
			_targetlocation = [getpos _player, 0, 75, 5,0] call BIS_fnc_findSafePos;
			_reldir = [getPos _aircraft, _targetlocation] call BIS_fnc_dirTo;
			_aircraft setdir _reldir;
			_aircraft setVelocity [200 * (sin (getdir _aircraft)), 200 * (cos (getdir _aircraft )), 1];

				[_group, 1] setWaypointCombatMode "RED";

				_waypoint0 = _group addwaypoint[_targetlocation,0];
				_waypoint0 setwaypointtype "Move";
				_waypoint0 setWaypointCompletionRadius 1;

			_aircraft doTarget _player;

			/*
	13:00:23 "[""LowROF"",""close"",""near"",""short"",""medium"",""far""]"
	13:00:23 "[""Burst"",""Single"",""AIBurst""]"
	13:00:23 "[""this""]"
	13:00:23 "[""Far_AI"",""Medium_AI"",""Close_AI"",""Burst""]"
	13:00:23 "[""this""]"
			*/
			//12:11:49 ["%0",["CUP_Vacannon_GSh302K_veh","CMFlareLauncher","CUP_Vmlauncher_R73_veh","CUP_Vmlauncher_S8_veh","CUP_Vblauncher_Fab250_veh"]]
			if !([_aircraft, _player, 1200, 120, _wave] call bulwark_fnc_waitForAircraft) exitWith {};
			for [{_i = 0}, {_i < 5}, {_i = _i + 1}] do
			{
                if (!alive _aircraft || {!([_wave] call bulwark_fnc_waveActive)}) exitWith {};
				_hA = getPosATL _aircraft;
				_hT = getPosATL _player;
				_a = (_hA select 2) - (_hT select 2);
				_b = 1 max (_targetLocation distance2D getPos _aircraft);
				_angle =-((_a/_b)*45);
				diag_log _angle;
				[_aircraft, _angle-3, 0] call BIS_fnc_setPitchBank;
				_crew select 0 forceWeaponFire ["CUP_Vmlauncher_S8_veh","Burst"];
				if(_i%2==0) then {_crew select 0 forceWeaponFire ["CMFlareLauncher","Single"];};
				//_crew select 0 forceWeaponFire ["CUP_Vacannon_GSh302K_veh","close"];
				sleep 0.5;
			};

			if !([_aircraft, _player, 750, 60, _wave] call bulwark_fnc_waitForAircraft) exitWith {};

			_r = random 5;
			for [{_i = 0}, {_i < 15}, {_i = _i + 1}] do
			{
                if (!alive _aircraft || {!([_wave] call bulwark_fnc_waveActive)}) exitWith {};
				if(( getPosATL _aircraft )select 2 > 50) then {
					_hA = getPosATL _aircraft;
					_hT = getPosATL _player;
					_a = (_hA select 2) - (_hT select 2);
					_b = 1 max (_targetLocation distance2D getPos _aircraft);
					_angle =-((_a/_b)*45);
					diag_log _angle;
					[_aircraft, _angle-2, 0] call BIS_fnc_setPitchBank;
					//_crew select 0 forceWeaponFire ["CUP_Vmlauncher_S8_veh","Burst"];
					if(_i%5==0) then {_crew select 0 forceWeaponFire ["CMFlareLauncher","Single"];};
					_crew select 0 forceWeaponFire ["CUP_Vacannon_GSh302K_veh","close"];
					sleep 0.01
				};
			};
			private _nextAttack = time + 30;
            waitUntil {sleep 0.5; time >= _nextAttack || {!([_wave] call bulwark_fnc_waveActive)} || {!alive _aircraft}};
		};
		
		deletevehicle _aircraft;
		{deletevehicle _x} foreach _crew;
        deleteGroup _group;
	};
    BW_SPAWN_JOBS pushBack _flightJob;
	sleep 0.5;
};
