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
simOp4 = rocket.sims("15mph-Midland-N2220");
simOp5 = rocket.sims("15mph-Midland-N2000");
simOp6 = rocket.sims("15-Midland-N10000-CTI");
% Simulate and retrieve data for each motor option
openrocket.simulate(simRef);
openrocket.simulate(simOp1);
openrocket.simulate(simOp2);
openrocket.simulate(simOp3);
openrocket.simulate(simOp4);
openrocket.simulate(simOp5);
openrocket.simulate(simOp6);
dataRef = openrocket.get_data(simRef);
dataOp1 = openrocket.get_data(simOp1);
dataOp2 = openrocket.get_data(simOp2);
dataOp3 = openrocket.get_data(simOp3);
dataOp4 = openrocket.get_data(simOp4);
dataOp5 = openrocket.get_data(simOp5);
dataOp6 = openrocket.get_data(simOp6);
% Store initial weights for tabular output
M6000.weight = dataRef.("Mass")(1);
N3800.weight = dataOp1.("Mass")(1);
N2700.weight = dataOp2.("Mass")(1);
N3300.weight = dataOp3.("Mass")(1);
N2220.weight = dataOp4.("Mass")(1);
N2000.weight = dataOp5.("Mass")(1);
N10000.weight = dataOp6.("Mass")(1);
%% Stability Comparison
% Trim data for stability plot
ascentRange = timerange(eventfilter("LAUNCHROD"), eventfilter("APOGEE"), "openleft");
outFilter = eventfilter("BURNOUT");
stabRef = dataRef(ascentRange, ("Stability margin"));
stabOp1 = dataOp1(ascentRange, ("Stability margin"));
stabOp2 = dataOp2(ascentRange, ("Stability margin"));
stabOp3 = dataOp3(ascentRange, ("Stability margin"));
stabOp4 = dataOp4(ascentRange, ("Stability margin"));
stabOp5 = dataOp5(ascentRange, ("Stability margin"));
stabOp6 = dataOp6(ascentRange, ("Stability margin"));
% Store launchrod and burnout stabilities for tabular output
M6000.stabs = [stabRef.("Stability margin")(1),stabRef.("Stability margin")(outFilter)];
N3800.stabs = [stabOp1.("Stability margin")(1),stabOp1.("Stability margin")(outFilter)];
N2700.stabs = [stabOp2.("Stability margin")(1),stabOp2.("Stability margin")(outFilter)];
N3300.stabs = [stabOp3.("Stability margin")(1),stabOp3.("Stability margin")(outFilter)];
N2220.stabs = [stabOp4.("Stability margin")(1),stabOp4.("Stability margin")(outFilter)];
N2000.stabs = [stabOp5.("Stability margin")(1),stabOp5.("Stability margin")(outFilter)];
N10000.stabs = [stabOp6.("Stability margin")(1),stabOp6.("Stability margin")(outFilter)];
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
plot(stabOp5, "Time", "Stability margin");
plot(stabOp6, "Time", "Stability margin");
hold off;
xlim([seconds(0), seconds(6)]);
legend("Aerotech M6000", "Loki N3800", "AMW N2700", "Aerotech N3300", "Aerotech N2220", "Aerotech N2000", "CTI N10000", "Location", "southeast");
%% TWR Comparison
% Trim data for TWR calculation
g = 9.81;
twrRange = timerange(seconds(0), seconds(1), "closed");
M6000.TWR = mean(dataRef(twrRange, :).("Thrust"))/(M6000.weight*g);
N3800.TWR = mean(dataOp1(twrRange, :).("Thrust"))/(N3800.weight*g);
N2700.TWR = mean(dataOp2(twrRange, :).("Thrust"))/(N2700.weight*g);
N3300.TWR = mean(dataOp3(twrRange, :).("Thrust"))/(N3300.weight*g);
N2220.TWR = mean(dataOp4(twrRange, :).("Thrust"))/(N2220.weight*g);
N2000.TWR = mean(dataOp5(twrRange, :).("Thrust"))/(N2000.weight*g);
N10000.TWR = mean(dataOp6(twrRange, :).("Thrust"))/(N10000.weight*g);
% Tabular Output
fprintf("%6s %24s %24s %24s\n", "Motor", "Thrust/weight", "Launch Stability", "Burnout Stability");
fprintf("%6s %24.2f %24.2f %24.2f\n", "M6000", M6000.TWR, M6000.stabs(1), M6000.stabs(2));
fprintf("%6s %24.2f %24.2f %24.2f\n", "N3800", N3800.TWR, N3800.stabs(1), N3800.stabs(2));
fprintf("%6s %24.2f %24.2f %24.2f\n", "N2700", N2700.TWR, N2700.stabs(1), N2700.stabs(2));
fprintf("%6s %24.2f %24.2f %24.2f\n", "N3300", N3300.TWR, N3300.stabs(1), N3300.stabs(2));
fprintf("%6s %24.2f %24.2f %24.2f\n", "N2220", N2220.TWR, N2220.stabs(1), N2220.stabs(2));
fprintf("%6s %24.2f %24.2f %24.2f\n", "N2000", N2000.TWR, N2000.stabs(1), N2000.stabs(2));
fprintf("%6s %24.2f %24.2f %24.2f\n", "N10000", N10000.TWR, N10000.stabs(1), N10000.stabs(2));