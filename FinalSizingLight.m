% NG-CryoIRTel EPS Sizing Tool

clear; clc; close all;

set(groot, 'defaultFigureColor', 'w');
set(groot, 'defaultAxesColor', 'w');
set(groot, 'defaultAxesXColor', 'k');
set(groot, 'defaultAxesYColor', 'k');
set(groot, 'defaultTextColor', 'k');
set(groot, 'defaultAxesGridColor', 'k');
set(groot, 'defaultAxesFontSize', 11);
set(groot, 'defaultLineLineWidth', 1.5);
set(groot, 'defaultLegendBox', 'off');

% ------------------------------------------------------------------------
% LOAD PROFILE
% ------------------------------------------------------------------------

profile = [
    8, 1906;
    8, 1986;
    1, 1972;
    6, 1906;
    1, 2018
];

T_ref_h = 24;
dt = profile(:,1);
P_load = profile(:,2);

E_LOAD_Wh = sum(P_load .* dt);
E_LOAD_kWh = E_LOAD_Wh / 1000;
P_mean = E_LOAD_Wh / T_ref_h;
P_peak_avg = max(P_load);
P_peak_true = 2412;

fprintf('========== LOAD PROFILE ==========\n');
fprintf('E_LOAD = %.2f kWh (%.0f Wh)\n', E_LOAD_kWh, E_LOAD_Wh);
fprintf('P_mean = %.0f W\n', P_mean);
fprintf('P_peak_true = %.0f W\n\n', P_peak_true);

% ------------------------------------------------------------------------
% EFFICIENCIES
% ------------------------------------------------------------------------

eta_BCR = 0.94;
eta_BDR = 0.94;
eta_BATTc = 0.95;
eta_BATTd = 0.98;
margin_power = 1.20;

fprintf('========== EFFICIENCIES ==========\n');
fprintf('eta_BCR = %.2f, eta_BDR = %.2f\n', eta_BCR, eta_BDR);
fprintf('eta_BATTc = %.2f, eta_BATTd = %.2f\n', eta_BATTc, eta_BATTd);
fprintf('margin = %.0f%%\n\n', (margin_power-1)*100);

% ------------------------------------------------------------------------
% THERMAL ENVIRONMENT
% ------------------------------------------------------------------------

G_AM0 = 1361;
R_au_aphelion = 1.0167;
G_sun = G_AM0 / (R_au_aphelion^2);
theta = 15;
cos_theta = cosd(theta);

fprintf('========== THERMAL ENVIRONMENT ==========\n');
fprintf('G_sun = %.0f W/m^2\n', G_sun);
fprintf('cos(theta) = %.6f\n\n', cos_theta);

% ------------------------------------------------------------------------
% THERMAL MODEL
% ------------------------------------------------------------------------

sigma = 5.670374419e-8;
alpha_solar = 0.89;
epsilon_IR = 0.80;
eta_25C = 0.29;
gamma_temp = -0.005;
T_ref_C = 25;

fprintf('========== THERMAL MODEL ==========\n');

max_iter_thermal = 20;
tolerance_thermal = 0.01;
T_old_K = 300;

for iter = 1:max_iter_thermal
    T_C = T_old_K - 273.15;
    eta_T = eta_25C * (1 + gamma_temp * (T_C - T_ref_C));
    T_new_K = ((alpha_solar - eta_T) * G_sun * cos_theta / (2 * epsilon_IR * sigma))^(1/4);
    
    if abs(T_new_K - T_old_K) < tolerance_thermal
        break;
    end
    T_old_K = T_new_K;
end

T_panel_K = T_new_K;
T_panel_C = T_panel_K - 273.15;
eta_op = eta_25C * (1 + gamma_temp * (T_panel_C - T_ref_C));

fprintf('T_panel = %.2f K (%.2f °C)\n', T_panel_K, T_panel_C);
fprintf('eta_op = %.1f%%\n\n', eta_op * 100);

% ------------------------------------------------------------------------
% SOLAR CELL DATASHEET
% ------------------------------------------------------------------------

cells{1,1} = 'Spectrolab K4702 (Silicon)';
cells{1,2} = 0.133;
cells{1,3} = 0.490;
cells{1,4} = 64.00;
cells{1,5} = 55;
cells{1,6} = 0.0392;
cells{1,7} = -0.00220;
cells{1,8} = 20.0e-6;
cells{1,9} = 28;
cells{1,10} = 1353;
cells{1,11} = 0.85;
cells{1,12} = 0.74;
cells{1,13} = 0.78;

