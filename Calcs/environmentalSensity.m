%% Environmental Sensitivity Assessment
% IREC Systems 2026
% Last updated 4 October 2025
%% Setup
clear; close all; clc;
% Run a test OR sim
filePath = "C:\IREC-2026-Systems\Rocket Files\IREC-2026.ork"; 
if ~isfile(filePath)
    error("Error: not on path", filePath);
end
TB1 = openrocket(filePath);
% "Baseline", "15mph-Midland-N3800", and "15mph-Midland-N3300" are valid currently
simName = "Baseline";
sim = TB1.sims(simName);
opts = sim.getOptions();
windBounds = [1.5 6.0]; % [min max] [m/s]
windRange = windBounds(2)-windBounds(1);
tempOffset = [-5 5]; % [K]
tempRange = tempOffset(2)-tempOffset(1);
pressOffset = [-5 5]*10^3; % [Pa]
pressRange = pressOffset(2) - pressOffset(1);
% Reduction is currently 366 m for N3800, 359 m for N3300
appReduction = 383;
% Use air data
airDataFilePath = "C:\IREC-2026-Systems\atmosphereData\21-Jun-2025-10.21.00-midland-gfs_1.mat";
airdata = importdata(airDataFilePath);
airdata.TMP = airdata.TMP + 273.15; % conv Celcius to Kelvin
offsetAirData = airdata;

%% Monte Carlo Loop
N = 200; % Number of samples
apogeeList = zeros([N,1]);
pressAppList = zeros([N,1]);
elapsed = tic;
for i = 1:N
    disp("Running simulation " + i + " of " + N)
    wind = windBounds(1) + rand()*windRange;
    offsetAirData.TMP = airdata.TMP;% + rand()*tempRange+tempOffset(1);
    offsetAirData.PRES = airdata.PRES;% + rand()*pressRange+pressOffset(1);
    
    opts.setWindSpeedAverage(wind);
    TB1.simulate(sim, atmos = offsetAirData(:, ["HGT", "PRES", "TMP"]));
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
C1 = 3.28; % m/s to mph
tempsF = (tempOffset)*1.8;
pressOffset = pressOffset*10^-3;
%% Output
fprintf("\nSimulation used: " + simName);
fprintf("\n%d Simulations run varying parameters in the listed ranges", N);
fprintf("\n   Wind Speed: %1.1f to %1.1f [m/s]; %2.1f to %2.1f [mph]",...
    windBounds(1), windBounds(2), windBounds(1)*C1, windBounds(2)*C1);
% fprintf("\n   Temperature profile offset: %2.1f to %2.1f [Celcius]; %2.1f to %2.1f [Fahrenheit]",...
%     tempOffset(1), tempOffset(2), tempsF(1), tempsF(2));
% fprintf("\n   Pressure profile offset: %4.2f to %4.2f [kPa]",...
%     pressOffset(1), pressOffset(2));
fprintf("\nGFS data for Midland on 21 June 2025 used for atmosphere model");
fprintf("\n2 sigma bounds");

fprintf("\n\nApogee (geometric): %4.1f [m] +/- %3.1f [m]\n", avgAlt, 2*sigAlt);
fprintf("Apogee (indicated): %4.1f [m] +/- %3.1f [m]\n", avgPressAlt, 2*sigPressAlt);
fprintf("Apogee error: %2.1f [m] +/- %2.1f [m]\n", avgErr, 2*sigErr);

fprintf("\nAirbrake apogee reduction of %3.0f [m] corresponds to %2.1f sigma\n", appReduction, (appReduction/sigAlt));