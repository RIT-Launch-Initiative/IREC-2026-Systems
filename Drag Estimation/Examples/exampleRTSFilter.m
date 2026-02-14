clear all;close all;

samplerate=100;
dt=1/samplerate;

% Start at launch and end at apogee
% This is so that the acceleration init condition is valid
global_time_r=(6.9+1.8:1/samplerate:30)';

load("a.mat")
a=a(1:end-1,:);
a=[0 0;a];
rrc3_time=a(:,1);
rrc3_alt=a(:,2);
rrc3_alt_r=interp1(rrc3_time,rrc3_alt,global_time_r,"linear","extrap");

load("b.mat")
b=b(1:end-1,:);
feather_time=b(:,1);
feather_alt=b(:,2);
feather_alt_r=interp1(feather_time,feather_alt,global_time_r,"linear","extrap");

clear a b








%% Kalman smoothing
% Define the number of iterations
N = length(rrc3_alt_r);

% Initialize the state vectors (position; velocity; acceleration)
x_fm = nan(3,N); % fm for forward, minus
x_fp = nan(size(x_fm)); % fp for forward, plus
x_bp = nan(size(x_fm)); % bp for backward, plus
x_0 = [250; 260; -16]; % initial state vector

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
    ] * 0.01;
 
% Initialize the observation matrix (updated at each iteration)
H = [1 0 0;1 0 0];
 
% Initialize the measurement noise matrix
R = [318 0;...
     0   100];

gps_noise_low = 100;
gps_noise_high = 100000;
 
% iterate forward (kalman filter)
for k = 1:N
    % adjust noise
    if k < 370
        R = [318 0;...
        0   gps_noise_high];
    else
        R = [318 0;...
        0   gps_noise_low];
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
 
    z = [rrc3_alt_r(k);...
         feather_alt_r(k)];
 
    % % handle zero velocity detection
    % if zv(k)
    %     H(2,2) = 1;
    % else
    %     H(2,2) = 0;
    % end
 
    % calculate the kalman gain
    K = P_fm(:,:,k) * H' * inv(H * P_fm(:,:,k) * H' + R);

    % calculate the state vector and the covariance matrix
    x_fp(:,k) = x_fm(:,k) + K * (z - H * x_fm(:,k));
    P_fp(:,:,k) = (eye(3) - K * H) * P_fm(:,:,k);
 
end
 
% iterate backward (smoother)
for k = N-1:-1:1 % not including zero since zero is perfectly known
    % adjust noise
    if k < 370
        R = [318 0;...
        0   gps_noise_high];
    else
        R = [318 0;...
        0   gps_noise_low];
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

figure(1);
plot(global_time_r,rrc3_alt_r,"r--");hold on;
plot(global_time_r,feather_alt_r,"b--");
plot(global_time_r,x_bp(1,:),"k");
% xlim([0 70]);
legend("RRC3","Feather","Filtered","Location","best");
title("Position");

figure(2);
plot(global_time_r(1:end-1),diff(rrc3_alt_r)./diff(global_time_r),"r--");hold on;
plot(global_time_r(1:end-1),diff(feather_alt_r)./diff(global_time_r),"b--");
plot(global_time_r,x_bp(2,:),"k");
% xlim([0 70]);
legend("RRC3","GPS","Filtered","Location","best");
xlabel("Time [s]")
ylabel("Velocity [m/s]")
title("Velocity");

figure(3);
% plot(global_time_r(1:end-2),diff(diff(rrc3_alt_r)./diff(global_time_r)./diff(global_time_r)),"r--");hold on;
% plot(global_time_r(1:end-2),diff(diff(feather_alt_r)./diff(global_time_r)./diff(global_time_r)),"b--");
plot(global_time_r,x_bp(3,:),"k");
% xlim([0 70]);
% legend("RRC3","Feather","Filtered","Location","best");
title("Acceleration");