cells{2,1} = 'AZUR SPACE 3G28C';
cells{2,2} = 0.28;
cells{2,3} = 2.371;
cells{2,4} = 30.18;
cells{2,5} = 86;
cells{2,6} = 0.01677;
cells{2,7} = -0.0061;
cells{2,8} = 10.6e-6;
cells{2,9} = 28;
cells{2,10} = 1367;
cells{2,11} = 0.95;
cells{2,12} = 0.91;
cells{2,13} = 0.83;

cells{3,1} = 'CESI CTJ30-Thin';
cells{3,2} = 0.29;
cells{3,3} = 2.31;
cells{3,4} = 26.50;
cells{3,5} = 50;
cells{3,6} = 0.01785;
cells{3,7} = -0.0064;
cells{3,8} = 14.0e-6;
cells{3,9} = 25;
cells{3,10} = 1367;
cells{3,11} = 0.91;
cells{3,12} = 0.89;
cells{3,13} = 0.82;

% ------------------------------------------------------------------------
% CELL CORRECTION
% ------------------------------------------------------------------------

fprintf('========== CELL CORRECTION ==========\n\n');

for i = 1:3
    name = cells{i,1};
    eta_ref = cells{i,2};
    Vmp_ref = cells{i,3};
    area_cm2 = cells{i,4};
    rho = cells{i,5};
    Jsc_ref = cells{i,6};
    beta_V = cells{i,7};
    alpha_J = cells{i,8};
    T_ref_cell = cells{i,9};
    G_ref = cells{i,10};
    k_rad = cells{i,11};
    FF = cells{i,13};
    
    delta_T = T_panel_C - T_ref_cell;
    
    Vmp_T = Vmp_ref + beta_V * delta_T;
    Jsc_temp = Jsc_ref + alpha_J * delta_T;
    k_irr = G_sun / G_ref;
    Jsc_T = Jsc_temp * k_irr;
    Imp_T = Jsc_T * FF;
    eta_T = eta_ref * (1 + gamma_temp * delta_T);
    
    cells{i,14} = Vmp_T;
    cells{i,15} = Jsc_T;
    cells{i,16} = Imp_T;
    cells{i,17} = eta_T;
    cells{i,18} = area_cm2 / 10000;
    cells{i,19} = delta_T;
    
    fprintf('%s:\n', name);
    fprintf('  Vmp: %.3f V, Imp: %.4f A/cm^2\n', Vmp_T, Imp_T);
    fprintf('  eta: %.2f%%, k_rad = %.3f\n\n', eta_T*100, k_rad);
end

% ------------------------------------------------------------------------
% MARIN-COCA ITERATION
% ------------------------------------------------------------------------

P_SA_old = P_mean * margin_power;
fprintf('========== MARIN-COCA ==========\n');

max_iter = 50;
tolerance = 1;

for iter = 1:max_iter
    I_A = (P_SA_old > P_load);
    I_B = ~I_A;
    
    num = sum(P_load(I_A) .* dt(I_A) * eta_BCR * eta_BATTc) + ...
          sum(P_load(I_B) .* dt(I_B) / (eta_BATTd * eta_BDR));
    den = sum(dt(I_A) * eta_BCR * eta_BATTc) + ...
          sum(dt(I_B) / (eta_BATTd * eta_BDR));
    P_SA_new = num / den;
    
    if abs(P_SA_new - P_SA_old) < tolerance
        fprintf('P_PV_EOL = %.0f W\n\n', P_SA_new);
        break;
    end
    P_SA_old = P_SA_new;
end

P_PV_EOL = P_SA_new;

% ------------------------------------------------------------------------
% DEGRADATION PARAMETERS
% ------------------------------------------------------------------------

k_deg = 0.85;
k_mismatch = 0.97;
k_packing = 0.80;
overhead_factor = 2.2;

fprintf('========== DEGRADATION ==========\n');
fprintf('k_deg = %.2f, k_mismatch = %.2f\n', k_deg, k_mismatch);
fprintf('k_packing = %.2f, overhead = %.1f\n\n', k_packing, overhead_factor);

% ------------------------------------------------------------------------
% SOLAR ARRAY SIZING
% ------------------------------------------------------------------------

V_bus = 28;

fprintf('========== PV SIZING (Bus %d V) ==========\n', V_bus);

mission_years = 5;
mission_hours = mission_years * 365 * 24;
lambda_cell_total_FIT = 45;
lambda_cell_total = lambda_cell_total_FIT * 1e-9;

PV_results = [];

