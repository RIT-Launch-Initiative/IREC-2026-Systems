%% Motor Comparison
% IREC Systems 2026
% Last updated September 12th, 2025
%% Setup
clear; close all; clc;
% Retrieve openrocket
filepath = "C:\IREC-2026-Systems\Rocket Files\IREC-2026-4U.ork";
rocket = openrocket(filepath);
% Reference simulations
simRef = rocket.sims("Baseline");
simOp1 = rocket.sims("15mph-Midland-N3800-Loki");
simOp2 = rocket.sims("15mph-Midland-N2700-AMW");
simOp3 = rocket.sims("15mph-Midland-N3300");
simOp4 = rocket.sims("15-Midland-N10000-CTI");
% Simulate and retrieve data for each motor option
openrocket.simulate(simRef);
openrocket.simulate(simOp1);
openrocket.simulate(simOp2);
openrocket.simulate(simOp3);
openrocket.simulate(simOp4);
dataRef = openrocket.get_data(simRef);
dataOp1 = openrocket.get_data(simOp1);
dataOp2 = openrocket.get_data(simOp2);
dataOp3 = openrocket.get_data(simOp3);
dataOp4 = openrocket.get_data(simOp4);
% Store initial weights for tabular output
M6000.weight = dataRef.("Mass")(1);
N3800.weight = dataOp1.("Mass")(1);
N2700.weight = dataOp2.("Mass")(1);
N3300.weight = dataOp3.("Mass")(1);
N10000.weight = dataOp4.("Mass")(1);
%% Stability Comparison
% Trim data for stability plot
ascentRange = timerange(eventfilter("LAUNCHROD"), eventfilter("APOGEE"), "openleft");
outFilter = eventfilter("BURNOUT");
stabRef = dataRef(ascentRange, ("Stability margin"));
stabOp1 = dataOp1(ascentRange, ("Stability margin"));
stabOp2 = dataOp2(ascentRange, ("Stability margin"));
stabOp3 = dataOp3(ascentRange, ("Stability margin"));
stabOp4 = dataOp4(ascentRange, ("Stability margin"));
% Store launchrod and burnout stabilities for tabular output
M6000.stabs = [stabRef.("Stability margin")(1),stabRef.("Stability margin")(outFilter)];
N3800.stabs = [stabOp1.("Stability margin")(1),stabOp1.("Stability margin")(outFilter)];
N2700.stabs = [stabOp2.("Stability margin")(1),stabOp2.("Stability margin")(outFilter)];
N3300.stabs = [stabOp3.("Stability margin")(1),stabOp3.("Stability margin")(outFilter)];
N10000.stabs = [stabOp4.("Stability margin")(1),stabOp4.("Stability margin")(outFilter)];
% Stability comparison plot
figure(name = "Stability Comparison");
title("Stability Comparison");
xlabel("Time [s]");
ylabel("Stability margin [Cal]");
hold on;
plot(stabRef, "Time", "Stability margin");
plot(stabOp1, "Time", "Stability margin");
plot(stabOp2, "Time", "Stability margin");
plot(stabOp3, "Time", "Stability margin");
plot(stabOp4, "Time", "Stability margin");
hold off;
xlim([seconds(0), seconds(6)]);
legend("Aerotech M6000", "Loki N3800", "AMW N2700", "Aerotech N3300", "CTI N10000", "Location", "southeast");
%% Launch Rod Exit Comparison
rodFilter = eventfilter("LAUNCHROD");
M6000.exit = dataRef.("Total velocity")(rodFilter);
N3800.exit = dataOp1.("Total velocity")(rodFilter);
N2700.exit = dataOp2.("Total velocity")(rodFilter);
N3300.exit = dataOp3.("Total velocity")(rodFilter);
N10000.exit = dataOp4.("Total velocity")(rodFilter);
%% TWR Comparison
% Trim data for TWR calculation
g = 9.81;
twrRange = timerange(seconds(0), seconds(1), "closed");
M6000.TWR = mean(dataRef(twrRange, :).("Thrust"))/(M6000.weight*g);
N3800.TWR = mean(dataOp1(twrRange, :).("Thrust"))/(N3800.weight*g);
N2700.TWR = mean(dataOp2(twrRange, :).("Thrust"))/(N2700.weight*g);
N3300.TWR = mean(dataOp3(twrRange, :).("Thrust"))/(N3300.weight*g);
N10000.TWR = mean(dataOp4(twrRange, :).("Thrust"))/(N10000.weight*g);
% Tabular Output
fprintf("%6s %24s %24s %24s\n", "Motor", "Thrust/weight", "Rod Exit Velocity [m/s]", "Rod Exit Stability [cal]");
fprintf("%6s %24.2f %24.2f %24.2f\n", "M6000", M6000.TWR, M6000.exit, M6000.stabs(1));
fprintf("%6s %24.2f %24.2f %24.2f\n", "N3800", N3800.TWR, N3800.exit, N3800.stabs(1));
fprintf("%6s %24.2f %24.2f %24.2f\n", "N2700", N2700.TWR, N2700.exit, N2700.stabs(1));
fprintf("%6s %24.2f %24.2f %24.2f\n", "N3300", N3300.TWR, N3300.exit, N3300.stabs(1));
fprintf("%6s %24.2f %24.2f %24.2f\n", "N10000", N10000.TWR, N10000.exit, N10000.stabs(1));