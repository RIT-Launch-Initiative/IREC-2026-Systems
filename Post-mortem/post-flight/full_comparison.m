% load_conditions;
% load_flightdata;
% fprintf(2, "The first 'load_' lines are only necessary once, comment out to save time after this\n")
% comment these out after the first run

clear;

%% DATA INPUT
m_per_ft = 0.3048;
Pa_per_mbar = 100;
%
ork_path = pfullfile("data", "otis.ork");
air_data = pfullfile("data", "airdata.mat");
flight_data = pfullfile("data", "measured.mat");
% filtered_data = pfullfile("data", "filtered.mat");

aero_path = pfullfile("data", "OTIS_RA_Aerodata.CSV");

base_config_name = "[M6000ST-P]";
mod_config_name = "[M6000ST-PS-Custom-P]";

% requires running <load_conditions>
load(air_data, "airdata", "launch");

% requires running <load_flightdata>
load(flight_data, "rrc3_data", "runcam_data", "gps_data");

% requires running <postprocessing>
% load(filtered_data, "logs");

doc = openrocket(ork_path);
orksim = doc.sims("Postflight");

aerotable = import_rasaero_aerodata(aero_path);
orkdrag = ork2dragtable(doc, 0:0.05:1.5);

%% MODIFY FOR SIMULATION INPUT

airdata.TMP = airdata.TMP + 273.15; % C to K

aerotable = aerotable.align("mach");
rasdrag = table(aerotable.mach, aerotable.pick{"aoa", 0, "field", "CD"}, ...
    VariableNames = ["MACH", "DRAG"]);
rasdrag.MACH(1) = 0; % first point RA2 gives is at 0.1, but that causes NaNs in OR

gps_data{:, ["ALT", "HORZV", "VERTV"]} = gps_data{:, ["ALT", "HORZV", "VERTV"]} * m_per_ft;
gps_data.Time = gps_data.UTCTIME - launch.time;

rrc3_data.("Corrected Altitude") = interp1(flip(airdata.PRES), ...
    flip(airdata.HGT), rrc3_data.Pressure * Pa_per_mbar);
rrc3_data.("Corrected Altitude") = rrc3_data.("Corrected Altitude") - ...
    rrc3_data{1, "Corrected Altitude"};

%% SIMULATE

base_cfg = doc.get_config(base_config_name);
orksim.setFlightConfigurationId(base_cfg.getId);
baseline = openrocket.simulate(orksim, outputs = "ALL");

mod_cfg = doc.get_config(mod_config_name);
orksim.setFlightConfigurationId(mod_cfg.getId);
bestfit = openrocket.simulate(orksim, outputs = "ALL", ...
    atmos = airdata, wind = airdata, drag = rasdrag);

%% Compare data sources and methodologies

figure(name = "Flight data comparison");
hold on; grid on;

plot(baseline.Time, baseline.Altitude, DisplayName = "Baseline simulation");
plot(bestfit.Time, bestfit.Altitude, DisplayName = "Best-fit (drag+atmos+wind+TC)");
plot(gps_data.Time, gps_data.ALT - gps_data.ALT(1), DisplayName = "GPS altitude");
plot(rrc3_data.Time, rrc3_data.("Corrected Altitude"), DisplayName = "Corrected RRC3 altitude");

legend;
ylabel("Geometric altitude");
ysecondarylabel("m AGL");
xlabel("Time");

%% Compare drag curves between Ras/OR for OTIS and OMEN

figure(name = "Drag curve comparison");
layout = tiledlayout("vertical");
layout.TileSpacing = "compact";

nexttile; hold on; grid on;
title("OTIS");

plot(orkdrag.MACH, orkdrag.DRAG, DisplayName = "OpenRocket");
plot(rasdrag.MACH, rasdrag.DRAG, DisplayName = "RasAero");

legend;
ylabel("Drag coefficient");
ylim([0 1]);


nexttile; hold on; grid on;
title("OMEN");

% Read in OMEN data for reference
omen_doc = openrocket(pfullfile("data", "omen.ork"));
omen_aero_path = pfullfile("data", "OMEN_RA_Aerodata.CSV");
omen_aerotable = import_rasaero_aerodata(omen_aero_path);
omen_orkdrag = ork2dragtable(omen_doc, 0:0.05:1.5);
omen_rasdrag = table(omen_aerotable.mach, omen_aerotable.pick{"aoa", 0, "field", "CD"}, ...
    VariableNames = ["MACH", "DRAG"]);
omen_rasdrag.MACH(1) = 0; % first point RA2 gives is at 0.1, but that causes NaNs in OR

plot(omen_orkdrag.MACH, omen_orkdrag.DRAG, DisplayName = "OpenRocket");
plot(omen_rasdrag.MACH, omen_rasdrag.DRAG, DisplayName = "RasAero");
legend;

ylabel("Drag coefficient");
ylim([0 1]);

xlabel(layout, "Mach number");
linkaxes(findobj(layout.Children, Type = "axes"), "x")
xlim([0 1.2]);