for i = 1:3
    name = cells{i,1};
    eta_T = cells{i,17};
    Vmp_T = cells{i,14};
    area_cm2 = cells{i,4};
    area_m2 = cells{i,18};
    rho = cells{i,5};
    Imp_T = cells{i,16};
    Jsc_T = cells{i,15};
    k_rad = cells{i,11};
    FF = cells{i,13};
    
    S_active = P_PV_EOL / (G_sun * cos_theta * eta_T * k_rad * k_deg * k_mismatch);
    S_panel = S_active / k_packing;
    
    N_s = ceil(V_bus / Vmp_T);
    N_cells_total = ceil(S_active / area_m2);
    N_strings_area = ceil(N_cells_total / N_s);
    
    I_mp_string = Imp_T * area_cm2;
    P_area = V_bus * N_strings_area * I_mp_string;
    
    M = ceil(P_PV_EOL / (V_bus * I_mp_string));
    
    lambda_str = N_s * lambda_cell_total;
    R_str = exp(-lambda_str * mission_hours);
    
    N_str_rel = M;
    P_rel = 0;
    while P_rel < 0.99
        P_rel = 1 - binocdf(M - 1, N_str_rel, R_str);
        if P_rel >= 0.99
            break;
        end
        N_str_rel = N_str_rel + 1;
    end
    
    N_str_final = max(N_strings_area, N_str_rel);
    P_eff = V_bus * N_str_final * I_mp_string;
    
    S_active_actual_m2 = N_s * N_str_final * area_m2;
    S_panel_actual_m2 = S_active_actual_m2 / k_packing;
    rho_kg_m2 = rho * 0.01;
    m_cells = S_active_actual_m2 * rho_kg_m2;
    m_PV_bare = m_cells;
    m_PV_complete = m_cells * overhead_factor;
    
    margin_pct = (P_eff - P_PV_EOL) / P_PV_EOL * 100;
    
    fprintf('%s:\n', name);
    fprintf('  N_s = %d, N_str = %d\n', N_s, N_str_final);
    fprintf('  I_mp = %.3f A, P_eff = %.0f W (+%.1f%%)\n', I_mp_string, P_eff, margin_pct);
    fprintf('  m_bare = %.2f kg, m_complete = %.2f kg\n', m_PV_bare, m_PV_complete);
    fprintf('  R_str = %.4f, P_success = %.1f%%\n\n', R_str, P_rel*100);
    
    PV_results = [PV_results; i, N_s, N_str_final, P_eff, m_PV_bare, m_PV_complete, margin_pct, S_active_actual_m2, I_mp_string, R_str, P_rel, M, S_panel_actual_m2];
end

[~, best_idx] = min(PV_results(:,5));
best_PV_cell = cells{PV_results(best_idx,1),1};
best_PV_mass_bare = PV_results(best_idx,5);
best_PV_mass_complete = PV_results(best_idx,6);
best_PV_P = PV_results(best_idx,4);
best_N_s_PV = PV_results(best_idx,2);
best_N_str = PV_results(best_idx,3);
best_I_mp_string = PV_results(best_idx,9);
best_margin = PV_results(best_idx,7);
best_R_str = PV_results(best_idx,10);
best_P_success = PV_results(best_idx,11);
best_M = PV_results(best_idx,12);
best_S_active = PV_results(best_idx,8);
best_S_panel = PV_results(best_idx,13);

fprintf('--- SELECTED ---\n');
fprintf('Cell: %s\n', best_PV_cell);
fprintf('N_s = %d, N_str = %d\n', best_N_s_PV, best_N_str);
fprintf('P_eff = %.0f W (+%.1f%%), m_bare = %.2f kg\n', best_PV_P, best_margin, best_PV_mass_bare);
fprintf('R_str = %.4f, P_success = %.1f%%\n\n', best_R_str, best_P_success*100);

% ------------------------------------------------------------------------
% PARAMETRIC BATTERY SIZING
% ------------------------------------------------------------------------

E_LEOP_nom = (192 * 130/60) + (924 * 90/60);
E_LEOP_req = E_LEOP_nom * margin_power;

fprintf('========== BATTERY SIZING ==========\n');
fprintf('E_LEOP = %.0f Wh\n\n', E_LEOP_req);

V_nom_cell = 3.60;
V_min_cell = 2.70;
V_max_cell = 4.10;
C_cell = 4.5;
m_cell_kg = 0.112;
R_cell = 0.025;

Ns_min = 1;
Ns_max = floor(2 * V_bus / V_max_cell);
Ns_range = Ns_min:1:Ns_max;
n_configs = length(Ns_range);

