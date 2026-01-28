% =========================================================================== %
%> @example derivation3RtsSmoother.m
%>
%> This example demonstrates the application of the RTS Smoother for the
%> estimation of the position, velocity and acceleration of a moving object.
%> The example is based on the explanations in @ref derivation3RtsSmoother
%> and uses the same trajectory and sensor data generation as in the previous
%> examples. The example also includes the zero velocity detection and the
%> pseudo measurement of the position. The example also includes the Kalman.
%>
%> @note a more detailed explanation can be found here: @ref derivation3RtsSmoother
%>
%> <details>
% =========================================================================== %
 
clear; close all; clc;
 
% flags if the pesudo measurement of distance should be used
PM_P = true;
 
rng(1); % seed the random number generator for reproducibility
 
%% Sensor Data Generation
% Define the trajectory object
traj = Trajectory("fs", 200); % 200 Hz sampling frequency
 
% add waypoints
traj.addWaypoints(seconds(0), seconds(1), [0,0,0], quaternion.ones(1)); %initial pos for one second
traj.addWaypoints(seconds(10), seconds(1), [10,0,0], quaternion.ones(1)); %move 10m in x direction and stay there for one second
traj.addWaypoints(seconds(20), seconds(1), [0,0,0], quaternion.ones(1)); %move back to origin
 
% generate the trajectory
traj.generateTrajectory("pos","minJerk"); % generate the trajectory with minimum jerk interpolation
 
% Define the sensor object (realistic sensor)
js = JumpSensor;
 
% generate the sensor data
data = js.generateFromTrajectory(traj);
accelReadings = data.tt.acc(:,1); % only consider the x axis
 
% define time step
dt = 1/data.mpu_rate;
 
% get actual bias and sensitivity
bias = js.getParams.mpu.acc.ConstantBias(1);
sensitivity = js.getParams.mpu.acc.AxesMisalignment(1,1) / 100; % convert from percentage to fraction
 
%% Zero Velocity Detection
% a good zero velocity estimation on a one axis accelerometer is not easy to
% achieve. Therefore the zero velocity detection is hard coded here.
zv = false(size(accelReadings));
 
% in the actual data the zero velocity is between index 1:200, 2000:2200 and
% 4000:4200. But we would't know that in a real scenario. Therefore only a few
% zero velocity points are set to true.
zv(1) = true;
zv(end) = true;
 
%% Position Pseudo Measurement
% We define a pseudo measurement of the position at the static position at 10m
% and 20s.
PM_P_idx = [2100,4100];
PM_P_val = [10,0];
 
%% Kalman smoothing
% Define the number of iterations
N = length(accelReadings);
 
% Initialize the state vectors (position; velocity; acceleration)
x_fm = nan(4,N); % fm for forward, minus
x_fp = nan(size(x_fm)); % fp for forward, plus
x_bp = nan(size(x_fm)); % bp for backward, plus
x_0 = [0; 0; 0; 0]; % initial state vector
 
% Initialize the covariance matrices
P_fm = nan(4,4,N); % fm for forward, minus
P_fp = nan(size(P_fm)); % fp for forward, plus
P_bp = nan(size(P_fm)); % bp for backward, plus
P_0 = zeros(4,4); P_0(4,4) = 0.59; % initial covariance matrix
 
% Initialize the state transition matrix
F = [...
     1, dt, 0.5*dt^2, 0; ...
     0, 1,  dt,       0; ...
     0, 0,  1,        0; ...
     0, 0,  0,        1; ...
     ];
    
% Initialize the process noise matrix
stdDevAccel = 0.0025; % standard deviation of the acceleration process noise
Q = [...
    dt^4/4, dt^3/2, dt^2/2, 0,              ;...
    dt^3/2, dt^2,   dt,     0,              ;...
    dt^2/2, dt,     1,      0,              ;...
    0,      0,      0,      1e-9/stdDevAccel...
    ] * stdDevAccel;
 
% Initialize the observation matrix (updated at each iteration)
if PM_P
    H = [...
        0, 0, 1, 1; ...
        0, 1, 0, 0; ...
        1, 0, 0, 0  ...
        ];
