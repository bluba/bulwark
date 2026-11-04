/**
*  spawnLoot
*
*  Spawns loot randomly around the play area
*
*  Domain: Server
**/

//activeLoot = [];
lootDebugMarkers = [];

private _started = diag_tickTime;
private _houseRooms = [];
lootHouses = [];
private _lootPositions = [];
{
    private _rooms = _x buildingPos -1;
    if !(_rooms isEqualTo []) then {
        lootHouses pushBack _x;
        _houseRooms pushBack _rooms;
        _lootPositions append _rooms;
    };
} forEach ((getPos bulwarkBox) nearObjects ["House", 100]);
if (lootHouses isEqualTo []) exitWith {diag_log "Bulwark: no enterable buildings near the truck"};
private _weaponPool = LOOT_WEAPON_POOL - List_Launchers;
/* Item to reveal all loot on the Map (1 spawns every wave) */
droneRoom = selectRandom _lootPositions;


/* Item to unlock Support Menu (1 spawns every wave until found) */
satRoom = [];
if (!SUPPORTMENU) then {
	satRoom = selectRandom _lootPositions;
	_satSupport = createVehicle ["Land_SatelliteAntenna_01_F", satRoom, [], 0, "CAN_COLLIDE"];
	[_satSupport, ["<t color='#ff00ff'>" + "Unlock Support Menu", "
		_satSupport = _this select 0;
		_player = _this select 1;
		[_satSupport] remoteExec ['removeAllActions', 0];
		_pointsMulti = ('SCORE_KILL' call BIS_fnc_getParamValue);
		if (!SUPPORTMENU) then {
			['TaskAssigned',['Support','Support Menu Unlocked at Bulwark Box']] remoteExec ['BIS_fnc_showNotification', 0];
			['comNoise'] remoteExec ['playSound', 0];
		};
		SUPPORTMENU = true;
		publicVariable 'SUPPORTMENU';
		SatUnlocks = missionNamespace getVariable 'SatUnlocks';
		[_player, (20 * _pointsMulti)] remoteExecCall ['killPoints_fnc_add', 2];
		{
			[_x] remoteExec ['deleteVehicle', 2];
		} forEach SatUnlocks;
	"]] remoteExec ["addAction", 0, true];
	SatUnlocks pushBack _satSupport;
	publicVariable 'SatUnlocks';
	mainZeus addCuratorEditableObjects [[_satSupport], true];
};

//activeLoot pushback _droneSupport;

// Item to give KillPoints (1 spawns every wave)
pointsLootRoom = selectRandom _lootPositions;
pointsLoot = createVehicle ["Land_Money_F", pointsLootRoom, [], 0, "CAN_COLLIDE"];
[pointsLoot, ["<t color='#00ff00'>" + "Collect Points", "[_this select 0, _this select 1] execVM 'loot\lootPoints.sqf'; [_this select 0] remoteExec ['removeAllActions', 0];","",1,true,false,"true","true",2.5]] remoteExec ["addAction", 0, true];

//activeLoot pushback pointsLoot;
_lootCount =0;
/* Master loot spawner */
_houseCount = floor random 3; // Mix up the loot houses a bit
_houseLoot = 0;
_roomCount = 0;
{

	_houseCount = _houseCount + 1;
	if (_houseCount mod LOOT_HOUSE_DISTRIBUTION == 0) then {
		_houseLoot = _houseLoot + 1;

		_lootBulding = _x;
		_lootRooms = _houseRooms select _forEachIndex;

		_roomCount = -1;
		{
			_roomCount = _roomCount + 1;
			if (_roomCount mod LOOT_ROOM_DISTRIBUTION == 0) then {
				if (!(_x isEqualTo droneRoom) && !(_x isEqualTo satRoom) && !(_x isEqualTo pointsLootRoom)) then {
					_lootRoomPos = _x;
					_lootHolder = "WeaponHolderSimulated_Scripted" createVehicle _lootRoomPos;
					if (LOOT_WHITELIST_MODE != 1) then {
						switch (floor random 8) do {
							case 7;
							case 6;
							case 0: {
								_weapon = selectRandom _weaponPool;
								_ammoArray = getArray (configFile >> "CfgWeapons" >> _weapon >> "magazines");
								_lootHolder addMagazineCargoGlobal [selectRandom _ammoArray, 1];
								_lootHolder addWeaponCargoGlobal [_weapon, 1];
							};
							case 1: {
								_weapon = selectRandom _weaponPool;
								_ammoArray = getArray (configFile >> "CfgWeapons" >> _weapon >> "magazines");
								_lootHolder addMagazineCargoGlobal [selectRandom _ammoArray, 1 + (floor random 3)];
							};
							case 2: {
								_clothes = selectRandom LOOT_APPAREL_POOL;
								_lootHolder addItemCargoGlobal [_clothes, 1];
							};
							case 3: {
								_items = selectRandom LOOT_ITEM_POOL;
								_lootHolder addItemCargoGlobal [_items, 1];
							};
							case 4: {
								_backpack = selectRandom LOOT_STORAGE_POOL;
								_lootHolder addBackpackCargoGlobal [_backpack, 1];
							};
							case 5: {
								_explosive = selectRandom LOOT_EXPLOSIVE_POOL;
								_lootHolder addMagazineCargoGlobal [_explosive, 1 + (floor random 3)];
							};
						};
					};
					if (LOOT_WHITELIST_MODE > 0) then {
						switch (floor random 8) do {
							case 7;
							case 6;
							case 0: {
								_weapon = selectRandom LOOT_WHITELIST_WEAPON;
								_ammoArray = getArray (configFile >> "CfgWeapons" >> _weapon >> "magazines");
								_lootHolder addMagazineCargoGlobal [selectRandom _ammoArray, 1];
								_lootHolder addWeaponCargoGlobal [_weapon, 1];
							};
							case 1: {
								_weapon = selectRandom LOOT_WHITELIST_WEAPON;
								_ammoArray = getArray (configFile >> "CfgWeapons" >> _weapon >> "magazines");
								_lootHolder addMagazineCargoGlobal [selectRandom _ammoArray, 1 + (floor random 3)];
							};
							case 2: {
								_clothes = selectRandom LOOT_WHITELIST_APPAREL;
								_lootHolder addItemCargoGlobal [_clothes, 1];
							};
							case 3: {
								_items = selectRandom LOOT_WHITELIST_ITEM;
								_lootHolder addItemCargoGlobal [_items, 1];
							};
							case 4: {
								_backpack = selectRandom LOOT_WHITELIST_STORAGE;
								_lootHolder addBackpackCargoGlobal [_backpack, 1];
							};
							case 5: {
								_explosive = selectRandom LOOT_WHITELIST_EXPLOSIVE;
								_lootHolder addMagazineCargoGlobal [_explosive, 1 + (floor random 3)];
							};
						};
					};
					_lootHolder setPos [_lootRoomPos select 0, _lootRoomPos select 1, (_lootRoomPos select 2) + 0.1];

					//activeLoot pushback _lootHolder; // Add object to array for later cleanup

					[_lootHolder, ['ContainerClosed', { // Add event to delete container if empty
							params ['_container','_player'];
							[_container] call loot_fnc_deleteIfEmpty;
					}]] remoteExec ['addEventHandler', 0];
					_lootCount =_lootCount +1;
					// Spread object/network creation across frames in dense towns.
                    if (canSuspend && {_lootCount mod 5 == 0}) then {sleep 0.01};

				};

			};
		} forEach _lootRooms;
	};

} forEach lootHouses;

/* Supply Drop */
//[bulwarkCity, ["<t color='#00ff00'>" + "FILL AMMO", "supports\ammoDrop.sqf","",2,true,false,"true","true",4], "B_T_VTOL_01_vehicle_F"] remoteExec ["supports_fnc_supplyDrop", 2];

diag_log format ["BULWARK PERF loot spawn: %1 objects, %2 houses, %3 ms elapsed (includes pacing)", _lootCount, count lootHouses, 1000 * (diag_tickTime - _started)];
