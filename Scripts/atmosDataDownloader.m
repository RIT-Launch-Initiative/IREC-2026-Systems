%% Weather Data Tool
% IREC Systems 2026
% This script downloads weather model data
clear; close all; clc;
%% Inputs
% valid time - time we care about
validtime = datetime(2026, 02, 20, 10, 20, 00, TimeZone = -hours(6));
% reference time - time the forecast is published
reftime = datetime(2024, 06, 21, 10, 20, 00, TimeZone = -hours(6)) - hours(12);
% weather model to use
% options: 
model = "hrrr";
produce = "wrfprsf";

%% Setup
model_ref = ncep.analysis(model, "wrfprsf", validtime);