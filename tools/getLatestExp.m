function [run, exp] = getLatestExp(app)
            % Loads the latest DAQ run to the input
            
            % Get latest DAQ number from elog
            run = lcaGetSmart('SIOC:SYS1:ML02:AO400');
            
            %Get latest DAQ experiment name
            exp = lcaGetSmart('SIOC:SYS1:ML02:AO398');
            if exp == 0
                exp = 'TEST';
            else
                exp = sprintf('E%d',exp); % E300 etc
            end
            
end