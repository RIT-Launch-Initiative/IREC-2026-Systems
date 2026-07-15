info = table(dates, masses, avionicsmasses, payloadmasses, 'VariableNames', {'Date','Mass', 'AvionicsBayMass', 'PayloadMass'});
info = sortrows(info,'Date');

% Create a figure for separate subplots
figure;

% Plot Launch Mass
subplot(3, 1, 1);
plot(info.Date, info.Mass, '-o', 'LineWidth', 1.5);
xlabel('Date');
ylabel('Launch Mass (kg)');
title('Rocket Launch Mass Over Time');
axis padded
grid on;

% Plot Avionics Bay Mass
subplot(3, 1, 2);
plot(info.Date, info.AvionicsBayMass, '-x', 'LineWidth', 1.5);
xlabel('Date');
ylabel('Avionics Bay Mass (kg)');
title('Avionics Bay Mass Over Time');
axis padded
grid on;

% Plot Payload Mass
subplot(3, 1, 3);
plot(info.Date, info.PayloadMass, '-s', 'LineWidth', 1.5);
xlabel('Date');
ylabel('Payload Mass (kg)');
title('Payload Mass Over Time');
axis padded
grid on;


