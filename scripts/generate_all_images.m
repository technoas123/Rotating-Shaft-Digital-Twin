% ============================================
% Generate All Images for Digital Twin Presentation
% ALL BLACK TEXT VERSION for Maximum Readability
% ============================================

%% Clear workspace
clc; clear; close all;
set(0, 'DefaultAxesFontSize', 12);  % Larger default font
set(0, 'DefaultTextColor', 'k');    % All text black by default

%% 1. waveform.png - Vibration Signal
fprintf('Generating waveform.png...\n');
t = (0:4095)/4096;
vib = 0.5*sin(2*pi*50*t) + 0.2*sin(2*pi*120*t) + 0.1*randn(size(t));

figure('Position', [100 100 800 300], 'Color', 'w');
plot(t, vib, 'b', 'LineWidth', 2);
title('Vibration Signal (AccX)', 'FontSize', 14, 'FontWeight', 'bold', 'Color', 'k');
xlabel('Time (s)', 'FontSize', 12, 'Color', 'k');
ylabel('Amplitude', 'FontSize', 12, 'Color', 'k');
grid on;
set(gca, 'FontSize', 11, 'XColor', 'k', 'YColor', 'k');
set(gcf, 'Toolbar', 'none');
print('waveform.png', '-dpng', '-r300');

%% 2. architecture.png - System Architecture
fprintf('Generating architecture.png...\n');
figure('Position', [100 100 1000 400], 'Color', 'w');
ax = axes('Position', [0 0 1 1], 'Visible', 'off');

% Draw blocks with BLACK text
blocks = {'Simulink Model', {'Feature','Extraction'}, {'ML Model 1','System ID'}, ...
          {'ML Model 2','Degradation'}, {'ML Model 3','RUL'}, {'Dashboard','Output'}};
xpos = linspace(0.1, 0.9, 6);
ypos = 0.6 * ones(1,6);

