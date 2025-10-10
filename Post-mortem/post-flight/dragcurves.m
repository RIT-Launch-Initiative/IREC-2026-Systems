clear;
ft_per_m = 1/0.3048;

ork_file = pfullfile("data", "omen.ork");
data_path = pfullfile("data", "OMEN_RA_Aerodata.CSV");

doc = openrocket(ork_file);
sim = doc.sims(1);
machs = linspace(0, 1.5, 20);
ork_drag_table = ork2dragtable(doc, machs);

rasaerodata = import_rasaero_aerodata(data_path);
axial = rasaerodata.pick(aoa = 0, field = "CD");
ras_drag_table = table(axial.mach, double(axial), VariableNames = ["MACH", "DRAG"]);
ras_drag_table.MACH(1) = 0; % starts at 0.1 and not 0, causing NaNs in the simulation

figure(name = "Drag curves");
hold on; grid on;
plot(ork_drag_table.MACH, ork_drag_table.DRAG, DisplayName = "OpenRocket");
plot(ras_drag_table.MACH, ras_drag_table.DRAG, DisplayName = "RasAero");

legend;
xlabel("Mach number");
ylabel("Drag coefficient");
xlim([0 1.5]);
ylim([0 1]);

data_ork = doc.simulate(sim, outputs = "Altitude", stop = "APOGEE");
fprintf("OpenRocket: %.1f m (%.0f ft)\n", ...
    max(data_ork.Altitude), max(data_ork.Altitude) * ft_per_m);
data_ras = doc.simulate(sim, outputs = "Altitude", stop = "APOGEE", drag = ras_drag_table);
fprintf("RA2: %.1f m (%.0f ft)\n", ...
    max(data_ras.Altitude), max(data_ras.Altitude) * ft_per_m);
