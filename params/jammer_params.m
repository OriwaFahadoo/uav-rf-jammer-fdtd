function J = jammer_params(stage)
% JAMMER_PARAMS  The jammer antenna for each stage. This is the ONLY thing that changes between stages.
%
%   Stage A = Case 3 : bare omni, a vertical lambda/4 whip on a small square ground plate
%   Stage B = Case 2 : the same omni inside a 90 degree corner reflector (2.4 GHz "high" reflector of the
%                      case figure: apex -> whip S 60 mm, side L 200 mm, height H 150 mm)
%   Stage C = Case 4 : RFSPACE TSA600 tapered-slot (Vivaldi) antenna, board vertical (V-pol), aimed at the TX
%   Stage D = Stage C + reflector : the TSA600 with a 90 degree corner reflector behind its back edge, sized for
%                      the 330 x 240 mm board. Variants D1..D3 try sizes; 'D' is the one picked.
%   'BABS'           : the earlier Stage B idea (omni + graded absorber behind it), kept for reference only
%   'A0'             : the old Stage A jammer (JH-HB8 whip on its 45 x 75 x 130 mm housing), only to check
%                      that this code reproduces the settled Stage A numbers
%
% Case 1 (omni + reflector -> TSA600) is the lab's gain calibration. Here it is the antenna-alone free-space
% runs of the Stage B and Stage C antennas (C1_antenna_check(..., false)): their gains and the reflector's delta.
%
% The jammer always sits on the +x axis, at the TX height, and directional antennas aim at -x (towards the TX).
% Distance d (set in case_params) = TX feed to the jammer's radiating element:
%   omni / omni + reflector : to the whip;   TSA600 (+ reflector) : to the mouth (front edge) of the board.
% Power: 30 dBm at the port (J.P_dBm below), all inside the 20 MHz victim channel. The earlier runs used 27 dBm;
% the reference jammer datasheet gives about 27 dBm for its 2.4 GHz channel.

if nargin < 1, stage = 'A'; end
J.stage  = upper(stage);
J.P_dBm  = 30;   % V2: jammer port power 30 dBm (real IX channel power); was 27
J.BW_Hz  = 20e6;
J.R      = 50;
J.height = 500;                 % feed / centre height above the ground (mm), same as the TX

% the bare omni of Case 3 (also the element of Stage B)
omni.type   = 'omni';
omni.L      = 24.1;             % whip length above the feed gap (mm); lambda/4 = 31.2 mm. Tuned in C1.
omni.radius = 1;                % whip radius (mm)
omni.gap    = 2;                % feed gap plate -> whip (mm), 50 ohm lumped port
omni.plate  = 50;               % square ground plate side (mm), "small ground plane"; fits inside the corner reflector
omni.res    = 1;

switch J.stage
  case 'A'
    J.name = 'Case 3 bare omni (lambda/4 whip on a 50 mm plate)';
    J.ant  = omni;
  case 'BABS'
    J.name = 'omni + absorber behind it (earlier Stage B idea, reference only)';
    J.ant  = omni;
    % graded lossy block (stand-in for the 30 cm pyramidal absorber of the case box), behind the whip (+x)
    J.absorber.gap    = 100;                         % whip -> absorber front face (mm)
    J.absorber.size   = [400 400];                   % width (y) x height (z), mm
    J.absorber.t      = [60 60 60 60 60];            % layers front -> back (mm), 300 mm in total
    J.absorber.epsR   = [1.2 1.2 1.2 1.2 1.2];
    J.absorber.kappa  = [0.007 0.02 0.05 0.12 0.27]; % S/m, increasing into the block (eps'' 0.05 -> 2 at 2.4 GHz)
  case {'C', 'D', 'D1', 'D2', 'D3'}
    J.name = 'Case 4 RFSPACE TSA600 Vivaldi (330 x 240 mm, 11 dBi @ 2.4 GHz datasheet)';
    t.type    = 'tsa600';
    t.Lb      = 330;            % board length (mm), datasheet
    t.Wb      = 240;            % board height = aperture width (mm), datasheet
    t.Lt      = 280;            % taper length throat -> mouth (mm)  [tuned]
    t.w0      = 2;              % slot width at the throat (mm)       [assumed]
    t.Wm      = 230;            % slot opening at the mouth (mm), 5 mm metal left at each edge [tuned: 10.5 dBi]
    t.rc      = 12;             % radius of the circular slot cavity behind the throat (mm) [assumed]
    t.stub    = 6;              % slot length throat -> cavity (mm)   [assumed]
    t.res     = 2;              % mesh on the board (mm)
    t.gain_ds = 11;             % datasheet gain at 2.4 GHz (dBi)
    t.vswr_ds = 1.03;           % datasheet VSWR at 2.45 GHz
    J.ant = t;
    % the bare slot has Zin ~ 125 ohm; the real board has a balun matched to 50 ohm (VSWR 1.03 @ 2.45 GHz).
    % That balun is modelled as an ideal lossless transformer: port impedance = slot impedance.
    J.R = 125;
    J.mesher = 'grade';         % fine board mesh: use lib/grade_mesh (SmoothMesh is too slow here)
    if J.stage(1) == 'D'
      % corner reflector behind the board's back edge (apex S behind it), opening towards the TX.
      % The case-figure reflector (L 200, H 150) is smaller than the board, so it is scaled up.
      %            S    L    H        variant
      V = struct('D1', [60 300 300], 'D2', [60 400 300], 'D3', [120 400 300]);
      if strcmp(J.stage, 'D'), v = V.D3; else, v = V.(J.stage); end   % 'D' = chosen variant (set after C1)
      J.name = sprintf('TSA600 + 90 deg corner reflector behind it (S %d, L %d, H %d mm)', v);
      % mesh on the reflector plates (mm): 2 = full resolution (default here), 4 or 6 = coarser and faster.
      % Set it from Terminal:  D_RES=4 ./run_stage.sh D
      rres = str2double(getenv('D_RES')); if isnan(rres), rres = 2; end
      J.corner = struct('S', v(1), 'L', v(2), 'H', v(3), 't', 3, 'res', rres, 'ref', 'back');
    end
  case 'B'
    J.name = 'Case 2 omni + 90 deg corner reflector (high: S 60, L 200, H 150 mm)';
    J.ant  = omni;
    J.corner.S = 60;            % apex -> whip (mm), case figure "high reflector" (channels 4,2,3,5,7)
    J.corner.L = 200;           % side length (mm)
    J.corner.H = 150;           % plate height (mm)
    J.corner.t = 3;             % plate thickness in the model (mm)
    J.corner.res = 2;           % mesh on the plates (mm)
    J.corner.ref = 'element';   % S is measured from the whip
    J.mesher = 'grade';
  case 'AG'
    J.name = 'Stage A omni meshed with lib/grade_mesh (check of the mesher used for C and D)';
    J.ant = omni;  J.mesher = 'grade';
  case 'A0'
    J.name = 'old Stage A jammer: JH-HB8 whip on its housing (check only)';
    J.ant = struct('type', 'whip', 'housing', [45 75 130], 'L', 24.8, 'gap', 2, 'radius', 1, ...
                   'collar', [2 6], 'res', 1);
  otherwise
    error('unknown stage %s (use A, B, C, D, D1-D3, BABS or A0)', stage);
end
end
