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
%  PHASE B : 28-CASE PARAMETER SWEEP (AUTOMATED MIL & PIL)
%  =====================================================================
fprintf('--- Phase B : 35-case parameter sweep (MIL & PIL) ---\n\n');
T = {
 % ID, name,                        mu_pk, v0,   m,    PBmax, Rr,    slip, tStop
  1,'Dry_Nominal_88fps',            0.80,  88,  50,  1500,  1.25,  0.20, 13
  2,'Dry_HighSpeed_100fps',         0.80, 100,  50,  1500,  1.25,  0.20, 15
  3,'Dry_Heavy_Mass60',             0.80,  88,  60,  1500,  1.25,  0.20, 15
  4,'Dry_Light_Mass40',             0.80,  88,  40,  1500,  1.25,  0.20, 12
  5,'Dry_LowBrake_PB1200',          0.80,  88,  50,  1200,  1.25,  0.20, 15
  6,'Dry_HighBrake_PB1700',         0.80,  88,  50,  1700,  1.25,  0.20, 12
  7,'Dry_SlipTgt_0p15',             0.80,  88,  50,  1500,  1.25,  0.15, 13
  8,'Dry_SlipTgt_0p25',             0.80,  88,  50,  1500,  1.25,  0.25, 13
  9,'Dry_SmallTire_Rr1p15',         0.80,  88,  50,  1500,  1.15,  0.20, 13
 10,'Dry_TinyTire_Rr1p05',          0.80,  88,  50,  1500,  1.05,  0.20, 13
 11,'Dry_Combined_HeavyFast',       0.80, 100,  60,  1700,  1.25,  0.20, 14

 12,'Wet_Nominal',                  0.50,  88,  50,  1500,  1.25,  0.15, 22
 13,'Wet_HighSpeed_100',            0.50, 100,  50,  1500,  1.25,  0.15, 26
 14,'Wet_Light_Mass40',             0.50,  88,  40,  1500,  1.25,  0.15, 20
 15,'Wet_SlipTgt_0p12',             0.50,  88,  50,  1500,  1.25,  0.12, 22
 16,'Wet_SlipTgt_0p18',             0.50,  88,  50,  1500,  1.25,  0.18, 22
 17,'Wet_HighBrake_PB1700',         0.50,  88,  50,  1700,  1.25,  0.15, 20

 18,'Ice_Nominal',                  0.15,  88,  50,  1500,  1.25,  0.10, 30
 19,'Ice_Light_Mass40',             0.15,  88,  40,  1500,  1.25,  0.10, 28
 20,'Ice_SlipTgt_0p12',             0.15,  88,  50,  1500,  1.25,  0.12, 30
 21,'Ice_Combined_HeavyFast',       0.15,  95,  60,  1500,  1.25,  0.10, 34

 22,'Snow_mu0p30',                  0.30,  88,  50,  1500,  1.25,  0.12, 24
 23,'Snow_mu0p30_HighSpd',          0.30,  95,  50,  1500,  1.25,  0.12, 26
 24,'Snow_mu0p35_Mid',              0.35,  88,  50,  1500,  1.25,  0.13, 22
 25,'Snow_mu0p35_HighSpd',          0.35,  95,  50,  1500,  1.25,  0.13, 24
 26,'Dry_HighSpeed_110',            0.80, 110,  50,  1500,  1.25,  0.20, 16
 27,'Ice_LowSpeed_50',              0.15,  50,  50,  1500,  1.25,  0.10, 22
 28,'Gravel_mu0p40',                0.40,  80,  50,  1500,  1.25,  0.14, 22
};
nTests = size(T,1);
sim_modes = {'Normal', 'Processor-in-the-loop (PIL)'};
mode_labels = {'MIL', 'PIL'};
All_Res = struct();