Np = zeros(1, n_configs);
E_batt = zeros(1, n_configs);
m_batt = zeros(1, n_configs);
V_batt_min = zeros(1, n_configs);
V_batt_nom = zeros(1, n_configs);
V_batt_max = zeros(1, n_configs);
S4R_compatible = false(1, n_configs);
boost_ratio = zeros(1, n_configs);
I_batt_avg = zeros(1, n_configs);
I_string_batt = zeros(1, n_configs);
P_joule_string = zeros(1, n_configs);
P_joule_total = zeros(1, n_configs);
N_cells_total_batt = zeros(1, n_configs);
position_str = cell(1, n_configs);

fprintf(' Ns | Np | E_batt | m_batt | V_min | V_nom | V_max | Position | S4R\n');
fprintf('----|----|--------|--------|-------|-------|-------|----------|-----\n');

for i = 1:n_configs
    Ns = Ns_range(i);
    
    C_req = E_LEOP_req / (Ns * V_min_cell * 0.80);
    Np(i) = ceil(C_req / C_cell);
    
    V_batt_min(i) = Ns * V_min_cell;
    V_batt_nom(i) = Ns * V_nom_cell;
    V_batt_max(i) = Ns * V_max_cell;
    
    if V_batt_max(i) < V_bus
        position_str{i} = 'BELOW';
        S4R_compatible(i) = true;
    elseif V_batt_min(i) > V_bus
        position_str{i} = 'ABOVE';
        S4R_compatible(i) = false;
    else
        position_str{i} = 'STRADDLES';
        S4R_compatible(i) = false;
    end
    
    E_batt(i) = Ns * Np(i) * V_nom_cell * C_cell;
    m_batt(i) = Ns * Np(i) * m_cell_kg;
    
    if V_batt_nom(i) < V_bus
        boost_ratio(i) = V_bus / V_batt_nom(i);
    else
        boost_ratio(i) = 1.0;
    end
    
    I_batt_avg(i) = E_batt(i) / V_batt_nom(i);
    I_string_batt(i) = C_cell / 1;
    R_string = Ns * R_cell;
    P_joule_string(i) = I_string_batt(i)^2 * R_string;
    P_joule_total(i) = Np(i) * P_joule_string(i);
    N_cells_total_batt(i) = Ns * Np(i);
    
    s4r_str = 'NO';
    if S4R_compatible(i)
        s4r_str = 'SI';
    end
    
    fprintf(' %2d | %2d | %6.0f | %6.1f | %5.1f | %5.1f | %5.1f | %-8s | %3s\n', ...
        Ns, Np(i), E_batt(i), m_batt(i), V_batt_min(i), V_batt_nom(i), V_batt_max(i), ...
        position_str{i}, s4r_str);
end

fprintf('\n');

% ------------------------------------------------------------------------
% KEY CONFIGURATIONS
% ------------------------------------------------------------------------

S4R_indices = find(S4R_compatible == true);
if ~isempty(S4R_indices)
    idx_S4R_candidate = S4R_indices(end);
    Ns_S4R = Ns_range(idx_S4R_candidate);
else
    idx_S4R_candidate = [];
    Ns_S4R = NaN;
end

[~, idx_S3R_candidate] = min(abs(V_batt_nom - V_bus));
Ns_S3R = Ns_range(idx_S3R_candidate);

fprintf('========== KEY CONFIGURATIONS ==========\n');
fprintf('S4R candidate: Ns = %d\n', Ns_S4R);
fprintf('S3R candidate: Ns = %d\n\n', Ns_S3R);

% ------------------------------------------------------------------------
% PCDU MASS
% ------------------------------------------------------------------------

P_peak_kW = P_peak_true / 1000;
m_PCDU_S3R = P_peak_kW * 2.0;
m_PCDU_S4R = P_peak_kW * 1.8;

fprintf('========== PCDU MASS ==========\n');
fprintf('S3R: %.1f kg, S4R: %.1f kg\n\n', m_PCDU_S3R, m_PCDU_S4R);

% ------------------------------------------------------------------------
% TOTAL EPS MASS
% ------------------------------------------------------------------------

m_EPS_CDF = 89.9;
overhead_battery = 1.35;
overhead_PCDU = 1.25;

fprintf('========== TOTAL EPS MASS ==========\n');
fprintf('CDF baseline: %.1f kg\n\n', m_EPS_CDF);

key_indices = [];
if ~isempty(idx_S4R_candidate)
    key_indices = [key_indices, idx_S4R_candidate];
