%% Drag estimation tool
% IREC Systems 2026
% This script calculates the drag curve of a rocket from flight data
clear; close all; clc;
%% Inputs
samplerate=100;
dt=1/samplerate;
timeInterval = 30; % [s] Length of time to use
rrc3FilePath = pfullfile("Drag Estimation\Flight Data\OTIS","OTIS Primary RRC3.xlsx");
featherweightFilePath = pfullfile("Drag Estimation\Flight Data\OTIS","featherweight_downloaded.csv");
ORFilePath = pfullfile("Rocket Files\Other","TB-1.ork");
airDataFilePath = "atmosphereData\airdata.mat";
ORSimName = "15mph_URRG";

%% Load and trim flight data
% Load data
rrc3Data = readtable(rrc3FilePath);
featherweightData = readtable(featherweightFilePath,"Delimiter",",");
airData = load(airDataFilePath);

%% Get dimensions and mass trend from openrocket
OR = openrocket(ORFilePath);
rocket = OR.rocket();
% Reference simulation
sim = OR.sims(ORSimName);
% Rocket parameters
L = rocket.getLength();
[D, A] = OR.refdims();
% Run simulation
simData = OR.simulate(sim, outputs = "ALL");
% Isolate mass over time
massCurve = simData(:, "Mass");

%% Trim and re-sample
% Prepare time vector
globalTime = (0:dt:30);

% Pressure-altitude relationship
press = flip(airData.PRES);
alt = flip(airData.HGT);
adjPressAlt = griddedInterpolant(press, alt, "linear", "linear");

% Trim data
rrc3DataTrimmed = trimRRC3Data(rrc3Data, adjPressAlt);
featherweightTrimmed = trimFeatherweightData(featherweightData);

% Re-sample and align
[rrc3Data, featherweightData] = alignData(rrc3DataTrimmed, featherweightTrimmed, globalTime);

%% Process
%[motion.time, motion.vel, motion.vel, motion.accel] = filterData(rrc3Data, featherweightData, 0, 0, 0);

%% Drag calculation