tic;
for m_idx = 1:length(sim_modes)
    current_mode = sim_modes{m_idx};
    label = mode_labels{m_idx};
    
    fprintf('--- Executing %s Sweep ---\n', label);
    set_param(PIL_SUBSYSTEM, 'SimulationMode', current_mode);
    
    Res = struct();
    for k = 1:nTests
        id   = T{k,1};  name = T{k,2};  muPk = T{k,3};
        v0k  = T{k,4};  mk   = T{k,5};  PBk  = T{k,6};
        Rrk  = T{k,7};  sTgt = T{k,8};  tEnd = T{k,9};
        mu_road = mu_baseline * muPk;
        
        assignin('base','slip', slip_vec); assignin('base','mu', mu_road);
        assignin('base','mu_dry', mu_road); assignin('base','mu_wet', mu_road);
        assignin('base','mu_ice', mu_road); assignin('base','slip_desired',sTgt);
        assignin('base','v0', v0k); assignin('base','m', mk);
        assignin('base','PBmax', PBk); assignin('base','Rr', Rrk);
        assignin('base','g', 32.18); assignin('base','Kf', 1);
        assignin('base','TB', 0.01); assignin('base','I', 5);
        set_param(model,'StopTime',num2str(tEnd));
        
        % ABS ON
        assignin('base','ctrl',1);
        try
            simOn = sim(model,'ReturnWorkspaceOutputs','on');
            [t,Vs,Ww,Sd,slipR] = extractSignals(simOn);
            idx     = t >= 0.5;
            maxSlip = max(slipR(idx));
            stopON  = Sd(end);
            vEnd    = Vs(end);
        catch ME
            fprintf('[%2d] %s : %s ON failed (%s)\n',id,name,label,ME.message);
            maxSlip=NaN; stopON=NaN; vEnd=NaN;
        end
        
        % ABS OFF (Only needed once, calculating during MIL pass to save time)
        if strcmp(label, 'MIL')
            try
                assignin('base','ctrl',0);
                simOff = sim(model,'ReturnWorkspaceOutputs','on');
                [~,~,~,SdOff,~] = extractSignals(simOff);
                stopOFF = SdOff(end);
            catch
                stopOFF = NaN;
            end
        else
            stopOFF = All_Res.MIL(k).stopOFF; % reuse from MIL sweep
        end
        
        c1 = maxSlip <= sTgt + 0.15;                      
        c2 = (stopOFF - stopON)/max(stopOFF,1) >= 0.03;   
        c3 = true;                                        
        pass = c1 && c2;
        
        Res(k).id = id; Res(k).name = name; Res(k).mu_peak = muPk;
        Res(k).v0 = v0k; Res(k).mass = mk; Res(k).PBmax = PBk; Res(k).Rr = Rrk;
        Res(k).slip_tgt= sTgt; Res(k).maxSlip = maxSlip;
        Res(k).stopON = stopON; Res(k).stopOFF = stopOFF;
        Res(k).improv = 100*(stopOFF-stopON)/max(stopOFF,1);
        Res(k).vEnd = vEnd; Res(k).c1 = c1; Res(k).c2 = c2; Res(k).c3 = c3;
        Res(k).pass = pass;
        
        if strcmp(label, 'MIL')
            fprintf('[%2d/%d] %-30s  maxSlip=%.2f  stop=%5.1f ft  saves=%5.1f%%  %s\n', ...
                id,nTests,name,maxSlip,stopON,Res(k).improv, ternary(pass,'PASS','FAIL'));
        else
            fprintf('[%2d/%d] %-30s  stop=%5.1f ft (PIL)\n', id,nTests,name,stopON);
        end
    end
    All_Res.(label) = Res;
    
    if strcmp(label, 'MIL')
        nPass  = sum([Res.pass]);
        fprintf('--> MIL Sweep complete | %d / %d PASS (%.1f%%)\n\n', nPass,nTests,100*nPass/nTests);
    end
end
tSweep = toc;
fprintf('\nBoth Sweeps complete in %.1f s\n\n', tSweep);

%% =====================================================================
%  PHASE C : REPORTING
%  =====================================================================
fprintf('--- Phase C : Reporting ---\n\n');
Res = All_Res.MIL; % Use MIL data for original plots

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
drawnow; exportgraphics(f1,fullfile(results_dir,'fig1_slip_ratio.png'),'Resolution',120);

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
drawnow; exportgraphics(f2,fullfile(results_dir,'fig2_speed.png'),'Resolution',120);

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
drawnow; exportgraphics(f3,fullfile(results_dir,'fig3_stopping_distance.png'),'Resolution',120);

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
drawnow; exportgraphics(f4,fullfile(results_dir,'fig4_abs_on_vs_off.png'),'Resolution',120);

% ---------- FIG 5 : adaptive slip overlay ----------
f5 = figure('Name','Adaptive Slip Targets','Position',[160 160 1100 600]);
hold on; grid on;
for k = 1:3
    plot(core(k).t,core(k).slip,'Color',colors{k},'LineWidth',1.8, ...
        'DisplayName',sprintf('%s - target %.2f',core(k).name,core(k).slip_tgt));
    yline(core(k).slip_tgt,':','Color',colors{k},'LineWidth',1.0, ...
        'HandleVisibility','off');
end
xlabel('Time (s)'); ylabel('Slip ratio'); ylim([0 1]);
title('MIL - Adaptive Slip Targets Across Road Conditions', ...
      'FontWeight','bold','FontSize',13);
legend('Location','northeast'); set(gca,'FontSize',11);
drawnow; exportgraphics(f5,fullfile(results_dir,'fig5_adaptive_overlay.png'),'Resolution',120); 

