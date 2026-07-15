%% Motor Stability Comparison
% IREC Systems 2026
% Last updated September 12th, 2025
%% Setup
clear; close all; clc;
% Retrieve openrocket
filepath = "C:\IREC-2026-Systems\Rocket Files\IREC-2026.ork";
rocket = openrocket(filepath);
% Reference simulations
simRef = rocket.sims("Baseline");
simOp1 = rocket.sims("15mph-Midland-N3800-Loki");
simOp2 = rocket.sims("15mph-Midland-N3300");
simOp3 = rocket.sims("15mph-Midland-N2220");
% Simulate and retrieve data for each motor option
openrocket.simulate(simRef);
openrocket.simulate(simOp1);
openrocket.simulate(simOp2);
openrocket.simulate(simOp3);
dataRef = openrocket.get_data(simRef);
dataOp1 = openrocket.get_data(simOp1);
dataOp2 = openrocket.get_data(simOp2);
dataOp3 = openrocket.get_data(simOp3);
%% Stability Comparison
% Trim data for stability plot
ascentRange = timerange(eventfilter("LAUNCHROD"), eventfilter("APOGEE"), "openleft");
stabRef = dataRef(ascentRange, ("Stability margin"));
stabOp1 = dataOp1(ascentRange, ("Stability margin"));
stabOp2 = dataOp2(ascentRange, ("Stability margin"));
stabOp3 = dataOp3(ascentRange, ("Stability margin"));
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
hold off;
legend("Aerotech M6000", "Loki N3800", "Aerotech N3300", "Aerotech N2220", "Location", "southeast");