% %% calculate 95% confidence intervals for acc, vel and pos (forward and smoothed)
% % calculate the 95% confidence intervals for the acceleration
% conf_acc_filt = [x_fp(3,:)' - 1.96 * sqrt(squeeze(P_fp(3,3,:))), x_fp(3,:)' + 1.96 * sqrt(squeeze(P_fp(3,3,:)))];
% conf_acc_smooth = [x_bp(3,:)' - 1.96 * sqrt(squeeze(P_bp(3,3,:))), x_bp(3,:)' + 1.96 * sqrt(squeeze(P_bp(3,3,:)))];
% 
% % calculate the 95% confidence intervals for the velocity
% conf_vel_filt = [x_fp(2,:)' - 1.96 * sqrt(squeeze(P_fp(2,2,:))), x_fp(2,:)' + 1.96 * sqrt(squeeze(P_fp(2,2,:)))];
% conf_vel_smooth = [x_bp(2,:)' - 1.96 * sqrt(squeeze(P_bp(2,2,:))), x_bp(2,:)' + 1.96 * sqrt(squeeze(P_bp(2,2,:)))];
% 
% % calculate the 95% confidence intervals for the position
% conf_pos_filt = [x_fp(1,:)' - 1.96 * sqrt(squeeze(P_fp(1,1,:))), x_fp(1,:)' + 1.96 * sqrt(squeeze(P_fp(1,1,:)))];
% conf_pos_smooth = [x_bp(1,:)' - 1.96 * sqrt(squeeze(P_bp(1,1,:))), x_bp(1,:)' + 1.96 * sqrt(squeeze(P_bp(1,1,:)))];
% 
% %% Plot the results
% % visualize the results
% figure("Position", [100, 400, 1200, 600]);
% subplot(3,1,1); % position
% yyaxis left;
% plot(traj.getTrajectory.t, traj.getTrajectory.pos(:,1), 'DisplayName', 'True position');
% hold on;
% plot(traj.getTrajectory.t, x_fp(1,:), 'DisplayName', 'Estimated position (filtered)');
% plot(traj.getTrajectory.t, x_bp(1,:), 'DisplayName', 'Estimated position (smoothed)');
% fill([traj.getTrajectory.t; flipud(traj.getTrajectory.t)], [conf_pos_filt(:,1); flipud(conf_pos_filt(:,2))], 'r', 'EdgeColor', 'none', 'FaceAlpha', 0.3, 'DisplayName', '95% confidence interval (filtered)');
% fill([traj.getTrajectory.t; flipud(traj.getTrajectory.t)], [conf_pos_smooth(:,1); flipud(conf_pos_smooth(:,2))], 'b', 'EdgeColor', 'none', 'FaceAlpha', 0.3, 'DisplayName', '95% confidence interval (smoothed)');
% hold off;
% xlabel('t [s]');
% ylabel('p [m]');
% legend("Location","bestoutside");
% grid on;
% yyaxis right;
% plot(traj.getTrajectory.t, traj.getTrajectory.pos(:,1) - x_fp(1,:)', 'DisplayName', 'Error after filtering');
% hold on;
% plot(traj.getTrajectory.t, traj.getTrajectory.pos(:,1) - x_bp(1,:)', 'DisplayName', 'Error after smoothing');
% 
% ylabel('\Delta p [m]');
% 
% subplot(3,1,2); % velocity
% yyaxis left;
% plot(traj.getTrajectory.t, traj.getTrajectory.vel(:,1), 'DisplayName', 'True velocity');
% hold on;
% plot(traj.getTrajectory.t, x_fp(2,:), 'DisplayName', 'Estimated velocity (filtered)');
% plot(traj.getTrajectory.t, x_bp(2,:), 'DisplayName', 'Estimated velocity (smoothed)');
% fill([traj.getTrajectory.t; flipud(traj.getTrajectory.t)], [conf_vel_filt(:,1); flipud(conf_vel_filt(:,2))], 'r', 'EdgeColor', 'none', 'FaceAlpha', 0.3, 'DisplayName', '95% confidence interval (filtered)');
% fill([traj.getTrajectory.t; flipud(traj.getTrajectory.t)], [conf_vel_smooth(:,1); flipud(conf_vel_smooth(:,2))], 'b', 'EdgeColor', 'none', 'FaceAlpha', 0.3, 'DisplayName', '95% confidence interval (smoothed)');
% hold off;
% xlabel('t [s]');
% ylabel('v [m/s]');
% legend("Location","bestoutside");
% grid on;
% yyaxis right;
% plot(traj.getTrajectory.t, traj.getTrajectory.vel(:,1) - x_fp(2,:)', 'DisplayName', 'Error after filtering');
% hold on;
% plot(traj.getTrajectory.t, traj.getTrajectory.vel(:,1) - x_bp(2,:)', 'DisplayName', 'Error after smoothing');
% ylabel('\Delta v [m/s]');
% 
% subplot(3,1,3); % acceleration
% yyaxis left;
% plot(traj.getTrajectory.t, traj.getTrajectory.acc(:,1), 'DisplayName', 'True acceleration');
% hold on;
% plot(traj.getTrajectory.t, x_fp(3,:), 'DisplayName', 'Estimated acceleration (filtered)');
% plot(traj.getTrajectory.t, x_bp(3,:), 'DisplayName', 'Estimated acceleration (smoothed)');
% plot(traj.getTrajectory.t, accelReadings, 'DisplayName', 'Measured acceleration');
% fill([traj.getTrajectory.t; flipud(traj.getTrajectory.t)], [conf_acc_filt(:,1); flipud(conf_acc_filt(:,2))], 'r', 'EdgeColor', 'none', 'FaceAlpha', 0.3, 'DisplayName', '95% confidence interval (filtered)');
% fill([traj.getTrajectory.t; flipud(traj.getTrajectory.t)], [conf_acc_smooth(:,1); flipud(conf_acc_smooth(:,2))], 'b', 'EdgeColor', 'none', 'FaceAlpha', 0.3, 'DisplayName', '95% confidence interval (smoothed)');
% hold off;
% xlabel('t [s]');
% ylabel('a [m/s^2]');
% legend("Location","bestoutside");
% grid on;
% yyaxis right;
% plot(traj.getTrajectory.t, traj.getTrajectory.acc(:,1) - x_fp(3,:)', 'DisplayName', 'Error after filtering');
% hold on;
% plot(traj.getTrajectory.t, traj.getTrajectory.acc(:,1) - x_bp(3,:)', 'DisplayName', 'Error after smoothing');
% ylabel('\Delta a [m/s^2]');
% 
% % common x axis
% linkaxes(findall(gcf,'type','axes'),'x');