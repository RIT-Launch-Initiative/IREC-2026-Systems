%% Drag estimation tool
% IREC Systems 2026
% This script calculates the drag curve of a rocket from flight data
% This version is specifically for TB-1
% clear; 
close all; clc;
%% Inputs
samplerate=500;
dt=1/samplerate;
timeInterval = [3 10]; % [s] Time interval to use
% Extension times: 0 - no airbrakes, 1 - airbrakes, 2 - disregard
extensionTimes = [0, 3.53, 3.75, 3.96, 4.45, 4.75, 5.10, 5.40, 5.85, 6.05, 6.45, 6.75, 7.20, 7.45, 7.85, 10;...
                  2, 1,    2,    0,    2,    1,    2,    0,    2,    1,    2,    0,    2,    1,    2,   2];
controlsMod = pfullfile("Drag Estimation\Flight Data\TB-1_1\data.csv");
raven = pfullfile("Drag Estimation\Flight Data\TB-1_1\TB1_1_Raven.csv");
ORFilePath = pfullfile("Rocket Files\Other","TB-1.ork");
ORSimName = "15mph_URRG";
A_airbrake = 0.005357432; % Airbrake frontal area

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
Q = diag([1e-3 1e-5 1e-7]);
[motion, innovation] = filterData_TB1(dataTrimmed, Q);

%% Drag calculation
% Calculate the drag
L = length(massCurve);
for i = 260 : length(massCurve)
    out.F(i) = massCurve(i)*(motion(4,i)+9.81);
    out.q(i) = 0.5*rhoCurve(i)*motion(3,i)^2;
    out.C(i) = abs(out.F(i))/(out.q(i)*A);
end
machCurve = motion(3,:)./aCurve;
% Isolate airbrake and non-airbrake times
C_retracted = NaN(1,length(out.C));
C_extended = NaN(1,length(out.C));
for i = 1:length(out.C)
    t = motion(1, i);
    j = 2;
    currentExtension = 2;
    while (extensionTimes(1,j) <= t && j < length(extensionTimes(1,:)))
        currentExtension = extensionTimes(2, j);
        j = j + 1;
    end
    if currentExtension == 0
        C_retracted(i) = out.C(i);
    end
    if currentExtension == 1
        C_extended(i) = out.C(i);
    end
end

% Take averages (constant C over velocity regime)
Cd_R_retracted = fit_C(C_retracted);
Cd_R_extended = fit_C(C_extended);

% Convert to CdA
CdA_R_retracted = Cd_R_retracted*A;
CdA_R_extended = Cd_R_extended*A;

% Find airbrake drag by taking difference
CdA_airbrake = CdA_R_extended - CdA_R_retracted;

% Divide by airbrake area to get an airbrake Cd
Cd_airbrake = CdA_airbrake/A_airbrake;

fprintf("The drag coefficent of the airbrakes is %.3f\n(Fully extended, 0.25 < M < 0.4)\n", Cd_airbrake)

%plotAlt(globalTime, dataTrimmed, motion)
%plotVel(globalTime, dataTrimmed, motion)
%plotAccel(globalTime, dataTrimmed, motion)
%plotInnovation(motion, innovation)
% plotCD(motion, out.C, machCurve, "Complete Drag Curve")
% plotCD(motion, C_retracted, machCurve, "Airbrakes Retracted Drag")
% plotCD(motion, C_extended, machCurve, "Airbrakes Extended Drag")
% motionSummary(globalTime, dataTrimmed, motion)
% % dragSummary(motion, out.C, machCurve)
% accelSummary(globalTime, dataTrimmed, motion)
plotAdjData(dataTrimmed)

function out = fit_C(in)
    temp = [];
    for i = 1:length(in)
        if not(isnan(in(i)))
            temp = [temp, in(i)];
        end
    end
    out = mean(temp);
end

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
    figure(name = "Acceleration");
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

