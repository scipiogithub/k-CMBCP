# Q-LS for the *k*-Clustering Minimum Biclique Completion Problem (*k*-CMBCP)

This repository contains the implementation of **Q-LS**, the Q-learning-driven local
search framework for the *k*-CMBCP described in the paper:

> *A Q-Learning-driven local search framework for the k-clustering minimum biclique
> completion problem.* (Manuscript CAOR-D-26-00439, *Computers & Operations Research*.)

The single source file `k-CMBCP.jl` implements all algorithmic components: the
two-stage randomized initialization (`randomC`), the local search operators
(`swap!` = Inter-exchange (1–1), `move!` = Inter-relocate (1–0),
`move2!` = Inter-relocate (2–0)), the Q-table update and ε-greedy policy
(`action` and the update step in `main`), the adaptive parameter control, and the
biclique completion cost (`fitnes`/`fitness`).

---

## 1. Repository structure

```
.
├── k-CMBCP.jl     # complete Q-LS implementation
└── data/          # benchmark instances (Groups I, II, III)
```

Each instance file in `data/` follows the standard *k*-CMBCP format: the first line
contains the number of services |S|, the number of clients |C|, and the number of
clusters K; each subsequent line lists an existing service–client edge.

---

## 2. Environment

The results reported in the paper were produced in the following environment:

- **Hardware:** Apple M2 Pro, 12-core, 3.48 GHz, 16 GB RAM
- **OS:** macOS Ventura
- **Language:** Julia 1.9.2

Dependencies:

- `Random` — random number generation (ships with Julia)
- `StatsBase` — sampling utilities
- `HTTP` — fetching instance files

Install the registered dependencies with:

```bash
julia -e 'using Pkg; Pkg.add(["StatsBase", "HTTP"])'
```

---

## 3. Running Q-LS

Q-LS is run from the command line with two arguments:

```bash
julia k-CMBCP.jl <instance_file> <time_limit_seconds>
```

- `<instance_file>` — the name of an instance in `data/` (e.g. `300-300-15-0.5.dat`)
- `<time_limit_seconds>` — the wall-clock time limit T in seconds

Example:

```bash
julia k-CMBCP.jl 300-300-15-0.5.dat 900
```

The program prints the best objective value found and the time at which it was first
reached. Instance files are read from the `data/` directory of this repository via
its raw GitHub URL, set in the `url` variable near the bottom of `k-CMBCP.jl`; adjust
this variable if you run from a fork or a local copy.

### Reproducing the reported results

The time limit T used in the paper depends on instance size: 150 s for |S| < 120,
300 s for 120 ≤ |S| < 200, 600 s for |S| = 200, and 900 s for |S| = 300. Each
instance was executed 10 independent times, and the best, average, standard
deviation, median, and time-to-best were aggregated across runs.

---

## 4. Hyperparameters

The hyperparameters are set in `k-CMBCP.jl` and were calibrated with the
[irace](https://github.com/MLopez-Ibanez/irace) package
(1200 evaluations, max 500 s per run, 15 randomly selected calibration instances):

- learning rate `α = 0.1`
- discount factor `γ = 0.9`
- initial exploration rate `ϵ = 0.05`, initial intensification probability `ω = 0.05`
- episode length (`stepsize`): 10 for |S| < 200, 5 for |S| = 200, and 2 for |S| = 300

---

## 5. Citation

If you use this code, please cite:

```bibtex
@article{QLS_kCMBCP,
  title   = {A Q-Learning-driven local search framework for the k-clustering minimum biclique completion problem},
  author  = {<authors>},
  journal = {Computers & Operations Research},
  year    = {<year>},
  note    = {Code: https://github.com/scipiogithub/k-CMBCP, v1.0-submission;
             Zenodo: https://doi.org/10.5281/zenodo.20617760}
}
```

---

## 6. License

Specify a license (e.g. MIT) so that others may legally reuse the code.
