// Shared visibility switch; reserve CAT_OPEN 2 for standalone debug buttons.
params [["_tab", 0, [0]]];
if (!hasInterface || {!(_tab in [0, 1, 2, 3])}) exitWith {};
disableSerialization;
private _display = findDisplay 9998;
if (isNull _display) exitWith {};
CAT_OPEN = _tab;
(_display displayCtrl 1501) ctrlSetTooltip "";
private _debug = _tab == 2;
{(_display displayCtrl _x) ctrlShow (!_debug)} forEach [1500, 1501, 1602, 1200];
{(_display displayCtrl _x) ctrlShow _debug} forEach [1611, 1010, 1510, 1612, 1613];
if (_debug) then {
    private _allowed = isServer || {serverCommandAvailable "#kick"};
    {(_display displayCtrl _x) ctrlEnable _allowed} forEach [1611, 1612, 1613];
    private _list = _display displayCtrl 1510;
    if (lbSize _list == 0) then {
        {private _row = _list lbAdd (_x select 1); _list lbSetData [_row, _x select 0]} forEach ([] call bulwark_fnc_debugSpecials);
        _list lbSetCurSel 0;
    };
};
