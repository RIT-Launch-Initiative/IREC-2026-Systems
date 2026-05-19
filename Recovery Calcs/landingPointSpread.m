%% Recovery Monte Carlo
% IREC Systems 2026
clear; close all; clc;

%% INPUTS
N = 200; % Number of sims to run

drogue_diameter = 30; % Inches
drogue_CD = 0.97;
main_diameter = 96; % Inches
main_CD = 2.2;

windBounds = [1.5 10]; % m/s
windHeadingBounds = [0 180]; % Degrees
rodHeadingBounds = [75 105];
rodAngleBounds = [4 6]; % Degrees (off vertical)

airDataFilePath = "C:\IREC-2026-Systems\atmosphereData\postFlightAtmos.mat";
dragFilePath = "C:\IREC-2026-Systems\Data\CDplot-RISK.csv";

% Convert units
drogue_diameter = 24*0.0254;
main_diameter = 120*0.0254;
windHeadingBounds = windHeadingBounds*(pi/180);
rodHeadingBounds = rodHeadingBounds*(pi/180);
rodAngleBounds = rodAngleBounds*(pi/180);

%% Setup
% Retrieve openrocket
filepath = "C:\IREC-2026-Systems\Rocket Files\RISK.ork";
risk = openrocket(filepath);
rocket = risk.rocket();
% Reference simulation
sim = risk.sims("15mph-Midland");
opts = sim.getOptions();
opts.setLaunchIntoWind(false);
% Get air data
airdata = importdata(airDataFilePath);
airdata.TMP = airdata.TMP + 273.15; % conv Celcius to Kelvin
% Get drag
rasDrag = import_rasaero_aerodata(dragFilePath);
rasDrag = rasDrag.align("mach");
rasDrag = table(rasDrag.mach, rasDrag.pick{"aoa", 0, "field", "CD"}, ...
    VariableNames = ["MACH", "DRAG"]);
rasDrag.MACH(1) = 0;

%% Set rocket recovery parameters
main = risk.component(name = "Main");
main.setDiameter(main_diameter);
main.setCD(main_CD);

drogue = risk.component(name = "Drogue");
drogue.setDiameter(drogue_diameter);
drogue.setCD(drogue_CD);

%% Prepare for simulations
outVec = zeros(N, 2);
drogueDescentRates = zeros(N, 1);
mainDescentRates = zeros(N, 1);
windSize = windBounds(2)-windBounds(1);
windHeadingSize = windHeadingBounds(2)-windHeadingBounds(1);
rodHeadingSize = rodHeadingBounds(2)-rodHeadingBounds(1);
rodAngleSize = rodAngleBounds(2)-rodAngleBounds(1);

opts.setWindTurbulenceIntensity(0.15)
opts.setTimeStep(0.05); % Go faster pls
hitFilter = eventfilter("GROUND_HIT");
drogueRange = timerange(eventfilter("APOGEE"), eventfilter("MAIN"));

%% Monte-Carlo Simulation
elapsed = tic;
for i = 1 : N
    disp("Running simulation " + i + " of " + N)
    % Randomize simulation parameters
    opts.setWindDirection( windHeadingBounds(1) + (rand()-0.5)*windHeadingSize );
    opts.setLaunchRodDirection( rodHeadingBounds(1) + (rand()-0.5)*rodHeadingSize );
    opts.setWindSpeedAverage( windBounds(1) + (rand()-0.5)*windSize )
    opts.setLaunchRodAngle( rodAngleBounds(1) + (rand()-0.5)*rodAngleSize )
    % Simulate
    simData = risk.simulate(sim, outputs = "ALL", atmos = airdata(:, ["HGT", "PRES", "TMP"]),...
    drag = rasDrag);
    % Store relevant data
    drogueDescentRates(i) = simData(drogueRange, "Vertical velocity").("Vertical velocity")(end);
    mainDescentRates(i) = simData(:, "Vertical velocity").("Vertical velocity")(end);
    simData = simData(hitFilter, ["Position East of launch", "Position North of launch"]);
    outVec(i, 1) = simData.("Position East of launch");
    outVec(i, 2) = simData.("Position North of launch");