end
key_indices = [key_indices, idx_S3R_candidate];
key_indices = unique(key_indices);

fprintf(' Config | Ns | Np | Batt[kg] | Batt_comp[kg] | PV[kg] | PV_comp[kg] | PCDU[kg] | Total[kg] | Red[%%]\n');
fprintf('--------|----|----|----------|---------------|--------|-------------|----------|-----------|-------\n');

for k = 1:length(key_indices)
    idx = key_indices(k);
    Ns = Ns_range(idx);
    Np_val = Np(idx);
    m_batt_val = m_batt(idx);
    m_batt_comp = m_batt_val * overhead_battery;
    m_PV_comp = best_PV_mass_complete;
    m_PCDU_comp = m_PCDU_S3R * overhead_PCDU;
    position = position_str{idx};
    
    total_bare = best_PV_mass_bare + m_batt_val + m_PCDU_S3R;
    total_comp = m_PV_comp + m_batt_comp + m_PCDU_comp;
    reduction = (m_EPS_CDF - total_comp) / m_EPS_CDF * 100;
    
    fprintf(' S3R %s | %2d | %2d | %8.1f | %11.1f | %6.2f | %9.2f | %8.1f | %9.1f | %5.1f%%\n', ...
        position, Ns, Np_val, m_batt_val, m_batt_comp, best_PV_mass_bare, m_PV_comp, m_PCDU_S3R, total_comp, reduction);
    
    if S4R_compatible(idx)
        m_PCDU_S4R_comp = m_PCDU_S4R * overhead_PCDU;
        total_bare_S4R = best_PV_mass_bare + m_batt_val + m_PCDU_S4R;
        total_comp_S4R = m_PV_comp + m_batt_comp + m_PCDU_S4R_comp;
        reduction_S4R = (m_EPS_CDF - total_comp_S4R) / m_EPS_CDF * 100;
        
        fprintf(' S4R %s | %2d | %2d | %8.1f | %11.1f | %6.2f | %9.2f | %8.1f | %9.1f | %5.1f%%\n', ...
            position, Ns, Np_val, m_batt_val, m_batt_comp, best_PV_mass_bare, m_PV_comp, m_PCDU_S4R, total_comp_S4R, reduction_S4R);
    end
end

fprintf('\n');

% ------------------------------------------------------------------------
% SUMMARY
% ------------------------------------------------------------------------

total_comp_rec = best_PV_mass_complete + m_batt(idx_S3R_candidate)*overhead_battery + m_PCDU_S3R*overhead_PCDU;

fprintf('========== SUMMARY ==========\n');
fprintf('PV: %s, %.2f kg (bare), %.2f kg (complete)\n', best_PV_cell, best_PV_mass_bare, best_PV_mass_complete);
fprintf('Battery: %dS%dP, %.1f kg (bare), %.1f kg (complete)\n', Ns_S3R, Np(idx_S3R_candidate), m_batt(idx_S3R_candidate), m_batt(idx_S3R_candidate)*overhead_battery);
fprintf('PCDU: S3R, %.1f kg (bare), %.1f kg (complete)\n', m_PCDU_S3R, m_PCDU_S3R*overhead_PCDU);
fprintf('Total EPS: %.1f kg (complete)\n', total_comp_rec);
fprintf('Reduction vs CDF: %.1f%%\n', (m_EPS_CDF - total_comp_rec) / m_EPS_CDF * 100);
fprintf('Reliability: %.1f%% (requirement 99%%)\n\n', best_P_success*100);

% ------------------------------------------------------------------------
% FIGURES
% ------------------------------------------------------------------------

fprintf('========== FIGURES ==========\n');

folder = 'EPS_Figures';
if ~exist(folder, 'dir')
    mkdir(folder);
end

% Figure 1: PV cell mass comparison
figure('Color', 'w', 'Position', [100, 100, 900, 600]);
cells_names = {'Spectrolab K4702', 'AZUR 3G28C', 'CESI CTJ30-Thin'};
bare = [PV_results(1,5), PV_results(2,5), PV_results(3,5)];
complete = [PV_results(1,6), PV_results(2,6), PV_results(3,6)];
x = 1:3;
width = 0.35;

b1 = bar(x - width/2, bare, width, 'FaceColor', [0.12 0.47 0.71], 'EdgeColor', 'k', 'DisplayName', 'Bare mass');
hold on;
b2 = bar(x + width/2, complete, width, 'FaceColor', [1 0.5 0], 'EdgeColor', 'k', 'DisplayName', 'Complete mass');

