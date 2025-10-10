clear;

launch.time = datetime(2025, 06, 11, 13, 32, 22, TimeZone = -hours(5)); % from start of GPS ascent
launch.lat = 31.044238; % [deg] from Jake GPS point
launch.lon = -103.535096; % [deg] from Jake GPS point
launch.alt = elevationquery(launch.lat, launch.lon); % [m] from OpenTopography query

cache_path = pfullfile("data", "airdata.mat");
cache = matfile(cache_path, Writable = true);

model = "gfs";
product = "pgrb2.0p50";
minpres = 450; % cull pressure levels

airdata = atmosphere(model, product, launch.lat, launch.lon, ...
    launch.time, minpres = minpres);

cache.airdata = airdata;
cache.launch = launch;
