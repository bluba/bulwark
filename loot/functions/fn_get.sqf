// Return each loot object once even when player search areas overlap.
private _objects = [];
{
    {
        _objects pushBackUnique _x;
    } forEach (nearestObjects [getPos _x, ["WeaponHolderSimulated_Scripted", "WeaponHolderSimulated", "Box_C_UAV_06_Swifd_F", "Land_Money_F", "Weapon_Empty", "GroundWeaponHolder"], BULWARK_RADIUS * 1.2]);
} forEach allPlayers;
_objects
