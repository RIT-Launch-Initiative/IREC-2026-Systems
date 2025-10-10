clear;

rrc3_launch = seconds(0);
rrc3_apogee = seconds(23.05);
rrc3_landing = seconds(152.25);
rrc3_evs = eventtable([rrc3_launch, rrc3_apogee, rrc3_landing], ...
    EventLabels = ["LAUNCH", "APOGEE", "LANDING"]);

rrc3_data = readtable(pfullfile("data", "OTIS_RRC3_primary.csv"), ...
    Delimiter = ",", VariableNamingRule = "preserve");
rrc3_data.Time = seconds(rrc3_data.Time);
rrc3_data = table2timetable(rrc3_data);

rrc3_data.Properties.Events = rrc3_evs;

cam_apogee = seconds(19.907);
cam_landing = seconds(148.752);

runcam_data = import_runcam_gcsv(pfullfile("data", "OTIS_runcam_mainbay.gcsv"));
runcam_data.Time = runcam_data.Time - cam_apogee;
runcam_data.Time = runcam_data.Time * ((rrc3_landing - rrc3_apogee) / (cam_landing - cam_apogee));
runcam_data.Time = runcam_data.Time + rrc3_apogee;
runcam_data.Properties.Events = rrc3_evs;

gps_launch = datetime(2025, 06, 11, 18, 32, 21.599, TimeZone = "UTC");
gps_apogee = datetime(2025, 06, 11, 18, 32, 45.199, TimeZone = "UTC");
gps_landing = datetime(2025, 06, 11, 18, 34, 55.000, TimeZone = "UTC");
gps_evs = eventtable([gps_launch, gps_apogee, gps_landing], ...
    EventLabels = ["LAUNCH", "APOGEE", "LANDING"]);

gps_data = import_featherweight_csv(pfullfile("data","rocket_fwt_gps.csv"));
gps_data.UTCTIME = gps_data.UTCTIME - days(1); % NOTE for some reason
gps_data.Properties.Events = gps_evs;

save(pfullfile("data", "measured.mat"), "rrc3_data", "runcam_data", "gps_data");
