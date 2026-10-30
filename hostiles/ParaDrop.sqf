diag_log "PARATROOPERS SQF";
/**
*  fn_supplyDrop
*
*  Calls VTOL to drop a box with the action definend by _cargo attached
*
*  Domain: Server
**/
 for "_i" from 0 to  floor( attkWave/5) do {
  [] spawn {
    _angle = round random 180;
    _height = 100;


    _targetPos = getPos selectRandom allPlayers ;

    _spawnGround = [bulwarkbox, 500, 1000,5,0,1,0] call BIS_fnc_findSafePos;
    _spawnAir  = [(_spawnGround select 0), (_spawnGround select 1), _height];
    _dropGround = [bulwarkbox, 50, 100,1,0] call BIS_fnc_findSafePos;    
    _dropAir  = [(_dropGround select 0), (_dropGround select 1), _height];
    _extractGround = [bulwarkbox, 1000, 1500,5,0,1,0] call BIS_fnc_findSafePos;
    _extractAir  = [(_extractGround select 0), (_extractGround select 1), _height];
//RHS_Mi8mt_Cargo_vvsc
//B_T_VTOL_01_vehicle_F
//RHS_TU95MS_vvs_tambov
//CUP_C_C47_CIV
    _agSpawn = [_spawnAir, 0, "RHS_Mi8mt_Cargo_vvsc", EAST] call bis_fnc_spawnvehicle;
    _agVehicle = _agSpawn select 0;	//the aircraft
    _relDir = [_spawnAir, _dropAir] call BIS_fnc_dirTo;
      _agVehicle setdir _relDir;

    mainZeus addCuratorEditableObjects [[_agVehicle], true];
    _agCrew = _agSpawn select 1;	//the units that make up the crew
    _ag = _agSpawn select 2;	//the group
    {_x allowFleeing 0} forEach units _ag;

    _agVehicle flyInHeight _height;
 

    [_ag, 1] setWaypointSpeed "FULL";
    [_ag, 1] setWaypointCombatMode "RED";
    [_ag, 1] setWaypointBehaviour "CARELESS";

    _waypoint0 = _ag addwaypoint[_dropAir,0];
    _waypoint0 setwaypointtype "Move";
    _waypoint0 setWaypointCompletionRadius 1;
  
    _waypoint0 setWaypointStatements ["True","vehicle this setFuel 0.5;"];
    //_waypoint0 setWaypointStatements ["True","_heli =vehicle this; _heli addItemCargoGlobal ['Medikit', 1];"];

 


    _agVehicle animateDoor ['Door_1_source', 1];
    waitUntil{  fuel _agVehicle < 0.6};
    sleep 1.5;

    _agVehicle doMove _extractAir;

    // Drop cargo
    _classes = ["rhs_vdv_sergeant","rhs_vdv_medic","rhs_vdv_arifleman","rhs_vdv_arifleman_rpk","rhs_vdv_rifleman","rhs_vdv_LAT"];
       

        _myGroup = [_spawnGround, EAST, _classes,[],[],[],[],[],180] call BIS_fnc_spawnGroup;
        hosSkill = 0.7;
        _attGroupBand = createGroup [EAST, true];
        {
          _unit = _x;
          [_unit] join _attGroupBand;
          _unit setUnitAbility hosSkill;
          _unit setSkill ["aimingAccuracy", hosSkill];
          _unit setSkill ["aimingSpeed", (hosSkill * 0.75)];
          _unit setSkill ["aimingShake", hosSkill];
          _unit setSkill ["spotTime", 0.05];
          _unit addEventHandler ["Hit", killPoints_fnc_hit];
          _unit addEventHandler ["Killed", killPoints_fnc_killed];
          removeAllAssignedItems _unit; 
          _unit setVariable ["points", []];
          _unit setVariable ["killPointMulti", 2];
          _unit addBackpack "B_Parachute";
          
          _unit setPos [getPos _agVehicle select 0, getPos _agVehicle select 1, (getPos _agVehicle select 2)-2];
          sleep 1;

          mainZeus addCuratorEditableObjects [[_unit], true];
          unitArray = waveUnits select 0;
          unitArray append [_unit];			

          _x setVariable ["lambs_danger_disableAI", nil];
          [_x, 1000] spawn lambs_wp_fnc_taskRush;

          diag_log _unit;			
          
        } foreach units _myGroup;


    sleep 15;
    deletevehicle _agVehicle;
    {deletevehicle _x} foreach _agCrew;

  };
};