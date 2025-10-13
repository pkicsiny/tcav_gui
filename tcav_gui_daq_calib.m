classdef tcav_gui_daq_calib < handle
    properties
        guihan
        daq_params
    end
    
    properties (SetObservable)
        daqPath
    end
    methods
        function obj = tcav_gui_daq_calib(apphandle)
            obj.guihan = apphandle;   
            obj.daqPath = 'DAQ_params_TEST.mat';
            data = load(obj.daqPath);
            obj.daq_params = data.daq_params;
            
            % access F2_fastDAQ_HDF5 to run DAQ from here
            addpath /usr/local/facet/tools/matlabTNG/F2_DAQ
            
            % to access calibration functions
            addpath /home/fphysics/pkicsiny/git_work/matlabTNG/F2_TCAV/tools
            
            % set values from gui default
            obj.setScanParamsFromGui();
        end
        
        function setScanParamsFromGui(obj)
            % set values from gui default
            obj.daq_params.startVals = obj.guihan.PhaseStartEditField.Value;
            obj.daq_params.stopVals = obj.guihan.PhaseStopEditField.Value;
            obj.daq_params.nSteps = obj.guihan.PhaseStepsEditField.Value;
            
            obj.daq_params.totalSteps = obj.daq_params.nSteps;
            obj.daq_params.scanVals = linspace(obj.daq_params.startVals, obj.daq_params.stopVals, obj.daq_params.nSteps);
            obj.daq_params.stepsAll = (1:obj.daq_params.nSteps)'; 
            
            obj.daq_params.comment = 'TEST XTCAV';
        end
        
        function launchPhaseScan(obj)
             
             %daq was fixed create new template
             % ask sharon where i can get number for most recent daq its
             % maybe a pv
             % calibrate_phase_position has a dummy daq output
             % 13729 run, E300
             % experiment
             
             % need to be on facet srv20 for this
             obj.guihan.LogTextArea.Value = [obj.guihan.LogTextArea.Value; {'[tcav_gui_daq_calib.m] Launching phase scan...'}];
             F2_fastDAQ_HDF5(obj.daq_params);
        end
        
        function onDaqPathValueChanged(obj, src, event)
            %disp(["File selected: ", obj.daqPath])
            % LOAD daq_PARAMS MAT WHICH HAS THE daq_params struct then i change that then call the qui
            % sharon why daq not on timing group needs to fix
            % DAQ is launched from here using the .mat file
            
            
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
            
            
        end
    end
end