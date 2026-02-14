% %Load open rocket using interface script example
clear 
clc

run_sweep = true;
run_monte = true;
run_opt = true;

%When usingg make sure this is your file path and has the correct open
%rocket
rocket_path = "Rocket Files\RISK.ork";
rocket=openrocket(rocket_path);
Lh_main_e=60; %ft, recovery harness length
Lh_drogue_e=50; %ft, recovery harness length
Lh_main=Lh_main_e*0.3048; %m, recovery harness length
Lh_drogue=Lh_drogue_e*0.3048; %m, recovery harness length
ea_e=1045;  %lb, Found by Elasticity constant * Area
ea=ea_e*4.44822; %Newtons
k_d=ea/Lh_drogue; %k constant
k_m=ea/Lh_main; %k constant

%Area and volume Calculation for main
reco_tube = rocket.component(name = "Forward Reco Tube");
reco_tube_inner_radius = reco_tube.getInnerRadius();
forward_reco_tube=rocket.component(name = "Forward Reco Tube");
forward_ir=forward_reco_tube.getInnerRadius(); %meters
bulkhead1=rocket.component(name="Retaining Bulkhead");
[bulkhead1_loc]=lengthfinder(bulkhead1);
bulkhead2=rocket.component(name="Upper Avi Bulkhead");
[bulkhead2_loc]=lengthfinder(bulkhead2);
forward_length = abs(bulkhead2_loc - bulkhead1_loc);
At_main=pi()*(reco_tube_inner_radius^2);
Vc_main=At_main*forward_length;

%Coupler Main
nose_cone_coupler=rocket.component(name="Nosecone Tube Coupler");
nc_coupler_length=nose_cone_coupler.getLength();
nc_Lc=nc_coupler_length/2;

%Coupler Drogue
airbrake_coupler=rocket.component(name="10 in Coupler");
a_coupler_lg=airbrake_coupler.getLength();
a_Lc=a_coupler_lg/2;

%Area and volume Calculation for drogue
reco_tube_d = rocket.component(name = "Aft Reco Tube");
d_reco_tube_inner_radius = reco_tube_d.getInnerRadius();
aft_reco_tube=rocket.component(name = "Aft Reco Tube"); 
aft_ir=aft_reco_tube.getInnerRadius(); %meters
bulkhead3=rocket.component(name="Lower Avi Bulkhead");
[bulkhead3_loc]=lengthfinder(bulkhead3);
bulkhead4=rocket.component(name="Aft Reco Bulkhead");
[bulkhead4_loc]=lengthfinder(bulkhead4);
aft_length= abs(bulkhead4_loc - bulkhead3_loc);%meters
At_drogue=pi()*(d_reco_tube_inner_radius^2);
Vc_drogue=At_drogue*aft_length;

[CG, mass, moi] = rocket.massdata('BURNOUT');

gamma=1.4;

%pressure
simu = rocket.sims(1); % get simulation by number
simu.getOptions().setWindTurbulenceIntensity(0);
openrocket.simulate(simu); % execute simulation
data = openrocket.get_data(simu); % get all of the simulation's outputs
drogue_pressure = data{eventfilter("DROGUE"), "Air pressure"}; %In Pascal
main_range = timerange(eventfilter("LAUNCHROD"), eventfilter("MAIN"), "openleft");
data_main = data(main_range, :);
main_pressure = data_main.("Air pressure")(end); %In Pascal

%run simulink
drogue = sim('SeparationForce_Drogue');
AF_drogue_data=drogue.AF_drogue;
RV_drogue_data=drogue.RV_drogue;
SF_drogue_data=drogue.SF_drogue;
drogue = sim('SeparationForce_Main');
AF_main_data=drogue.AF_main;
RV_main_data=drogue.RV_main;
SF_main_data=drogue.SF_main;

%Arresting Force Plots
AF_data_m=AF_main_data.Data;
AF_time_m=AF_main_data.Time;
figure (1)
plot(AF_time_m,AF_data_m,'m')
title("Arresting Force")
xlabel("Time (s)")
ylabel("Arresting Force (N)")
hold on
AF_data_d=AF_drogue_data.Data;
AF_time_d=AF_drogue_data.Time;
plot(AF_time_d,AF_data_d,'b')
legend on
legend("Main", "Drogue")
hold off

%Relative Velocity Plots
RV_data_m=RV_main_data.Data;
RV_time_m=RV_main_data.Time;
figure (2)
plot(RV_time_m,RV_data_m,'m')
title("Relative Velocity")
xlabel("Time (s)")
ylabel("Velocity (m/s)")
hold on
RV_data_d=RV_drogue_data.Data;
RV_time_d=RV_drogue_data.Time;
plot(RV_time_d,RV_data_d,'b')
legend on
legend("Main", "Drogue")
hold off

%Separation Force Plots
SF_data_m=SF_main_data.Data;
SF_time_m=SF_main_data.Time;
figure (3)
plot(SF_time_m,SF_data_m,'m')
title("Separation Force")
xlabel("Time (s)")
ylabel("Separation Force (N)")
hold on
SF_data_d=SF_drogue_data.Data;
SF_time_d=SF_drogue_data.Time;
plot(SF_time_d,SF_data_d,'b')
legend on
legend("Main", "Drogue")
hold off



function [length]=lengthfinder(name)

length=0;
x=1;
while x~=0
    x_coord=name.getPosition();
    x=x_coord.x;
    length=x+length;
    name=name.getParent();
end
end