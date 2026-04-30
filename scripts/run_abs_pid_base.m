%% run_mil_pil_compare.m
%  =====================================================================
%  COMPLETE MIL & PIL VERIFICATION FOR ABS CONTROLLER
%  Mathworks Project 257 - ARM/Simulink ABS (Anti-Lock Braking System)
%  =====================================================================

model = 'sldemo_absbrake';
PIL_SUBSYSTEM   = 'sldemo_absbrake/Controller';
load_system(model);
sldemo_absdata;                                    % baseline parameters
mu_baseline = [0 .4 .8 .97 1.0 .98 .96 .94 .92 .9 .88 .855 ...
               .83 .81 .79 .77 .75 .73 .72 .71 .7];
slip_vec    = (0:0.05:1.0);

% --- SETUP PATHS AND DIRECTORIES ---
projectRoot = fileparts(fileparts(mfilename('fullpath')));
run(fullfile(projectRoot, 'setup_project.m'));
results_dir = fullfile(projectRoot, 'results', 'MIL_PIL_Results');
if ~exist(results_dir, 'dir')
    mkdir(results_dir);
end

fprintf('=====================================================\n');
fprintf('  ABS MIL & PIL VERIFICATION CAMPAIGN\n');
fprintf('  Model : %s\n',model);
fprintf('  Date  : %s\n',datestr(now,'yyyy-mm-dd HH:MM:SS'));
fprintf('  Output Directory : .\\%s\\\n', results_dir);
fprintf('=====================================================\n\n');

%% =====================================================================
%  PHASE A : CORE 3-ROAD TEST (MIL BASELINE)
%  =====================================================================
fprintf('--- Phase A : 3-road core test (MIL Baseline) ---\n\n');
set_param(PIL_SUBSYSTEM , 'SimulationMode' , 'Normal');

road_names  = {'Dry','Wet','Ice'};
mu_peak_set = [0.80, 0.50, 0.15];
slip_target = [0.20, 0.15, 0.10];
stop_times  = [13,   22,   28];
colors      = {[0 0.45 0.74], ...
               [0.85 0.33 0.10], ...
               [0.47 0.67 0.19]};
core = struct();
for k = 1:numel(road_names)
    rn   = road_names{k};
    muPk = mu_peak_set(k);
    sTgt = slip_target(k);
    tEnd = stop_times(k);
    mu_road = mu_baseline * muPk;
    
    assignin('base','slip',        slip_vec);
    assignin('base','mu',          mu_road);
    assignin('base','mu_dry',      mu_road);
    assignin('base','mu_wet',      mu_road);
    assignin('base','mu_ice',      mu_road);
    assignin('base','slip_desired',sTgt);
    assignin('base','ctrl',        1);
    set_param(model,'StopTime',num2str(tEnd));
    
    simOn = sim(model,'ReturnWorkspaceOutputs','on');
    [tOn,VsOn,WwOn,SdOn,slipOn] = extractSignals(simOn);
    
    assignin('base','ctrl',0);
    simOff = sim(model,'ReturnWorkspaceOutputs','on');
    [tOff,VsOff,WwOff,SdOff,slipOff] = extractSignals(simOff);
    
    idx      = tOn >= 0.5;
    maxSlip  = max(slipOn(idx));
    avgSlip  = mean(slipOn(idx));
    stopON   = SdOn(end);
    stopOFF  = SdOff(end);
    improve  = 100 * (stopOFF - stopON) / max(stopOFF,1);
    
    pass = (maxSlip <= sTgt + 0.10) && (improve >= 3);
    
    core(k).name = rn; core(k).mu_peak = muPk; core(k).slip_tgt = sTgt;
    core(k).t = tOn; core(k).Vs = VsOn; core(k).Ww = WwOn; core(k).Sd = SdOn;
    core(k).slip = slipOn; core(k).tOff = tOff; core(k).VsOff = VsOff;
    core(k).WwOff = WwOff; core(k).SdOff = SdOff; core(k).slipOff = slipOff;
    core(k).maxSlip = maxSlip; core(k).avgSlip = avgSlip;
    core(k).stopON = stopON; core(k).stopOFF = stopOFF;
    core(k).improve = improve; core(k).pass = pass;
    
    fprintf('[%s] mu_peak=%.2f  slipTgt=%.2f  maxSlip=%.3f  stopON=%.1f ft  stopOFF=%.1f ft  saves=%.1f%%  %s\n', ...
        rn,muPk,sTgt,maxSlip,stopON,stopOFF,improve, ternary(pass,'PASS','FAIL'));
