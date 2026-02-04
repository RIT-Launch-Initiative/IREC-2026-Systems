function dataOut = trimFeatherweightData(dataIn)
    dataIn.UTCTIME = datetime(dataIn.UTCTIME(:),"InputFormat","MMM dd yyyy HH:mm:ss.SSS 'UTC'","TimeZone","UTC");
    dt=seconds(time(between(dataIn.UTCTIME(1),dataIn.UTCTIME(:))));
    % featherweightDataTrimmed = featherweightData;
    % featherweightDataTrimmed = renamevars(featherweightDataTrimmed,"UTCTIME","Time");
    % featherweightDataTrimmed.Time = dt;
    % featherweightDataTrimmed = table2timetable(featherweightDataTrimmed);
    dataOut = [dt dataIn.AltitudeAGL/3.281];
end