else
    H = [0, 0, 1, 1; 0, 1, 0, 0];
end
 
% Initialize the measurement noise matrix
if PM_P
    R = [0.0449, 0, 0; 0, 0.001, 0; 0, 0, 0.5];
else
    R = [0.0449, 0; 0, 0.001];
end
 
% iterate forward (kalman filter)
for k = 1:N
 
    % predict
    if k == 1
        % initial prediction
        x_fm(:,k) = F * x_0;
        P_fm(:,:,k) = F * P_0 * F' + Q;
    else
        x_fm(:,k) = F * x_fp(:,k-1);
        P_fm(:,:,k) = F * P_fp(:,:,k-1) * F' + Q;
    end
 
    % update
    if PM_P
        z = [accelReadings(k); 0; 0];
    else
        z = [accelReadings(k); 0];
    end
 
    % handle zero velocity detection
    if zv(k)
        H(2,2) = 1;
    else
        H(2,2) = 0;
    end
 
    % handle pseudo measurement of position
    if PM_P
        if any(k == PM_P_idx)
            % pseudo measurement of position
            H(3,1) = 1;
            z(3) = PM_P_val(PM_P_idx == k);
        else
            H(3,1) = 0;
        end
    end
 
    % calculate the kalman gain
    K = P_fm(:,:,k) * H' * inv(H * P_fm(:,:,k) * H' + R);
 
    % calculate the state vector and the covariance matrix
    x_fp(:,k) = x_fm(:,k) + K * (z - H * x_fm(:,k));
    P_fp(:,:,k) = (eye(4) - K * H) * P_fm(:,:,k);
 
end
 
% iterate backward (smoother)
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
 
%% calculate 95% confidence intervals for acc, vel and pos (forward and smoothed)
% calculate the 95% confidence intervals for the acceleration
conf_acc_filt = [x_fp(3,:)' - 1.96 * sqrt(squeeze(P_fp(3,3,:))), x_fp(3,:)' + 1.96 * sqrt(squeeze(P_fp(3,3,:)))];
conf_acc_smooth = [x_bp(3,:)' - 1.96 * sqrt(squeeze(P_bp(3,3,:))), x_bp(3,:)' + 1.96 * sqrt(squeeze(P_bp(3,3,:)))];
 
% calculate the 95% confidence intervals for the velocity
conf_vel_filt = [x_fp(2,:)' - 1.96 * sqrt(squeeze(P_fp(2,2,:))), x_fp(2,:)' + 1.96 * sqrt(squeeze(P_fp(2,2,:)))];
conf_vel_smooth = [x_bp(2,:)' - 1.96 * sqrt(squeeze(P_bp(2,2,:))), x_bp(2,:)' + 1.96 * sqrt(squeeze(P_bp(2,2,:)))];
 
% calculate the 95% confidence intervals for the position
conf_pos_filt = [x_fp(1,:)' - 1.96 * sqrt(squeeze(P_fp(1,1,:))), x_fp(1,:)' + 1.96 * sqrt(squeeze(P_fp(1,1,:)))];
conf_pos_smooth = [x_bp(1,:)' - 1.96 * sqrt(squeeze(P_bp(1,1,:))), x_bp(1,:)' + 1.96 * sqrt(squeeze(P_bp(1,1,:)))];
 
