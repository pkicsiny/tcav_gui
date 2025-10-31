classdef tcav_gui_phase_calib < handle
    properties
        guihan
        daq_params
        tcav_params % list, stores [status, pdes, ades, prb, arb] PVs
    end
    
    properties (SetObservable)
        daqPath
    end
    methods
        function obj = tcav_gui_phase_calib(apphandle)
            obj.guihan = apphandle; 
            
            % change this to latest
            obj.daqPath = 'TCAV_10.mat'; % inside data struct scan func name is defined
            data = load(obj.daqPath);
            obj.daq_params = data.daq_params;
            
            % access F2_fastDAQ_HDF5 to run DAQ from here
            addpath /usr/local/facet/tools/matlabTNG/F2_DAQ
            
            % to access calibration functions
            addpath /home/fphysics/pkicsiny/git_work/matlabTNG/F2_TCAV/tools
        end
        
        function setScanParamsFromGui(obj)
            % set values into daq_params of .mat file (doesnt overwrite original), add n_shot
            obj.daq_params.startVals = obj.guihan.PhaseStartEditField.Value;
            obj.daq_params.stopVals = obj.guihan.PhaseStopEditField.Value;
            obj.daq_params.nSteps = obj.guihan.PhaseStepsEditField.Value;
            
            obj.daq_params.totalSteps = obj.daq_params.nSteps;
            obj.daq_params.scanVals = {linspace(obj.daq_params.startVals, obj.daq_params.stopVals, obj.daq_params.nSteps)};
            obj.daq_params.stepsAll = (1:obj.daq_params.nSteps)'; 
            
            obj.daq_params.comment = {'TEST XTCAV CALIBRATION'};
            
            % set which tcav to manipulate
            obj.daq_params.scanPVs = obj.tcav_params(2); % PDES
            obj.daq_params.RBV_PVs = obj.tcav_params(4); % P readback

        end
        
        function showScanSteps(obj)
            % when i set nsteps, it prints start stop steps on gui
            start_value = obj.guihan.PhaseStartEditField.Value;
            end_value = obj.guihan.PhaseStopEditField.Value;
            num_steps = obj.guihan.PhaseStepsEditField.Value;
            
            if num_steps > 0
                obj.guihan.ScanValuesTextArea.Value = {...
                num2str(linspace(start_value, end_value, num_steps))};
                
                %drawnow;
            end
            
        end
        
        function launchPhaseScan(obj)
             
             %daq was fixed create new template
             % ask sharon where i can get number for most recent daq its
             % maybe a pv
             % calibrate_phase_position has a dummy daq output
             % 13729 run, E300
             % experiment
             
             %obj.setScanParamsFromGui();
             
             % need to be on facet srv20 for this
             obj.guihan.LogTextArea.Value = [obj.guihan.LogTextArea.Value; {'[tcav_gui_daq_calib.m] Launching phase scan...'}];
             % 
             F2_fastDAQ_HDF5(obj.daq_params);
        end

            % scan: -90, 90, off
            % write function that scans those 3 phases
            % tcav toggler function onoff button:
            % scan function: on 90, off, 
            
            % daq generates utput
            % i need to post process that file and plot 
            % this is the calibration plot
            % bunch length measurement is different
            
            % this goes to bottom left panel
            % this uses the -90, off, 90 phase setup
            
            % finds centroid of each image: one dot on plot
            % each image has the centroid
            % fits line to get slope
            
            % tcav on buttom from old gui
            % bg subtraction fro, profmon
            % debug bunchlegth from daq
            % show steps in phase scan
            % enabled/disabled status: TCAV:LI20:2400:C_1_TCTL
            % run('/home/fphysics/pkicsiny/git_work/matlabTNG/F2_DAQ/F2_DAQ.mlapp')
    end
end