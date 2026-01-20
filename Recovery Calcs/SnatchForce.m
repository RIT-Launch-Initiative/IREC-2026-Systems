clear; clc;

% %Load open rocket using interface script example
run_sweep = true;
run_monte = true;
run_opt = true;

load("C://IREC-2026-Systems/Design Reporting/reportData2.mat");


%When using make sure this is your file path and has the correct open
%rocket

rocket_path = "C:\IREC-2026-Systems\Rocket Files\RISK.ork";
rocket=openrocket(rocket_path);


%Mass Tracking
[CG_launch, mass_with_motor, moi_launch] = rocket.massdata('LAUNCH'); %mass in kg
[CG, post_boost_mass, moi] = rocket.massdata('BURNOUT'); %mass of rocket in kg

%Parachute
chute = rocket.component(name = "Main");
chute_drag_Cd = chute.getCD;
chute_drag_area = chute.getArea(); % Drag area for parachute in m^2

%drogue
drogue = rocket.component(name = "Drogue");
drogue_drag_area = drogue.getArea(); %meter squared
drogue_drag_Cd = drogue.getCD();


%Simulation

sim = rocket.sims(1); % get simulation by number
sim.getOptions().setWindTurbulenceIntensity(0);
openrocket.simulate(sim); % execute simulation
data = openrocket.get_data(sim); % get all of the simulation's outputs
drogue_deploy_velocity = data{eventfilter("APOGEE"), "Total velocity"}; % Initial velocity at deployment in m/s taken from open rocket total velocity



%Drogue Sim Outputs
drogue_tempature = data{eventfilter("DROGUE"), "Air temperature"}; %In Kelvin
drogue_pressure = data{eventfilter("DROGUE"), "Air pressure"}; %In Pascal
R= 287.05; %J/(kg*K)
drogue_deployment_alitutde_air_density=drogue_pressure/(drogue_tempature*R);%Air density in kg/m^3
drogue_range = timerange(eventfilter("LAUNCHROD"), eventfilter("DROGUE"), "openleft");
data_drogue = data(drogue_range, :);
drogue_range_2=timerange(eventfilter('DROGUE'),eventfilter("MAIN"),'openleft');
data_drogue_2=data(drogue_range_2,:);
drogue_descent_rate = data_drogue_2.("Total velocity")(end);

% Main Air Sim Output
main_range = timerange(eventfilter("LAUNCHROD"), eventfilter("MAIN"), "openleft");
data_main = data(main_range, :);
main_pressure = data_main.("Air pressure")(end); %In Pascal
main_tempature = data_main.("Air temperature")(end); %In Kelvin
chute_deployment_alitutde_air_density = main_pressure/(main_tempature*R); %Air density in kg/m^3
main_range_2=timerange(eventfilter('MAIN'),eventfilter("GROUND_HIT"),'openleft');
data_main_2=data(main_range_2,:);
main_descent_rate=data_main_2.("Total velocity")(180);

% Environmental parameters
g = 9.81; % Acceleration due to gravity in m/s^2

%Ground Hit Velocity
ground_range = timerange(eventfilter("LAUNCHROD"), eventfilter("GROUND_HIT"), "openleft");
data_ground = data(ground_range, :);
ground_hit_velocity=data_ground.("Total velocity")(end); %ground hit velocity in m/s

% maximum drag force when fully deployed
drogue_max_drag_force = 0.5 * drogue_deployment_alitutde_air_density * drogue_deploy_velocity^2 * drogue_drag_Cd * drogue_drag_area;


% Display results for drogue
fprintf('Snatch Force Calculation for drogue chute\n');
fprintf('-------------------------------------------------\n');
fprintf('Mass of rocket at burnout: %.2f kg\n', post_boost_mass);
fprintf('Drogue device area: %.2f m^2\n', drogue_drag_area);
fprintf('Drogue coefficient (Cd): %.2f\n', drogue_drag_Cd);
fprintf('Drogue altitude air density: %.3f kg/m^3\n', drogue_deployment_alitutde_air_density);
fprintf('Maximum drogue snatch force: %.2f N\n', drogue_max_drag_force);
fprintf('Drogue descent rate: %.2f m/s\n\n', drogue_descent_rate);

% maximum drag force when fully deployed
main_max_drag_force = 0.5 * chute_deployment_alitutde_air_density * drogue_descent_rate^2 * chute_drag_Cd * chute_drag_area;

% decent rate at drogue


% Display results for drogue
fprintf('Snatch Force Calculation for main chute\n');
fprintf('-------------------------------------------------\n');
fprintf('Mass of rocket at burnout: %.2f kg\n', post_boost_mass);
fprintf('Chute area: %.2f m^2\n', chute_drag_area);
fprintf('Chute coefficient (Cd): %.2f\n', chute_drag_Cd);
fprintf('Chute altitude air density: %.3f kg/m^3\n', chute_deployment_alitutde_air_density);
fprintf('Maximum main snatch force: %.2f N\n', main_max_drag_force);
fprintf('Main descent rate: %.2f m/s\n\n\n', main_descent_rate);

%Display Ground Hit
fprintf('Ground hit velocity: %.2f m/s \n',ground_hit_velocity)

%% Generate report
dTime = seconds(data_drogue_2.Time(end)) - seconds(data_drogue_2.Time(1));
mTime = seconds(data_main_2.Time(end)) - seconds(data_main_2.Time(1));
reportData2.snatch = max(main_max_drag_force, drogue_max_drag_force);
reportData2.drogueRate = drogue_descent_rate;
reportData2.drogueTime = dTime;
reportData2.mainRate = main_descent_rate;
reportData2.groundHit = ground_hit_velocity;
reportData2.mainTime = mTime;

save("C://IREC-2026-Systems/Design Reporting/reportData2.mat", "reportData2")
updateReport;