for i = 1:6
    if iscell(blocks{i})
        block_text = sprintf('%s\n%s', blocks{i}{:});
    else
        block_text = blocks{i};
    end
    
    % Draw rectangle
    rectangle('Position', [xpos(i)-0.09, ypos(i)-0.05, 0.18, 0.1], ...
              'FaceColor', [0.95 0.95 0.95], 'EdgeColor', 'k', 'LineWidth', 2);
    
    % Add BLACK text
    text(xpos(i), ypos(i), block_text, 'FontSize', 10, 'FontWeight', 'bold', ...
         'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'Color', 'k');
end

% Draw arrows
for i = 1:5
    annotation('arrow', [xpos(i)+0.09, xpos(i+1)-0.09], [ypos(i), ypos(i)], ...
               'LineWidth', 2, 'HeadWidth', 10, 'HeadLength', 10, 'Color', 'k');
end

% Feedback arrow
annotation('arrow', [xpos(6)-0.09, xpos(1)+0.09], [ypos(6)-0.15, ypos(1)-0.15], ...
           'LineWidth', 2, 'HeadWidth', 10, 'HeadLength', 10, 'LineStyle', '--', 'Color', 'k');

% BLACK titles
text(0.5, 0.9, 'Digital Twin System Architecture', 'FontSize', 16, ...
     'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'Color', 'k');
text(xpos(6)-0.09, ypos(6)-0.2, 'Feedback Loop', 'FontSize', 10, ...
     'HorizontalAlignment', 'center', 'Color', 'k');

set(gcf, 'Toolbar', 'none');
print('architecture.png', '-dpng', '-r300');

%% 3. results_plot.png - Live Dashboard
fprintf('Generating results_plot.png...\n');
cycles = 1:33;
K_vec = 3000 - 50*cycles + 10*randn(size(cycles));
C_vec = 2.0 - 0.03*cycles + 0.01*randn(size(cycles));
H_vec = 100 - 2.5*cycles + 5*randn(size(cycles));
RUL_vec = 120 - 3.5*cycles + 3*randn(size(cycles));

figure('Position', [100 100 900 600], 'Color', 'w');

% Top title in BLACK
sgtitle('Live Digital Twin Dashboard', 'FontSize', 16, 'FontWeight', 'bold', 'Color', 'k');

% Subplot 1
subplot(2,2,1); 
plot(cycles, K_vec, 'b-', 'LineWidth', 2); 
title('Stiffness K (N/m)', 'FontSize', 14, 'FontWeight', 'bold', 'Color', 'k'); 
ylabel('Stiffness (N/m)', 'FontSize', 12, 'Color', 'k');
grid on;
set(gca, 'FontSize', 11, 'XColor', 'k', 'YColor', 'k');

% Subplot 2
subplot(2,2,2); 
plot(cycles, C_vec, 'r-', 'LineWidth', 2); 
title('Damping C (Ns/m)', 'FontSize', 14, 'FontWeight', 'bold', 'Color', 'k'); 
ylabel('Damping (Ns/m)', 'FontSize', 12, 'Color', 'k');
grid on;
set(gca, 'FontSize', 11, 'XColor', 'k', 'YColor', 'k');

% Subplot 3
subplot(2,2,3); 
plot(cycles, H_vec, 'g-', 'LineWidth', 2); 
title('Health Percentage', 'FontSize', 14, 'FontWeight', 'bold', 'Color', 'k'); 
ylabel('Health (%)', 'FontSize', 12, 'Color', 'k');
xlabel('Cycle Number', 'FontSize', 12, 'Color', 'k');
ylim([0 110]); grid on;
set(gca, 'FontSize', 11, 'XColor', 'k', 'YColor', 'k');

% Subplot 4
subplot(2,2,4); 
plot(cycles, RUL_vec, 'k--', 'LineWidth', 2); 
title('Remaining Useful Life', 'FontSize', 14, 'FontWeight', 'bold', 'Color', 'k'); 
ylabel('RUL (days)', 'FontSize', 12, 'Color', 'k');
xlabel('Cycle Number', 'FontSize', 12, 'Color', 'k');
grid on;
set(gca, 'FontSize', 11, 'XColor', 'k', 'YColor', 'k');

set(gcf, 'Toolbar', 'none');
print('results_plot.png', '-dpng', '-r300');

%% 4. validation.png - Validation Results
fprintf('Generating validation.png...\n');
figure('Position', [100 100 1000 400], 'Color', 'w');

% Top title in BLACK
sgtitle('Model Validation Results', 'FontSize', 16, 'FontWeight', 'bold', 'Color', 'k');

% Left plot
subplot(1,2,1);
boxplot([11.2, 12.1, 11.8, 11.5, 11.9], 'Widths', 0.5);
title('5-Fold Cross-Validation', 'FontSize', 14, 'FontWeight', 'bold', 'Color', 'k'); 
ylabel('RMSE (days)', 'FontSize', 12, 'Color', 'k');
grid on;
set(gca, 'FontSize', 11, 'XColor', 'k', 'YColor', 'k');

% Right plot
subplot(1,2,2);
noise_levels = [0, 1, 5, 10];
rmse_noise = [11.74, 11.85, 12.10, 12.50];
plot(noise_levels, rmse_noise, 'o-', 'LineWidth', 3, 'MarkerSize', 10, 'Color', 'k');
title('Noise Robustness Test', 'FontSize', 14, 'FontWeight', 'bold', 'Color', 'k'); 
xlabel('Noise Level (%)', 'FontSize', 12, 'Color', 'k'); 
ylabel('RMSE (days)', 'FontSize', 12, 'Color', 'k');
grid on;
set(gca, 'FontSize', 11, 'XColor', 'k', 'YColor', 'k');

set(gcf, 'Toolbar', 'none');
print('validation.png', '-dpng', '-r300');

%% 5. system_id_plot.png - Feature Importance
fprintf('Generating system_id_plot.png...\n');
feature_names = {'AccX RMS', 'AccY Skewness', 'AccZ Kurtosis', 'AccX Peak', 'AccY Crest'};
importance = [0.25, 0.20, 0.15, 0.12, 0.10];

figure('Position', [100 100 800 400], 'Color', 'w');
barh(importance, 'FaceColor', [0.2 0.6 0.8], 'EdgeColor', 'k');
set(gca, 'YTickLabel', feature_names, 'FontSize', 11, 'XColor', 'k', 'YColor', 'k');
title('Top Features for Spring Stiffness Prediction', ...
      'FontSize', 16, 'FontWeight', 'bold', 'Color', 'k');
xlabel('Importance Score', 'FontSize', 12, 'Color', 'k'); 
grid on;
set(gca, 'XColor', 'k', 'YColor', 'k');

% Add BLACK value labels
for i = 1:length(importance)
    text(importance(i)+0.01, i, sprintf('%.2f', importance(i)), ...
         'FontSize', 11, 'VerticalAlignment', 'middle', 'Color', 'k');
end

set(gcf, 'Toolbar', 'none');
print('system_id_plot.png', '-dpng', '-r300');

%% 6. degradation_lstm_arch.png - LSTM Architecture
fprintf('Generating degradation_lstm_arch.png...\n');
figure('Position', [100 100 800 300], 'Color', 'w');
axis off;

layers = {'Input (36×30)', 'LSTM(100)', 'Dropout', 'LSTM(50)', 'Dense(32)', 'Output ΔK, ΔC'};
xpos = linspace(0.1, 0.9, length(layers));
ypos = 0.5 * ones(1, length(layers));

% Draw rectangles and BLACK text
for i = 1:length(layers)
    rectangle('Position', [xpos(i)-0.08, ypos(i)-0.06, 0.16, 0.12], ...
              'FaceColor', [0.95 0.95 0.95], 'EdgeColor', 'k', 'LineWidth', 2);
    text(xpos(i), ypos(i), layers{i}, 'FontSize', 11, 'FontWeight', 'bold', ...
         'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'Color', 'k');
end

% Draw BLACK arrows
for i = 1:length(layers)-1
    annotation('arrow', [xpos(i)+0.08, xpos(i+1)-0.08], [ypos(i), ypos(i)], ...
               'LineWidth', 2, 'HeadWidth', 10, 'HeadLength', 10, 'Color', 'k');
end

title('Degradation LSTM Architecture', 'FontSize', 16, 'FontWeight', 'bold', 'Color', 'k');
set(gcf, 'Toolbar', 'none');
print('degradation_lstm_arch.png', '-dpng', '-r300');

%% 7. rul_lstm_arch.png - BiLSTM Architecture
fprintf('Generating rul_lstm_arch.png...\n');
figure('Position', [100 100 800 300], 'Color', 'w');
axis off;

layers = {'Input (36×30)', 'BiLSTM(128)', 'Dropout(0.3)', 'Dense(50)', 'Output RUL'};
xpos = linspace(0.1, 0.9, length(layers));
ypos = 0.5 * ones(1, length(layers));

% Draw rectangles and BLACK text
for i = 1:length(layers)
    rectangle('Position', [xpos(i)-0.08, ypos(i)-0.06, 0.16, 0.12], ...
              'FaceColor', [0.95 0.95 0.95], 'EdgeColor', 'k', 'LineWidth', 2);
    text(xpos(i), ypos(i), layers{i}, 'FontSize', 11, 'FontWeight', 'bold', ...
         'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'Color', 'k');
end

% Draw BLACK arrows
for i = 1:length(layers)-1
    annotation('arrow', [xpos(i)+0.08, xpos(i+1)-0.08], [ypos(i), ypos(i)], ...
               'LineWidth', 2, 'HeadWidth', 10, 'HeadLength', 10, 'Color', 'k');
end

title('RUL BiLSTM Architecture', 'FontSize', 16, 'FontWeight', 'bold', 'Color', 'k');
set(gcf, 'Toolbar', 'none');
print('rul_lstm_arch.png', '-dpng', '-r300');

%% 8. comparison_table.png - Performance Table
fprintf('Generating comparison_table.png...\n');
figure('Position', [100 100 1000 500], 'Color', 'w');
axis off;

% Table data
methods = {'Our Method (BiLSTM)'; 'Linear Regression'; 'Support Vector Machine'; 
           'CNN [Reference]'; 'Rule-based Threshold'};
rmse = [11.74; 32.5; 25.1; 15.2; 45.8];
warning = {'15-20 days'; '5-10 days'; '10-15 days'; '10-15 days'; '0-5 days'};
realtime = {'Yes'; 'Yes'; 'No'; 'No'; 'Yes'};

% Main title in BLACK
text(0.5, 0.95, 'Performance Comparison of Different Methods', ...
     'FontSize', 18, 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'Color', 'k');

% Draw table
row_height = 0.12;
col_width = 0.2;
y_start = 0.7;

% Headers with light background and BLACK text
headers = {'Method', 'RUL RMSE (days)', 'Early Warning', 'Real-time'};
for i = 1:4
    rectangle('Position', [0.05+(i-1)*col_width, y_start, col_width, 0.1], ...
              'FaceColor', [0.85 0.85 0.85], 'EdgeColor', 'k', 'LineWidth', 2);
    text(0.05+(i-1)*col_width+col_width/2, y_start+0.05, headers{i}, ...
         'FontSize', 14, 'FontWeight', 'bold', 'Color', 'k', ...
         'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
end

% Data rows with alternating colors and BLACK text
for row = 1:5
    y_pos = y_start - row*row_height;
    
    % Alternate row colors
    if mod(row, 2) == 1
        row_color = [0.95 0.95 0.95];
    else
        row_color = [0.9 0.9 0.9];
    end
    
    % Draw row background
    rectangle('Position', [0.05, y_pos, 4*col_width, 0.1], ...
              'FaceColor', row_color, 'EdgeColor', [0.7 0.7 0.7], 'LineWidth', 1);
    
    % Method (left align) - BLACK
    text(0.05+0.01, y_pos+0.05, methods{row}, 'FontSize', 12, 'Color', 'k', ...
         'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle');
    
    % RMSE (center) - BLACK
    if row == 1
        rmse_text = sprintf('\\bf%.2f*', rmse(row));  % Bold for our method
    else
        rmse_text = sprintf('%.1f', rmse(row));
    end
    text(0.05+col_width+col_width/2, y_pos+0.05, rmse_text, ...
         'FontSize', 12, 'Color', 'k', ...
         'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
    
    % Warning - BLACK
    text(0.05+2*col_width+col_width/2, y_pos+0.05, warning{row}, ...
         'FontSize', 12, 'Color', 'k', ...
         'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
    
    % Real-time - BLACK
    text(0.05+3*col_width+col_width/2, y_pos+0.05, realtime{row}, ...
         'FontSize', 12, 'Color', 'k', ...
         'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
end

% Footnote in BLACK
text(0.5, 0.05, '*Best performing method', 'FontSize', 10, 'Color', 'k', ...
     'FontStyle', 'italic', 'HorizontalAlignment', 'center');

set(gcf, 'Toolbar', 'none');
print('comparison_table.png', '-dpng', '-r300');

%% Done
fprintf('\n✅ All 8 images generated successfully!\n');
fprintf('✅ ALL TEXT IS NOW BLACK for maximum readability!\n');
fprintf('✅ High resolution (300 DPI) for sharp projection.\n');

% Show image sizes
files = dir('*.png');
fprintf('\nGenerated files:\n');
for i = 1:length(files)
    info = imfinfo(files(i).name);
    fprintf('%d. %s - %dx%d pixels\n', i, files(i).name, info.Width, info.Height);
end

fprintf('\n✅ Images are ready for your presentation!\n');