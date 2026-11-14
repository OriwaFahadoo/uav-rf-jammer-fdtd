"""Clean figures for the stages, from the CSV files written by C3_postprocess.

    python3 plot_cases.py <results folder> A [B C D]

Writes <results>/stage<X>/fig_*.png and, with several stages, <results>/compare/fig_compare_*.png.
"""
import csv, os, sys
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

BASE_D = [50, 100, 250, 500, 1000, 2000]
BASE_C = [-16.3, -20.7, -28.9, -32.2, -46.2, -42.5]
CASE = {"A": ("Case 3", -36.1), "B": ("Case 2", -27.1), "C": ("Case 4", -27.1), "BABS": ("Case 3", -36.1)}
NAMES = {"A": "A: bare omni (Case 3)", "B": "B: omni + corner reflector (Case 2)", "C": "C: TSA600 (Case 4)",
         "D": "D: TSA600 + corner reflector", "BABS": "omni + absorber (reference)", "A0": "settled Stage A jammer"}
COL = {"A": "#1f77b4", "B": "#2ca02c", "C": "#d62728", "D": "#9467bd"}
PJ, PS = 30.0, 20.0   # V2: jammer 30 dBm


def table(root, st):
    rows = list(csv.DictReader(open(os.path.join(root, f"stage{st}", f"stage{st}_table.csv"))))
    for r in rows:
        for k in r:
            if k != "stage":
                r[k] = float(r[k])
    return rows


def style(ax):
    ax.grid(True, which="both", alpha=0.3)
    ax.set_xscale("log")
    ax.set_xticks([100, 250, 500, 1000, 2000])
    ax.set_xticklabels(["0.1", "0.25", "0.5", "1", "2"])
    ax.set_xlim(40, 2600)


def distance_fig(root, stages, out):
    fig, (a1, a2) = plt.subplots(2, 1, figsize=(7.5, 7.5), sharex=True)
    a1.plot(BASE_D, BASE_C, "o--", color="0.45", label="settled Stage A (whip on housing)")
    a2.plot(BASE_D, [PJ + c - PS for c in BASE_C], "o--", color="0.45", label="settled Stage A")
    for st in stages:
        rows = table(root, st)
        g = sorted([r for r in rows if r["ground"] == 1], key=lambda r: r["d_mm"])
        f = [r for r in rows if r["ground"] == 0]
        c = COL.get(st, "k")
        a1.plot([r["d_mm"] for r in g], [r["coupling_dB"] for r in g], "s-", color=c, lw=2, label=f"Stage {NAMES[st]}, PEC ground")
        a2.plot([r["d_mm"] for r in g], [r["JS_dB"] for r in g], "s-", color=c, lw=2, label=f"Stage {NAMES[st]}")
        for r in f:
            a1.plot(r["d_mm"], r["coupling_dB"], "^", color=c, ms=9, mfc="white", mew=2,
                    label=f"Stage {st} free space (sim)")
        if len(stages) == 1 and st in CASE:
            a1.plot(1010, CASE[st][1], "x", color="k", ms=10, mew=2.5, label=f"{CASE[st][0]} figure (free space)")
    a2.axhline(10, color="r", ls="--", lw=1.5, label="target +10 dB")
    a2.axhline(PJ - PS, color="k", ls=":", lw=1.2, label="ceiling +10 dB (30 vs 20 dBm)")
    style(a1); style(a2)
    a1.set_ylabel("coupling jammer → TX terminals (dB)")
    a2.set_ylabel("J/S at the receiver, TX 20 dBm (dB)")
    a2.set_xlabel("distance TX → jammer (m)")
    a1.legend(fontsize=8, loc="lower left"); a2.legend(fontsize=8, loc="lower left")
    t = "Stage " + ", ".join(stages) if len(stages) > 1 else f"Stage {NAMES[stages[0]]}"
    a1.set_title(f"{t} vs settled Stage A, 2.4 GHz")
    fig.tight_layout(); fig.savefig(out, dpi=130); plt.close(fig)


