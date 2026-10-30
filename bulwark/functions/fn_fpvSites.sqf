// Fixed map-authored settlement layout, cached once. No random world positions.
// An explicit BW_FPV_SITES array overrides this catalogue (including []).
if (!isNil "BW_FPV_SITES") exitWith {
    if (!(BW_FPV_SITES isEqualType [])) exitWith {[]};
    BW_FPV_SITES select {_x isEqualType [] && {count _x == 3} && {(_x findIf {!(_x isEqualType 0) || {!finite _x}}) < 0}}
};
private _sites = [];
{
    if (_x find "fpv_station_" == 0) then {_sites pushBack (getMarkerPos _x)};
} forEach allMapMarkers;
// Authored markers take precedence over the settlement fallback.
if !(_sites isEqualTo []) exitWith {BW_FPV_SITES = _sites; +_sites};
if (toLower worldName == "altis") then {
    {
        private _center = locationPosition _x;
        {
            private _radius = _x;
            {_sites pushBack (_center getPos [_radius, _x])} forEach [0,45,90,135,180,225,270,315];
        } forEach [350,550];
    } forEach nearestLocations [[worldSize / 2,worldSize / 2,0], ["NameVillage","NameCity","NameCityCapital"], worldSize];
};
BW_FPV_SITES = _sites;
+_sites
