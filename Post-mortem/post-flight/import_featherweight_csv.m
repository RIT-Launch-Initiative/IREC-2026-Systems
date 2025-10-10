function data = import_featherweight_csv(path)
    arguments (Input)
        path (1,1) string {mustBeFile};
    end
    arguments (Output)
        data timetable;
    end

    opts = detectImportOptions(path, Delimiter = ",");
    opts.VariableNamingRule = "preserve";
    opts = setvaropts(opts, "UTCTIME", Type = "datetime", ...
        InputFormat = "MMM dd uuuu HH:mm:ss.SSS 'UTC'", TimeZone = "UTC");

    data = readtable(path, opts);
    data = table2timetable(data);
end

