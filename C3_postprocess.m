function C3_postprocess(stage)
% C3_POSTPROCESS  Numbers and pictures for one stage: jammer S11, coupling jammer -> TX terminals,
% J, S, J/S at the receiver, TX power for J/S = +10 dB, compared with the settled Stage A and the case figure.
% Writes results/stage<X>/report_stage<X>.txt, summary_stage<X>.mat and PNG figures.
if nargin < 1, stage = 'A'; end
setup_paths;
if exist('OCTAVE_VERSION', 'builtin'), graphics_toolkit('gnuplot'); end
stage = upper(stage);
P0 = case_params(stage, 100, true);
B  = stageA_baseline();
dB = @(x) 20*log10(abs(x));
out = fullfile(P0.root, ['stage' stage]);
if ~exist(out, 'dir'), mkdir(out); end

%% antenna-alone checks
K = struct();
for g = {'pec', 'free'}
  f = fullfile(P0.root, ['check_jam' stage '_' g{1}], 'check.mat');
  if exist(f, 'file'), K.(g{1}) = load(f); end
end
ftx = fullfile(P0.root, 'check_tx_pec', 'check.mat');
if exist(ftx, 'file'), T = load(ftx); else, T = []; end

%% scene runs
R = struct('tag', {}, 'd', {}, 'ground', {}, 's11', {}, 's21', {}, 'coup', {}, 'coup_raw', {}, 's11_0', {}, 'zin_0', {});
for ground = [true false]
  for d = [50 100 250 500 1000 1010 2000]
    P = case_params(stage, d, ground);
    path = fullfile(P.root, P.tag);
    if ~exist(fullfile(path, 'done.txt'), 'file'), continue; end
    [~, ~, port, ~, info] = build_scene(P, 'jam');
    port{1} = calcPort(port{1}, path, P.freq, 'RefImpedance', P.tx.R);
    port{2} = calcPort(port{2}, path, P.freq, 'RefImpedance', P.jam.R);
    r = port_results(port, info.active, P);
    % V2: perfect impedance match assumed. The simulated S21 is power-normalised, so it contains the mismatch loss of the
    % jammer port (1-|S11_jam|^2) and of the TX port (1-|S11_TX|^2); both are removed (raw S21 stays in coup_raw).
    if ~isempty(r.s21)
      mmj = -10*log10(1 - abs(r.s11(:)).^2);
      if ~isempty(T), mmt = -10*log10(1 - abs(T.r.s11(:)).^2); else, mmt = zeros(size(mmj)); end
      s21raw = r.s21;  r.s21 = reshape(r.s21(:) .* 10.^((mmj + mmt) / 20), size(r.s21));
    end
    k = numel(R) + 1;
    R(k).tag = P.tag; R(k).d = d; R(k).ground = ground; R(k).s11 = r.s11; R(k).s21 = r.s21;
    R(k).coup_raw = dB(s21raw(r.i0));  R(k).coup = dB(r.s21(r.i0)); R(k).s11_0 = dB(r.s11(r.i0)); R(k).zin_0 = r.zin(r.i0);
  end
end
if isempty(R), error('No finished scene runs for stage %s. Run C2_run_scene(''%s'') first.', stage, stage); end
i0 = find(abs(P0.freq - P0.f0) == min(abs(P0.freq - P0.f0)), 1);

