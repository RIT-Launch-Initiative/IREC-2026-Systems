function [out, vn] = filterData_TB1(dataTrimmed)
    % Combines data from flight computers and gps and outputs velocity and
    % axial acceleration magnitudes
    % time = FCData.Time;
    % vel = FCData.Velocity;
    % accel = zeros(length(time));

    shared_time = dataTrimmed(1,:);
    FCPos = dataTrimmed(2,:);
    FCVel = dataTrimmed(3,:);
    CMAccel = dataTrimmed(4,:);

    dt=shared_time(2)-shared_time(1);

    %% Kalman smoothing
    % Define the number of iterations
    N = length(shared_time);
    
    % Initialize the state vectors (position; velocity; acceleration)
    x_fm = nan(3,N); % fm for forward, minus
    x_fp = nan(size(x_fm)); % fp for forward, plus
    x_bp = nan(size(x_fm)); % bp for backward, plus
    x_0 = [dataTrimmed(2,1); dataTrimmed(3,1); dataTrimmed(4,1)]; % initial state vector

    % Initialize innovation
    v = nan(3,N);
    
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
    stdDevPos = 0.1;
    stdDevVel = 0.005;
    stdDevAccel = 0.01; % standard deviation of the acceleration process noise

    Q = diag([stdDevPos, stdDevVel, stdDevAccel]);
     
    % Initialize the observation matrix (updated at each iteration)
    H = [1 0 0;0 0 0;0 0 1];
     
    % Initialize the measurement noise matrix
    R = diag([24.4697118 0.318560409 2.3659593e-05]);
     
    % iterate forward (kalman filter)
    for k = 1:N
        % Change noise depending on phase of flight
        % if k < 250 % I unfortunately determined this index by looking at the data
        %     R = [318  0   0;...
        %         0   10   0;...
        %         0   0   100];
        % else
        %     R = [318  0   0;...
        %         0   100   0;...
        %         0   0   20];
        % end

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
            CMAccel(k)];

        S = H * P_fm(:,:,k) * H' + R;

        % calculate the kalman gain
        K = P_fm(:,:,k) * H' * inv(S);
        
        % calculate the state vector and the covariance matrix
        x_fp(:,k) = x_fm(:,k) + K * (z - H * x_fm(:,k));
        P_fp(:,:,k) = (eye(3) - K * H) * P_fm(:,:,k);
        
        v(:,k) = z - H*x_fm(:,k);
        vn(:,k) = (S^(-0.5)) * v(:,k);
    end
     
    %iterate backward (smoother)
    for k = N-1:-1:1 % not including zero since zero is perfectly known
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
    out = [shared_time; x_fp(1,:); x_fp(2,:); x_fp(3,:)];
end

