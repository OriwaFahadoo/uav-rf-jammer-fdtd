# Compare_all: what is in this folder (plain words)

> Note: `JS_vs_TXpower` and `far_distance_friis` were computed earlier with a 27 dBm jammer. The pattern files
> (`pattern3d_free_*`, `pattern_summary_free.csv`) do not depend on source power. For current coupling and J/S at
> 30 dBm see `results/stage<X>/stage<X>_table.csv` and `results/compare/`.

All numbers come from your Mac results (`StageA updated`, `Stage B`, `Stage C`, `Stage D`). Nothing was re-simulated.
Jammer power 27 dBm. J/S = 27 dBm + coupling - TX power. The target is J/S of +10 dB or more.

## 1. J/S for different TX powers
* `JS_vs_TXpower.png`: four panels, one per TX power (20, 10, 0, -10 dBm). In each panel there is one line per stage
  (A omni, B omni + corner reflector, C TSA600, D TSA600 + corner reflector), J/S against distance. The dashed line is the +10 dB target.
  A line that is above the dashed line means the jammer wins by 10 dB or more. Open diamonds are the free-space runs at 1.01 m.
* `JS_vs_TXpower.csv`: the same numbers, plus the TX power that would give exactly +10 dB.
* Stage A is nearly the same at 1 m and 2 m (-39.8 dB both): that is what the existing Stage A runs gave over the metal ground.

## 2. Longer distances (3 m and 5 m): CALCULATED, not simulated
* `far_distance_friis.png` / `far_distance_friis.csv`.
* Method: the standard free-space (Friis) formula, coupling = G_jammer(towards the TX) + G_TX (2.04 dBi) + 20 log10(wavelength / (4 pi d)).
  The jammer gain is the simulated free-space gain towards the TX. The result is then shifted by one fixed number per stage,
  the difference between the simulated free-space coupling at 1.01 m and the formula at 1.01 m. That number is the "offset" in the csv:
  A -0.50 dB, B -0.22 dB, C -1.53 dB, D -0.75 dB.
* These are free-space values. There is no ground reflection in them, so they are not comparable one-to-one with the over-ground runs at 0.1 to 2 m.
* The formula is only strictly valid in the far field, beyond 2 D^2 / wavelength (wavelength 125 mm). For the TSA600 board (D about 0.33 m)
  that is about 1.7 m. For the corner reflector of D (400 mm sides, opening about 0.57 m) it is about 5 m, so even 3 m is still inside it
  for Stage D and the 3 m and 5 m values for D are the least certain. Stage B (reflector opening about 0.28 m) is about 1.3 m.

## 3. Clean 3D pattern of each jammer, in FREE SPACE
* `pattern3d_free_stageA.png` ... `stageD.png`: left, a 3D picture of the realized gain of the jammer alone (colour = dBi). The surface is cut off 20 dB
  below the peak so the main beam is clear. The arrow shows the direction of the TX. Right, two cuts through the pattern with 0 degrees pointing at the TX:
  the vertical cut (x-z plane, called E-plane here because the antennas are vertically polarised) and the horizontal cut (x-y plane, H-plane),
  with the half-power beamwidth (HPBW) in the legend and the gain towards the TX and the front-to-back ratio in the title.
* These are **free space** on purpose. The over-ground pattern has extra lobes from the metal ground (the "image" of the antenna).
* `pattern3d_free_stageA.vtk` ... `stageD.vtk`: the same 3D surface for ParaView (colour by `Gain_dBi`; radius is 0.5 m at the peak).
* `pattern_summary_free.csv`: peak gain, gain towards the TX, front-to-back, HPBW (E and H plane).
* Each stage's results folder also has its own copy in `results/stageX/pattern3d_free/`.

## Caution
The A omni whip has no front or back (front-to-back 0 dB, horizontal HPBW 360 degrees), so its "3D pattern" is a doughnut.
