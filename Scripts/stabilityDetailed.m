%% Stability Dynamics
% IREC Systems 2026
% This script runs adjusted openrocket simulations and analyzes the
% stability of the vehicle
clear; close all; clc;
%% Inputs
settlingTimeWinds = linspace(0, 10, 20);
%% Auto inputs
load("C://IREC-2026-Systems/Design Reporting/reportData1.mat");
load("C://IREC-2026-Systems/Design Reporting/reportData2.mat");
load("C://IREC-2026-Systems/Design Reporting/reportData3.mat");
%% Setup
% Retrieve openrocket
filepath = "C:\IREC-2026-Systems\Rocket Files\RISK.ork";
risk = openrocket(filepath);
rocket = risk.rocket();
% rocket parameters
L = rocket.getLength();
[D, ~] = risk.refdims();
% Reference simulation
sim = risk.sims("15mph-Midland");
opts = sim.getOptions;
% air data
airDataFilePath = "C:\IREC-2026-Systems\atmosphereData\postFlightAtmos.mat";
% Rasaero drag curve
dragFilePath = "C:\IREC-2026-Systems\Data\CDplot-RISK.csv";

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
    drag = rasDrag);
% Add percent stability to table
simData.("Stability percent") = 100*simData.("Stability margin")*D/L;
% Times vector
times = simData.Time;
ascentRange = timerange(eventfilter("LAUNCHROD"), eventfilter("APOGEE"), "openleft");

%% Settling time


%% Generate text output
stabData = simData(ascentRange, ["Stability margin", "Stability percent"]);
stabRod = stabData.("Stability percent")(2);
stabRodCal = stabData.("Stability margin")(2);
stabMax = max(simData.("Stability percent"));
stabMaxCal = max(simData.("Stability margin"));

%% Plot outputs
plotStabPercent(simData)
plotStabCombined(simData)
plotDynamicResponse(simData)

%% Update Report

%% Text output
fprintf("\nLaunch stability: %2.2f percent (%.2f cal)\nMaximum stability: %2.2f percent (%.2f cal)\n",...
      stabRod, stabRodCal, stabMax, stabMaxCal);

%% Functions
function plotStabPercent(simData)
    % Trim data
    ascentRange = timerange(eventfilter("LAUNCHROD"), eventfilter("APOGEE"), "openleft");
    stabData = simData(ascentRange, ["Stability percent", "Angle of attack"]);
    stabData.("Angle of attack") = (180/pi)*stabData.("Angle of attack");
    % Plot the data
    figure(name = "Stability")
    hold on;
    % Left side
    yyaxis("left")
    plot(stabData, "Time", "Stability percent");
    ylabel("Stability [%]")
    % Right side
    yyaxis("right")
    plot(stabData, "Time", "Angle of attack");
    ylabel("Angle of Attack [degrees]")
    hold off;
    % Finish plot
    xlabel("Time [s]")
    % xl = xline(ev_in_range.Time(selected_ev), "-k", ...
    % ev_in_range.EventLabels(selected_ev), ...
    % Interpreter = "none", HandleVisibility = "off");
    % xl(end).LabelHorizontalAlignment = "left";
end
function plotStabCombined(simData)
    % Trim data
    ascentRange = timerange(eventfilter("LAUNCHROD"), eventfilter("APOGEE"), "openleft");
    stabData = simData(ascentRange, ["Stability percent", "Stability margin"]);
    % Plot the data
    figure(name = "Stability (% and cal)")
    hold on;
    % Left side
    yyaxis("left")
    plot(stabData, "Time", "Stability percent");
    ylabel("Stability [%]")
    % Right side
    yyaxis("right")
    plot(stabData, "Time", "Stability margin");
    ylabel("Stability calibers [cal]")
    hold off;
    % Finish plot
    xlabel("Time [s]")
    grid on
    title("Stability (No Wind)")
end