set(gca, 'XTick', x, 'XTickLabel', cells_names);
xtickangle(15);
xlabel('Cell Technology', 'Color', 'k', 'FontSize', 12);
ylabel('Mass (kg)', 'Color', 'k', 'FontSize', 12);
title('Photovoltaic Cell Mass Comparison (28 V Bus)', 'Color', 'k', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'northwest', 'FontSize', 11, 'Box', 'on', 'EdgeColor', 'k', 'TextColor', 'k', 'Color', 'w');

grid on; grid minor;
set(gca, 'XColor', 'k', 'YColor', 'k', 'GridColor', 'k', ...
    'GridAlpha', 0.15, 'MinorGridAlpha', 0.08, 'LineWidth', 1);

for i = 1:3
    text(i - width/2, bare(i) + 0.15, sprintf('%.2f', bare(i)), ...
        'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold', 'Color', 'k');
    text(i + width/2, complete(i) + 0.15, sprintf('%.2f', complete(i)), ...
        'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold', 'Color', 'k');
end

exportgraphics(gcf, fullfile(folder, 'pv_cell_mass_comparison.png'), ...
    'Resolution', 800, 'BackgroundColor', 'white');
fprintf('Figure 1 saved: pv_cell_mass_comparison.png\n');

% Figure 2: Battery mass invariance
figure('Color', 'w', 'Position', [100, 100, 900, 600]);

p1 = plot(Ns_range, m_batt, 'o-', 'Color', [0.12 0.47 0.71], 'LineWidth', 2, ...
    'MarkerSize', 8, 'MarkerFaceColor', [0.12 0.47 0.71], ...
    'MarkerEdgeColor', 'k', 'DisplayName', 'Battery mass');
hold on;

l1 = yline(min(m_batt), 'r--', 'LineWidth', 1.5, 'DisplayName', sprintf('Min mass = %.1f kg', min(m_batt)));
l2 = yline(max(m_batt), 'r--', 'LineWidth', 1.5, 'DisplayName', sprintf('Max mass = %.1f kg', max(m_batt)));

fill([Ns_range, fliplr(Ns_range)], ...
    [repmat(min(m_batt),1,length(Ns_range)), fliplr(repmat(max(m_batt),1,length(Ns_range)))], ...
    [0.12 0.47 0.71], 'FaceAlpha', 0.08, 'EdgeColor', 'none', 'HandleVisibility', 'off');

xlabel('Number of Series Cells N_s', 'Color', 'k', 'FontSize', 12);
ylabel('Battery Mass (kg)', 'Color', 'k', 'FontSize', 12);
title('Battery Mass Invariance Across Series Cell Configurations', ...
    'Color', 'k', 'FontSize', 14, 'FontWeight', 'bold');

grid on; grid minor;
set(gca, 'XColor', 'k', 'YColor', 'k', 'GridColor', 'k', ...
    'GridAlpha', 0.15, 'MinorGridAlpha', 0.08, 'LineWidth', 1);

p2 = plot(Ns_S3R, m_batt(idx_S3R_candidate), 's', 'Color', 'r', 'MarkerSize', 12, ...
    'LineWidth', 2, 'MarkerFaceColor', 'r', 'DisplayName', sprintf('Ns=%d (selected)', Ns_S3R));
text(Ns_S3R + 0.3, m_batt(idx_S3R_candidate) + 0.2, sprintf('Ns=%d (selected)', Ns_S3R), ...
    'FontSize', 11, 'FontWeight', 'bold', 'Color', 'r');

legend([p1, l1, l2, p2], 'Location', 'northeast', 'FontSize', 11, 'Box', 'on', ...
    'EdgeColor', 'k', 'TextColor', 'k', 'Color', 'w');

exportgraphics(gcf, fullfile(folder, 'battery_mass_invariance.png'), ...
    'Resolution', 800, 'BackgroundColor', 'white');
fprintf('Figure 2 saved: battery_mass_invariance.png\n');

% Figure 3: S3R vs S4R comparison
figure('Color', 'w', 'Position', [100, 100, 900, 500]);
labels_plot = {'Battery Current (A)', 'Boost Ratio'};
s4r_vals = [I_batt_avg(idx_S4R_candidate), boost_ratio(idx_S4R_candidate)];
s3r_vals = [I_batt_avg(idx_S3R_candidate), boost_ratio(idx_S3R_candidate)];
x = 1:2;
width = 0.35;

