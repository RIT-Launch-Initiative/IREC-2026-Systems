function dataTrimmed = trimTB1Data(CMData, ravenData, globalTime)
% This function outputs a position and velocity measurement (from raven)
% and acceleration measurement (from controls mod)
%   Detailed explanation goes here
    t_CM = CMData.timestamp__ms;
    % Convert to relative seconds
    for i = 1:length(t_CM)
        t_CM(i) = (CMData.timestamp__ms(i) - CMData.timestamp__ms(1))*10^-3;
    end
    t_CM1 = t_CM;
    % Trim CM accel
    CMAccel_pre1 = CMData.accel_z__m_s2;
    i = 1;
    while (CMAccel_pre1(i) < 50)
        i = i + 1;
    end
    CMAccel_pre = CMAccel_pre1(i:i+8000);
    t_CM = t_CM(1:8001);

    % Trim raven time
    FCTime_pre = ravenData.Flight_Time__s_;
    FCTime_pre1 = FCTime_pre;
    i = 1;
    while (FCTime_pre(i) < 0)
        i = i + 1;
    end
    FCTime_pre = FCTime_pre(i:i+3000);

    % Trim raven altitude
    FCPos_pre = ravenData.Baro_Altitude_AGL__feet_;
    FCPos_pre1 = FCPos_pre*0.3048;
    i = 1;
    while (FCPos_pre(i) < 5)
        i = i + 1;
    end
    FCPos_pre = FCPos_pre(i:i+3000);

    % Trim raven velocity
    FCVel_pre = ravenData.Velocity_Up;
    i = 1;
    while (FCVel_pre(i) < 1)
        i = i + 1;
    end
    FCVel_pre = FCVel_pre(i:i+3000);

    FCPos = interp1(FCTime_pre, FCPos_pre, globalTime, "linear", "extrap");
    FCPos = FCPos*0.3048; % Convert to m
    FCVel = interp1(FCTime_pre, FCVel_pre, globalTime, "linear", "extrap");
    FCVel = FCVel*0.3048; % Convert to m/s
    CM_accel = interp1(t_CM, CMAccel_pre, globalTime, "linear", "extrap");

    dataTrimmed = [globalTime; FCPos; FCVel; CM_accel-9.81];

    %dataTrimmed = dataTrimmed(:,301:1001);

    f = figure(name = "Uncorrected Data");
    hold on;
    yyaxis left
    plot(FCTime_pre1, FCPos_pre1);
    ylabel("Altitude [m]")

    yyaxis right
    plot(t_CM1, CMAccel_pre1);
    ylabel("Acceleration [m/s^2]")

    hold off;
    
    xlabel("Flight Time [s]")
    xlim([-1 10])
    legend("Measured Altitude", "Measured Acceleration", "Location","northeast")

    % print to pdf
    slidesSz = [600, 400];
    path = "C:\IREC-2026-Systems\Drag Estimation\Figures\uncorrected-data-2.png";
    print2size(f, path, slidesSz)
    function print2size(fig, path, sz)
    
        drawnow;
    
        fig.Units = "pixels";
        fig.Position = [1 1 sz];
        waitfor(fig, Position = [1 1 sz]);
    
        exportgraphics(fig, path, ContentType = "vector");
    
        % fig.WindowStyle = old_window;
        % waitfor(fig, WindowStyle = old_window);
    end

end