%% Plot the results
% visualize the results
figure("Position", [100, 400, 1200, 600]);
subplot(3,1,1); % position
yyaxis left;
plot(traj.getTrajectory.t, traj.getTrajectory.pos(:,1), 'DisplayName', 'True position');
hold on;
plot(traj.getTrajectory.t, x_fp(1,:), 'DisplayName', 'Estimated position (filtered)');
plot(traj.getTrajectory.t, x_bp(1,:), 'DisplayName', 'Estimated position (smoothed)');
fill([traj.getTrajectory.t; flipud(traj.getTrajectory.t)], [conf_pos_filt(:,1); flipud(conf_pos_filt(:,2))], 'r', 'EdgeColor', 'none', 'FaceAlpha', 0.3, 'DisplayName', '95% confidence interval (filtered)');
fill([traj.getTrajectory.t; flipud(traj.getTrajectory.t)], [conf_pos_smooth(:,1); flipud(conf_pos_smooth(:,2))], 'b', 'EdgeColor', 'none', 'FaceAlpha', 0.3, 'DisplayName', '95% confidence interval (smoothed)');
hold off;
xlabel('t [s]');
ylabel('p [m]');
legend("Location","bestoutside");
grid on;
yyaxis right;
plot(traj.getTrajectory.t, traj.getTrajectory.pos(:,1) - x_fp(1,:)', 'DisplayName', 'Error after filtering');
hold on;
plot(traj.getTrajectory.t, traj.getTrajectory.pos(:,1) - x_bp(1,:)', 'DisplayName', 'Error after smoothing');
 
ylabel('\Delta p [m]');
 
subplot(3,1,2); % velocity
yyaxis left;
plot(traj.getTrajectory.t, traj.getTrajectory.vel(:,1), 'DisplayName', 'True velocity');
hold on;
plot(traj.getTrajectory.t, x_fp(2,:), 'DisplayName', 'Estimated velocity (filtered)');
plot(traj.getTrajectory.t, x_bp(2,:), 'DisplayName', 'Estimated velocity (smoothed)');
fill([traj.getTrajectory.t; flipud(traj.getTrajectory.t)], [conf_vel_filt(:,1); flipud(conf_vel_filt(:,2))], 'r', 'EdgeColor', 'none', 'FaceAlpha', 0.3, 'DisplayName', '95% confidence interval (filtered)');
fill([traj.getTrajectory.t; flipud(traj.getTrajectory.t)], [conf_vel_smooth(:,1); flipud(conf_vel_smooth(:,2))], 'b', 'EdgeColor', 'none', 'FaceAlpha', 0.3, 'DisplayName', '95% confidence interval (smoothed)');
hold off;
xlabel('t [s]');
ylabel('v [m/s]');
legend("Location","bestoutside");
grid on;
yyaxis right;
plot(traj.getTrajectory.t, traj.getTrajectory.vel(:,1) - x_fp(2,:)', 'DisplayName', 'Error after filtering');
hold on;
plot(traj.getTrajectory.t, traj.getTrajectory.vel(:,1) - x_bp(2,:)', 'DisplayName', 'Error after smoothing');
ylabel('\Delta v [m/s]');
 
subplot(3,1,3); % acceleration
yyaxis left;
plot(traj.getTrajectory.t, traj.getTrajectory.acc(:,1), 'DisplayName', 'True acceleration');
hold on;
plot(traj.getTrajectory.t, x_fp(3,:), 'DisplayName', 'Estimated acceleration (filtered)');
plot(traj.getTrajectory.t, x_bp(3,:), 'DisplayName', 'Estimated acceleration (smoothed)');
plot(traj.getTrajectory.t, accelReadings, 'DisplayName', 'Measured acceleration');
fill([traj.getTrajectory.t; flipud(traj.getTrajectory.t)], [conf_acc_filt(:,1); flipud(conf_acc_filt(:,2))], 'r', 'EdgeColor', 'none', 'FaceAlpha', 0.3, 'DisplayName', '95% confidence interval (filtered)');
fill([traj.getTrajectory.t; flipud(traj.getTrajectory.t)], [conf_acc_smooth(:,1); flipud(conf_acc_smooth(:,2))], 'b', 'EdgeColor', 'none', 'FaceAlpha', 0.3, 'DisplayName', '95% confidence interval (smoothed)');
hold off;
xlabel('t [s]');
ylabel('a [m/s^2]');
legend("Location","bestoutside");
grid on;
yyaxis right;
plot(traj.getTrajectory.t, traj.getTrajectory.acc(:,1) - x_fp(3,:)', 'DisplayName', 'Error after filtering');
hold on;
plot(traj.getTrajectory.t, traj.getTrajectory.acc(:,1) - x_bp(3,:)', 'DisplayName', 'Error after smoothing');
ylabel('\Delta a [m/s^2]');
 
% common x axis
linkaxes(findall(gcf,'type','axes'),'x');