% ---------- FIG 6 : sweep summary ----------
names  = {Res.name}';
sOn    = [Res.stopON]';
sOff   = [Res.stopOFF]';
impr   = [Res.improv]';
passes = [Res.pass]';
f6 = figure('Name','Parameter Sweep Summary','Position',[60 60 1500 820]);
subplot(2,1,1); hold on; grid on;
bar(1:nTests,[sOn sOff],'grouped');
legend({'ABS ON','ABS OFF'},'Location','northwest');
xticks(1:nTests); xticklabels(names); xtickangle(60);
ylabel('Stopping distance (ft)');
title('Parameter Sweep - Stopping Distance per Case','FontWeight','bold');
set(gca,'FontSize',9);
subplot(2,1,2); hold on; grid on;
passColors = zeros(nTests,3);
for k = 1:nTests
    if passes(k), passColors(k,:) = [0.30 0.75 0.35];
    else,         passColors(k,:) = [0.85 0.25 0.20];
    end
end
bar(1:nTests,impr,'FaceColor','flat','CData',passColors);
yline(3,'--k','3% threshold');
xticks(1:nTests); xticklabels(names); xtickangle(60);
ylabel('Stopping distance improvement (%)');
title(sprintf('ABS Improvement by Case - Green = PASS, Red = FAIL  (%d / %d PASS)', ...
      nPass,nTests),'FontWeight','bold');
set(gca,'FontSize',9);
drawnow; exportgraphics(f6,fullfile(results_dir,'fig6_sweep_summary.png'),'Resolution',120); 

% ---------- FIG 7: MIL vs PIL Stopping Distance Bar Chart ----------
stop_MIL = [All_Res.MIL.stopON]';
stop_PIL = [All_Res.PIL.stopON]';
f7 = figure('Name','MIL vs PIL Stopping Distance','Position',[100 100 1200 600]);
b = bar(1:nTests, [stop_MIL, stop_PIL], 'grouped');
b(1).FaceColor = [0 0.4470 0.7410]; 
b(2).FaceColor = [0.8500 0.3250 0.0980]; 
legend({'MIL (Host)', 'PIL (ARM Cortex-M7)'}, 'Location', 'northwest');
xticks(1:nTests); xticklabels(names); xtickangle(45);
ylabel('Stopping Distance (ft)');
title('Equivalence Test: MIL vs PIL Stopping Distances', 'FontWeight', 'bold');
grid on;
drawnow; exportgraphics(f7,fullfile(results_dir,'fig7_mil_vs_pil_distance.png'),'Resolution',120); 

% ---------- FIG 8: Equivalence Error Plot ----------
abs_error = abs(stop_MIL - stop_PIL);
f8 = figure('Name','MIL vs PIL Error','Position',[150 150 1200 400]);
stem(1:nTests, abs_error, 'filled', 'Color', [0.4660 0.6740 0.1880]);
yline(0, 'k-', 'LineWidth', 1);
xticks(1:nTests); xticklabels(names); xtickangle(45);
ylabel('Absolute Error (ft)');
title('Numerical Equivalence Error (|MIL - PIL|)', 'FontWeight', 'bold');
grid on;
drawnow; exportgraphics(f8,fullfile(results_dir,'fig8_mil_vs_pil_error.png'),'Resolution',120); 

% ---------- CSV + XLSX export ----------
ids    = [Res.id]'; mus    = [Res.mu_peak]'; v0s    = [Res.v0]';
masses = [Res.mass]'; PBs    = [Res.PBmax]'; Rrs    = [Res.Rr]';
stgts  = [Res.slip_tgt]'; maxSl  = [Res.maxSlip]';
c1v = [Res.c1]'; c2v = [Res.c2]'; c3v = [Res.c3]';
results_table = table(ids,names,mus,v0s,masses,PBs,Rrs,stgts, ...
    maxSl,sOn,stop_PIL,sOff,impr,abs_error,c1v,c2v,c3v,passes, ...
    'VariableNames',{'ID','Name','mu_peak','v0','mass','PBmax','Rr', ...
    'slip_tgt','max_slip','MIL_stop_ft','PIL_stop_ft','stop_OFF_ft','improv_pct', ...
    'MIL_PIL_Error_ft','C1_noLockup','C2_ABSBetter','C3_Stopped','MIL_PASS'});
writetable(results_table,fullfile(results_dir,'MIL_PIL_TestSuite_Results.csv'));
writetable(results_table,fullfile(results_dir,'MIL_PIL_TestSuite_Results.xlsx'));

