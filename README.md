# Solution to MATLAB and Simulink Challenge project 
# 257 -Processor-in-the-Loop Automotive Controller on an Arm Cortex-M7 Fast Model Emulator

This repository provides a structured solution and verification environment for the Anti-Lock Braking System (ABS) Controller. It demonstrates Processor-in-the-Loop (PIL) and Model-in-the-Loop (MIL) testing workflows.

[Project description link](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/tree/main/projects/Processor-in-the-Loop%20Automotive%20Controller%20on%20an%20Arm%20Cortex-M7%20Fast%20Model%20Emulator)

## Project details
This project is an implementation and verification setup for an Anti-Lock Braking System using MATLAB and Simulink. The core functionality is testing embedded code logic against a vehicle dynamic model. 
The workspace is organized into a modular structure:
- `models/`: Contains the Simulink models (`ABS_Controller_core.slx`, `sldemo_absbrake.slx`).
- `scripts/`: MATLAB scripts for running simulations and analyzing data (`run_abs_pid_base.m`, `run_mil_pil_test_compare.m`).
- `data/`: MATLAB data files storing baseline variables and variables required for simulation.
- `tests/`: Contains verification rules and requirement files (`abs_verification_rules.slreqx`).
- `results/`: Output directories containing coverage details and MIL/PIL comparison results.
- `Verification Report.mlx`: The main Live Script acting as the central entry point and report for the verification tasks.

## How to run section
1. Open MATLAB and navigate to the root directory of this repository.
2. Run the `setup_project.m` script from the MATLAB Command Window to add all subdirectories to your MATLAB path.
   ```matlab
   setup_project
   ```
3. The simplest way to run the entire verification sequence is to use the main Live Script:
   - Open `Verification Report.mlx`
   - Click **Run All** in the Live Editor tab.
   - This will automatically execute all required background scripts (including `run_mil_pil_test_compare.m`) in the correct sequence and display the analysis inline.
4. Standalone output plots, CSVs, and logs will also be saved in the `results/MIL_PIL_Results` folder.

**Required Toolboxes:**
- MATLAB
- Simulink
- Simulink Test (for PIL/MIL comparisons and verification)
- Embedded Coder (for generating C code and PIL testing)

## Demo/Results
The scripts perform automated testing across different road conditions (Dry, Wet, Ice) and evaluate the performance of the ABS. The results and coverage information are populated in the `results/` folder, which includes figures such as "Slip Ratio vs Time", "Stopping Distance", and "ABS ON vs OFF".

*(Check the `results/MIL_PIL_Results` folder for visual plots generated during the simulation)*

## Reference
- MathWorks Project 257: ARM/Simulink ABS (Anti-Lock Braking System)
- MathWorks Simulink ABS Demo (`sldemo_absbrake`)
