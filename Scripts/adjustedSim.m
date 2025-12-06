%% Adjusted simulation tool
% IREC Systems 2026
% This script runs openrocket simulations with adjustments for atmospheric
% profile, drag curve, and with extra outputs
% TO-DO
% Plot flight trajectory
clear; close all; clc;
%% Inputs
alt_target = 3423; % meters
alt_var = 127; % meters

%% Setup
% Retrieve openrocket
filepath = "C:\IREC-2026-Systems\Rocket Files\RISK.ork";
risk = openrocket(filepath);
rocket = risk.rocket();
% Reference simulation
sim = risk.sims("15mph-Midland");
% rocket parameters
L = rocket.getLength();
[D, ~] = risk.refdims();
% Other parameters
R = 0.287; % Specific gas constant for air

% Valid sites: "spaceport-midland", "spaceport-america", "urrg", "mars"
site = launchsites("spaceport-midland"); 
% Launch time
lTime.date = [2025, 06, 21]; % [year, month, day]
lTime.time = [10, 21, 00]; % [hour, minute, second]
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
    wind = airdata, drag = rasDrag);
% Add density and dynamic pressure to table
simData.("Air density") = simData.("Air pressure")./(1000*R*simData.("Air temperature"));
simData.("Dynamic pressure") = 0.5*simData.("Air density").*simData.("Total velocity").^2;
% Add percent stability to table
simData.("Stability percent") = 100*simData.("Stability margin")*D/L;
% Add Indicated altitude to table
simData.("Indicated altitude") = pressalt("m", simData.("Air pressure"), "Pa") - pressalt("m", simData{1, "Air pressure"}, "Pa");
simData.("Altitude error") = simData.("Indicated altitude") - simData.("Altitude");
% Times vector
times = simData.Time;

%% Generate text output
% Apogee
ascentRange = timerange(eventfilter("LAUNCHROD"), eventfilter("APOGEE"));
mAlt = max(simData.Altitude);
mAltInd = max(simData.("Indicated altitude"));
errAlt = mAlt - mAltInd;
targetErr = mAlt - alt_target;
if abs(targetErr) <= alt_var
    strTarget = "APOGEE TARGET ACHIEVED";
else
    if targetErr > 0
        strTarget = "OVERSHOOT";
    else
        strTarget = "UNDERSHOOT";
    end
end
% Stability
stabData = simData(ascentRange, ["Stability margin", "Stability percent"]);
stabRod = stabData.("Stability percent")(2);
stabRodCal = stabData.("Stability margin")(2);
stabMax = max(simData.("Stability percent"));
stabMaxCal = max(simData.("Stability margin"));
% Flutter
fins = risk.component(class="FinSet");
flutterFOS = FOS_finflutter(simData, fins);
% Dynamic pressure
qData = simData(ascentRange, "Dynamic pressure").("Dynamic pressure");
max_q = [0 0];
for i = 1 : length(qData)
    if qData(i) > max_q(2)
        max_q = [seconds(times(i)) qData(i)];
    end
end
accelData = simData(ascentRange, "Total acceleration");
maxVel = max(simData.("Total velocity"));
maxMach = max(simData.("Mach number"));
maxAccel = max(accelData.("Total acceleration"));
maxG = maxAccel/9.81;


%% Plot outputs :)
plotRange = timerange(eventfilter("LAUNCH"), eventfilter("DROGUE"));
plot_openrocket(simData(plotRange, :), "Altitude", "Total velocity", end_ev = "DROGUE", labels = ["LAUNCHROD", "BURNOUT", "APOGEE"]);
% plotAltitudeError(simData)
% plotErrorVAltitude(simData)
plotStabPercent(simData)
plotStabCombined(simData)
% plotCPlocation(simData)

close all;

%% Text output
fprintf("%s\n", strTarget);
fprintf("\nGeometric Apogee: %4.0f m\nIndicated Apogee: %4.0f m\nMeasurement Error: %3.0f m\n"...
    + "Apogee Error: %2.1f m\n", mAlt, mAltInd, errAlt, targetErr);
fprintf("\nMaximum velocity: %4.0f m/s\nMaximum acceleration: %3.0f m/s^2 (%2.1f g)\n" + ...
    "Maximum mach number: %1.2f\n", maxVel, maxAccel, maxG, maxMach);
fprintf("\nLaunch stability: %2.2f percent (%.2f cal)\nMaximum stability: %2.2f percent (%.2f cal)\n",...
      stabRod, stabRodCal, stabMax, stabMaxCal);
fprintf("\nFlutter FoS: %1.2f\n", flutterFOS);
fprintf("\nMax q: %.2f kPa at %.2f seconds\n", (max_q(2)*10^-3), max_q(1))

%% Functions
function plotMotion(simData)
    ascentRange = timerange(eventfilter("LAUNCHROD"), eventfilter("DROGUE"), "openleft");
    data = simData(ascentRange, ["Altitude", "Total velocity"]);
    figure(name = "Total Motion")
    xlabel("Time [s]")
    yyaxis("left");
    plot(data, "Time", "Altitude")
    ylabel("Altitude [m]")
    yyaxis("right")
    plot(data, "Time", "Total velocity")
    ylabel("Velocity [m/s]")
end
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
function plotCPlocation(simData)
    % Trim data
    ascentRange = timerange(eventfilter("LAUNCHROD"), eventfilter("APOGEE"), "openleft");
    stabData = simData(ascentRange, ["CP location", "Angle of attack", "Mach number"]);
    stabData.("CP location") = stabData.("CP location")/0.0254;
    % Plot the data
    figure(name = "CP location")
    hold on;
    % Left side
    yyaxis("left")
    plot(stabData, "Time", "CP location", "Color", "r");
    ylabel("CP location [inches]")
    xlabel("Time [s]")
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
end
