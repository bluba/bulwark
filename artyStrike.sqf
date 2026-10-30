_ammo      = _this select 0;
_bombsite1 = _this select 1;
_delay     = _this select 2;
_height    = _this select 3;
_amount    = _this select 4;
_spread    = _this select 5;
_y         = 0;

//Delays the script for the amount of time stored in _delay

sleep _delay;

// Loops the amount of times stored in _amount

for [{_x = 0}, {_x <= _amount}, {_x = _x + 1}] 

do 

{
	//Creates the slected ARTY_Sh_122_HE at 300 meters
	_artilleryStrike = _ammo createVehicle [(getMarkerPos _bombsite1 select 0) + (_y - 10),( getMarkerPos _bombsite1 select 1) + 

(_y - 			10), _height];

	//Creates a ramndom number from 0 up to the value assigned to _spread
	_y = round(random _spread);

	//Delays the code for the selected amount of time
	sleep _delay;
};
