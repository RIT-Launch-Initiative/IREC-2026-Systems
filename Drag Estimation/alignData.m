function [FCData,GPSData] = alignData(FCData, GPSData, globalTime)
    % Interpolate
    rrc3AltAdj = interp1(FCData(:,1), FCData(:,2), globalTime, "linear", "extrap");
    rrc3VelAdj = interp1(FCData(:,1), FCData(:,3), globalTime, "linear", "extrap");
    GPSAltAdj = interp1(GPSData(:,1), GPSData(:,2), globalTime, "linear", "extrap");

    FCData = [globalTime, rrc3AltAdj, rrc3VelAdj];
    GPSData = [globalTime, GPSAltAdj];
end