end
fprintf("\nRun time:\n %.2f minutes\n", toc(elapsed)/60)

%% Some Calculations
aveLandingSpot = [mean(outVec(:,1)) mean(outVec(:,2))];
[aveDistance, stdDistance] = calcAveLandingPointErr(aveLandingSpot, outVec);
avgDrogueRate = abs(mean(drogueDescentRates));
avgMainRate = abs(mean(mainDescentRates));

%% Plot Landing Points
figure(name = "Landing Points")
% Decide plot bounds
pad = 0.2;
[xLimits, yLimits] = makeBounds(outVec, pad);

% Plot Monte Points
f = figure(name = "Recovery point spread");
scatter(outVec(:,1), outVec(:,2), 6, "filled")
hold on;
% Average landing spot
scatter(aveLandingSpot(1), aveLandingSpot(2), 36, "filled", "red")
plotCircle(aveLandingSpot, 2*stdDistance, [1, 0.1, 0.1, 0.1]);
hold off;
xlabel("Position East of Launch [m]", "FontName", "Times New Roman")
ylabel("Position North of Launch [m]", "FontName", "Times New Roman")
xlim([-200 1000])
ylim([-600 600])
%xlim(xLimits)
%ylim(yLimits)
axis equal
grid on;

path = "C:\IREC-2026-Systems\Drag Estimation\Figures\landing-point.pdf";
sz = [900, 300];
print2size(f, path, sz)

%close("Landing Points")

%% Text out
drogue_diameter = drogue_diameter/0.0254;
main_diameter = main_diameter/0.0254;
fprintf("\nIterations: %.0f", N)
fprintf("\nDrogue: %.2f inches, Cd = %.2f, Drogue descent rate = %.2f m/s",...
    drogue_diameter, drogue_CD, avgDrogueRate)
fprintf("\nMain: %.2f inches, Cd = %.2f, Main descent rate = %.2f m/s",...
    main_diameter, main_CD, avgMainRate)
fprintf("\nPosition East: %.0f [m]\nPosition North: %.0f [m]\nDistance: %.0f [m]\nVariation: %.0f [m]\n",...
    aveLandingSpot(1), aveLandingSpot(2), aveDistance, stdDistance)

%% Functions
function [xLimits, yLimits] = makeBounds(outVec, pad)
    xMin = min(outVec(:,1));
    xMax = max(outVec(:,1));
    
    yMin = min(outVec(:,2));
    yMax = max(outVec(:,2));
    
    xRange = (xMax -  xMin);
    yRange = (yMax -  yMin);
    halfRange = 0.5*max(xRange, yRange);
    xMid = xMin + 0.5*xRange;
    yMid = yMin + 0.5*yRange;
    
    xMin = xMid - halfRange*(1+pad);
    xMax = xMid + halfRange*(1+pad);
    yMin = yMid - halfRange*(1+pad);
    yMax = yMid + halfRange*(1+pad);

    xLimits = [xMin, xMax];
    yLimits = [yMin, yMax];
end

function [average, deviation] = calcAveLandingPointErr(aveLandingSpot, outVec)
    len = length(outVec(:,1));
    out1 = zeros(len, 1);
    out2 = zeros(len, 1);
    for i = 1 : len
        out1(i) = norm(outVec(i,:) - aveLandingSpot);
        out2(i) = norm(outVec(i,:));
    end
    average = mean(out1);
    deviation = std(out2);
end

function plotCircle(c, r, color)
    n = 1000;
    t = linspace(0,2*pi,n);
    x = c(1) + r*sin(t);
    y = c(2) + r*cos(t);
    fill(x,y,color(1:3),"FaceAlpha", color(4), "LineStyle", "none")
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
