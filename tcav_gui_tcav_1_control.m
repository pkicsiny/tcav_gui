classdef tcav_gui_tcav_1_control < handle
    
    events
        PVUpdated_1 % PV object list notifies this event after each set of monitored PVs have finished updating
    end
    properties
        guihan
        pvlist PV
        pvs
    end
    properties
        %tcav_status_PV   = "TCAV:LI20:2400:C_1_TCTL"
        %phase_control_PV = "TCAV:LI20:2400:PDES"
        %ampli_control_PV = "TCAV:LI20:2400:ADES"
        
        %phase_readback_PV = "TCAV:LI20:2400:P"
        %ampli_readback_PV = "TCAV:LI20:2400:A"
        
        tcav_status_PV   = "KLYS:LI10:51:TRIGMODE" %rval
        phase_control_PV = "KLYS:LI10:51:PDES"
        ampli_control_PV = "KLYS:LI10:51:ADES"
        
        phase_readback_PV = "KLYS:LI10:51:PACT05"
        ampli_readback_PV = "KLYS:LI10:51:POWER_W0CH0"
        
        which_tcav uint8 = 0

        tolerance = 0.1;
    end
    properties(Hidden)
        listeners
    end
    
    methods
        
       % set TCAV PVs depending on which TCAV is selected 
       % constructor, matlab & has to be launched from matlabTNG folder to
       % see PV class
       function obj = tcav_gui_tcav_1_control(apphandle)

            % Associate class with GUI
            obj.guihan=apphandle;
            
            context = obj.guihan.context;             

            obj.pvlist=[...
                PV(context,'name',   "tcav_status",'pvname',    obj.tcav_status_PV,'mode', "r",'monitor',true, 'pvdatatype', "string");
                PV(context,'name', "phase_control",'pvname',  obj.phase_control_PV,'mode',"rw",'monitor',true);
                PV(context,'name',"phase_readback",'pvname', obj.phase_readback_PV,'mode', "r",'monitor',true);
                PV(context,'name', "ampli_control",'pvname',  obj.ampli_control_PV,'mode',"rw",'monitor',true);
                PV(context,'name',"ampli_readback",'pvname', obj.ampli_readback_PV,'mode', "r",'monitor',true);
                ] ;
            pset(obj.pvlist,'debug',0) ;
            obj.pvs = struct(obj.pvlist);
          
            % Set GUI callbacks for PVs
            obj.pvs.tcav_status.guihan    = obj.guihan.TCAVStatusEditField_1;
            obj.pvs.ampli_control.guihan  = obj.guihan.AmplitudeDESEditField_1;
            obj.pvs.ampli_readback.guihan = obj.guihan.AmplitudeRBVEditField_1;
            obj.pvs.phase_control.guihan  = obj.guihan.PhaseDESEditField_1;
            obj.pvs.phase_readback.guihan = obj.guihan.PhaseRBVEditField_1;
   
            % Start listening for PV updates
            obj.listeners = addlistener(obj,'PVUpdated_1',@(~,~) obj.loop) ;
            run(obj.pvlist, true, 0.1, obj, 'PVUpdated_1');  
            
         
        end
        
        function loop(obj)
            obj.pvs.tcav_status.guihan.Value = obj.pvs.tcav_status.val{1};
            return 
        end
        
    end
end