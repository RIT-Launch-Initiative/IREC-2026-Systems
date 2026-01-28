%% Adjusted simulation tool
% IREC Systems 2026
% This script calculates the drag curve of a rocket from flight data
clear; close all; clc;
%% Inputs
rrc3FilePath = "C:\IREC-2026-Systems\Drag Estimation\Flight Data\OTIS\OTIS Primary RRC3.xlsx";
featherweightFilePath = "C:\IREC-2026-Systems\Drag Estimation\Flight Data\OTIS\featherweight_downloaded.csv";
ORFilePath = "C:\IREC-2026-Systems\Rocket Files\Older Rockets\IREC_2025_M6000ST-0.ork";
ORSimName = "15MPH-TEXAS-36C-(TYP)";

%% Load and trim flight data
% Load data
rrc3Data = readtable(rrc3FilePath);
featherweightData = readtable(featherweightFilePath);

% Trim data
rrc3DataTrimmed = trimRRC3(rrc3Data);

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

%% Process
[motion.time, motion.vel, motion.accel] = filterData(rrc3Data, featherweightData);

%% Drag calculation


%% Functions
function dataOut = trimRRC3(dataIn)
    % figure out index of Drogue event
    i = 1;
    while (dataIn.Events(i) ~= "Drogue")
        i = i + 1;
    end
    % Trim to drogue
    dataOut = dataIn(1:i, :);
    % Unit conversions
    dataOut.Altitude = dataOut.Altitude*0.3048;
    dataOut.Velocity = dataOut.Velocity*0.3048;
    dataOut.Pressure = dataOut.Pressure*100; % conv millibar to kPa
    dataOut.Temperature = (dataOut.Temperature-32)*(5/9) + 273; % F to K
    % Discard excess information
    dataOut.Events = [];
    dataOut.Voltages = [];
    % Convert to a timetable
    timeVec = [];
    for i = 1:length(dataOut.Time)
        timeVec = [timeVec;seconds(dataOut.Time(i))];
    end
    dataOut.Time = timeVec;
    dataOut = table2timetable(dataOut);
end