%% link budget (TX at 20 dBm, jammer 30 dBm (V2) all in the 20 MHz channel, as in the settled Stage A)
tx = P0.tx;  jm = P0.jam;
rep = fullfile(out, ['report_stage' stage '.txt']);
fid = fopen(rep, 'w');
if fid < 0, error('Cannot write %s', rep); end
pr = @(varargin) tee(fid, varargin{:});    % print to the screen and the report file
pr('===== Stage %s @ 2.400 GHz: %s =====\n', stage, jm.name);
pr('TX frozen at the settled Stage A design: %.1f mm dipole, %d mm high, %g dBm; receiver wired to its terminals\n', tx.L, tx.height, tx.P_dBm);
pr('Jammer: %g dBm, all inside the 20 MHz channel. J/S target >= %g dB.\n', jm.P_dBm, P0.JS_target_dB);
pr('V2: perfect impedance match assumed (mismatch loss of the jammer and TX ports removed from S21); jammer port power 30 dBm.\n\n');
if ~isempty(T)
  pr('TX alone (PEC)     : S11 %6.1f dB, Zin %5.1f%+5.1fj ohm, max realized gain %5.2f dBi\n', ...
     dB(T.r.s11(i0)), real(T.r.zin(i0)), imag(T.r.zin(i0)), T.F.Gmax_dBi);
end
for g = {'pec', 'free'}
  if isfield(K, g{1})
    k = K.(g{1});
    pr('Jammer alone (%-4s): f_res %.3f GHz, S11 %6.1f dB, Zin %5.1f%+5.1fj ohm, max realized gain %5.2f dBi, towards the TX %5.2f dBi, back %5.2f dBi (free-space part)\n', ...
      g{1}, k.r.f_res/1e9, dB(k.r.s11(i0)), real(k.r.zin(i0)), imag(k.r.zin(i0)), k.F.Gmax_dBi, k.F.G_bore_fs_dBi, k.F.G_back_fs_dBi);
  end
end
pr('\n   d/mm  ground | S11 jam  coupling |   J dBm   J/S dB | P_TX for +10 dB | settled A coupling  J/S | change\n');
for k = 1:numel(R)
  J = jm.P_dBm + R(k).coup;  JS = J - tx.P_dBm;  Pneed = J - P0.JS_target_dB;
  ib = find(B.d_mm == R(k).d);
  if R(k).ground, gs = 'PEC '; else, gs = 'free'; end
  if ~isempty(ib) && R(k).ground
    pr('  %5d  %s   | %6.1f   %6.1f   |  %6.1f   %6.1f |  %8.1f dBm   |   %6.1f       %6.1f | %+5.1f dB\n', ...
      R(k).d, gs, R(k).s11_0, R(k).coup, J, JS, Pneed, B.coup_dB(ib), B.JS_dB(ib), R(k).coup - B.coup_dB(ib));
  else
    pr('  %5d  %s   | %6.1f   %6.1f   |  %6.1f   %6.1f |  %8.1f dBm   |\n', R(k).d, gs, R(k).s11_0, R(k).coup, J, JS, Pneed);
  end
end
pr('\nCeiling: J/S can not exceed %g - %g = %g dB however good the coupling.\n', jm.P_dBm, tx.P_dBm, jm.P_dBm - tx.P_dBm);
fr = R(~[R.ground]);
if ~isempty(fr)
  switch stage
    case {'A', 'BABS', 'A0'}, cf = B.case3_dB; cn = 'Case 3';
    case 'B', cf = B.case2_dB; cn = 'Case 2';
    case 'C', cf = B.case4_dB; cn = 'Case 4';
    otherwise, cf = B.case4_dB + 2; cn = 'Case 4 + 2 dB (rule of thumb)';
  end
  pr('Case check, free space at %d mm: simulated %.1f dB vs %s figure %.1f dB (2 dBi omni receiver; our TX dipole is %.1f dBi)\n', ...
     fr(1).d, fr(1).coup, cn, cf, 2.15);
end
fclose(fid);
save(fullfile(out, ['summary_stage' stage '.mat']), 'R', 'K', 'B', 'P0');
% tables for plot_cases.py (and Excel)
fid = fopen(fullfile(out, ['stage' stage '_table.csv']), 'w');
fprintf(fid, 'stage,d_mm,ground,S11_jam_dB,coupling_dB,J_dBm,S_dBm,JS_dB,P_TX_for_10dB_dBm\n');
for k = 1:numel(R)
  J = jm.P_dBm + R(k).coup;
  fprintf(fid, '%s,%d,%d,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f\n', stage, R(k).d, R(k).ground, R(k).s11_0, R(k).coup, J, tx.P_dBm, J - tx.P_dBm, J - P0.JS_target_dB);
