// Fixed map-authored settlement layout, cached once. No random world positions.
// An explicit BW_FPV_SITES array overrides this catalogue (including []).
if (!isNil "BW_FPV_SITES") exitWith {
    BW_FPV_SITE_SOURCE = "explicit";
    if (!(BW_FPV_SITES isEqualType [])) exitWith {[]};
    BW_FPV_SITES select {_x isEqualType [] && {count _x == 3} && {(_x findIf {!(_x isEqualType 0) || {!finite _x}}) < 0}}
};
if (!isNil "BW_FPV_CACHED_SITES") exitWith {
    BW_FPV_SITE_SOURCE = missionNamespace getVariable ["BW_FPV_CACHED_SITE_SOURCE","automatic"];
    +BW_FPV_CACHED_SITES
};
private _sites = [];
{
    if (_x find "fpv_station_" == 0) then {_sites pushBack (getMarkerPos _x)};
} forEach allMapMarkers;
// Authored markers take precedence over the settlement fallback.
if !(_sites isEqualTo []) exitWith {BW_FPV_CACHED_SITE_SOURCE = "markers"; BW_FPV_SITE_SOURCE = "markers"; BW_FPV_CACHED_SITES = _sites; +_sites};
if (toLower worldName == "altis") then {
    {
        private _center = locationPosition _x;
        {
            private _radius = _x;
            {_sites pushBack (_center getPos [_radius, _x])} forEach [0,15,30,45,60,75,90,105,120,135,150,165,180,195,210,225,240,255,270,285,300,315,330,345];
        } forEach [150,350,550,750];
    } forEach nearestLocations [[worldSize / 2,worldSize / 2,0], ["NameVillage","NameCity","NameCityCapital"], worldSize];
};
BW_FPV_CACHED_SITE_SOURCE = "automatic";
BW_FPV_SITE_SOURCE = "automatic";
BW_FPV_CACHED_SITES = _sites;
+_sites
