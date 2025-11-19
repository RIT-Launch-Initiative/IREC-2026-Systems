%% Numbers
% IREC Systems 2026
% This script runs openrocket simulations with adjustments for atmospheric
% profile, drag curve, and with extra outputs

clear; close all; clc;
%% Inputs
alt_target = 3423; % meters
alt_var = 127; % meters

%% Setup
% Retrieve openrocket
filepath = "Rocket Files/RISK.ork";
risk = openrocket(filepath);
rocket = risk.rocket();
% Reference simulation
sim = risk.sims("15mph-Midland");
% rocket parameters
L = rocket.getLength();
[D, ~] = risk.refdims();
% Other parameters
R = 0.287; % Specific gas constant for air

% Valid sites: "spaceport-midland", "spaceport-america", "urrg", "mars"
site = launchsites("spaceport-midland"); 
% Launch time
airDataFilePath = "atmosphereData\postFlightAtmos.mat";

% Rasaero drag curve
dragFilePath = "Data\CDplot-RISK.csv";

%% Get atmosphere
airdata = importdata(airDataFilePath);
airdata.TMP = airdata.TMP + 273.15; % conv Celcius to Kelvin
%% Get drag curve
rasDrag = import_rasaero_aerodata(dragFilePath);
rasDrag = rasDrag.align("mach");
rasDrag = table(rasDrag.mach, rasDrag.pick{"aoa", 0, "field", "CD"}, ...
    VariableNames = ["MACH", "DRAG"]);
rasDrag.MACH(1) = 0;

%% Simulate!!
simData = risk.simulate(sim, outputs = "ALL", atmos = airdata(:, ["HGT", "PRES", "TMP"]),...
    wind = airdata, drag = rasDrag);
% Add density and dynamic pressure to table
simData.("Air density") = simData.("Air pressure")./(1000*R*simData.("Air temperature"));
simData.("Dynamic pressure") = 0.5*simData.("Air density").*simData.("Total velocity").^2;
% Add percent stability to table
simData.("Stability percent") = 100*simData.("Stability margin")*D/L;
% Add Indicated altitude to table
simData.("Indicated altitude") = pressalt("m", simData.("Air pressure"), "Pa") - pressalt("m", simData{1, "Air pressure"}, "Pa");
simData.("Altitude error") = simData.("Indicated altitude") - simData.("Altitude");
% Times vector
times = simData.Time;
