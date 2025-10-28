classdef scanFunc_tcav_bunch_length < handle
    properties
        guihan
        pvlist PV
        pvs
        initial_phase_control
        initial_phase_readback
        initial_ampli_control
        initial_ampli_readback
        set_phase
        set_ampli
    end
    properties(Constant)
        
        phase_control_PV = "TCAV:LI20:2400:PDES"
        ampli_control_PV = "TCAV:LI20:2400:ADES"
        
        phase_readback_PV = "TCAV:LI20:2400:P"
        ampli_readback_PV = "TCAV:LI20:2400:A"

        tolerance = 0.1;
    end
    % dont call this file directly, write another function similar to
    % tcav_gui_phase_calib that loads bunchlengt h.mat fills in scan params
    % and does scanhdf5()
    % one .mat for calib scan and one for bunchlength .mat
    methods 
        % make this in format of gamma2_filter_pos function
        function obj = scanFunc_tcav_bunch_length(apphandle)
                    
            context = PV.Initialize(PVtype.EPICS);
            obj.pvlist=[...
                PV(context,'name', "phase_control",'pvname',  obj.phase_control_PV,'mode',"rw",'monitor',true);
                PV(context,'name',"phase_readback",'pvname', obj.phase_readback_PV,'mode', "r",'monitor',true);
                PV(context,'name', "ampli_control",'pvname',  obj.ampli_control_PV,'mode',"rw",'monitor',true);
                PV(context,'name',"ampli_readback",'pvname', obj.ampli_readback_PV,'mode', "r",'monitor',true);
                ];
            pset(obj.pvlist,'debug',0);
            obj.pvs = struct(obj.pvlist);
            
            % Associate class with GUI
            obj.guihan=apphandle;
            
            obj.initial_phase_control  = caget(obj.pvs.phase_control);
            obj.initial_phase_readback = caget(obj.pvs.phase_readback);
            obj.initial_ampli_control  = caget(obj.pvs.ampli_control);
            obj.initial_ampli_readback = caget(obj.pvs.ampli_readback);            
        end
        
        % instead of taking phase it takes step value 1,2,3, set phase ampl
        % of tcav to either full value or 0 or full value -90
        % tcav_li2_bunchlength
        % set pdes ades too above not just pdes
        % value ill be 1,2,3: if 1: phase=90, ampl = full
        % in constructor here pull value of 
        % in.mat i can hardcode start step stop
        % how many points per shot i need to provide: n_shot
        % get S from slide: calib measurement scan, or using model params:
        % readin magnet values, calculate expression, manually input
        % V0: readback ampli
        % phi_rf: readback phase
        % psi_y: phase advance between TCAv nd OTR location
        % get betas from xsuite model
        % call xsuite script to get twiss and betas and get phaseadvance between xtcav otr
        % zac has a live model that reflects magnet changes
        %% set phase and ampli DES values and make sure readback
        % value is within tolerance
        function [phase_delta, ampli_delta] = set_value(obj, value)
            
            % set phase and ampli values
            switch value
                case 1
                    obj.set_phase = -90;
                    obj.set_ampli = obj.guihan.AmplitudeDESEditField;
                case 2
                    obj.set_phase = 0;
                    obj.set_ampli = 0;
                case 3
                    obj.set_phase = 90;
                    obj.set_ampli = obj.guihan.AmplitudeDESEditField;

                otherwise
                    error("Invalid value encountered for variable 'value': " + value);
            end
            
            caput(obj.pvs.phase_control, obj.set_phase);
            caput(obj.pvs.ampli_control, obj.set_ampli);
                    
            obj.guihan.LogTextArea.Value = [obj.guihan.LogTextArea.Value;...
                 {sprintf('[tcav_gui_daq_calib.m] Set %s to %0.2f [deg] and %s to %0.2f [V]',...
                 obj.pvs.phase_control, obj.set_phase, obj.pvs.ampli_control, obj.set_ampli)}];
                    
            % read back set value, will not be the same as des
            phase_current_value = caget(obj.pvs.phase_readback);
            ampli_current_value = caget(obj.pvs.ampli_readback);
            
            % waits till readback value matches the value i asked for within tolerance
            while abs(phase_current_value - obj.pvs.phase_control) > obj.tolerance
                phase_current_value = caget(obj.pvs.phase_readback);
                pause(0.1);
            end 
            while abs(ampli_current_value - obj.pvs.ampli_control) > obj.tolerance
                ampli_current_value = caget(obj.pvs.ampli_readback);
                pause(0.1);
            end 
            
            phase_delta = phase_current_value - obj.pvs.phase_control;
            ampli_delta = ampli_current_value - obj.pvs.ampli_control;

            obj.guihan.LogTextArea.Value = [obj.guihan.LogTextArea.Value;...
                {sprintf('%s readback is %0.2f', obj.pvs.phase_readback.name, phase_current_value)}];
            obj.guihan.LogTextArea.Value = [obj.guihan.LogTextArea.Value;...
                {sprintf('%s readback is %0.2f', obj.pvs.ampli_readback.name, ampli_current_value)}];
            F2_fastDAQ_HDF5(obj.daq_params);
        end
        
        %% restore phase and ampli DES values to those before changing them 
        function restoreInitValue(obj)
            obj.guihan.LogTextArea.Value = [obj.guihan.LogTextArea.Value;...
                {'Restoring initial valuesfor %s and %s',obj.pvs.phase_control.name, obj.pvs.ampli_control.name }];
            obj.set_value(obj.initial_phase_control);
            obj.set_value(obj.initial_ampli_control);

        end
        
    end
    
end
