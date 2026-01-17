%% Apogee Sensitivity Assessment
% IREC Systems 2026
% Last updated 12 January 2026
%% Setup
clear; close all; clc;
% Run a test OR sim
filePath = "C:\IREC-2026-Systems\Rocket Files\RISK.ork"; 
if ~isfile(filePath)
    error("Error: not on path", filePath);
end
rocket = openrocket(filePath);
simName = "15mph-Midland";
sim = rocket.sims(simName);
opts = sim.getOptions();
windBounds = [1.5 9.0]; % [min max] [m/s]
windRange = windBounds(2)-windBounds(1);
tempSpread = 10; % [K]
pressSpread = 2*10^3; % [Pa]
% Reduction is currently 183 m for M3464
appReduction = 183;
% Use air data
airDataFilePath = "C:\IREC-2026-Systems\atmosphereData\postFlightAtmos.mat";
airdata = importdata(airDataFilePath);
airdata.TMP = airdata.TMP + 273.15; % conv Celcius to Kelvin
offsetAirData = airdata;
% RasAero drag curve
dragFilePath = "C:\IREC-2026-Systems\Data\CDplot-RISK.csv";
rasDrag = import_rasaero_aerodata(dragFilePath);
rasDrag = rasDrag.align("mach");
rasDrag = table(rasDrag.mach, rasDrag.pick{"aoa", 0, "field", "CD"}, ...
    VariableNames = ["MACH", "DRAG"]);
rasDrag.MACH(1) = 0;

%% Monte Carlo Loop
N = 10; % Number of samples
apogeeList = zeros([N,1]);
pressAppList = zeros([N,1]);
elapsed = tic;
for i = 1:N
    disp("Running simulation " + i + " of " + N)
    wind = windBounds(1) + rand()*windRange;
    offsetAirData.TMP = airdata.TMP + (rand()-0.5)*tempSpread;
    offsetAirData.PRES = airdata.PRES + (rand()-0.5)*pressSpread;
    
    opts.setWindSpeedAverage(wind);
    rocket.simulate(sim, atmos = offsetAirData(:, ["HGT", "PRES", "TMP"]), drag = rasDrag);
    altData = openrocket.get_data(sim, [("Altitude"), ("Air pressure")]);
    apogeeList(i) = max(altData.("Altitude"));
    pressAppList(i) = pressalt("m", min(altData.("Air pressure")), "Pa")-pressalt("m", altData.("Air pressure")(1), "Pa");
end
fprintf("\nRun time:\n %4.2f minutes\n\n", toc(elapsed)/60);

%% Analysis
appErr = pressAppList - apogeeList; % Supposed measurement error
% Averages
avgAlt = mean(apogeeList); 
avgPressAlt = mean(pressAppList);
avgErr = mean(appErr);
% Standard deviations
sigAlt = std(apogeeList);
sigPressAlt = std(pressAppList);
sigErr = std(appErr);
% Conversions factors
C1 = 2.237; % m/s to mph
tempF = tempSpread*1.8;
pressSpread = pressSpread*10^-3;
%% Output
fprintf("\nSimulation used: " + simName);
fprintf("\n%d Simulations run varying parameters in the listed ranges", N);
fprintf("\n   Wind Speed: %1.1f to %1.1f [m/s]; %2.1f to %2.1f [mph]",...
    windBounds(1), windBounds(2), windBounds(1)*C1, windBounds(2)*C1);
fprintf("\n   Temperature offest spread: %2.1f [Celcius]; %2.1f [Fahrenheit]",...
    tempSpread, tempF);
fprintf("\n   Pressure offset spread: %4.2f [kPa]",...
    pressSpread);
fprintf("\nGFS data for Midland on 21 June 2025 used for atmosphere model");
fprintf("\n2 sigma bounds");

fprintf("\n\nApogee (geometric): %4.1f [m] +/- %3.1f [m]\n", avgAlt, 2*sigAlt);
% fprintf("Apogee (indicated): %4.1f [m] +/- %3.1f [m]\n", avgPressAlt, 2*sigPressAlt);
% fprintf("Apogee error: %2.1f [m] +/- %2.1f [m]\n", avgErr, 2*sigErr);

fprintf("\nAirbrake apogee reduction of %3.0f [m] corresponds to %2.1f sigma\n", appReduction, (appReduction/sigAlt));