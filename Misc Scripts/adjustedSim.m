%% Adjusted simulation tool
% IREC Systems 2026
% Last updated 30 September 2025
% This script runs openrocket simulations with adjusted atmospheric data
%% Setup
clear; close all; clc;
% Retrieve openrocket
filepath = "C:\IREC-2026-Systems\Rocket Files\IREC-2026.ork";
rocket = openrocket(filepath);
% Reference simulations
% "Baseline", "15mph-Midland-N3800", "15mph-Midland-N3300", and "15mph-Midland-M3400" are valid currently
sim = rocket.sims("Baseline");
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
airDataFilePath = "C:\IREC-2026-Systems\atmosphereData\kylefluence.mat";
%% Get atmosphere
launchtime = datetime(lTime.date(1), lTime.date(2), lTime.date(3),...
    lTime.time(1), lTime.time(2), lTime.time(3), TimeZone = "MST");
if loadAirDataTable
    airdata = importdata(airDataFilePath);
else
    airdata = atmosphere("gfs", "pgrb2.1p00", site.lat, site.lon, launchtime, minpres = 450); %#ok<UNRCH>
end
airdata.TMP = airdata.TMP + 273.15; % conv Celcius to Kelvin
%% Adjust components maybe

%% Simulate!! :)
simData = rocket.simulate(sim, outputs = "ALL", atmos = airdata(:, ["HGT", "PRES", "TMP"]));
% Indicated altitude
simData.("Indicated altitude") = pressalt("m", simData.("Air pressure"), "Pa") - pressalt("m", simData{1, "Air pressure"}, "Pa");
simData.("Altitude error") = simData.("Indicated altitude") - simData.("Altitude");
%% Apogee Error Information :)
plotAltitudeError(simData)
plotErrorVAltitude(simData)
mAlt = max(simData.Altitude);
mAltInd = max(simData.("Indicated altitude"));
errAlt = mAlt - mAltInd;
fprintf("\nGeometric apogee: %4.0f m\nIndicated apogee: %4.0f m\nApogee error: %3.0f m\n",...
    mAlt, mAltInd, errAlt);



%% Functions
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