function plotCD(motion, C, machCurve, figTitle)
    figure(name = figTitle);
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

function print2size(fig, path, sz)
    arguments
        fig;
        path (1,1) string;
        sz (1,2) double;
    end

    drawnow;

    fig.Units = "pixels";
    fig.Position = [1 1 sz];
    waitfor(fig, Position = [1 1 sz]);

    exportgraphics(fig, path, ContentType = "vector");

    % fig.WindowStyle = old_window;
    % waitfor(fig, WindowStyle = old_window);
end

function motionSummary(globalTime, dataTrimmed, motion)
    f = figure(name = "Filter Comparison");
    C = 3.2808399;
    C = 1;
    % Velocity plot
    subplot(1, 2, 1)
    hold on;
    plot(globalTime, dataTrimmed(3,:)*C);
    plot(motion(1,:), motion(3,:)*C);
    hold off;
    ylabel("Velocity [m/s]")
    xlabel("Flight Time [s]")
    xlim([3,10])
    legend("Measured Data", "Filtered Data", "Location","northeast")

    % Acceleration plot
    subplot(1, 2, 2)
    hold on;
    plot(globalTime, dataTrimmed(4,:)*C);
    plot(motion(1,:), motion(4,:)*C);
    hold off;
    ylabel("Acceleration [m/s^2]")
    xlabel("Flight Time [s]")
    xlim([3,10])
    legend("Measured Data", "Filtered Data", "Location","southeast")

    % print to pdf
    reportSz = [900, 300];
    slidesSz = [1000, 400];
    path = "C:\IREC-2026-Systems\Drag Estimation\Figures\filter-comparison.png";
    print2size(f, path, slidesSz)
end

function accelSummary(globalTime, dataTrimmed, motion)
    f = figure(name = "Accel Comparison");
    hold on;
    plot(globalTime, dataTrimmed(4,:));
    plot(motion(1,:), motion(4,:));
    hold off;
    ylabel("Acceleration [m/s^2]")
    xlabel("Flight Time [s]")
    xlim([3,10])
    legend("Measured Data", "Filtered Data", "Location","southeast")

    % print to pdf
    reportSz = [900, 300];
    slidesSz = [400, 400];
    path = "C:\IREC-2026-Systems\Drag Estimation\Figures\accel-comparison.png";
    print2size(f, path, slidesSz)
end

function dragSummary(motion, C, machCurve)
    f = figure(name = "Drag Summary");
    subplot(2, 1, 1)
    plot(motion(1,:), C)
    xlabel("Time [s]", "FontName", "Times New Roman")
    ylabel("Cd", "FontName", "Times New Roman")
    ylim([0 1])
    xlim([3.5 10])
    grid on;
    
    subplot(2, 1, 2)
    scatter(machCurve, C, 2, "filled")
    xlabel("Mach Number", "FontName", "Times New Roman")
    ylabel("Cd", "FontName", "Times New Roman")
    ylim([0 1])
    xlim([0.28 0.41])
    grid on;
    % print to pdf
    path = "C:\IREC-2026-Systems\Drag Estimation\Figures\drag-curve.png";
    reportSz = [900, 400];
    slidesSz = [400, 400];
    print2size(f, path, slidesSz)
end

function plotAdjData(dataTrimmed)
    f = figure(name = "Adjusted Data");
    hold on;
    yyaxis left
    plot(dataTrimmed(1,:), dataTrimmed(2,:));
    ylabel("Altitude [m]")

    yyaxis right
    plot(dataTrimmed(1,:), dataTrimmed(4,:));
    ylabel("Acceleration [m/s^2]")

    hold off;
    
    xlabel("Flight Time [s]")
    legend("Measured Altitude", "Measured Acceleration", "Location", "southeast")

    % print to pdf
    slidesSz = [600, 400];
    path = "C:\IREC-2026-Systems\Drag Estimation\Figures\corrected-data.png";
    print2size(f, path, slidesSz)
end
