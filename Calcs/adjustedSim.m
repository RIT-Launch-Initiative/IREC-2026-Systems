%% Adjusted simulation tool
% IREC Systems 2026
% Last updated 30 October 2025
% This script runs openrocket simulations with adjustments for atmospheric
% profile, drag curve, and with extra outputs
% TO-DO
% Show stability percent
% Plot flight trajectory
% Output max q (value, time)
% 
%% Setup
clear; close all; clc;
% Retrieve openrocket
filepath = "C:\IREC-2026-Systems\Rocket Files\IREC-2026-M3464.ork";
rocket = openrocket(filepath);
% Reference simulations
% "Baseline", "15mph-Midland-N3800", "15mph-Midland-N3300", and "15mph-Midland-M3400" are valid currently
sim = rocket.sims("15mph-Midland");
%% Inputs
% Rocket parameters
L = 132; % inches
D = 6.2; % inches
L = 0.0254*L; D = 0.0254*D; % conv to meter
% Other parameters
R = 0.287; % Specific gas constant for air

% Valid sites: "spaceport-midland", "spaceport-america", "urrg", "mars"
site = launchsites("spaceport-midland"); 
% Launch time
lTime.date = [2025, 06, 21]; % [year, month, day]
lTime.time = [10, 21, 00]; % [hour, minute, second]
airDataFilePath = "C:\IREC-2026-Systems\atmosphereData\postFlightAtmos.mat";

% Rasaero drag curve
dragFilePath = "C:\IREC-2026-Systems\Data\CDplot-M3464.csv";

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
simData = rocket.simulate(sim, outputs = "ALL", atmos = airdata(:, ["HGT", "PRES", "TMP"]),...
    wind = airdata, drag = rasDrag);
% Add density and dynamic pressure to table
simData.("Air density") = simData.("Air pressure")./(1000*R*simData.("Air temperature"));
simData.("Dynamic pressure") = 0.5*simData.("Air density").*simData.("Total velocity").^2;
% Add percent stability to table
simData.("Stability percent") = 100*simData.("Stability margin")*D/L;
% Add Indicated altitude to table
simData.("Indicated altitude") = pressalt("m", simData.("Air pressure"), "Pa") - pressalt("m", simData{1, "Air pressure"}, "Pa");
simData.("Altitude error") = simData.("Indicated altitude") - simData.("Altitude");

%% Generate parameters to output
ascentRange = timerange(eventfilter("LAUNCHROD"), eventfilter("APOGEE"));
mAlt = max(simData.Altitude);
mAltInd = max(simData.("Indicated altitude"));
errAlt = mAlt - mAltInd;
% Stability
stabData = simData(ascentRange, "Stability percent").("Stability percent");
stabRod = stabData(2);
stabMax = max(simData.("Stability percent"));

%% Plot outputs :)
% plotStabPercent(simData)
% plotAltitudeError(simData)
% plotErrorVAltitude(simData)

%% Text output
fprintf("\nLaunch stability: %2.2f percent\nMaximum stability: %2.2f percent\n",...
      stabRod, stabMax);
% fprintf("\nGeometric apogee: %4.0f m\nIndicated apogee: %4.0f m\nApogee error: %3.0f m\n",...
%     mAlt, mAltInd, errAlt);

%% Functions
function plotStabPercent(simData)
    % Trim data
    ascentRange = timerange(eventfilter("LAUNCHROD"), eventfilter("APOGEE"), "openleft");
    stabData = simData(ascentRange, ["Stability percent", "Angle of attack"]);
    % Plot the data
    figure(name = "Stability")
    hold on;
    % Left side
    yyaxis("left")
    plot(stabData, "Time", "Stability percent", "Color", "b");
    ylabel("Stability [%]")
    % Right side
    yyaxis("right")
    plot(stabData, "Time", "Angle of attack", "Color", "r");
    ylabel("Angle of Attack [degrees]")
    hold off;
    % Finish plot
    xlabel("Time [s]")
end
function plotAltitudeError(simData)
    % Adjust data for plotting
    ascentRange = timerange(eventfilter("LAUNCHROD"), eventfilter("APOGEE"), "openleft");
    altData = simData(ascentRange, ["Altitude", "Indicated altitude", "Altitude error"]);
    yMax = max(altData.("Altitude"))*1.1;
    % Plot altitudes
    figure(name = "Altitude comparison")
    % Left side
    yyaxis("left")
    plot(altData, "Time", "Altitude", "Color","b");
    ylim([0,yMax])
    ylabel("Altitude [m]")
    hold on;
    plot(altData, "Time", "Indicated altitude", "Color", "g");
    % Right side
    yyaxis("right")
    plot(altData, "Time", "Altitude error", "Color", "r");
    hold off;
    ylabel("Altitude error [m]")
    % Other plot related things
    xlabel("Time [s]")
    legend("Altitude", "Indicated altitude", "Error", "location", "northeast")
end
function plotErrorVAltitude(simData)
    % Adjust data for plotting
    ascentRange = timerange(eventfilter("LAUNCHROD"), eventfilter("MAIN"), "openleft");
    altData = simData(ascentRange, ["Altitude", "Indicated altitude", "Altitude error"]);
    yMax = max(altData.("Altitude"))*1.1;
    % Plot altitudes
    figure(name = "Altitude comparison")
    % Left side
    yyaxis("left")
    plot(altData, "Time", "Altitude", "Color","b");
    ylim([0,yMax])
    ylabel("Altitude [m]")
    hold on;
    plot(altData, "Time", "Indicated altitude", "Color", "g");
    % Right side
    yyaxis("right")
    plot(altData, "Time", "Altitude error", "Color", "r");
    hold off;
    ylabel("Altitude error [m]")
    % Other plot related things
    xlabel("Time [s]")
    legend("Altitude", "Indicated altitude", "Error", "location", "northeast")
end