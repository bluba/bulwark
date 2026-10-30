_v = _this select 0;
_c = HOSTILE_LEVEL_3 +HOSTILE_LEVEL_2+HOSTILE_LEVEL_1;

_u = [];
		for ("_i") from 0 to _teamCount do {
			_u append [selectRandom _c];
		};

_cargoLimit = getNumber (configfile >> "CfgVehicles" >> _class >> "transportSoldier"); //units in cargo
_turretLimit = "getNumber (_x >> 'dontCreateAI') == 1" configClasses (configfile >> "CfgVehicles" >> _class >> "Turrets"); //not populated turret
_cargoLimit = _cargoLimit + (count _turretLimit); //cumulate values
		_grp = [[0,0,0], opforSide, _u, [], [], [0.3, 0.3]] call BIS_fnc_spawnGroup; // Create team onboard, need to be done at the last time or enableDynamicSimulation will fail
		_grp allowFleeing 0; //not allowed to flee
		_grp deleteGroupWhenEmpty true; //Mark for auto deletion and enable Dynamic simulation
		_cargoCurrent = 0;
		{
			_cargoCurrent = _cargoCurrent + 1; //increment 
			if (_cargoCurrent > _cargoLimit-2) then { //cargo overflow
				deleteVehicle _x; //delete unit
			} else {
				_x moveInCargo _v; //move in cargo
				_x assignAsCargo _v; //assign as cargo
				[_x] call nss_fnc_AIskill; //set skills
			};
			_x  setVariable ["aiMode","NonCQB"];
			_x setVariable ["lambs_danger_disableAI", true];
			mainZeus addCuratorEditableObjects [[_x], true];
		} forEach (units _grp); //units loop