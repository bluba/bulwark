params [["_container", objNull, [objNull]]];
if (!isServer || {isNull _container}) exitWith {0};
private _converted = 0;
isNil {
    private _cargo = getItemCargo _container;
    private _classes = _cargo select 0;
    private _counts = _cargo select 1;
    private _index = _classes find "FirstAidKit";
    if (_index >= 0) then {
        private _kits = _counts select _index;
        _converted = floor (_kits / 10);
        if (_converted > 0) then {
            _counts set [_index, _kits mod 10];
            clearItemCargoGlobal _container;
            {if ((_counts select _forEachIndex) > 0) then {
                _container addItemCargoGlobal [_x, _counts select _forEachIndex];
            }} forEach _classes;
            _container addItemCargoGlobal ["Medikit", _converted];
        };
    };
};
_converted
