function dict = PVConfig()

            dict = containers.Map();

            % Add key-value pairs
            dict('GAMMA1') = 'CAMR:LI20:302';
            %dict('GAMMA2') = 'CMOS:LI20:3507';
            %dict('GAMMA4') = 'CAMR:LI20:303';
            %dict('DTOTR1') = 'CMOS:LI20:3505';
            dict('DTOTR2') = 'CAMR:LI20:107';

end

% TODO:
% - control tcav itself
% - tcav isnt on pvs are there
% - controls: voltage, phase, on/off, facethone :RF sector 20
% caget pv prints value
% ADES, PDES amplitude and phase, phase is pm 90
% phase drifts, (xtcav pad-1 feedback)
% CH0 phase, phasing process set v low and adjust this phase till kick
% goes 0
% autophase button: does phase calibration till no kick on beam: this is
% CH0
% do calib with voltage 1 2 5 10 20 ramping up
% get more resolution with higher voltage
% look at old gui find what is tcav on off button

% integrate with daq system
% daq can be run from command line
% sharon
% profmon l20 facet daq
% test daq function F2_DAQ
% todo:
% read in from mat file which is the output from the daw gui
% start stop values num steps of phase scan change with beam config
% dougs file to save the data
% dougs script include in gui
% gui -> calls daq with settings -> settings file is the .mat -> daq
% outputs an elog which can be postprocessed later

% toggle between tcav phase: -90, 0, 90, 0, keep looping 5 s in each
% in 2 weeks beam

