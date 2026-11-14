function B = stageA_baseline()
% STAGEA_BASELINE  The settled Stage A results (old jammer: JH-HB8 whip on its housing), for comparison.
% Source: stageA_sweep/report_sweep.txt and stageA_final/summary_stageA.txt (27 dBm in the 20 MHz channel).
B.d_mm     = [50 100 250 500 1000 2000];
B.coup_dB  = [-16.3 -20.7 -28.9 -32.2 -46.2 -42.5];
B.JS_dB    = 27 + B.coup_dB - 20;            % TX at 20 dBm
B.name     = 'settled Stage A (whip on housing)';
% Case-figure predictions at 2.4 GHz, 1.01 m, free space (absorber box), port to port:
B.case3_dB = -36.1;   % Case 3: omni (2 dBi) -> omni (2 dBi), FSPL 40.1 dB
B.case4_dB = -27.1;   % Case 4: TSA600 (11 dBi) -> omni (2 dBi)
B.case2_dB = -27.1;   % Case 2: omni + corner reflector (11 dBi) -> omni (2 dBi)
end
