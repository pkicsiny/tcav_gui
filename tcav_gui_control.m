classdef tcav_gui_control < handle
    
    events
        PVUpdated % PV object list notifies this event after each set of monitored PVs have finished updating
    end
    properties
        guihan
        pvlist PV
        pvs
    end
    properties(Constant)
        
        phase_control_PV = "TCAV:LI20:2400:PDES"
        ampli_control_PV = "TCAV:LI20:2400:ADES"
        
        phase_readback_PV = "TCAV:LI20:2400:P"
        ampli_readback_PV = "TCAV:LI20:2400:A"

        tolerance = 0.1;
    end
    properties(Hidden)
        listeners
    end
    
    methods
        
       % constructor, matlab & has to be launched from matlabTNG folder to
       % see PV class
       function obj = tcav_gui_control(apphandle)
           
            % initialize object and add PVs to be monitored
            context = PV.Initialize(PVtype.EPICS) ;             

            obj.pvlist=[...
                PV(context,'name', "phase_control",'pvname',  obj.phase_control_PV,'mode',"rw",'monitor',true);
                PV(context,'name',"phase_readback",'pvname', obj.phase_readback_PV,'mode', "r",'monitor',true);
                PV(context,'name', "ampli_control",'pvname',  obj.ampli_control_PV,'mode',"rw",'monitor',true);
                PV(context,'name',"ampli_readback",'pvname', obj.ampli_readback_PV,'mode', "r",'monitor',true);
                ] ;
            pset(obj.pvlist,'debug',0) ;
            obj.pvs = struct(obj.pvlist);
           
            % Associate class with GUI
            obj.guihan=apphandle;
           
            % Set GUI callbacks for PVs
            obj.pvs.ampli_control.guihan  = apphandle.AmplitudeDESEditField;
            obj.pvs.ampli_readback.guihan = apphandle.AmplitudeRBVEditField;
            obj.pvs.phase_control.guihan  = apphandle.PhaseDESEditField;
            obj.pvs.phase_readback.guihan = apphandle.PhaseRBVEditField;
        
            % Start listening for PV updates
            obj.listeners = addlistener(obj,'PVUpdated',@(~,~) obj.loop) ;
            run(obj.pvlist, true, 0.1, obj, 'PVUpdated');  
            
         
        end
        
        function loop(obj)
            return 
        end
        
    end
end