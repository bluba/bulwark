 _height = 200;
    _spawnGround = getPos bulwarkbox;//[bulwarkbox, 100, 200,5,0,1,0] call BIS_fnc_findSafePos;
    _spawnAir  = [(_spawnGround select 0), (_spawnGround select 1), _height];
//RHS_Mi8mt_Cargo_vvsc
//B_T_VTOL_01_vehicle_F
//RHS_TU95MS_vvs_tambov
//CUP_C_C47_CIV
//"CUP_O_UAZ_MG_RU",
//"CUP_O_GAZ_Vodnik_KPVT_RU",
//"CUP_O_GAZ_Vodnik_BPPU_RU",
//"CUP_O_GAZ_Vodnik_PK_RU",
//"CUP_O_GAZ_Vodnik_AGS_RU",
//"CUP_O_UAZ_AA_RU",
//"CUP_O_URAL_ZU23_RU

    _airVG = [_spawnAir, 0, "RHS_Mi8mt_Cargo_vvsc", WEST] call bis_fnc_spawnvehicle;
	_airV = _airVG select 0;
	mainZeus addCuratorEditableObjects [[_airV], true];

	_groundVLoc =[(_spawnAir select 0), (_spawnAir select 1), (_spawnAir select 2)-10];
    _groundVG = [_groundVLoc, 0, "CUP_O_GAZ_Vodnik_KPVT_RU", WEST] call bis_fnc_spawnvehicle;	
	_groundV = _groundVG select 0;
	mainZeus addCuratorEditableObjects [[_groundV], true];
	_groundV attachTo [_airV, [0,0,-10]];

	[_airV] call lambs_wp_fnc_taskReset;  
	_airV flyInHeight 12;
	/*
	sleep 10;
	detach _groundV;
	_parachute = "B_Parachute_02_F" CreateVehicle [0,0,0];		  
    _parachute setPos [getPos _groundV select 0, getPos _groundV select 1, getPos _groundV select 2];
    _groundV attachTo [_parachute, [0,0,0]];
	*/
	waitUntil {getpos _groundV select 2<4};
	detach _groundV;