def spectra_figs(root, st):
    p = os.path.join(root, f"stage{st}", f"stage{st}_spectra.csv")
    d = np.genfromtxt(p, delimiter=",", names=True)
    f = d["f_GHz"]
    fig, ax = plt.subplots(figsize=(7.5, 4.2))
    for n in d.dtype.names:
        if n == "S11_alone_pec":
            ax.plot(f, d[n], "k-", lw=2.2, label="jammer alone")
        elif n == "S11_tx":
            ax.plot(f, d[n], "k--", lw=1.6, label="TX (frozen Stage A)")
        elif n.startswith("S11_d") and n.endswith("pec"):
            ax.plot(f, d[n], lw=1.1, label=f"jammer in scene, d = {int(n.split('_')[1][1:])} mm")
    ax.axvline(2.4, color="0.5", ls=":"); ax.set_ylim(-35, 0); ax.grid(alpha=0.3)
    ax.set_xlabel("frequency (GHz)"); ax.set_ylabel("S11 (dB)"); ax.legend(fontsize=8)
    ax.set_title(f"Stage {NAMES[st]}: match")
    fig.tight_layout(); fig.savefig(os.path.join(root, f"stage{st}", f"fig_stage{st}_S11.png"), dpi=130); plt.close(fig)

    fig, ax = plt.subplots(figsize=(7.5, 4.2))
    for n in d.dtype.names:
        if n.startswith("S21_d"):
            dd, g = n.split("_")[1][1:], n.split("_")[2]
            ax.plot(f, d[n], "-" if g == "pec" else "--", lw=1.4, label=f"d = {int(dd)} mm, {'PEC ground' if g == 'pec' else 'free space'}")
    ax.axvline(2.4, color="0.5", ls=":"); ax.grid(alpha=0.3)
    ax.set_xlabel("frequency (GHz)"); ax.set_ylabel("coupling jammer → TX (dB)"); ax.legend(fontsize=8)
    ax.set_title(f"Stage {NAMES[st]}: coupling vs frequency")
    fig.tight_layout(); fig.savefig(os.path.join(root, f"stage{st}", f"fig_stage{st}_coupling_vs_f.png"), dpi=130); plt.close(fig)


def pattern_fig(root, stages, out):
    fig = plt.figure(figsize=(6.2, 6.2)); ax = fig.add_subplot(111, projection="polar")
    for st in stages:
        p = os.path.join(root, f"stage{st}", f"stage{st}_pattern_free.csv")
        if not os.path.exists(p):
            p = os.path.join(root, f"stage{st}", f"stage{st}_pattern_pec.csv")
        if not os.path.exists(p):
            continue
        d = np.genfromtxt(p, delimiter=",", names=True)
        ph = np.deg2rad(np.r_[d["phi_deg"], d["phi_deg"][0]])
        g = np.r_[d["G_fs_dBi"], d["G_fs_dBi"][0]]
        ax.plot(ph, np.maximum(g, -25), color=COL.get(st, "k"), lw=2, label=f"{NAMES[st]} (max {g.max():.1f} dBi)")
    ax.set_rlim(-25, 15); ax.set_rticks([-20, -10, 0, 10])
    ax.set_theta_zero_location("E")
    ax.annotate("TX this way (180°)", xy=(np.pi, 12), ha="center", fontsize=8)
    ax.set_title("Jammer alone, horizontal cut, free space (dBi)", pad=18)
    ax.legend(fontsize=8, loc="lower center", bbox_to_anchor=(0.5, -0.22))
    fig.tight_layout(); fig.savefig(out, dpi=130); plt.close(fig)


if __name__ == "__main__":
    root, stages = sys.argv[1], [s.upper() for s in sys.argv[2:]]
    for st in stages:
        distance_fig(root, [st], os.path.join(root, f"stage{st}", f"fig_stage{st}_coupling_JS_vs_distance.png"))
        spectra_figs(root, st)
        pattern_fig(root, [st], os.path.join(root, f"stage{st}", f"fig_stage{st}_pattern.png"))
    if len(stages) > 1:
        os.makedirs(os.path.join(root, "compare"), exist_ok=True)
        distance_fig(root, stages, os.path.join(root, "compare", "fig_compare_coupling_JS.png"))
        pattern_fig(root, stages, os.path.join(root, "compare", "fig_compare_patterns.png"))
