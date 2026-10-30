/**
*  fn_paraTroop
*
*  Calls VTOL to drop a group of paratroopers on the specified location
*
*  Domain: Server
**/
params ["_player", "_targetPos"];

if (count _targetPos == 0) then {
  [_player, "paraDrop"] remoteExec ["BIS_fnc_addCommMenuItem", _player]; //refund the support if looking at sky when activated
}else{
    _height = 200;
    _spawnGround = [_player, 4000, 4500,5,0,1,0] call BIS_fnc_findSafePos;
    _spawnAir  = [(_spawnGround select 0), (_spawnGround select 1), _height];
    _dropGround =_targetPos; 
    _dropAir  = [(_dropGround select 0), (_dropGround select 1), _height];
//RHS_Mi8mt_Cargo_vvsc
//B_T_VTOL_01_vehicle_F
//RHS_TU95MS_vvs_tambov
//CUP_C_C47_CIV
    _agSpawn = [_spawnAir, 0, "B_T_VTOL_01_vehicle_F", WEST] call bis_fnc_spawnvehicle;
    _agVehicle = _agSpawn select 0;	//the aircraft
    mainZeus addCuratorEditableObjects [[_agVehicle], true];
    _agCrew = _agSpawn select 1;	//the units that make up the crew
    _ag = _agSpawn select 2;	//the group
    {_x allowFleeing 0} forEach units _ag;    
    _agVehicle flyInHeight _height;

      _relDir = [getpos _agVehicle, _dropAir] call BIS_fnc_dirTo;
      _agVehicle setdir _relDir;
      _agVehicle setVelocity [200 * (sin (getdir _agVehicle)), 200 * (cos (getdir _agVehicle )), 1];
      sleep 5;
      [_ag, 1] setWaypointSpeed "LIMITED";
      [_ag, 1] setWaypointCombatMode "RED";
      [_ag, 1] setWaypointBehaviour "CARELESS";
      _waypoint0 = _ag addwaypoint[_dropAir,0];
     _waypoint0 setwaypointtype "Move";

      //_waypoint0 setWaypointStatements ["True","_heli =vehicle this; _heli addItemCargoGlobal ['Medikit', 1];"];

      waitUntil { (_dropGround distance2D getPos _agVehicle)  < 100 || (_dropGround distance2D getPos _agVehicle) > 3000};

      if((_dropGround distance2D getPos _agVehicle) > 4000) then {
        _relDir = [getpos _agVehicle, _dropAir] call BIS_fnc_dirTo;
        _agVehicle setdir _relDir;
        sleep 5;
        [_ag, 1] setWaypointSpeed "LIMITED";
        [_ag, 1] setWaypointCombatMode "RED";
        [_ag, 1] setWaypointBehaviour "CARELESS";
        _waypoint0 = _ag addwaypoint[_dropAir,0];
      _waypoint0 setwaypointtype "Move";
      _waypoint1 = _ag addwaypoint[[_targetPos, 4000, 4500,5,0,1,0] call BIS_fnc_findSafePos,0];
      _waypoint1 setwaypointtype "Move";
      sleep 5;
      };
      waitUntil { (_dropGround distance2D getPos _agVehicle)  < 100 || (_dropGround distance2D getPos _agVehicle) > 2000};
      // Drop cargo
      _classes = ["rhs_vdv_sergeant","rhs_vdv_medic","rhs_vdv_arifleman","rhs_vdv_arifleman_rpk","rhs_vdv_rifleman","rhs_vdv_LAT"];   

          _myGroup = [_spawnGround, EAST, _classes,[],[],[],[],[],180] call BIS_fnc_spawnGroup;
          hosSkill = 0.7;         
        
          _supplyBox = createVehicle ["B_supplyCrate_F", [0,0,0], [], 0, "CAN_COLLIDE"];	
		  
		  clearItemCargoGlobal _supplyBox;
			clearWeaponCargoGlobal _supplyBox;
			clearMagazineCargoGlobal _supplyBox;
			clearBackpackCargoGlobal _supplyBox;	  

			 _supplyBox addItemCargoGlobal ["Medikit", 2];
			 _supplyBox addItemCargoGlobal ["FirstAidKit", 6];

         	 _supplyBox setPos [getPos _agVehicle select 0, getPos _agVehicle select 1, (getPos _agVehicle select 2)-5];
			{
			// Current result is saved in variable _x
			[_supplyBox,_x] execVM "supports\ammoDrop.sqf";
			} forEach allPlayers;
			if(attkWave>5) then {
				_supplyBox addItemCargoGlobal ["PSZ_RPG7V",1];
				_supplyBox addItemCargoGlobal ["PSZ_Grom",3];
				_supplyBox addItemCargoGlobal ["PSZ_PG7VR_THEAT",2];
			};
			if(attkWave>10) then{				
 				_supplyBox addItemCargoGlobal ["PSZ_Spike_THEAT",2];
 				_supplyBox addItemCargoGlobal ["PSZ_Spike_LR",1];
			};
          //[_supplyBox, ["<t color='#00ff00'>" + "FILL AMMO", "supports\ammoDrop.sqf","",2,true,false,"true","true",4]] remoteExec ["addAction", 0, true];
		  waitUntil {((getpos _supplyBox) select 2)<50};
		  _parachute = "B_Parachute_02_F" CreateVehicle [0,0,0];		  
          _parachute setPos [getPos _supplyBox select 0, getPos _supplyBox select 1, getPos _supplyBox select 2];
          _supplyBox attachTo [_parachute, [0,0,0]];
          _supplyBox allowDamage false;
          waitUntil {getpos _supplyBox select 2<4};
          _smoker = "SmokeShellBlue" createVehicle (getpos _supplyBox vectorAdd [0,0,5]);
          detach _supplyBox;
			_supplyBox setVariable ["spawnWave",attkWave];
			 mainZeus addCuratorEditableObjects [[_supplyBox], true];
          sleep 15;

    
    deletevehicle _agVehicle;
    {deletevehicle _x} foreach _agCrew;
};