end
fprintf('\n');

%% =====================================================================
%  PHASE B : REPORTING
%  =====================================================================
fprintf('--- Phase B : Reporting ---\n\n');
set(0,'DefaultFigureVisible','on')

% ---------- FIG 1 : slip ratio per road ----------
f1 = figure('Name','Slip Ratio vs Time','Position',[80 80 1200 720]);
for k = 1:3
    subplot(3,1,k); hold on; grid on;
    plot(core(k).t,core(k).slip,'Color',colors{k},'LineWidth',1.6);
    yline(core(k).slip_tgt,'--k','LineWidth',1.2, ...
          'Label',sprintf('target = %.2f',core(k).slip_tgt));
    yline(core(k).slip_tgt+0.10,':r','LineWidth',1.0,'Label','limit');
    title(sprintf('%s road  (\\mu_{peak}=%.2f)   max slip = %.3f   stop = %.1f ft   [%s]', ...
        core(k).name,core(k).mu_peak,core(k).maxSlip, ...
        core(k).stopON,ternary(core(k).pass,'PASS','FAIL')), ...
        'FontWeight','bold');
    xlabel('Time (s)'); ylabel('Slip ratio'); ylim([0 1]);
end
sgtitle('MIL - ABS Slip Ratio (Dry / Wet / Ice)','FontSize',14,'FontWeight','bold');
drawnow; exportgraphics(f1,fullfile(results_dir,'fig1_slip_ratio.png'),'Resolution',120); close(f1);

% ---------- FIG 2 : vehicle vs wheel speed ----------
f2 = figure('Name','Vehicle vs Wheel Speed','Position',[100 100 1200 720]);
for k = 1:3
    subplot(3,1,k); hold on; grid on;
    plot(core(k).t,core(k).Vs,'-', 'Color',colors{k},'LineWidth',1.6);
    plot(core(k).t,core(k).Ww,'--','Color',colors{k}*0.6,'LineWidth',1.3);
    title([core(k).name ' road'],'FontWeight','bold');
    xlabel('Time (s)'); ylabel('Speed (rad/s)');
    legend('Vehicle','Wheel','Location','northeast');
end
sgtitle('MIL - Vehicle vs Wheel Speed','FontSize',14,'FontWeight','bold');
drawnow; exportgraphics(f2,fullfile(results_dir,'fig2_speed.png'),'Resolution',120); close(f2);

% ---------- FIG 3 : stopping distance ----------
f3 = figure('Name','Stopping Distance','Position',[120 120 1100 620]);
hold on; grid on;
for k = 1:3
    plot(core(k).t,core(k).Sd,'Color',colors{k},'LineWidth',1.8, ...
         'DisplayName',sprintf('%s - final %.1f ft', ...
         core(k).name,core(k).stopON));
end
xlabel('Time (s)'); ylabel('Stopping distance (ft)');
title('MIL - Stopping Distance (ABS ON)','FontWeight','bold','FontSize',13);
legend('Location','southeast'); set(gca,'FontSize',11);
drawnow; exportgraphics(f3,fullfile(results_dir,'fig3_stopping_distance.png'),'Resolution',120); close(f3);

