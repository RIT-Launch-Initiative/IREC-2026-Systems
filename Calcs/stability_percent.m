% Stability 

function [stab_launch, stab_max] = stability_percent(data, D, L)
    arguments
        data timetable
        D
        L
    end

    data_range = timerange(eventfilter("LAUNCHROD"), eventfilter("BURNOUT"), "openleft");
    data = data(data_range, :);
    data.("Stability percent") = 100*data.("Stability margin")*D/L;
    stab_launch = data{1, "Stability percent"}; % launchrod
    stab_max = max(data.("Stability percent")); % burnout
end