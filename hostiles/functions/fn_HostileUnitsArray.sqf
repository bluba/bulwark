params ["_groupConfig", "_destArr"];
_count = count (_groupConfig);
for "_x" from 0 to (_count-1) do {
    _item=((_groupConfig) select _x);
    if (isClass _item) then {
		if((getText (_item >> "vehicle") in _destArr)==false) then 
      {
		    _destArr pushback getText (_item >> "vehicle");
      };
    };
};
_destArr;