% ---------- FIG 4 : ABS ON vs OFF ----------
f4 = figure('Name','ABS ON vs OFF','Position',[140 140 1300 820]);
for k = 1:3
    subplot(3,2,2*k-1); hold on; grid on;
    plot(core(k).t,   core(k).slip,   '-','Color',colors{k},'LineWidth',1.5);
    plot(core(k).tOff,core(k).slipOff,'--','Color',[0.5 0.5 0.5],'LineWidth',1.2);
    yline(core(k).slip_tgt,':k');
    ylim([0 1]); xlabel('Time (s)'); ylabel('Slip');
    title([core(k).name ' - slip ratio'],'FontWeight','bold');
    legend('ABS ON','ABS OFF','target','Location','best');
    subplot(3,2,2*k); hold on; grid on;
    plot(core(k).t,   core(k).Sd,   '-','Color',colors{k},'LineWidth',1.8);
    plot(core(k).tOff,core(k).SdOff,'--','Color',[0.5 0.5 0.5],'LineWidth',1.3);
    xlabel('Time (s)'); ylabel('Distance (ft)');
    title(sprintf('%s - stopping (ABS saves %.1f%%)', ...
        core(k).name,core(k).improve),'FontWeight','bold');
    legend(sprintf('ON  %.1f ft',core(k).stopON), ...
           sprintf('OFF %.1f ft',core(k).stopOFF), ...
           'Location','southeast');
end
sgtitle('MIL - ABS ON vs OFF (All Road Conditions)','FontSize',14,'FontWeight','bold');
drawnow; exportgraphics(f4,fullfile(results_dir,'fig4_abs_on_vs_off.png'),'Resolution',120); close(f4);


%% =====================================================================
%  LOCAL HELPERS
%  =====================================================================
function [t,Vs,Ww,Sd,slipR] = extractSignals(simOut)
%EXTRACTSIGNALS  Pull Vs, Ww, Sd from an sldemo_absbrake sim output.
    
    if isa(simOut,'Simulink.SimulationOutput')
        logged = simOut.who;
        ds = [];
        for ii = 1:numel(logged)
            cand = simOut.get(logged{ii});
            if isa(cand,'Simulink.SimulationData.Dataset')
                ds = cand; break;
            end
        end
    else
        ds = simOut;
    end
    
    if isempty(ds)
        error('extractSignals:NoDataset','No Dataset in simOut.');
    end
    
    nEl   = ds.numElements;
    elems = cell(nEl,1);
    names = strings(nEl,1);
    for ii = 1:nEl
        elems{ii} = ds.getElement(ii);
        names(ii) = string(elems{ii}.Name);
    end
    
    [Vsv,Wwv,Sdv] = deal([]);
    yIdx = find(names == "yout",1);
    if ~isempty(yIdx)
        yv  = elems{yIdx}.Values;
        if isstruct(yv) || isobject(yv)
            if isfield(yv,'Vs') || isprop(yv,'Vs'), Vsv = yv.Vs; end
            if isfield(yv,'Ww') || isprop(yv,'Ww'), Wwv = yv.Ww; end
            if isfield(yv,'Sd') || isprop(yv,'Sd'), Sdv = yv.Sd; end
        end
    end
    
    if isempty(Vsv), i = find(names=="Vs",1); if ~isempty(i), Vsv = elems{i}.Values; end, end
    if isempty(Wwv), i = find(names=="Ww",1); if ~isempty(i), Wwv = elems{i}.Values; end, end
    if isempty(Sdv), i = find(names=="Sd",1); if ~isempty(i), Sdv = elems{i}.Values; end, end
    
    if isempty(Vsv) || isempty(Wwv) || isempty(Sdv)
        error('extractSignals:MissingSignal', ...
              'Could not find Vs / Ww / Sd in Dataset.');
    end
    
    % --- THE MINLEN FIX ---
    t  = Vsv.Time(:);
    Vs = Vsv.Data(:);
    Ww = Wwv.Data(:);
    Sd = Sdv.Data(:);
    % Find shortest array to prevent mismatch error
    minLen = min([length(t), length(Vs), length(Ww), length(Sd)]);
    % Truncate all arrays to matching lengths
    t  = t(1:minLen);
    Vs = Vs(1:minLen);
    Ww = Ww(1:minLen);
    Sd = Sd(1:minLen);
    % -----------------------
    
    VsSafe = max(Vs,1e-3);
    slipR  = (VsSafe - Ww) ./ VsSafe;
    slipR  = max(min(slipR,1),0);
end

function out = ternary(cond,a,b)
    if cond, out = a; else, out = b; end
end
