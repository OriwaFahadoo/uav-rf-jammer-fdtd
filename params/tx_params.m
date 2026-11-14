function A = tx_params()
% TX_PARAMS  Victim TX, FROZEN at the settled Stage A design. Do not change per stage:
% the only thing that changes from stage to stage is the jammer (params/jammer_params.m).
% Values from stageA_geometry/dimensions.txt and stageA_final/summary_stageA.txt.

A.name   = 'TX (2.4 GHz Wi-Fi, settled in Stage A)';
A.type   = 'dipole';   % vertical half-wave dipole, two round rods with a feed gap
A.pos    = [0 0];      % x y (mm): the TX sits at the origin
A.height = 500;        % feed height above the PEC ground (mm)
A.L      = 52.2;       % tip-to-tip length (mm), tuned in Stage A (S11 -16 dB at 2.4 GHz). All stored results use this length. VERT2450 datasheet length (108 mm) is an alternative, not yet simulated.
A.gap    = 2;          % feed gap (mm), 50 ohm lumped port
A.radius = 1;          % rod radius (mm)
A.res    = 1;          % mesh cell around the rod (mm)
A.R      = 50;
A.P_dBm  = 20;         % TX power into its feed (100 mW) = the "S" of J/S
A.BW_Hz  = 20e6;       % one 20 MHz Wi-Fi channel
end
