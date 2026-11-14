import csv, sys, os
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt
src, out = sys.argv[1], sys.argv[2]
NAMES = {"A": "A: bare omni whip", "B": "B: whip + corner reflector", "C": "C: TSA600 Vivaldi", "D": "D: TSA600 + corner reflector"}
COL = {"A": "#1f77b4", "B": "#2ca02c", "C": "#d62728", "D": "#9467bd"}
data = {}
for s in "ABCD":
    rows = list(csv.DictReader(open(f"{src}/stage{s}/stage{s}_table.csv")))
    data[s] = rows
def panel(ax, key, ylabel, title, target=None):
    for s, rows in data.items():
        g = sorted([r for r in rows if r["ground"] == "1"], key=lambda r: float(r["d_mm"]))
        f = [r for r in rows if r["ground"] == "0"]
        ax.plot([float(r["d_mm"])/1000 for r in g], [float(r[key]) for r in g], "o-", color=COL[s], lw=1.8, label=NAMES[s])
        ax.plot([float(r["d_mm"])/1000 for r in f], [float(r[key]) for r in f], "D", mfc="white", color=COL[s], ms=7)
    if target is not None:
        ax.axhline(target, color="k", ls="--", lw=1)
    ax.set_xscale("log"); ax.set_xticks([0.1, 0.2, 0.5, 1, 2]); ax.set_xticklabels(["0.1", "0.2", "0.5", "1", "2"])
    ax.set_xlabel("TX to jammer distance (m)"); ax.set_ylabel(ylabel); ax.set_title(title, fontsize=11)
    ax.grid(True, which="both", alpha=0.3)
fig, axs = plt.subplots(1, 2, figsize=(12, 4.6))
panel(axs[0], "coupling_dB", "Coupling, jammer feed to TX terminals (dB)", "Coupling at 2.4 GHz")
panel(axs[1], "JS_dB", "J/S (dB)", "J/S at the TX (jammer 30 dBm, TX 20 dBm)", target=10)
axs[0].legend(fontsize=9, loc="lower left")
fig.text(0.5, -0.02, "Filled circles: over the PEC ground. Open diamonds: free space at 1.01 m. Dashed line: J/S = 10 dB criterion.", ha="center", fontsize=9)
fig.tight_layout()
fig.savefig(f"{out}/compare_coupling_JS_all_stages.png", dpi=150, bbox_inches="tight")
for key, ylabel, title, name, tgt in [("coupling_dB", "Coupling, jammer feed to TX terminals (dB)", "Coupling vs distance, all stages (PEC ground, 2.4 GHz)", "compare_coupling_vs_distance.png", None),
                                      ("JS_dB", "J/S (dB)", "J/S vs distance, all stages (jammer 30 dBm, TX 20 dBm)", "compare_JS_vs_distance.png", 10)]:
    fig, ax = plt.subplots(figsize=(8, 5)); panel(ax, key, ylabel, title, tgt); ax.legend(fontsize=9, loc="lower left")
    fig.tight_layout(); fig.savefig(f"{out}/{name}", dpi=130)

# coupling vs frequency (S21 columns of the spectra files = coupling with the perfect-match correction)
fig, axs = plt.subplots(1, 2, figsize=(12, 4.6), sharey=True)
for ax, d, lab in [(axs[0], "d100_pec", "0.1 m"), (axs[1], "d1000_pec", "1 m")]:
    for s in "ABCD":
        p = f"{src}/stage{s}/stage{s}_spectra.csv"
        if not os.path.exists(p): continue
        rows = list(csv.DictReader(open(p)))
        ax.plot([float(r["f_GHz"]) for r in rows], [float(r["S21_" + d]) for r in rows], color=COL[s], lw=1.6, label=NAMES[s])
    ax.axvline(2.4, color="k", ls=":", lw=1)
    ax.set_xlabel("Frequency (GHz)"); ax.set_title(f"Coupling vs frequency, d = {lab}, over the PEC ground", fontsize=11)
    ax.grid(True, alpha=0.3)
axs[0].set_ylabel("Coupling, jammer feed to TX terminals (dB)"); axs[0].legend(fontsize=9, loc="lower left")
fig.tight_layout(); fig.savefig(f"{out}/compare_coupling_vs_frequency.png", dpi=130)
