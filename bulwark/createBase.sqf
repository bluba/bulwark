/**
*  createBase
*
*  Selects a base location and spawns required mission items
*
*  Domain: Server
*
*  EDITED BY: SMITH
**/

PLAYER_OBJECT_LIST =[]; //create empty variable for player placed objects

bulwarkBox = createVehicle ["PSZ_PL_WDL10_Star_1466", [0,0,0], [], 0, "CAN_COLLIDE"];
// pointBankAmount for the Bulwark box
bulwarkBox setVariable ["pointBankAmount", POINT_BANK_INIT_AMOUNT, true];

_bulMon = createVehicle ["Land_Laptop_device_F", [0,0,0], [], 0, "CAN_COLLIDE"];
_bulMon allowDamage false;
bulwarkBox allowDamage false;
bulwarkFallDamage = {
_damage = 0;
if((_this select 4) != "") then
{
  _damage = _this select 2;
};
_damage
};
bulwarkBox addEventHandler ["HandleDamage", { _this call bulwarkFallDamage }];
clearItemCargoGlobal bulwarkBox;
clearWeaponCargoGlobal bulwarkBox;
clearMagazineCargoGlobal bulwarkBox;
clearBackpackCargoGlobal bulwarkBox;
[_bulMon,[0,"preview.paa"]] remoteExec ["setObjectTexture",0,true];
_bulMon enableSimulation false;
_bulMon attachTo [bulwarkBox, [0,0.1,0.6]];
_bulMon setDir 180;

_isWater = true;
while {_isWater} do {
	_bulwarkLocation = [BULWARK_LOCATIONS, BULWARK_RADIUS] call bulwark_fnc_bulwarkLocation;
	bulwarkRoomPos = _bulwarkLocation select 0;
	bulwarkCity = _bulwarkLocation select 1;
	diag_log bulwarkRoomPos;
	diag_log bulwarkCity;
	bulwarkBox setPos ([bulwarkRoomPos, 0, 50, 1,0] call BIS_fnc_findSafePos);
	bulwarkCity = getPos bulwarkbox;	
	_isWater = surfaceIsWater (getPos bulwarkBox);
};

publicVariable "bulwarkCity";

//bulwarkBox addWeaponCargoGlobal["hgun_P07_F",10];
//bulwarkBox addMagazineCargoGlobal ["16Rnd_9x21_Mag",20];
if(BULWARK_MEDIKITS > 0) then {
	bulwarkBox addItemCargoGlobal ["Medikit", BULWARK_MEDIKITS];
};

//Add actions to Bulwark Box
[bulwarkBox, ["<t color='#00ffff'>" + "Pickup", "bulwark\moveBox.sqf","",1,false,false,"true","true",2.5]] remoteExec ["addAction", 0, true];
[bulwarkBox, ["<t color='#00ff00'>" + "Shop +", "[] spawn bulwark_fnc_purchaseGuiNew; ShopCaller = _this select 1", "",1.5, false,false, "true", "true", 2.5]] remoteExec ["addAction", 0, true];
/*[bulwarkBox, ["<t color='#0000ff'>" + "Old Shop", "[] spawn bulwark_fnc_purchaseGui; ShopCaller = _this select 1","",1.5,false,false,"true","true",2.5]] remoteExec ["addAction", 0, true];*/
[bulwarkBox, ["<t color='#ff0000'>" + "Heal Yourself: 200p", "
	[_this select 1] remoteExecCall ['bulwark_fnc_heal', 2];
","",1,false,false,"true","true",2.5]] remoteExec ["addAction", 0, true];

//Add Bulwark Box to Zeus
mainZeus addCuratorEditableObjects [[bulwarkBox], true];

//Add EH for text to explain the FAK to Medkit feature
[bulwarkBox, ["ContainerOpened", {
	_playerId = _this select 1;
	["<t size = '.5'>Place 10 FAKs into the Bulwark to convert them into a Medikit</t>", 0, 1, 60, 0] remoteExec ["BIS_fnc_dynamicText", _playerId];
}]] remoteExec ["addEventHandler", 0, true];
[bulwarkBox, ["ContainerClosed", {
	_playerId = _this select 1;
	["", 0, 1, 0.05, 0] remoteExec ["BIS_fnc_dynamicText", _playerId];
}]] remoteExec ["addEventHandler", 0, true];

/* Place a table in the room for the lulz */
_relPos = [bulwarkRoomPos, 10, 0] call BIS_fnc_relPos;
_hits = lineIntersectsSurfaces [bulwarkRoomPos vectorAdd [0,0,0.2], _relPos, bulwarkBox, objNull, true, 1, "GEOM", "NONE"];
_boxPos = getPos bulwarkBox;

if(count _hits > 0) then {
	_hit = _hits select 0;
	_obj = _hit select 2;
	_objDir = getDir _obj;

	_furthestDist = 0;
	_furthestAngle = 0;
	_furthestPos = [0,0,0];
	_furthestDir = 0;
	for ("_i") from 0 to 360 step 22.5 do {
		_checkAngle = _objDir + _i;
		_relPos = [bulwarkRoomPos, 10, _checkAngle] call BIS_fnc_relPos;
		_hits = lineIntersectsSurfaces [bulwarkRoomPos vectorAdd [0,0,0.2], _relPos, bulwarkBox, objNull, true, 1, "GEOM", "NONE"];
		if(count _hits > 0) then {
			_hit = _hits select 0;
			_hitPos = _hit select 0;
			_distance = _boxPos distance _hitPos;
			_normalDir = [[0,0,0],(_hit select 1)] call BIS_fnc_dirTo;

			if(_distance > _furthestDist) then {
				_furthestDist = _distance;
				_furthestAngle = _checkAngle;
				_furthestPos = _hitPos;
				_furthestDir = _normalDir;
			};
		};
	};

	_tablePos = [_furthestPos, -0.5, _furthestAngle] call BIS_fnc_relPos;
	table = createVehicle ["Land_TableSmall_01_f", [0,0,0], [], 0, "CAN_COLLIDE"];
	table setPos [_tablePos select 0, _tablePos select 1, _boxPos select 2];
	table setDir _furthestDir-90;
	bulwarkBox setDir _objDir;
};



lootHouses = bulwarkCity nearObjects ["House", BULWARK_RADIUS];
diag_log lootHouses;

[] execVM "bulwark\fakToMedkit.sqf";

/* Spinner Box */

private _positions = [];
{_positions append (_x buildingPos -1)} forEach lootHouses;
private _lootBoxRoom = if (_positions isEqualTo []) then {getPosATL bulwarkBox} else {selectRandom _positions};
lootBox = createVehicle ["Land_WoodenBox_F", _lootBoxRoom, [], 4];
publicVariable "lootBox";
[lootBox, ["<t color='#00ffff'>" + "Pickup", "bulwark\moveSpinBox.sqf"]] remoteExec ["addAction", 0, true];
[lootBox, [
	format ["<t color='#FF0000'>Spin the box! %1p</t>", SCORE_RANDOMBOX], "
		[_this select 1] remoteExecCall ['bulwark_fnc_spinBox', 2];
	"
]] remoteExec ["addAction", 0, true];



