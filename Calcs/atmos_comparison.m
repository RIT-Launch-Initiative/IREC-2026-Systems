%% Atmosphere comparison
% IREC Systems 2026
% This script compares the ISA with a custom atmosphere
clear; close all; clc;
%% Well? Do the comparison already
airDataFilePath = "C:\IREC-2026-Systems\atmosphereData\airdata.mat";
airdata = importdata(airDataFilePath);
airdata.PRES = airdata.PRES*10^-2;
altVec = linspace(0, 4000, 1001);
customPRES = interp1(airdata.HGT, airdata.PRES, altVec, "linear", "extrap");
customTMP = interp1(airdata.HGT, airdata.TMP, altVec, "linear", "extrap");

isa_hgt = linspace(0, 4000, 9);
isa_pres = [1.01325, 0.9546, 0.8988, 0.8456, 0.7950, 0.7469, 0.7012, 0.6578, 0.6166] * 1000;
isa_tmp = [15.1, 11.9, 8.7, 5.4, 2.2, -1.1, -4.3, -7.6, -10.8];

ISAPRES = interp1(isa_hgt, isa_pres, altVec, "linear", "extrap");
ISATMP = interp1(isa_hgt, isa_tmp, altVec, "linear", "extrap");

f = figure(name = "atmosphere comparison");
hold on;
plot(ISAPRES, altVec)
plot(customPRES, altVec)
hold off;
legend("ISA", "Forecast", "FontName", "Times New Roman")
xlabel("Pressure [mBar]", "FontName", "Times New Roman")
ylabel("Altitude [m]", "FontName", "Times New Roman")
xlim([500 1050])
grid on;

% print to pdf
path = "C:\IREC-2026-Systems\Drag Estimation\Figures\atmos-comparison.pdf";
sz = [600, 300];
print2size(f, path, sz)


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
