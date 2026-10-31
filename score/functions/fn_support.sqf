/**
*  fn_support
*
*  Event handler for supports/communications menu
*
*  Domain: Client/Event
**/

if (!isServer) exitWith {};
params ["_player", ["_target", []], ["_type", ""], ["_aircraft", ""]];
if (!([_player] call bulwark_fnc_validCaller) || {!alive _player}) exitWith {};
/*
_target   = _this select 1;
_type     = _this select 2;
_aircraft = _this select 3; */

diag_log ["fn_support type %0",_type];

switch (_type) do {
    case ("paraTroop"): {
        [_player, _target, PARATROOP_COUNT, _aircraft, PARATROOP_CLASS] call supports_fnc_paraTroop;
    };
    case ("reconUAV"): {
        [_player, getPos _player, _aircraft] call supports_fnc_reconUAV;
    };
    case ("airStrike"): {
        [_player, _target, _aircraft] call supports_fnc_airStrike;
    };
    case ("ragePack"): {
        // Ragepack is a local effect so it needs to be executed locally
        [] remoteExec ["supports_fnc_ragePack", _player];
    };
    case ("armaKart"): {
    [_player] call supports_fnc_armaKart;
    };
    case ("mindConGas"): {
    [_player, _target] call supports_fnc_mindConGas;
    };
    case ("droneControl"): {
    [_player, _target] call supports_fnc_droneControl;
    };
    case ("mineField"): {
    [_player, _target] call supports_fnc_mineField;
    };
    case ("telePlode"): {
    [_player] call supports_fnc_telePlode;
    };
case ("ammoRequest"): {
        [_player, _target] call supports_fnc_ammoRequest;
    };
    case ("mortarStrike"): {
        [_player, _target] call supports_fnc_mortarStrike;
    };
    case ("artyStrike"): {
        [_player, _target] call supports_fnc_artyStrike;
    };
    case ("rocketStrike"): {
        [_player, _target] call supports_fnc_rocketStrike;
    };
};