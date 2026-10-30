private _players = ([] call bulwark_fnc_humanPlayers) select {alive _x && {lifeState _x != "INCAPACITATED"}};
if (_players isEqualTo []) exitWith {getPosATL bulwarkBox};
getPosATL (selectRandom _players)
