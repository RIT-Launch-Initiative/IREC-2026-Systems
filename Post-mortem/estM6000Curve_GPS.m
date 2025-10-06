%% M6000 Thrust Curve Estimation
% IREC Systems 2026
% Last updated 6 October 2025
%% Setup data for pressure-based estimation
clear; close all; clc;
% Import data
dataGPS = importdata("C:\IREC-2026-Systems\Data\featherweight_downloaded.csv");
airData = importdata("C:\IREC-2026-Systems\atmosphereData\21-Jun-2025-10.21.00-midland-gfs_1.mat");
% Convert all pressures to kPa and temps to K
dataRRC3(:,3) = dataRRC3(:,3)*0.1; % convert kPa
airData.PRES = airData.PRES*10^-3;
airData.TMP = airData.TMP+273;
% interpolants for height and temp with respect to pressure
heightGrid = griddedInterpolant(flip(airData.PRES), flip(airData.HGT));
tempGrid = griddedInterpolant(flip(airData.PRES), flip(airData.TMP));
% Trim data for ascent only
t_end = 2.2; % Appears to be actual end of burn
dataRRC3 = trimRRCData(dataRRC3, t_end); %trim data
% adjusted data: 
% [time [s], alitude [m], pressure [kPa], vel [m/s], accel [m/s^2], Temp [K], mach number]
adjData = convRRCData(dataRRC3, tempGrid, heightGrid); % convert to SI, include acceleration and mach number
%% Setup openrocket for drag calcs
otis = openrocket("C:\irec-2025-analysis\rocket_files\IREC_2025_M6000ST-0.ork");

Isp = 9510/4.2; % [Ns\kg] <-- total impulse and propellant weight from AT website
%% Iterate through flight data and calculate forces
[~, A] = refdims(otis); % drag area [m^2]
M = 32.979; % rocket mass [kg]
dragList = zeros(length(adjData),1);
Thrust = zeros(length(adjData),1);
impulse = 0;
dt = 0.05;
for i = 1:length(adjData)
    F_d = dragCalc(i, adjData, otis, A); % drag in Newtons
    dragList(i) = F_d;
    F_g = 9.81*M; % weight
    % Force balance to solve for thrust
    F_T = M*adjData(i,5) - F_d - F_g;
    if F_T < 0
        F_T = 0;
    end
    Thrust(i) = F_T;
    M = M - (F_T/Isp)*dt;
    impulse = impulse + F_T*dt;
end
%% Plot supposed thrust curve, display results, write it to a csv and make an eng file
% plot
figure(name = "Thrust Curve via RRC3 data, Midland atmosphere, and OR drag calculation")
plot(adjData(:,1), Thrust)
xlabel("Time [s]")
ylabel("Thrust [N]")
% text out
fprintf("\nTotal impulse: %4.0f Ns\n", impulse);
% csv output
curve = [adjData(:,1),Thrust];
writematrix(curve, "C:\IREC-2026-Systems\Post-mortem\estM6000-RRC3.csv");
% .eng output
exportPath = "C:\IREC-2026-Systems\Post-mortem\estM6000_RRC3.eng";
L = length(Thrust);
estM6000_RRC3 = array2timetable(Thrust(2:L), "RowTimes", seconds(adjData(2:L,1)));
% Setup metadata
estM6000_RRC3.Properties.VariableUnits = "N";
estM6000_RRC3.Properties.VariableNames = "Thrust";
estM6000_RRC3.Properties.Description = "98/10240 Super Thunder";
estM6000_RRC3.Properties.UserData.name = "M6000_Est_RRC3";
estM6000_RRC3.Properties.UserData.diameter_mm = 98;
estM6000_RRC3.Properties.UserData.length_mm = 808;
estM6000_RRC3.Properties.UserData.delays_sec = "P";
estM6000_RRC3.Properties.UserData.propmass_kg = 4.2;
estM6000_RRC3.Properties.UserData.wetmass_kg = 8.697;
estM6000_RRC3.Properties.UserData.manufacturer = "AeroTech";
export_motor_eng(exportPath, estM6000_RRC3);

%% Plot motion
figure(name = "Motion data")
yyaxis("left")
plot(adjData(:,1), adjData(:,2))
ylabel("Altitude [m]")
yyaxis("right")
plot(adjData(:,1), adjData(:,4))
hold on;
plot(adjData(:,1), adjData(:,5))
hold off;
ylabel("Velocity/acceleration [m/s]")
xlabel("Time [s]")

%% Functions
function data = trimRRCData(data, t)
    i = 1;
    while data(i,1) <= t 
        data(i,1);
        i = i+1;
    end
    data = data(1:i,:);
end
function data = convRRCData(data, tempGrid, heightGrid)
    dt = 0.05;
    % convert ft to m
    data(:,4) = data(:,4)*0.3048;
    data(:,2) = data(:,2)*0.3048;
    % pressure altitude adjustment
    % pressures = smooth(data(:,3));
    % pressures = smooth(pressures);
    % plot(pressures)
    % for i = 1:length(data)
    %     data(i,2) = heightGrid(pressures(i)) - heightGrid(pressures(1));
    % end
    % data(:,4) = gradient(data(:,2), dt);
    % initialize acceleration column
    data(:,5) = zeros(length(data),1);
    % Numerical diff for acceleration
    data(:,5) = smooth(gradient(data(:,4), dt));
    % for i = 2:length(data)-1
    %     dv = data(i+1,4) - data(i-1,4);
    %     dt = data(i+1,1) - data(i-1,1);
    %     data(i,5) = dv/dt;
    % end
    % mach number calc
    % initialize temp and mach columns
    data(:,6) = zeros(length(data),1);
    data(:,7) = zeros(length(data),1);
    for i = 1:length(data)
        T = tempGrid(data(i,3));
        data(i,6) = T;
        speedofsound = sqrt(1.4*287*T);
        mach = data(i,4)/speedofsound;
        data(i,7) = mach;
    end
end
function F = dragCalc(i, data, rocket, A)
    mach = data(i,7);
    fc = flight_condition(rocket, mach);
    [~, CD, ~, ~, ~] = aerodata3(rocket, fc);
    rho = data(i,3)/(0.287*data(i,6));
    q = 0.5*rho*data(i,4)^2;
    F = CD*A*q;
end
% Relates altitude to pressure profile based on a non-standard atmosphere profile
function alt = adjustedAltimer(press, heightGrid)
    alt = heightGrid(press);
end