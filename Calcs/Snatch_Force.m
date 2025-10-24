
clear; clc;

% %Load open rocket using interface script example
run_sweep = true;
run_monte = true;
run_opt = true;




%When usingg make sure this is your file path and has the correct open
%rocket

rocket_path = "C:\IREC-2026-Systems\Rocket Files\IREC-2026-N3800.ork";
rocket=openrocket(rocket_path);


%Mass Tracking
[CG_launch, mass_with_motor, moi_launch] = rocket.massdata('LAUNCH'); %mass in kg
[CG, post_boost_mass, moi] = rocket.massdata('BURNOUT'); %mass of rocket in kg

%Parachute
chute = rocket.component(name = "Main");
chute_drag_Cd = chute.getCD;
chute_diameter = chute.getDiameter(); %meter
chute_drag_area = pi * (chute_diameter / 2)^2; % Drag area for parachute in m^2

%drogue
drogue = rocket.component(name = "Drogue");
drogue_diameter = drogue.getArea(); %meter squared
drogue_drag_area = pi * (drogue_diameter / 2)^2; % Drag area for parachute in m^2
drogue_drag_Cd = drogue.getCD();


%Simulation
sim = rocket.sims(1); % get simulation by number
openrocket.simulate(sim); % execute simulation
data = openrocket.get_data(sim); % get all of the simulation's outputs
drogue_deploy_velocity_open_rocket = data{eventfilter("APOGEE"), "Total velocity"}; % Initial velocity at deployment in m/s taken from open rocket total velocity

%Drogue Sim Outputs
drogue_tempature = data{eventfilter("APOGEE"), "Air temperature"}; %In Kelvin
drogue_pressure = data{eventfilter("APOGEE"), "Air pressure"}; %In Pascal
R= 287.05; %J/(kg*K)
drogue_deployment_alitutde_air_density=drogue_pressure/(drogue_tempature*R);%Air density in kg/m^3
drogue_range = timerange(eventfilter("LAUNCHROD"), eventfilter("DROGUE"), "openleft");
data_drogue = data(drogue_range, :);
drogue_descent_rate = data_drogue.("Total velocity")(end);

% Main Air Sim Output
main_range = timerange(eventfilter("LAUNCHROD"), eventfilter("MAIN"), "openleft");
data_main = data(main_range, :);
main_pressure = data_main.("Air pressure")(end); %In Pascal
main_tempature = data_main.("Air temperature")(end); %In Kelvin
chute_deployment_alitutde_air_density = main_pressure/(main_tempature*R); %Air density in kg/m^3
main_descent_rate = data_main.("Total velocity")(end);

% Environmental parameters
g = 9.81; % Acceleration due to gravity in m/s^2

%Ground Hit Velocity
ground_range = timerange(eventfilter("LAUNCHROD"), eventfilter("GROUND_HIT"), "openleft");
data_ground = data(ground_range, :);
ground_hit_velocity=data_ground.("Total velocity")(end); %ground hit velocity in m/s

% maximum drag force when fully deployed
drogue_max_drag_force = 0.5 * drogue_deployment_alitutde_air_density * drogue_deploy_velocity_open_rocket^2 * drogue_drag_Cd * drogue_drag_area;


% Display results for drogue
fprintf('Snatch Force Calculation for drogue drogue\n');
fprintf('-------------------------------------------------\n');
fprintf('Mass of rocket at burnout: %.2f kg\n', post_boost_mass);
fprintf('drogue device area: %.2f m^2\n', drogue_drag_area);
fprintf('drogue coefficient (Cd): %.2f\n', drogue_drag_Cd);
fprintf('drogue altitude air density: %.3f kg/m^3\n', drogue_deployment_alitutde_air_density);
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
fprintf('Maximum main snatch force: %.2f kN\n', main_max_drag_force*10^-3);
fprintf('Main descent rate: %.2f m/s\n\n\n', main_descent_rate);

%Display Ground Hit
fprintf('Ground hit velocity: %.2f m/s \n',ground_hit_velocity)