function dataOut = trimRRC3Data(dataIn, adjPressAlt)
    % figure out index of Drogue event
    i = 1;
    while (dataIn.Events(i) ~= "Drogue")
        i = i + 1;
    end
    % Trim to drogue
    dataOut = dataIn(1:i, :);
    % Adjust altitude
    % for i = 1:length(dataOut.Time)
    %     dataOut.Altitude(i) = adjPressAlt(dataOut.Pressure(i)*100) - adjPressAlt(dataOut.Pressure(1)*100);
    % end
    % Unit conversions
    dataOut.Altitude = dataOut.Altitude*0.3048;
    dataOut.Velocity = dataOut.Velocity*0.3048;
    dataOut.Pressure = dataOut.Pressure*100; % conv millibar to kPa
    dataOut.Temperature = (dataOut.Temperature-32)*(5/9) + 273; % F to K
    % Discard excess information
    dataOut.Events = [];
    dataOut.Voltages = [];
    % Convert to an array
    timeVec = [];
    for i = 1:length(dataOut.Time)
        timeVec = [timeVec;dataOut.Time(i)];
    end
    dataOut.Time = timeVec;
    dataOut = [dataOut.Time, dataOut.Altitude, dataOut.Velocity];
end

