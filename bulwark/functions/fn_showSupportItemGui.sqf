disableSerialization;
[1] call bulwark_fnc_shopTab;

_listFormat = "%1 - %2";
_ctrl = (findDisplay 9998) displayCtrl 1500;
_ctrl lbSetCurSel -1;
_ctrl ctrlEnable false;
lbClear _ctrl;

_ctrl = (findDisplay 9998) displayCtrl 1500;
lbClear _ctrl;
_ctrl lbAdd format [_listFormat, "1 ", "Lives"];
_ctrl lbAdd format [_listFormat, "2 ", "Supports"];

_ctrl = (findDisplay 9998) displayCtrl 1501;
_ctrl lbSetCurSel -1;
lbClear _ctrl;
SUPPORTMENU = missionNamespace getVariable "SUPPORTMENU";
if (SUPPORTMENU) then {
	_ctrl = (findDisplay 9998) displayCtrl 1500;
	_ctrl ctrlEnable true;
	_ctrl = (findDisplay 9998) displayCtrl 1501;
	_ctrl lbSetCurSel -1;
	_ctrl ctrlEnable true;
	lbClear _ctrl;	
}else{
  _ctrl ctrlEnable false;
  _ctrl lbAdd " ";
  _ctrl lbAdd "";
  _ctrl lbAdd "         A Satellite Dish must be found";
  _ctrl lbAdd "             to unlock Support Menu";
};
