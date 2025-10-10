function tab = ork2dragtable(doc, machs)
    arguments (Input)
        doc (1,1) openrocket;
        machs (:,1) double {mustBeNonnegative};
    end
    arguments (Output)
        tab (:,2) table {mustHaveCols(tab, ["MACH", "DRAG"])}; % same as required for <drag = ...>
    end

    if machs(1) ~= 0
        warning("Mach vector does not start at zero, " + ...
            "which may cause the simulation to fail on NaN values");
    end
    if ~issorted(machs, "strictascend");
        warning("Machs vector is not strictly ascending, " + ...
            "which may cause the simulation to fail");
    end

    tab = table;
    tab.MACH = machs;
    tab.DRAG = NaN(size(machs));
    fc = doc.flight_condition(0, 0);
    for i_mach = 1:length(machs)
        fc.setMach(machs(i_mach));
        [~, tab.DRAG(i_mach), ~, ~, ~] = doc.aerodata3(fc);
    end
end

function mustHaveCols(input, cols)
    arguments
        input;
        cols (1,:) string;
    end

    err_id = "util:invalidTable";
    notpresent = setdiff(cols, input.Properties.VariableNames);
    if ~isempty(notpresent)
        mex = MException(err_id, "Required table columns %s not present", ...
            mat2str(notpresent));
        throwAsCaller(mex);
    end
end
