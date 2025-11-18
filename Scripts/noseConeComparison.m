%% Nose Cone Shape Comparison
% IREC Systems 2026
% Last updated 24 October 2025
% This script compares effects of nose cone shapes on apogee using RasAero
% generated drag curves
%% Setup
clear; close all; clc;
% Retrieve openrocket
filepath = "C:\IREC-2026-Systems\Rocket Files\IREC-2026-N3800.ork";
rocket = openrocket(filepath);
% Reference simulations
sim = rocket.sims("15mph-Midland");
%% Inputs
% Valid sites: "spaceport-midland", "spaceport-america", "urrg", "mars"
site = launchsites("spaceport-midland"); 
% Launch time
lTime.date = [2025, 06, 21]; % [year, month, day]
lTime.time = [10, 21, 00]; % [hour, minute, second]
% Choose whether to load air data from an existing file or download NWS data
% Faster to choose an existing file if applicable
% If downloading data, adjust parameters at line 29 as needed
loadAirDataTable = true;
%"C:\IREC-2026-Systems\atmosphereData\21-Jun-2025-10.21.00-midland-gfs_1.mat"
airDataFilePath = "C:\IREC-2026-Systems\atmosphereData\postFlightAtmos.mat";
% Rasaero drag curve locations
dragFile1 = "C:\IREC-2026-Systems\Data\CDplot-N3800-16.csv";
dragFile2 = "C:\IREC-2026-Systems\Data\CDplot-N3800-20.csv";
dragFile3 = "C:\IREC-2026-Systems\Data\CDplot-N3800-blunt.csv";
dragFile4 = "C:\IREC-2026-Systems\Data\CDplot-N3800-cone16.csv";

%% Get atmosphere
launchtime = datetime(lTime.date(1), lTime.date(2), lTime.date(3),...
    lTime.time(1), lTime.time(2), lTime.time(3), TimeZone = "MST");
if loadAirDataTable
    airdata = importdata(airDataFilePath);
else
    airdata = atmosphere("gfs", "pgrb2.1p00", site.lat, site.lon, launchtime, minpres = 450); %#ok<UNRCH>
end
airdata.TMP = airdata.TMP + 273.15; % conv Celcius to Kelvin
%% Get drag curves
rasDrag1 = getRasDrag(dragFile1);
rasDrag2 = getRasDrag(dragFile2);
rasDrag3 = getRasDrag(dragFile3);
rasDrag4 = getRasDrag(dragFile4);

%% Simulate!! :)
disp("Running simulation 1")
simData = rocket.simulate(sim, outputs = "ALL", atmos = airdata(:, ["HGT", "PRES", "TMP"]),...
    wind = airdata, drag = rasDrag1);
maxAlts.A1 = max(simData.("Altitude"));

disp("Running simulation 2")
simData = rocket.simulate(sim, outputs = "ALL", atmos = airdata(:, ["HGT", "PRES", "TMP"]),...
    wind = airdata, drag = rasDrag2);
maxAlts.A2 = max(simData.("Altitude"));

disp("Running simulation 3")
simData = rocket.simulate(sim, outputs = "ALL", atmos = airdata(:, ["HGT", "PRES", "TMP"]),...
    wind = airdata, drag = rasDrag3);
maxAlts.A3 = max(simData.("Altitude"));

disp("Running simulation 4")
simData = rocket.simulate(sim, outputs = "ALL", atmos = airdata(:, ["HGT", "PRES", "TMP"]),...
    wind = airdata, drag = rasDrag4);
maxAlts.A4 = max(simData.("Altitude"));

%% Summary
clc; 
fprintf("Summary:\n---------------------------------------------------------");
fprintf("\n%20s %4.0f [m]", "16 inch Ogive:", maxAlts.A1);
fprintf("\n%20s %4.0f [m] %18s %3.0f [m]", "20 inch ogive:", maxAlts.A2, "Apogee reduction:", (maxAlts.A1-maxAlts.A2));
fprintf("\n%20s %4.0f [m] %18s %3.0f [m]", "16 inch elliptical:", maxAlts.A3, "Apogee reduction:", (maxAlts.A1-maxAlts.A3));
fprintf("\n%20s %4.0f [m] %18s %3.0f [m]", "16 inch cone:", maxAlts.A4, "Apogee reduction:", (maxAlts.A1-maxAlts.A4));
fprintf("\n");

%% Functions
function rasDrag = getRasDrag(dragFilePath)
    rasDrag = import_rasaero_aerodata(dragFilePath);
    rasDrag = rasDrag.align("mach");
    rasDrag = table(rasDrag.mach, rasDrag.pick{"aoa", 0, "field", "CD"}, ...
    VariableNames = ["MACH", "DRAG"]);
    rasDrag.MACH(1) = 0;
end