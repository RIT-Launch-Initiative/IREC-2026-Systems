%% Drag Sensitivity Assessment
% IREC Systems 2026
% Last updated 14 June 2026
clear; close all; clc;
%% Auto inputs
load("C://IREC-2026-Systems/Design Reporting/reportData1.mat");
%% Setup OpenRocket
% Run a test OR sim
filePath = "C:\IREC-2026-Systems\Rocket Files\RISK.ork"; 
if ~isfile(filePath)
    error("Error: not on path", filePath);
end
rocket = openrocket(filePath);
simName = "15mph-Midland";
sim = rocket.sims(simName);
opts = sim.getOptions();
% Get rocket params
risk = rocket.rocket();
L = risk.getLength();
[D, ~] = rocket.refdims();
%% Get air data and drag curve
% Use air data
airDataFilePath = "C:\IREC-2026-Systems\atmosphereData\airdata.mat";
airdata = importdata(airDataFilePath);
airdata.TMP = airdata.TMP + 273.15; % conv Celcius to Kelvin
% RasAero drag curve
dragFilePath = "C:\IREC-2026-Systems\Data\CDplot-RISK.csv";
rasDragOrg = import_rasaero_aerodata(dragFilePath);
rasDragOrg = rasDragOrg.align("mach");
rasDragOrg = table(rasDragOrg.mach, rasDragOrg.pick{"aoa", 0, "field", "CD"}, ...
    VariableNames = ["MACH", "DRAG"]);
rasDragOrg.MACH(1) = 0;
rasDrag = rasDragOrg;

%% Bounds
lowBound = reportData1.target - 0.5*reportData1.range;
highBound = reportData1.target + 0.5*reportData1.range;

%% Search for max increase
flag = 0;
offsets = linspace(1, 1.20, 101);
for i = 1:length(offsets)
    fprintf("Running sim %.0f of %.0f", i, length(offsets))
    % Vary drag
    rasDrag.DRAG = rasDragOrg.DRAG*offsets(i);

    % Simulate
    apogee = getApogee(rocket, sim, airdata, rasDrag);
    fprintf("\tMultiplier: %.3f, Apogee: %.1f, Lower bound: %.1f\n", offsets(i), apogee, lowBound)

    % Enter this statement if lower bound is hit
    if apogee < lowBound
        fprintf("\nWe can be worse by a factor of %.2f", offsets(i))
        flag = 1;
        break;
    end
end

if flag == 0
    fprintf("\nWe chillin")
end

%% Output

%% Functions
function apogee = getApogee(rocket, sim, airdata, rasDrag)
    rocket.simulate(sim, atmos = airdata(:, ["HGT", "PRES", "TMP"]), drag = rasDrag);
    data = openrocket.get_data(sim, [("Altitude"), ("Air pressure"), ("Stability margin")]);
    apogee = max(data.("Altitude"));
end