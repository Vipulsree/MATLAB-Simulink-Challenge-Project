Time_sec = signals.Vs.Time;
VehicleSpeed_rads = signals.Vs.Data;
WheelSpeed_rads = signals.Ww.Data;
Distance_ft = signals.Sd.Data;
ABS_Results_Table = table(Time_sec,VehicleSpeed_rads,WheelSpeed_rads,Distance_ft);
writetable(ABS_Results_Table,'ABS_Baseline_Results.xlsx');
