function [shared_time, x_bp(1,:), x_bp(2,:), x_bp(3,:)] = filterData(FCDataPos,FCDataVel,GPSData, init_pos, init_vel, init_accel)
    % Combines data from flight computers and gps and outputs velocity and
    % axial acceleration magnitudes
    % time = FCData.Time;
    % vel = FCData.Velocity;
    % accel = zeros(length(time));

    shared_time = FCDataPos.Time;
    FCPos = FCDataPos.Altitude;
    FCVel = FCDataVel.Velocity;
    GPSAltitude = GPSData.Altitude;

    dt=shared_time(2)-shared_time(1);

    %% Kalman smoothing
    % Define the number of iterations
    N = length(shared_time);
    
    % Initialize the state vectors (position; velocity; acceleration)
    x_fm = nan(3,N); % fm for forward, minus
    x_fp = nan(size(x_fm)); % fp for forward, plus
    x_bp = nan(size(x_fm)); % bp for backward, plus
    x_0 = [init_pos; init_vel; init_accel]; % initial state vector
    
    % Initialize the covariance matrices
    P_fm = nan(3,3,N); % fm for forward, minus
    P_fp = nan(size(P_fm)); % fp for forward, plus
    P_bp = nan(size(P_fm)); % bp for backward, plus
    % P_0 = zeros(3,3); P_0(3,3) = 0.59; % initial covariance matrix
    P_0 = diag([0 0 0]);
    
    % Initialize the state transition matrix
    F = [...
         1 dt 0.5*dt^2; ...
         0 1  dt      ; ...
         0 0  1       ;
         ];
    
    % Initialize the process noise matrix
    stdDevAccel = 0.0025; % standard deviation of the acceleration process noise
    Q = [...
        dt^4/4 dt^3/2 dt^2/2;...
        dt^3/2 dt^2   dt    ;...
        dt^2/2 dt     1     ;...
        ] * stdDevAccel;
     
    % Initialize the observation matrix (updated at each iteration)
    H = [1 0 0;0 1 0;1 0 0];
     
    % Initialize the measurement noise matrix
    R = [318 0   0;...
         0   318 0;...
         0   0   100];
    
    gps_noise_low = 100;
    gps_noise_high = 100000;
    gps_switch_time = 3;
     
    % iterate forward (kalman filter)
    for k = 1:N
        % Dynamically trust GPS less before gps_switch_time
        if k < find(shared_time>gps_switch_time,1,"first")
            R = [318 0   0;...
                 0   318 0;...
                 0   0   gps_noise_high];
        else
            R = [318 0   0;...
                 0   318 0;...
                 0   0   gps_noise_low];
        end
        % predict
        if k == 1
            % initial prediction
            x_fm(:,k) = F * x_0;
            P_fm(:,:,k) = F * P_0 * F' + Q;
        else
            x_fm(:,k) = F * x_fp(:,k-1);
            P_fm(:,:,k) = F * P_fp(:,:,k-1) * F' + Q;
        end
     
        z = [FCPos(k);...
             FCVel(k);...
             GPSAltitude(k)];
     
        % calculate the kalman gain
        K = P_fm(:,:,k) * H' * inv(H * P_fm(:,:,k) * H' + R);
    
        % calculate the state vector and the covariance matrix
        x_fp(:,k) = x_fm(:,k) + K * (z - H * x_fm(:,k));
        P_fp(:,:,k) = (eye(3) - K * H) * P_fm(:,:,k);
     
    end
     
    % iterate backward (smoother)
    for k = N-1:-1:1 % not including zero since zero is perfectly known
        % Dynamically trust GPS less before gps_switch_time
        if k < find(shared_time>gps_switch_time,1,"first")
            R = [318 0   0;...
                 0   318 0;...
                 0   0   gps_noise_high];
        else
            R = [318 0   0;...
                 0   318 0;...
                 0   0   gps_noise_low];
        end
        if k == N-1
            % Initialization
            x_bp(:,N) = x_fp(:,N);
            P_bp(:,:,N) = P_fp(:,:,N);
        end
    
        I = P_fm(:,:,k+1)^-1;
        K = P_fp(:,:,k) * F' * I;
        x_bp(:,k) = x_fp(:,k) + K * (x_bp(:,k+1) - x_fm(:,k+1));
        P_bp(:,:,k) = P_fp(:,:,k) - K * (P_fm(:,:,k+1) - P_bp(:,:,k+1)) * K';
    end

end