b3 = bar(x - width/2, s4r_vals, width, 'FaceColor', [1 0.5 0], 'EdgeColor', 'k', 'DisplayName', 'S4R (Ns=6)');
hold on;
b4 = bar(x + width/2, s3r_vals, width, 'FaceColor', [0.12 0.47 0.71], 'EdgeColor', 'k', 'DisplayName', 'S3R (Ns=8)');

set(gca, 'XTick', x, 'XTickLabel', labels_plot);
xlabel('Parameter', 'Color', 'k', 'FontSize', 12);
ylabel('Value (A or Ratio)', 'Color', 'k', 'FontSize', 12);
title('S3R vs S4R Architecture Comparison', 'Color', 'k', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'northeast', 'FontSize', 11, 'Box', 'on', 'EdgeColor', 'k', 'TextColor', 'k', 'Color', 'w');

grid on; grid minor;
set(gca, 'XColor', 'k', 'YColor', 'k', 'GridColor', 'k', ...
    'GridAlpha', 0.15, 'MinorGridAlpha', 0.08, 'LineWidth', 1);

for i = 1:2
    text(i - width/2, s4r_vals(i) + 0.03*max([s4r_vals, s3r_vals]), sprintf('%.2f', s4r_vals(i)), ...
        'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold', 'Color', 'k');
    text(i + width/2, s3r_vals(i) + 0.03*max([s4r_vals, s3r_vals]), sprintf('%.2f', s3r_vals(i)), ...
        'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold', 'Color', 'k');
end

exportgraphics(gcf, fullfile(folder, 's3r_s4r_comparison.png'), ...
    'Resolution', 800, 'BackgroundColor', 'white');
fprintf('Figure 3 saved: s3r_s4r_comparison.png\n');

% Figure 4: Joule losses comparison
figure('Color', 'w', 'Position', [100, 100, 1000, 500]);

subplot(1,2,1);
labels_joule = {'S4R (Ns=6)', 'S3R (Ns=8)'};
losses = [P_joule_total(idx_S4R_candidate), P_joule_total(idx_S3R_candidate)];
colors_joule = {[1 0.5 0], [0.12 0.47 0.71]};

for i = 1:2
    bar(i, losses(i), 'FaceColor', colors_joule{i}, 'EdgeColor', 'k', 'DisplayName', labels_joule{i});
    hold on;
end

ylabel('Joule Losses (W)', 'Color', 'k', 'FontSize', 12);
title('Total Joule Losses', 'Color', 'k', 'FontSize', 12, 'FontWeight', 'bold');
set(gca, 'XTick', 1:2, 'XTickLabel', labels_joule);
grid on; grid minor;
set(gca, 'XColor', 'k', 'YColor', 'k', 'GridColor', 'k', ...
    'GridAlpha', 0.15, 'MinorGridAlpha', 0.08, 'LineWidth', 1);
ylim([0, 150]);
legend('Location', 'northeast', 'FontSize', 10, 'Box', 'on', 'EdgeColor', 'k', 'TextColor', 'k', 'Color', 'w');

for i = 1:2
    text(i, losses(i) + 2, sprintf('%.1f W', losses(i)), ...
        'HorizontalAlignment', 'center', 'FontSize', 11, 'FontWeight', 'bold', 'Color', 'k');
end

subplot(1,2,2);
currents_plot = [I_batt_avg(idx_S4R_candidate), I_batt_avg(idx_S3R_candidate)];

for i = 1:2
    bar(i, currents_plot(i), 'FaceColor', colors_joule{i}, 'EdgeColor', 'k', 'DisplayName', labels_joule{i});
    hold on;
end

ylabel('Battery Current (A)', 'Color', 'k', 'FontSize', 12);
title('Battery Terminal Current', 'Color', 'k', 'FontSize', 12, 'FontWeight', 'bold');
set(gca, 'XTick', 1:2, 'XTickLabel', labels_joule);
grid on; grid minor;
set(gca, 'XColor', 'k', 'YColor', 'k', 'GridColor', 'k', ...
    'GridAlpha', 0.15, 'MinorGridAlpha', 0.08, 'LineWidth', 1);
ylim([0, 200]);
legend('Location', 'northeast', 'FontSize', 10, 'Box', 'on', 'EdgeColor', 'k', 'TextColor', 'k', 'Color', 'w');

for i = 1:2
    text(i, currents_plot(i) + 5, sprintf('%.0f A', currents_plot(i)), ...
        'HorizontalAlignment', 'center', 'FontSize', 11, 'FontWeight', 'bold', 'Color', 'k');
end

exportgraphics(gcf, fullfile(folder, 'joule_losses_comparison.png'), ...
    'Resolution', 800, 'BackgroundColor', 'white');