end
fclose(fid);
fid = fopen(fullfile(out, ['stage' stage '_spectra.csv']), 'w');
hdr = 'f_GHz';  M = P0.freq(:) / 1e9;
if isfield(K, 'pec'), hdr = [hdr ',S11_alone_pec']; M = [M dB(K.pec.r.s11(:))]; end
if isfield(K, 'free'), hdr = [hdr ',S11_alone_free']; M = [M dB(K.free.r.s11(:))]; end
if ~isempty(T), hdr = [hdr ',S11_tx']; M = [M dB(T.r.s11(:))]; end
for k = 1:numel(R)
  if R(k).ground, gs = 'pec'; else, gs = 'free'; end
  hdr = [hdr sprintf(',S11_d%d_%s,S21_d%d_%s', R(k).d, gs, R(k).d, gs)];
  M = [M dB(R(k).s11(:)) dB(R(k).s21(:))];
end
fprintf(fid, '%s\n', hdr);
fprintf(fid, [repmat('%.4f,', 1, size(M,2)-1) '%.4f\n'], M');
fclose(fid);
% horizontal cut of the jammer alone (free-space part), for the polar plot
for g = {'pec', 'free'}
  if isfield(K, g{1})
    [~, it] = min(abs(K.(g{1}).F.th - pi/2));
    fid = fopen(fullfile(out, sprintf('stage%s_pattern_%s.csv', stage, g{1})), 'w');
    fprintf(fid, 'phi_deg,G_fs_dBi,G_dBi_horizon\n');
    fprintf(fid, '%.1f,%.3f,%.3f\n', [K.(g{1}).F.ph(:)*180/pi 10*log10(K.(g{1}).F.Greal_fs(it,:)') 10*log10(K.(g{1}).F.Greal(it,:)')]');
    fclose(fid);
  end
end

%% figures
f = P0.freq / 1e9;  G = R([R.ground]);
h = figure('visible', 'off'); hold on; grid on;
leg = {};
if isfield(K, 'pec'), plot(f, dB(K.pec.r.s11), 'k-', 'LineWidth', 2); leg{end+1} = 'jammer alone'; end
for k = 1:numel(G), plot(f, dB(G(k).s11), 'LineWidth', 1.2); leg{end+1} = sprintf('in scene, d = %d mm', G(k).d); end
if ~isempty(T), plot(f, dB(T.r.s11), 'k--', 'LineWidth', 1.5); leg{end+1} = 'TX (frozen)'; end
plot([2.4 2.4], [-30 0], 'k:'); ylim([-30 0]); xlabel('f / GHz'); ylabel('S11 / dB');
title(sprintf('Stage %s: jammer and TX match', stage)); legend(leg, 'Location', 'southwest');
print(h, fullfile(out, sprintf('stage%s_S11.png', stage)), '-dpng', '-r110'); close(h);

h = figure('visible', 'off'); hold on; grid on; leg = {};
for k = 1:numel(R)
  if R(k).ground, ls = '-'; s = 'PEC'; else, ls = '--'; s = 'free space'; end
  plot(f, dB(R(k).s21), ls, 'LineWidth', 1.3); leg{end+1} = sprintf('d = %d mm, %s', R(k).d, s);
end
plot([2.4 2.4], [-60 0], 'k:'); xlabel('f / GHz'); ylabel('coupling jammer -> TX terminals / dB');
title(sprintf('Stage %s: coupling vs frequency', stage)); legend(leg, 'Location', 'southwest');
print(h, fullfile(out, sprintf('stage%s_coupling_vs_f.png', stage)), '-dpng', '-r110'); close(h);

h = figure('visible', 'off');
subplot(2,1,1); hold on; grid on;
semilogx(B.d_mm, B.coup_dB, 'ko--', 'LineWidth', 1.2);
semilogx([G.d], [G.coup], 'bs-', 'LineWidth', 1.8, 'MarkerFaceColor', 'b');
if ~isempty(fr), semilogx(fr(1).d, fr(1).coup, 'r^', 'MarkerSize', 8, 'MarkerFaceColor', 'r'); semilogx(1010, cf, 'rx', 'MarkerSize', 10, 'LineWidth', 2); end
set(gca, 'XScale', 'log'); ylabel('coupling / dB'); title(sprintf('Stage %s vs settled Stage A', stage));
lg = {'settled Stage A', sprintf('Stage %s (PEC ground)', stage)};
if ~isempty(fr), lg = [lg {'free space (sim)', [cn ' figure']}]; end
legend(lg, 'Location', 'northeast');
subplot(2,1,2); hold on; grid on;
semilogx(B.d_mm, B.JS_dB, 'ko--', 'LineWidth', 1.2);
semilogx([G.d], jm.P_dBm + [G.coup] - tx.P_dBm, 'bs-', 'LineWidth', 1.8, 'MarkerFaceColor', 'b');
semilogx([40 2500], [10 10], 'r:', 'LineWidth', 1.5);
semilogx([40 2500], [7 7], 'k:');
set(gca, 'XScale', 'log'); xlabel('distance TX -> jammer / mm'); ylabel('J/S at TX 20 dBm / dB');
legend({'settled Stage A', sprintf('Stage %s', stage), 'target +10 dB', 'ceiling +7 dB'}, 'Location', 'northeast');
print(h, fullfile(out, sprintf('stage%s_coupling_JS_vs_distance.png', stage)), '-dpng', '-r110'); close(h);

if isfield(K, 'free') || isfield(K, 'pec')
  if isfield(K, 'free'), k = K.free; else, k = K.pec; end
  [~, it] = min(abs(k.F.th - pi/2));
  gph = 10*log10(k.F.Greal_fs(it, :));  ph = k.F.ph;
  h = figure('visible', 'off');
  rr = max(gph + 30, 0);
  polar([ph ph(1)], [rr rr(1)], 'b-'); hold on;
  title(sprintf('Stage %s jammer alone, horizontal cut, free space (0 dB ring = %.0f dBi; TX is at 180 deg). Max %.1f dBi', ...
        stage, -30, max(gph)));
  print(h, fullfile(out, sprintf('stage%s_pattern_horizontal.png', stage)), '-dpng', '-r110'); close(h);
end

% |E| map at 2.4 GHz on the horizontal feed plane, closest distance over the ground
[~, k] = min([G.d]);
fe = fullfile(P0.root, G(k).tag, 'Ef_plane.h5');
if exist(fe, 'file')
  [fld, msh] = ReadHDF5Dump(fe);
  E = fld.FD.values{1};  Em = squeeze(sqrt(sum(abs(E).^2, 4)));
  x = msh.lines{1} * 1e3;  y = msh.lines{2} * 1e3;     % lines are in m in the dump
  if max(abs(x)) < 10, x = x * 1e3; y = y * 1e3; end
  h = figure('visible', 'off');
  pcolor(x, y, 20*log10(Em' / max(Em(:)))); shading flat; axis equal tight; caxis([-50 0]); colorbar;
  hold on; plot(0, 0, 'wo', 'MarkerSize', 8, 'LineWidth', 2); plot(G(k).d, 0, 'w^', 'MarkerSize', 8, 'LineWidth', 2);
  xlabel('x / mm'); ylabel('y / mm');
  title(sprintf('Stage %s, |E| at 2.4 GHz, jammer driven, d = %d mm (dB, o = TX, ^ = jammer)', stage, G(k).d));
  print(h, fullfile(out, sprintf('stage%s_Efield_map.png', stage)), '-dpng', '-r110'); close(h);
end
fprintf('\nWritten: %s\n', out);
end

function tee(fid, varargin)
% print the same text to the command window and to the report file (MATLAB and Octave)
fprintf(1, varargin{:});
fprintf(fid, varargin{:});
end
