function [time, vel, accel] = filterData(FCData,GPSData)
    % Combines data from flight computers and gps and outputs velocity and
    % axial acceleration magnitudes
    time = FCData.Time;
    vel = FCData.Velocity;
    accel = zeros(length(time));
end

