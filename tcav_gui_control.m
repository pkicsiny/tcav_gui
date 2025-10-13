classdef tcav_gui_control < handle
    
    events
        PVUpdated % PV object list notifies this event after each set of monitored PVs have finished updating
    end
    properties
        guihan
        pvlist PV
        pvs
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
                PV(context,'name',"AmplitudeDES",'pvname',"TCAV:LI20:2400:ADES",'monitor',true,'mode',"rw");
                PV(context,'name',"AmplitudeRBV",'pvname',"TCAV:LI20:2400:A",'monitor',true,'mode',"r");
                PV(context,'name',"PhaseDES",'pvname',"TCAV:LI20:2400:PDES",'monitor',true,'mode',"rw");
                PV(context,'name',"PhaseRBV",'pvname',"TCAV:LI20:2400:P",'monitor',true,'mode',"r");
                ] ;
            pset(obj.pvlist,'debug',0) ;
            obj.pvs = struct(obj.pvlist);
           
            % Associate class with GUI
            obj.guihan=apphandle;
           
            % Set GUI callbacks for PVs
            obj.pvs.AmplitudeDES.guihan = apphandle.AmplitudeDESEditField;
            obj.pvs.AmplitudeRBV.guihan = apphandle.AmplitudeRBVEditField;
            obj.pvs.PhaseDES.guihan     = apphandle.PhaseDESEditField;
            obj.pvs.PhaseRBV.guihan     = apphandle.PhaseRBVEditField;
        
            % Start listening for PV updates
            obj.listeners = addlistener(obj,'PVUpdated',@(~,~) obj.loop) ;
            run(obj.pvlist, true, 0.1, obj, 'PVUpdated');  
            
         
        end
        
        function loop(obj)
            return 
        end
        
    end
end