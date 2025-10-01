%% M6000 Thrust Curve Estimation
% IREC Systems 2026
% Last updated 1 October 2025
%% Setup for pressure-based estimation
clear; close all; clc;
% Import data
dataRRC3 = importdata("C:\IREC-2026-Systems\Data\OTIS Primary RRC3.csv");
airData = importdata("C:\IREC-2026-Systems\atmosphereData\21-Jun-2025-10.21.00-midland-gfs_1.mat");
% Make interpolants for temperature and height in terms of pressure
dataRRC3(:,3) = dataRRC3(:,3)*0.1;
pressGrid = griddedInterpolant(flip(airData.PRES), flip(airData.HGT));
tempGrid = griddedInterpolant(flip(airData.PRES), flip(airData.TMP));
% Trim data for ascent only
t_end = 23.05; % RRC3 primary recorded drogue here
dataRRC3 = trimRRCData(dataRRC3, t_end);

%% Functions
function data = trimRRCData(data, t)
    i = 1;
    while data(i,1) <= t 
        data(i,1);
        i = i+1;
    end
    data = data(1:i,:);
end