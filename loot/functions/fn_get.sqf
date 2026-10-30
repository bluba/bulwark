/**
*  get
*
*  returns a list of all Loot in Zone
*
*  Domain: Client
**/
objects = [];
{
	// Current result is saved in variable _x
	objects = objects  + nearestObjects [getPos _x,["WeaponHolderSimulated_Scripted","WeaponHolderSimulated","Box_C_UAV_06_Swifd_F","Land_Money_F","Weapon_Empty","GroundWeaponHolder"],BULWARK_RADIUS * 1.2];
} forEach allPlayers;
objects
