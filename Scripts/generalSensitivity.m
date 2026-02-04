%% Apogee Sensitivity Assessment
% IREC Systems 2026
% Last updated 12 January 2026
clear; close all; clc;
%% Inputs
controlAuthority = 390;
windBounds = [1.5 9.0]; % [min max] [m/s]
tempSpread = 10; % [K]
pressSpread = 2*10^3; % [Pa]
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
%% Get air data and drag curve
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
%% Setup variation ranges
windRange = windBounds(2)-windBounds(1);
subsysVars = subsysRange(rocket);
compVars = compRange(rocket);
bodyVars = bodyRange(rocket);

%% Monte Carlo Loop
N = 50; % Number of samples
apogeeList = zeros([N,1]);
pressAppList = zeros([N,1]);
elapsed = tic;
for i = 1:N
    disp("Running simulation " + i + " of " + N)
    wind = windBounds(1) + rand()*windRange;
    offsetAirData.TMP = airdata.TMP + (rand()-0.5)*tempSpread;
    offsetAirData.PRES = airdata.PRES + (rand()-0.5)*pressSpread;
    
    varySubsys(rocket, subsysVars);
    varyComp(rocket, compVars);
    varyBody(rocket, bodyVars);

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
%% Generate report
reportData1.uncertainty = 2*sigAlt;
reportData1.control = controlAuthority;
reportData1.range = controlAuthority - 2*reportData1.uncertainty;
save("C://IREC-2026-Systems/Design Reporting/reportData1.mat", "reportData1")

updateReport;

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

fprintf("\nAirbrake apogee reduction of %3.0f [m] corresponds to %2.1f sigma\n", controlAuthority, (controlAuthority/sigAlt));

%% Functions

function out = subsysRange(rocket)
    out.abMass = rocket.component(name="Airbrake").getMass;
    out.aviMass = rocket.component(name="Avionics").getMass;
    out.payloadMass = rocket.component(name="Payload").getMass;
    out.abVar = 0.047;
    out.aviVar = 0.783;
    out.payloadVar = 0.638;
end

function out = compRange(rocket)
    out.ncMass = rocket.component(name="Nose Cone").getOverrideMass;
    out.ncVar = 0.1;
    out.fssMass = rocket.component(name="Fin Support Structure").getOverrideMass;
    out.fssVar = 0.1;
    out.boattailMass = rocket.component(name="Boattail").getOverrideMass;
    out.boattailVar = 0.05;
    out.finsMass = rocket.component(class="FinSet").getOverrideMass;
    out.finsVar = 0.15;
end

function out = bodyRange(rocket)
    % This function defines the mass variation parameters for body tubes
    bt1 = rocket.component(name="Forward Reco Tube");
    bt2 = rocket.component(name="Av Bay Tube");
    bt3 = rocket.component(name="Aft Reco Tube");
    bt4 = rocket.component(name="Airbrake Tube");
    bt5 = rocket.component(name="Booster Tube");
    bt5 = bt5(1);

    out.bt1Mass = bt1.getOverrideMass;
    out.bt1Len = bt1.getLength;
    out.bt2Mass = bt2.getOverrideMass;
    out.bt2Len = bt2.getLength;
    out.bt3Mass = bt3.getOverrideMass;
    out.bt3Len = bt3.getLength;
    out.bt4Mass = bt4.getOverrideMass;
    out.bt4Len = bt4.getLength;
    out.bt5Mass = bt5.getOverrideMass;
    out.bt5Len = bt5.getLength;
    
    c1 = 39.3700787;
    % nominal line density
    out.lineDensity = 0.0322*c1;
    % 2 std of measured line densities conv to kg/m
    out.lineDensityVar = 2*0.0036878*c1;
    % tube length variation
    out.lenVar = 0.125/c1;

    out.bt1Var = 0.345;
    out.bt2Var = 0.28;
    out.bt3Var = 0.206;
    out.bt4Var = 0.123;
    out.bt5Var = 0.237;
end

function varySubsys(rocket, vars)
    airbrake = rocket.component(name="Airbrake");
    avi = rocket.component(name="Avionics");
    payload = rocket.component(name="Payload");
    airbrake.setComponentMass(vars.abMass + 2*(rand()-0.5)*vars.abVar);
    avi.setComponentMass(vars.aviMass + 2*(rand()-0.5)*vars.aviVar);
    payload.setComponentMass(vars.payloadMass + 2*(rand()-0.5)*vars.payloadVar);
end

function varyComp(rocket, vars)
    noseCone = rocket.component(name="Nose Cone");
    FSS = rocket.component(name="Fin Support Structure");
    boattail = rocket.component(name="Boattail");
    fins = rocket.component(class="FinSet");

    noseCone.setOverrideMass(vars.ncMass + 2*(rand()-0.5)*vars.ncVar);
    FSS.setOverrideMass(vars.fssMass + 2*(rand()-0.5)*vars.fssVar);
    boattail.setOverrideMass(vars.boattailMass + 2*(rand()-0.5)*vars.boattailVar);
    fins.setOverrideMass(vars.finsMass + 2*(rand()-0.5)*vars.finsVar);
end

function varyBody(rocket, vars)
    % This function randomizes body tube masses and lengths
    bt1 = rocket.component(name="Forward Reco Tube");
    bt2 = rocket.component(name="Av Bay Tube");
    bt3 = rocket.component(name="Aft Reco Tube");
    bt4 = rocket.component(name="Airbrake Tube");
    bt5 = rocket.component(name="Booster Tube");
    bt5 = bt5(1);

    % % Randomize lengths
    % len1 = vars.bt1Len + 2*(rand()-0.5)*vars.lenVar;
    % len2 = vars.bt2Len + 2*(rand()-0.5)*vars.lenVar;
    % len3 = vars.bt3Len + 2*(rand()-0.5)*vars.lenVar;
    % len4 = vars.bt4Len + 2*(rand()-0.5)*vars.lenVar;
    % len5 = vars.bt5Len + 2*(rand()-0.5)*vars.lenVar;
    % 
    % % Define randomized masses using random lengths and line densities
    % m1 = len1*(vars.lineDensity + 2*(rand()-0.5)*vars.lineDensityVar);
    % m2 = len2*(vars.lineDensity + 2*(rand()-0.5)*vars.lineDensityVar);
    % m3 = len3*(vars.lineDensity + 2*(rand()-0.5)*vars.lineDensityVar);
    % m4 = len4*(vars.lineDensity + 2*(rand()-0.5)*vars.lineDensityVar);
    % m5 = len5*(vars.lineDensity + 2*(rand()-0.5)*vars.lineDensityVar);

    m1 = vars.bt1Var;
    m2 = vars.bt2Var;
    m3 = vars.bt3Var;
    m4 = vars.bt4Var;
    m5 = vars.bt5Var;

    bt1.setOverrideMass(m1);
    bt2.setOverrideMass(m2);
    bt3.setOverrideMass(m3);
    bt4.setOverrideMass(m4);
    bt5.setOverrideMass(m5);
end