%% Midland Pressure Spread Assessment
% IREC Systems 2026
% Last updated 14 June 2026
clear; close all; clc;
%% Import data
for i = 1:54
    files(i) = load(fullfile("Data\aidenAtmos\", "aiden (" + i + ").mat"));
end

%% Do stuff
groundPress = [];
for i = 1:54
    interpolant1 = griddedInterpolant(files(i).airdata.HGT, files(i).airdata.PRES);
    interpolant2 = griddedInterpolant(files(i).airdata.HGT, files(i).airdata.TMP);
    groundPress(i) = interpolant1(0);
    groundTemp(i) = interpolant2(0);
end

fprintf("Standard deviation of MSL pressure is %.4f Pa\n", std(groundPress))
fprintf("Standard deviation of MSL temperature is %.1f K\n", std(groundTemp))