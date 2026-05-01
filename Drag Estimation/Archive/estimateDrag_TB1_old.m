%% Drag estimation tool
% IREC Systems 2026
% This script calculates the drag curve of a rocket from flight data
% This version is specifically for TB-1
clear; close all; clc;
%% Inputs
samplerate=500;
dt=1/samplerate;
timeInterval = [3 10]; % [s] Time interval to use
% Extension times: 0 - no airbrakes, 1 - airbrakes, 2 - disregard
extensionTimes = [0, 3.83, 3.94, 4.55, 4.63, 5.17, 5.27, 5.90, 6.00, 6.54, 6.65, 7.30, 7.40, 7.80;...
                  0, 2,    1,    2,    0,    2,    1,    2,    0,    2,    1,    2,    0,    2];
controlsMod = pfullfile("Drag Estimation\Flight Data\TB-1_1\data.csv");
raven = pfullfile("Drag Estimation\Flight Data\TB-1_1\TB1_1_Raven.csv");
ORFilePath = pfullfile("Rocket Files\Other","TB-1.ork");
ORSimName = "15mph_URRG";

%% Load and trim flight data
% Load data
CMData = readtable(controlsMod);
ravenData = readtable(raven);

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
R = 287;
simData.Density = simData.("Air pressure")./(simData.("Air temperature")*R);

%% Trim and re-sample
% Prepare time vector
globalTime = (timeInterval(1):dt:timeInterval(2));

% Trim data
dataTrimmed = trimTB1Data(CMData, ravenData, globalTime);
tempCurve = interp1(seconds(simData.Time), simData(:, "Air temperature").("Air temperature"), globalTime, "linear", "extrap");
pressCurve = interp1(seconds(simData.Time), simData(:, "Air pressure").("Air pressure"), globalTime, "linear", "extrap");
massCurve = interp1(seconds(simData.Time), simData(:, "Mass").Mass, globalTime, "linear", "extrap");
rhoCurve = interp1(seconds(simData.Time), simData(:, "Density").Density, globalTime, "linear", "extrap");
aCurve = sqrt(tempCurve*287*1.4);
%% Process
[motion, innovation] = filterData_TB1(dataTrimmed);
machCurve = motion(3,:)./aCurve;

%% Drag calculation
% Calculate the drag
L = length(massCurve);
for i = 260 : length(massCurve)
    out.F(i) = massCurve(i)*(motion(4,i)+9.81);
    out.q(i) = 0.5*rhoCurve(i)*motion(3,i)^2;
    out.C(i) = abs(out.F(i))/(out.q(i)*A);
end

% Isolate airbrake and non-airbrake times
C_retracted = NaN(1,length(out.C));
C_extended = NaN(1,length(out.C));
for i = 1:length(out.C)
    t = motion(1, i);
    for j = 2:length(extensionTimes(1,:))
        if extensionTimes(1,j) > t
            currentExtension = extensionTimes(2, j-1);
            break;
        end
    end
    if currentExtension == 0
        C_retracted(i) = out.C(i);
    end
    if currentExtension == 1
        C_extended(i) = out.C(i);
    end
end

% plotAlt(globalTime, dataTrimmed, motion)
% plotVel(globalTime, dataTrimmed, motion)
% plotAccel(globalTime, dataTrimmed, motion)
% plotInnovation(motion, innovation)
plotCD(motion, out.C, machCurve)
plotCD(motion, C_extended, machCurve)

function plotAlt(globalTime, dataTrimmed, motion)
    figure(name = "Altitude")
    plot(motion(1,:), motion(2,:));
    hold on;
    plot(globalTime, dataTrimmed(2,:));
    hold off;
    legend("Filtered", "Raw")
    xlabel("Time [s]")
    ylabel("Altitude [m]")
    title("Filtered Altitude")
end

function plotVel(globalTime, dataTrimmed, motion)
    figure(name = "Velocity")
    plot(motion(1,:), motion(3,:));
    hold on;
    plot(globalTime, dataTrimmed(3,:));
    hold off;
    legend("Filtered", "Raw")
    xlabel("Time [s]")
    ylabel("Velocity [m/s]")
    title("Filtered Velocity")
end

function plotAccel(globalTime, dataTrimmed, motion)
    figure(name = "Acceleration")
    plot(motion(1,:), motion(4,:));
    hold on;
    plot(globalTime, dataTrimmed(4,:));
    hold off;
    legend("Filtered", "Raw")
    xlabel("Time [s]")
    ylabel("Acceleration [m/s^2]")
    title("Filtered Acceleration")
end

function plotInnovation(motion, innovation)
    figure(name = "Innovation")
    subplot(3, 1, 1)
    plot(motion(1,:), innovation(1,:))
    ylabel("Pos-Innovation")
    title("Innovation")
    yline([-2 2],"r--")
    ylim([-3 3])
    
    subplot(3, 1, 2)
    plot(motion(1,:), innovation(3,:))
    ylabel("Acc-Innovation")
    yline([-2 2],"r--")
    ylim([-3 3])
end

function plotCD(motion, C, machCurve)
    figure(name = "CD vs Time");
    plot(motion(1,:), C)
    xlabel("Time [s]")
    ylabel("CD")
    title("Drag Coefficient vs Time")
    ylim([0 1.5])
    xlim([3 8])

    figure(name = "CD vs Velocity");
    scatter(machCurve, C, 6, "filled")
    xlabel("Velocity [mach]")
    ylabel("CD")
    title("Drag Coefficient vs Velocity")
    ylim([0 1.25])
    xlim([0.25 0.5])
end