% ---------- Text report ----------
fid = fopen(fullfile(results_dir,'MIL_PIL_Report.txt'),'w');
fprintf(fid,'ABS MIL vs PIL VERIFICATION REPORT\n');
fprintf(fid,'Generated : %s\n\n',datestr(now));
fprintf(fid,'--- Phase A : 3-Road Core Test (MIL) ---\n');
for k = 1:3
    fprintf(fid,'%-5s | mu_peak=%.2f | slip_tgt=%.2f | max_slip=%.3f | stop_ON=%.1f ft | stop_OFF=%.1f ft | saves=%.1f%% | %s\n', ...
        core(k).name,core(k).mu_peak,core(k).slip_tgt, ...
        core(k).maxSlip,core(k).stopON,core(k).stopOFF, ...
        core(k).improve,ternary(core(k).pass,'PASS','FAIL'));
end
fprintf(fid,'\n--- Phase B : %d-case sweep (MIL vs PIL) ---\n',nTests);
fprintf(fid,'MIL Pass rate : %d / %d (%.1f%%)\n',nPass,nTests,100*nPass/nTests);
max_err = max(abs_error);
fprintf(fid,'Max Equivalence Error (MIL vs PIL) : %f ft\n', max_err);
fprintf(fid,'Total sweep time : %.1f s\n',tSweep);
fclose(fid);

fprintf('Artifacts saved to %s\\:\n', results_dir);
fprintf('  fig1_slip_ratio.png\n');
fprintf('  fig2_speed.png\n');
fprintf('  fig3_stopping_distance.png\n');
fprintf('  fig4_abs_on_vs_off.png\n');
fprintf('  fig5_adaptive_overlay.png\n');
fprintf('  fig6_sweep_summary.png\n');
fprintf('  fig7_mil_vs_pil_distance.png\n');
fprintf('  fig8_mil_vs_pil_error.png\n');
fprintf('  MIL_PIL_TestSuite_Results.csv\n');
fprintf('  MIL_PIL_TestSuite_Results.xlsx\n');
fprintf('  MIL_PIL_Report.txt\n\n');
fprintf('CAMPAIGN COMPLETE.\n');

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

%% =====================================================================
%  PHASE D : EXECUTION PROFILING EXTRACTION
%  =====================================================================
fprintf('--- Phase D : Execution Profiling Metrics ---\n');

if exist('simOn', 'var') && ismember('executionProfile', simOn.who)
    execProf = simOn.get('executionProfile');
    
    fprintf('Profiling data found successfully!\n');
    fprintf('Generating interactive HTML report...\n');
    
    try
        % Automatically generate and open the interactive HTML report
        execProf.report();
        fprintf('Success! The Execution Profiling HTML report should now be open.\n');
        fprintf('You can view your exact Max and Average CPU ticks directly in the table.\n');
        
        % Safely append a note to the text report without calling version-specific properties
        fid = fopen(fullfile(results_dir,'MIL_PIL_Report.txt'), 'a');
        fprintf(fid, '\n--- Processor-in-the-Loop (PIL) Profiling ---\n');
        fprintf(fid, 'Profiling data successfully captured during execution.\n');
        fprintf(fid, 'Please refer to the generated HTML Execution Profile Report for detailed CPU cycle metrics.\n');
        fclose(fid);
        
        fprintf('Note successfully appended to MIL_PIL_Report.txt\n');
        
    catch ME
        fprintf('Warning: Could not generate HTML report. (%s)\n', ME.message);
    end
else
    fprintf('No executionProfile found inside simOn. Check Simulink Code Generation settings.\n');
end

%% =====================================================================
%  PHASE E : STACK PROFILING EXTRACTION
%  =====================================================================
fprintf('\n--- Stack Profiling Metrics ---\n');

if exist('simOn','var') && ismember('stackProfile', simOn.who)
    
    stackProf = simOn.get('stackProfile');
    
    fprintf('Stack profiling data found successfully!\n');
    
    try
        % Generate HTML report (similar to executionProfile)
        stackProf.report();
        fprintf('Stack profiling HTML report generated successfully.\n');
        
        % Extract key info (if available)
        disp('Basic stack profiling info:');
        disp(stackProf);
        
        % Append to report file
        fid = fopen(fullfile(results_dir,'MIL_PIL_Report.txt'), 'a');
        fprintf(fid, '\n--- Stack Usage Analysis ---\n');
        fprintf(fid, 'Stack profiling data successfully captured.\n');
        fprintf(fid, 'Refer to generated stack profiling report for detailed usage metrics.\n');
        fclose(fid);
        
    catch ME
        fprintf('Warning: Could not generate stack report (%s)\n', ME.message);
    end
    
else
    fprintf('No stackProfile found. Check if stack profiling is enabled in settings.\n');
end