fprintf('Figure 4 saved: joule_losses_comparison.png\n');

% Figure 5: EPS mass comparison
figure('Color', 'w', 'Position', [100, 100, 900, 600]);

m_PV_comp_fig = best_PV_mass_complete;
m_batt_comp_fig = m_batt(idx_S3R_candidate) * overhead_battery;
m_PCDU_comp_fig = m_PCDU_S3R * overhead_PCDU;
total_comp_estimate = m_PV_comp_fig + m_batt_comp_fig + m_PCDU_comp_fig;

labels_mass = {'CDF Baseline', 'Present Study (Bare)', 'Present Study (Complete)'};
masses_plot = [m_EPS_CDF, total_bare, total_comp_estimate];
colors_mass = {[0.85 0.16 0.16], [0.17 0.63 0.17], [1 0.5 0]};

for i = 1:3
    barh(i, masses_plot(i), 'FaceColor', colors_mass{i}, 'EdgeColor', 'k', 'DisplayName', labels_mass{i});
    hold on;
end

set(gca, 'YTick', 1:3, 'YTickLabel', labels_mass);
xlabel('Mass (kg)', 'Color', 'k', 'FontSize', 12);
title('EPS Mass Comparison: CDF Baseline vs. Present Study', 'Color', 'k', 'FontSize', 14, 'FontWeight', 'bold');
xlim([0, 110]);

grid on; grid minor;
set(gca, 'XColor', 'k', 'YColor', 'k', 'GridColor', 'k', ...
    'GridAlpha', 0.15, 'MinorGridAlpha', 0.08, 'LineWidth', 1);
legend('Location', 'southeast', 'FontSize', 11, 'Box', 'on', 'EdgeColor', 'k', 'TextColor', 'k', 'Color', 'w');

for i = 1:3
    text(masses_plot(i) + 1.5, i, sprintf('%.1f kg', masses_plot(i)), ...
        'VerticalAlignment', 'middle', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k');
end

line([m_EPS_CDF, m_EPS_CDF], [0.5, 3.5], 'Color', 'r', 'LineStyle', '--', 'LineWidth', 1.5, 'HandleVisibility', 'off');

exportgraphics(gcf, fullfile(folder, 'eps_mass_comparison.png'), ...
    'Resolution', 800, 'BackgroundColor', 'white');
fprintf('Figure 5 saved: eps_mass_comparison.png\n');

% Figure 6: Areal mass reduction
figure('Color', 'w', 'Position', [100, 100, 800, 500]);
labels_areal = {'CDF era (2014)', 'CESI CTJ30-Thin'};
mass_areal = [118, 50];
colors_areal = {[0.85 0.16 0.16], [0.17 0.63 0.17]};

for i = 1:2
    bar(i, mass_areal(i), 'FaceColor', colors_areal{i}, 'EdgeColor', 'k', 'DisplayName', labels_areal{i});
    hold on;
end

set(gca, 'XTick', 1:2, 'XTickLabel', labels_areal);
ylabel('Areal Mass (mg/cm^2)', 'Color', 'k', 'FontSize', 12);
title('Solar Cell Areal Mass: Technology Evolution', 'Color', 'k', 'FontSize', 14, 'FontWeight', 'bold');

grid on; grid minor;
set(gca, 'XColor', 'k', 'YColor', 'k', 'GridColor', 'k', ...
    'GridAlpha', 0.15, 'MinorGridAlpha', 0.08, 'LineWidth', 1);
ylim([0, 140]);
legend('Location', 'northeast', 'FontSize', 11, 'Box', 'on', 'EdgeColor', 'k', 'TextColor', 'k', 'Color', 'w');

for i = 1:2
    text(i, mass_areal(i) + 3, sprintf('%.0f mg/cm^2', mass_areal(i)), ...
        'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k');
end

exportgraphics(gcf, fullfile(folder, 'areal_mass_reduction.png'), ...
    'Resolution', 800, 'BackgroundColor', 'white');
fprintf('Figure 6 saved: areal_mass_reduction.png\n');

fprintf('\n========== ALL FIGURES GENERATED ==========\n');
fprintf('Files saved in folder: %s\n', folder);
fprintf('  1. pv_cell_mass_comparison.png\n');
fprintf('  2. battery_mass_invariance.png\n');
fprintf('  3. s3r_s4r_comparison.png\n');
fprintf('  4. joule_losses_comparison.png\n');
fprintf('  5. eps_mass_comparison.png\n');
fprintf('  6. areal_mass_reduction.png\n');

fprintf('\n========== DONE ==========\n');