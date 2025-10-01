classdef tcav_gui_daq_control < handle
    properties
        guihan
    end
    
    properties (SetObservable)
        daqPath
    end
    methods
        function obj = tcav_gui_daq_control(apphandle)
            obj.guihan = apphandle;       
        end
        
        function onDaqPathValueChanged(obj, src, event)
            disp(["File selected: ", obj.daqPath])
            data = load(obj.daqPath);
        end
    end
end