function C4_make_report(stage)
% C4_MAKE_REPORT  The full Stage A picture set for one stage, same names and layout as the settled
% Stage A (A5 + A6 + A7), plus the comparison of all stages run so far. Needs C1, C2 and C3 first.
% Writes results/stage<X>/plots/*.png, pattern_tx.csv / pattern_jam.csv, results/stage<X>/patterns3d/*.vtk,
% results/stage<X>/index.html, and results/compare/*.png.
if nargin < 1, stage = 'A'; end
stage = upper(stage);
setup_paths; white_figs;
if exist('OCTAVE_VERSION', 'builtin'), graphics_toolkit('gnuplot'); end
P0 = case_params(stage, 100, true);
out = fullfile(P0.root, ['stage' stage]);
S = load(fullfile(out, ['summary_stage' stage '.mat']));
T = load(fullfile(P0.root, 'check_tx_pec', 'check.mat'));
Kj = S.K.pec;
R = S.R;  G = R([R.ground]);  [~, o] = sort([G.d]);  G = G(o);
k1 = find([G.d] == 100, 1);  if isempty(k1), k1 = 1; end
Rf = G(k1);                                              % the 0.1 m run = "final case" plots, as in Stage A
pd = fullfile(out, 'plots');  if ~exist(pd, 'dir'), mkdir(pd); end
dB = @(x) 20*log10(abs(x));
f  = P0.freq / 1e9;  i0 = find(abs(P0.freq - P0.f0) == min(abs(P0.freq - P0.f0)), 1);
tx = P0.tx;  jm = P0.jam;  rx = P0.rx;
S_dBm = tx.P_dBm - rx.cable_loss_dB;
N = -174 + 10*log10(rx.BW_Hz) + rx.NF_dB;
rmin = -20; rmax = 10 + 5*(max(Kj.F.Gmax_dBi) > 10);
sv = @(name) print(gcf, fullfile(pd, [name '.png']), '-dpng', '-r110');
jn = sprintf('Jammer, Stage %s (%s)', stage, jm.ant.type);

%% whole-scene pattern from the 0.1 m run (if it recorded one)
Fscene = [];
P1 = case_params(stage, Rf.d, true);
if P1.scene_ff && exist(fullfile(P1.root, P1.tag, 'nf2ff_E_xn.h5'), 'file')
  [~, ~, port, nf2ff, info] = build_scene(P1, 'jam');
  port{2} = calcPort(port{2}, fullfile(P1.root, P1.tag), P1.freq, 'RefImpedance', P1.jam.R);
  port{1} = calcPort(port{1}, fullfile(P1.root, P1.tag), P1.freq, 'RefImpedance', P1.tx.R);
  rr = port_results(port, 2, P1);
  here = cd(P1.root);
  Fscene = farfield(nf2ff, P1.tag, P1, info, rr, 'farfield_3D_scene.vtk');
  cd(here);
end

%% 00 geometry
gm = {'tx', '00a_geometry_TX_alone'; 'jam', '00b_geometry_interferer_alone'; 'both', '00c_geometry_both'};
P1.jam.feed = [Rf.d 0 jm.height];
for k = 1:3
  figure('Position', [100 100 1200 560]); draw_geometry(P1, gm{k, 1}); sv(gm{k, 2}); close;
end

%% 01 S11 and impedance, VSWR
figure('Position', [100 100 1000 420]);
subplot(1, 2, 1); hold on; grid on;
plot(f, dB(T.r.s11), f, dB(Kj.r.s11), f, dB(Rf.s11), '--', 'LineWidth', 1.5);
plot([P0.f0 P0.f0]/1e9, [-40 0], 'k:'); plot([f(1) f(end)], [-10 -10], 'r:'); ylim([-40 0]);
xlabel('f / GHz'); ylabel('S11 / dB'); legend('TX alone', 'jammer alone', 'jammer in the scene', 'Location', 'southeast');
title('S11 at the antenna feed');
subplot(1, 2, 2); hold on; grid on;
plot(f, real(T.r.zin), 'b-', f, imag(T.r.zin), 'b--', f, real(Kj.r.zin), 'r-', f, imag(Kj.r.zin), 'r--', 'LineWidth', 1.5);
plot([P0.f0 P0.f0]/1e9, [-100 250], 'k:'); ylim([-100 250]);
xlabel('f / GHz'); ylabel('Z_{in} / ohm'); legend('TX Re', 'TX Im', 'jammer Re', 'jammer Im', 'Location', 'northeast');
title(sprintf('Input impedance (alone); jammer port %g ohm', jm.R));
sv('01_S11_and_impedance'); close;
vswr = @(s) (1 + abs(s)) ./ max(1 - abs(s), 1e-6);
figure('Position', [100 100 700 450]); hold on; grid on;
plot(f, vswr(T.r.s11), 'b-', f, vswr(Kj.r.s11), 'r-', f, vswr(Rf.s11), 'r--', 'LineWidth', 1.5);
plot([P0.f0 P0.f0]/1e9, [1 10], 'k:'); plot([f(1) f(end)], [2 2], 'g:'); ylim([1 10]);
xlabel('f / GHz'); ylabel('VSWR'); legend('TX alone', 'jammer alone', 'jammer in the scene', 'Location', 'northeast');
title('VSWR at the antenna feed (below 2 is a good match)');
sv('01b_VSWR'); close;

%% 02/03 patterns of each antenna alone (polar, rectangular, map, 3D, csv)
C = {T, 'TX (half-wave dipole)', 'tx'; Kj, jn, 'jam'};
for k = 1:2
  F = C{k, 1}.F;  nm = C{k, 3};
  Gfs = 10*log10(max(F.Greal_fs, 1e-3));  Ggr = 10*log10(max(F.Greal, 1e-3));
  it = find(abs(F.th - pi/2) < 1e-9);  ia = 1;  ib = find(abs(F.ph - pi) < 1e-9);
  nr = @(g) (max(g, rmin) - rmin) / (rmax - rmin);
  figure('Position', [100 100 1500 520]);
  subplot(1, 3, 1); polar_axes(rmin, rmax, 10, 0, 360);
  r = nr(Gfs(it, :));  plot(r .* cos(F.ph), r .* sin(F.ph), 'b-', 'LineWidth', 2);
  title(sprintf('H-plane (horizon cut), free space; %.1f dBi', max(Gfs(it, :))), 'FontSize', 10);
  subplot(1, 3, 2); polar_axes(rmin, rmax, 10, 0, 360);
  for s = [ia ib]
    r = nr(Gfs(:, s));  sg = 1 - 2*(s == ib);  plot(sg * r .* sin(F.th(:)), r .* cos(F.th(:)), 'b-', 'LineWidth', 2);
  end
  title(sprintf('E-plane (x-z cut), free space; max %.1f dBi', max(Gfs(:))), 'FontSize', 10);
  subplot(1, 3, 3); polar_axes(rmin, rmax, 10, 0, 180);
  for s = [ia ib]
    r = nr(Ggr(:, s));  sg = 1 - 2*(s == ib);  plot(sg * r .* sin(F.th(:)), r .* cos(F.th(:)), 'r-', 'LineWidth', 1.5);
  end
  plot([-1 1], [0 0], 'k-', 'LineWidth', 1.5); text(0, -0.08, 'ground', 'HorizontalAlignment', 'center');
  title(sprintf('E-plane over the ground at 0.5 m; max %.1f dBi', max(Ggr(:))), 'FontSize', 10);
  text(0.5, 1.12, sprintf('%s: realized gain in dBi (rings %d ... %d; TX direction = 180 deg)', C{k, 2}, rmin, rmax), 'Units', 'normalized', 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
  sv(sprintf('%02d_pattern_polar_%s', 1 + k, nm)); close;

  thd = F.th(:) * 180/pi;  phd = F.ph(:)' * 180/pi;
  figure('Position', [100 100 1500 460]);
  subplot(1, 3, 1); hold on; grid on;
  plot(phd, Gfs(it, :), 'b-', 'LineWidth', 2); xlim([0 360]); ylim([rmin rmax]);
  xlabel('azimuth phi / deg (TX at 180)'); ylabel('realized gain / dBi'); title('H-plane (horizon cut), free space');
  subplot(1, 3, 2); hold on; grid on;
  ang = [-flipud(thd(2:end)); thd];  gcut = [flipud(Gfs(2:end, ib)); Gfs(:, ia)];
  plot(ang, gcut, 'b-', 'LineWidth', 2); xlim([-180 180]); ylim([rmin rmax]);
  xlabel('angle from the vertical / deg'); ylabel('realized gain / dBi'); title('E-plane (x-z cut), free space');
  subplot(1, 3, 3); hold on; grid on;
  gcut = [flipud(Ggr(2:end, ib)); Ggr(:, ia)];
  plot(ang, gcut, 'r-', 'LineWidth', 1.5); xlim([-90 90]); ylim([rmin rmax + 8]);
  xlabel('angle from the vertical / deg (0 = straight up)'); ylabel('realized gain / dBi'); title('E-plane over the ground at 0.5 m');
  sv(sprintf('%02db_pattern_rect_%s', 1 + k, nm)); close;

  figure('Position', [100 100 1300 460]);
  subplot(1, 2, 1); imagesc(phd, thd, max(Gfs, rmin)); axis xy; colorbar; caxis([rmin rmax]);
  xlabel('azimuth phi / deg'); ylabel('theta from the vertical / deg'); title('free space: realized gain / dBi');
  subplot(1, 2, 2); imagesc(phd, thd, max(Ggr, rmin)); axis xy; colorbar; caxis([rmin rmax + 6]);
  xlabel('azimuth phi / deg'); ylabel('theta from the vertical / deg'); ylim([0 90]); title('over the ground at 0.5 m: realized gain / dBi');
  sv(sprintf('%02dc_pattern_map_%s', 1 + k, nm)); close;

  [PHm, THm] = meshgrid(F.ph, F.th);
  fidc = fopen(fullfile(pd, sprintf('pattern_%s.csv', nm)), 'w');
  fprintf(fidc, 'theta_deg,phi_deg,gain_free_space_dBi,gain_over_ground_dBi\n');
  fprintf(fidc, '%.1f,%.1f,%.2f,%.2f\n', [THm(:)*180/pi, PHm(:)*180/pi, Gfs(:), Ggr(:)]');
  fclose(fidc);

  rr = max(Gfs - rmin, 0);  [PH, TH] = meshgrid([F.ph F.ph(1)+2*pi], F.th);  RR = [rr rr(:, 1)];
  X = RR .* sin(TH) .* cos(PH);  Y = RR .* sin(TH) .* sin(PH);  Z = RR .* cos(TH);
  figure('Position', [100 100 760 640]);
  surf(X, Y, Z, RR); shading interp; axis equal; colorbar; view(35, 22);
  lim = max(RR(:)) * 1.1;  axis([-lim lim -lim lim -lim lim]);
  xlabel('x (TX is at -x)'); ylabel('y'); zlabel('z (up)');
  title(sprintf('%s alone in free space: realized gain, colour = dBi + %g', C{k, 2}, -rmin), 'FontSize', 9);
  sv(sprintf('%02d_pattern_3d_%s', 3 + k, nm)); close;
end
p3 = fullfile(out, 'patterns3d');  if ~exist(p3, 'dir'), mkdir(p3); end
write_pattern_vtk(fullfile(p3, 'pattern_TX_alone.vtk'), T.F, [0 0 0], 0);
write_pattern_vtk(fullfile(p3, 'pattern_JAM_alone.vtk'), Kj.F, [0 0 0], 1);
write_pattern_vtk(fullfile(p3, 'pattern_TX_and_JAM.vtk'), {T.F, Kj.F}, {[-3 0 0], [3 0 0]}, {0, 1});

%% 06 received power vs frequency, 07 coupling, JS vs frequency, match_coupling (0.1 m run)
Jf = jm.P_dBm + dB(Rf.s21) - rx.cable_loss_dB;
figure('Position', [100 100 900 500]); hold on; grid on;
plot(f, Jf, 'r-', 'LineWidth', 1.8);
plot([f(1) f(end)], [S_dBm S_dBm], 'b-', 'LineWidth', 1.8);
plot([f(1) f(end)], [S_dBm S_dBm] + P0.JS_target_dB, 'k--');
plot([f(1) f(end)], [N N], ':', 'Color', [0.5 0.5 0.5]);
xlabel('f / GHz'); ylabel('power at the receiver / dBm');
legend('jammer power J picked up by the TX antenna', 'wanted signal S (TX, over the cable)', 'J needed for J/S = 10 dB', 'receiver noise floor', 'Location', 'east');
title(sprintf('Stage %s: received power at the TX terminals, %g mm spacing, TX %g dBm, jammer %g dBm', stage, Rf.d, tx.P_dBm, jm.P_dBm));
sv('06_received_power_vs_frequency'); close;

figure('Position', [100 100 900 480]); hold on; grid on;
plot(f, dB(Rf.s21), 'LineWidth', 1.8); yl = ylim; plot([P0.f0 P0.f0]/1e9, yl, 'k:');
xlabel('f / GHz'); ylabel('coupling / dB');
title(sprintf('Stage %s: jammer feed to TX terminals (S21), %g mm spacing: %.1f dB at 2.4 GHz', stage, Rf.d, Rf.coup));
sv('07_coupling_S21_vs_frequency'); close;

figure('Position', [100 100 800 500]); hold on; grid on;
plot(f, dB(T.r.s11), f, dB(Rf.s11), f, dB(Rf.s21), '--', 'LineWidth', 1.5);
yl = ylim; plot([P0.f0 P0.f0]/1e9, yl, 'k:'); xlabel('f / GHz'); ylabel('dB');
legend('S11 TX', 'S11 jammer', 'jammer \rightarrow TX terminals', 'Location', 'best');
title(sprintf('Stage %s: match and coupling, %g mm', stage, Rf.d));
sv('match_coupling'); close;

figure('Position', [100 100 800 500]); hold on; grid on;
plot(f, Jf - S_dBm, 'LineWidth', 1.5); plot([f(1) f(end)], [P0.JS_target_dB P0.JS_target_dB], 'r--');
legend('J/S', 'target'); xlabel('f / GHz'); ylabel('J/S at the TX terminals / dB');
title(sprintf('Stage %s: J/S vs frequency, %g mm, TX %g dBm', stage, Rf.d, tx.P_dBm));
sv('JS_vs_frequency'); close;

%% pattern_horizontal, pattern_elevation (over the ground, both antennas, as in A5)
it = find(abs(T.F.th - pi/2) < 1e-9);  pp = T.F.ph * 180/pi;
figure('Position', [100 100 800 500]); grid on; hold on;
plot(pp, 10*log10(T.F.Greal(it, :)), pp, 10*log10(Kj.F.Greal(it, :)), 'LineWidth', 1.5);
xlim([0 360]); xlabel('azimuth \phi / deg (TX direction from the jammer = 180)'); ylabel('realized gain / dBi'); legend('TX', 'Jammer');
title(sprintf('Stage %s: horizontal-plane realized gain over the ground', stage));
sv('pattern_horizontal'); close;
figure('Position', [100 100 800 500]); grid on; hold on;
ib = find(abs(T.F.ph - pi) < 1e-9);
plot(T.F.th*180/pi, 10*log10(T.F.Greal(:, 1)), Kj.F.th*180/pi, 10*log10(Kj.F.Greal(:, ib)), 'LineWidth', 1.5);
xlim([0 90]); ylim([-30 rmax + 10]); xlabel('\theta / deg (from straight up)'); ylabel('realized gain / dBi');
legend('TX', 'Jammer (towards the TX, phi = 180)');
title(sprintf('Stage %s: elevation cut over the ground', stage));
sv('pattern_elevation'); close;

%% E-field map (0.1 m run)
h5 = fullfile(P0.root, Rf.tag, 'Ef_plane.h5');
if exist(h5, 'file')
  fd = ReadHDF5Dump(h5);  m = ReadHDF5Mesh(h5);
  E  = squeeze(sqrt(sum(abs(fd.FD.values{1}).^2, 4)));
  xs = m.lines{1};  ys = m.lines{2};  if max(abs(xs)) < 50, xs = xs / P0.unit; ys = ys / P0.unit; end
  figure('Position', [100 100 900 600]);
  pcolor(xs, ys, 20*log10(E.' / max(E(:)))); shading flat; axis equal tight;
  caxis([-60 0]); colorbar; hold on;
  plot(tx.feed(1), tx.feed(2), 'w^', Rf.d, 0, 'r*', 'MarkerSize', 10, 'LineWidth', 2);
  xlabel('x / mm'); ylabel('y / mm'); title(sprintf('Stage %s: |E| (dB) at 2.4 GHz, jammer driven (TX is the white triangle)', stage));
  sv('Efield_map'); close;
end

%% 08/09 whole scene pattern
if ~isempty(Fscene)
  F = Fscene;  nr = @(g) (max(g, rmin) - rmin) / (rmax - rmin);
  Ggr = 10*log10(max(F.Greal, 1e-3));  it = find(abs(F.th - pi/2) < 1e-9);  ib = find(abs(F.ph - pi) < 1e-9);
  figure('Position', [100 100 1100 520]);
  subplot(1, 2, 1); polar_axes(rmin, rmax, 10, 0, 360);
  r = nr(Ggr(it, :));  plot(r .* cos(F.ph), r .* sin(F.ph), 'b-', 'LineWidth', 2);
  title(sprintf('Scene, H-plane (horizon): max %.1f dBi (TX on the -x side)', max(Ggr(it, :))), 'FontSize', 9);
  subplot(1, 2, 2); polar_axes(rmin, rmax, 10, 0, 180);
  for s = [1 ib]
    r = nr(Ggr(:, s));  sg = 1 - 2*(s == ib);  plot(sg * r .* sin(F.th(:)), r .* cos(F.th(:)), 'r-', 'LineWidth', 1.5);
  end
  plot([-1 1], [0 0], 'k-', 'LineWidth', 1.5);
  title(sprintf('Scene, vertical cut over the ground (x-z plane); max %.1f dBi', max(Ggr(:))), 'FontSize', 9);
  text(0.5, 1.12, sprintf('Stage %s whole scene: jammer driven, TX connected to its receiver; realized gain in dBi', stage), 'Units', 'normalized', 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
  sv('08_pattern_polar_scene'); close;
  rr = max(Ggr - rmin, 0);  [PH, TH] = meshgrid([F.ph F.ph(1)+2*pi], F.th);  RR = [rr rr(:, 1)];
  X = RR .* sin(TH) .* cos(PH);  Y = RR .* sin(TH) .* sin(PH);  Z = RR .* cos(TH);
  figure('Position', [100 100 760 640]);
  surf(X, Y, Z, RR); shading interp; axis equal; colorbar; view(35, 22);
  xlabel('x'); ylabel('y'); zlabel('z (up)');
  title(sprintf('Stage %s whole scene over the ground: realized gain, colour = dBi + %g', stage, -rmin), 'FontSize', 9);
  sv('09_pattern_3d_scene'); close;
end

%% distance plots (A6 style) and 10 receiver power vs distance; two source models as in Stage A
d = [G.d] / 1000;  L = [G.coup];
src = struct('ch5', 10*log10(185e6 / rx.BW_Hz), 'cw24', 0);     % ch5: 27 dBm spread over 185 MHz
Jc = jm.P_dBm + L - rx.cable_loss_dB - src.cw24;  J5 = jm.P_dBm + L - rx.cable_loss_dB - src.ch5;
figure('Position', [100 100 800 500]); hold on; grid on;
semilogx(d, J5 - S_dBm, 'o-', d, Jc - S_dBm, 's-', 'LineWidth', 1.5); set(gca, 'XScale', 'log');
plot([min(d) max(d)], [P0.JS_target_dB P0.JS_target_dB], 'r--');
yl = ylim; plot([P0.lambda/(2*pi) P0.lambda/(2*pi)]/1000, yl, 'k:'); ylim(yl);
xlabel('TX to jammer distance / m'); ylabel('J/S at the TX terminals / dB');
legend('ch5 (185 MHz)', '2.4 GHz-only (20 MHz)', 'target', '\lambda/2\pi', 'Location', 'northeast');
title(sprintf('Stage %s: J/S vs distance, TX %g dBm', stage, tx.P_dBm));
sv('JS_vs_distance'); close;
figure('Position', [100 100 800 500]); grid on;
semilogx(d, L, 'o-', 'LineWidth', 1.5); set(gca, 'XScale', 'log');
xlabel('distance / m'); ylabel('coupling jammer feed to TX terminals / dB'); title(sprintf('Stage %s: coupling vs distance', stage));
sv('coupling_vs_distance'); close;
tot = @(a, b) 10*log10(10.^(a/10) + 10.^(b/10));
Sfin = Jc(find([G.d] == Rf.d, 1)) - P0.JS_target_dB;              % TX power that gives J/S = 10 dB at 0.1 m
figure('Position', [100 100 1500 480]);
SS = [S_dBm Sfin];
for pnl = 1:2
  Sx = SS(pnl);
  subplot(1, 3, pnl); hold on; grid on; set(gca, 'XScale', 'log');
  plot(d, Sx * ones(size(d)), 'b-', 'LineWidth', 2);
  plot(d, Jc, 'r--s', 'LineWidth', 1.2); plot(d, tot(Sx, Jc), 'k-o', 'LineWidth', 2);
  plot(d, J5, ':^', 'Color', [0.8 0.4 0], 'LineWidth', 1.2); plot(d, tot(Sx, J5), '-d', 'Color', [0.8 0.4 0], 'LineWidth', 1.2);
  plot(d, N * ones(size(d)), ':', 'Color', [0.5 0.5 0.5]);
  xlabel('TX to jammer distance / m'); ylabel('power at the receiver / dBm');
  title(sprintf('TX %.1f dBm: before and after the jammer', Sx + rx.cable_loss_dB));
  if pnl == 1, legend('before: wanted S only', 'jammer J (2.4 GHz-only)', 'after: S + J (2.4 GHz-only)', 'jammer J (ch5)', 'after: S + J (ch5)', 'noise floor', 'Location', 'southeast'); end
end
subplot(1, 3, 3); hold on; grid on; set(gca, 'XScale', 'log');
plot(d, L, 'o-', 'LineWidth', 2);
xlabel('TX to jammer distance / m'); ylabel('power gain jammer feed to TX terminals / dB'); title('Power gain (coupling) versus distance');
sv('10_receiver_power_vs_distance'); close;

%% comparison of all stages that have results
cmp = fullfile(P0.root, 'compare');  if ~exist(cmp, 'dir'), mkdir(cmp); end
st = {'A', 'B', 'C', 'D'};  B0 = stageA_baseline();  M = {};
for q = 1:numel(st)
  fq = fullfile(P0.root, ['stage' st{q}], ['summary_stage' st{q} '.mat']);
  if exist(fq, 'file'), Q = load(fq); M(end+1, :) = {st{q}, Q.R}; end %#ok<AGROW>
end
cl = lines(4);
figure('Position', [100 100 900 560]); hold on; grid on; set(gca, 'XScale', 'log');
plot(B0.d_mm/1000, B0.coup_dB, 'o--', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.2); lg = {'settled Stage A (whip on housing)'};
for q = 1:size(M, 1)
  Gq = M{q, 2}([M{q, 2}.ground]);  [~, o] = sort([Gq.d]);  Gq = Gq(o);
  plot([Gq.d]/1000, [Gq.coup], 's-', 'Color', cl(q, :), 'LineWidth', 2); lg{end+1} = ['Stage ' M{q, 1}]; %#ok<AGROW>
end
xlabel('TX to jammer distance / m'); ylabel('coupling jammer feed to TX terminals / dB'); legend(lg, 'Location', 'southwest');
title('Coupling vs distance, all stages (PEC ground, 2.4 GHz)');
print(gcf, fullfile(cmp, 'compare_coupling_vs_distance.png'), '-dpng', '-r110'); close;
figure('Position', [100 100 900 560]); hold on; grid on; set(gca, 'XScale', 'log'); lg = {};
plot(B0.d_mm/1000, B0.JS_dB, 'o--', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.2); lg = {'settled Stage A'};
for q = 1:size(M, 1)
  Gq = M{q, 2}([M{q, 2}.ground]);  [~, o] = sort([Gq.d]);  Gq = Gq(o);
  plot([Gq.d]/1000, jm.P_dBm + [Gq.coup] - S_dBm, 's-', 'Color', cl(q, :), 'LineWidth', 2); lg{end+1} = ['Stage ' M{q, 1}]; %#ok<AGROW>
end
plot([0.08 2.2], [10 10], 'r--'); plot([0.08 2.2], [7 7], 'k:'); lg = [lg {'target +10 dB', 'ceiling +7 dB'}];
xlabel('TX to jammer distance / m'); ylabel('J/S at the TX terminals, TX 20 dBm / dB'); legend(lg, 'Location', 'southwest');
title('J/S vs distance, all stages');
print(gcf, fullfile(cmp, 'compare_JS_vs_distance.png'), '-dpng', '-r110'); close;
figure('Position', [100 100 900 560]); hold on; grid on; lg = {};
for q = 1:size(M, 1)
  Gq = M{q, 2}([M{q, 2}.ground]);  k = find([Gq.d] == 100, 1);
  if ~isempty(k), plot(f, dB(Gq(k).s21), 'Color', cl(q, :), 'LineWidth', 2); lg{end+1} = ['Stage ' M{q, 1} ', 0.1 m']; end %#ok<AGROW>
end
for q = 1:size(M, 1)
  Gq = M{q, 2}([M{q, 2}.ground]);  k = find([Gq.d] == 1000, 1);
  if ~isempty(k), plot(f, dB(Gq(k).s21), '--', 'Color', cl(q, :), 'LineWidth', 1.3); lg{end+1} = ['Stage ' M{q, 1} ', 1 m']; end %#ok<AGROW>
end
yl = ylim; plot([2.4 2.4], yl, 'k:'); xlabel('f / GHz'); ylabel('coupling jammer feed to TX terminals / dB');
legend(lg, 'Location', 'southwest'); title('Coupling vs frequency, all stages');
print(gcf, fullfile(cmp, 'compare_coupling_vs_frequency.png'), '-dpng', '-r110'); close;

%% index page
pics = dir(fullfile(pd, '*.png'));
fid = fopen(fullfile(out, 'index.html'), 'w');
fprintf(fid, '<!doctype html><meta charset="utf-8"><title>Stage %s results</title>\n<style>body{font:15px system-ui;max-width:1100px;margin:20px auto;padding:0 16px}img{max-width:100%%;border:1px solid #ccc}figure{margin:24px 0}pre{background:#f4f4f4;padding:10px;overflow:auto}</style>\n<h1>Stage %s results: %s</h1>\n', stage, stage, jm.name);
rep = fullfile(out, ['report_stage' stage '.txt']);
if exist(rep, 'file'), fprintf(fid, '<h2>Summary</h2><pre>%s</pre>\n', strrep(strrep(fileread(rep), '&', '&amp;'), '<', '&lt;')); end
for k = 1:numel(pics), fprintf(fid, '<figure><img src="plots/%s"><figcaption>%s</figcaption></figure>\n', pics(k).name, pics(k).name); end
cps = dir(fullfile(cmp, '*.png'));
for k = 1:numel(cps), fprintf(fid, '<figure><img src="../compare/%s"><figcaption>%s</figcaption></figure>\n', cps(k).name, cps(k).name); end
fclose(fid);
fprintf('Pictures in %s, open %s\n', pd, fullfile(out, 'index.html'));
end
