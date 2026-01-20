
clear
clc
%When usingg make sure this is your file path and has the correct open
%rocket
% %Load open rocket using interface script example
run_sweep = true;
run_monte = true;
run_opt = true;
rocket_path = "C:\IREC-2026-Systems\Rocket Files\RISK.ork";
rocket=openrocket(rocket_path);

load("C://IREC-2026-Systems/Design Reporting/reportData3.mat");

%Main Deployment Input Values
forward_reco_tube=rocket.component(name = "Forward Reco Tube");
forward_ir=forward_reco_tube.getInnerRadius(); %meters
bulkhead1=rocket.component(name="Nose Cone Bulkhead");
bulkhead1_coord=bulkhead1.getPosition();
bulkhead1_loc=bulkhead1_coord.x; %meters

bulkhead2=rocket.component(name="Upper Avi Bulkhead");
[bulkhead2_loc]=lengthfinder(bulkhead2);
forward_length = abs(bulkhead2_loc - bulkhead1_loc);


%Drogue Deployment Input Values
aft_reco_tube=rocket.component(name = "Aft Reco Tube"); 
aft_ir=aft_reco_tube.getInnerRadius(); %meters
bulkhead3=rocket.component(name="Lower Avi Bulkhead");
[bulkhead3_loc]=lengthfinder(bulkhead3);
bulkhead4=rocket.component(name="Aft Reco Bulkhead");
[bulkhead4_loc]=lengthfinder(bulkhead4);
aft_length= abs(bulkhead4_loc - bulkhead3_loc);%meters

%Constants
primary_charge=10; %psi
secondary_charge=15; %psi
b=265.92; %Constant (in-lbf/lbm)
combustion_temp=3307; %Combustion temp of FFFg (R)
c=1/453.593; %conversion ratio (lbs/g)

%Convert values to in
forward_length_E=39.3701*forward_length;
forward_ir_E=39.3701*forward_ir;
aft_length_E=39.3701*aft_length;
aft_ir_E=39.3701*aft_ir;

%Intermediate Calculations
v_dp=pi*(aft_ir_E^2)*aft_length_E; %Volume in in^3
v_mp=pi*(forward_ir_E^2)*forward_length_E; %Volume in in^3
z=1/(b*combustion_temp*c);
f_m=primary_charge*pi*(forward_ir_E^2);
f_d=primary_charge*pi*(aft_ir_E^2);

%Charge Calculations

%Drogue
drogue_grams_bp_primary=primary_charge*z*v_dp;
drogue_grams_bp_secondary=secondary_charge*z*v_dp;
drogue_1 = drogue_grams_bp_primary * 15.432;
drogue_grain_primary = ceil(drogue_1 / 10) * 10;
drogue_2 = drogue_grams_bp_secondary * 15.432;
drogue_grain_secondary = ceil(drogue_2 / 10) * 10;


%Main
main_grams_bp_primary=primary_charge*z*v_mp;
main_grams_bp_secondary=secondary_charge*z*v_mp;
main_1 = main_grams_bp_primary * 15.432;
main_grain_primary = ceil(main_1 / 10) * 10;
main_2 = main_grams_bp_secondary * 15.432;
main_grain_secondary = ceil(main_2 / 10) * 10;

fprintf('Main Deployment Primary: Grams of black powder: %.2f\n',main_grams_bp_primary)
fprintf('Main Deployment Primary: Grains of black powder: %.0f\n\n',main_grain_primary)
fprintf('Main Deployment Secondary: Grams of black powder: %.2f\n',main_grams_bp_secondary)
fprintf('Main Deployment Secondary: Grains of black powder: %.0f\n\n\n',main_grain_secondary)

fprintf('Drogue Deployment Primary: Grams of black powder: %.2f\n',drogue_grams_bp_primary)
fprintf('Drogue Deployment Primary: Grains of black powder: %.0f\n\n',drogue_grain_primary)
fprintf('Drogue Deployment Secondary: Grams of black powder: %.2f\n',drogue_grams_bp_secondary)
fprintf('Drogue Deployment Secondary: Grains of black powder: %.0f\n\n\n',drogue_grain_secondary)

%Shear Pins Calculations

%Shear Pin Data
M2_min=27; %lb
M2_max=39; %lb

two_fiftysix_min=31; %lb
two_fiftysix_max=46; %lb

four_forty_min=50; %lb
four_forty_max=76; %lb

M3_min=67; %lb
M3_max=91; %lb

six_thirtytwo_min = 75; %lb
six_thirtytwo_max=114; %lb

%required pins for drogue
m2_pin_d=floor(f_d/M2_min);
two_fiftysix_pin_d=floor(f_d/two_fiftysix_min);
four_forty_pin_d=floor(f_d/four_forty_min);
m3_pin_d=floor(f_d/M3_min);
six_thirtytwo_pin_d=floor(f_d/six_thirtytwo_min);

%required pins for main
m2_pin_m=floor(f_m/M2_min);
two_fiftysix_pin_m=floor(f_m/two_fiftysix_min);
four_forty_pin_m=floor(f_m/four_forty_min);
m3_pin_m=floor(f_m/M3_min);
six_thirtytwo_pin_m=floor(f_m/six_thirtytwo_min);

fprintf("M2 pins required for main: %.0f \n", m2_pin_m)
fprintf("M2 pins required for drogue: %.0f \n\n", m2_pin_d)
fprintf("2-56 pins required for main: %.0f \n", two_fiftysix_pin_m)
fprintf("2-56 pins required for drogue: %.0f \n\n", two_fiftysix_pin_d)
fprintf("4-40 pins required for main: %.0f \n", four_forty_pin_m)
fprintf("4-40 pins required for drogue: %.0f \n\n", four_forty_pin_d)
fprintf("M3 pins required for main: %.0f \n", m3_pin_m)
fprintf("M3 pins required for drogue: %.0f \n\n", m3_pin_d)
fprintf("6-32 pins required for main: %.0f \n", six_thirtytwo_pin_m)
fprintf("6-32 pins required for drogue: %.0f \n\n", six_thirtytwo_pin_d)

%% Generate report
reportData3.mainCharges = [main_grams_bp_primary, main_grams_bp_secondary];
reportData3.mainPins = four_forty_pin_m;

reportData3.drogueCharges = [drogue_grams_bp_primary, drogue_grams_bp_secondary];
reportData3.droguePins = four_forty_pin_d;

save("C://IREC-2026-Systems/Design Reporting/reportData3.mat", "reportData3")
updateReport;

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