function [cal, cal_scaled] = calibrate_phase_position(app, exp, run, PV_name, PV_range) 

    %if nargin == 1    
    %    exp = 'TEST'
    %    run = 13908%13729
    %    PV_range = [-Inf Inf]
    %    PV_name  = 'BSA_List_S10.BPMS_IN10_771_TMIT'
    %end
    
    % automatically get latest run data file from elog
    % http://physics-elog.slac.stanford.edu/facetelog/index.jsp
    if nargin == 1
        [run, exp] = getLatestExp();
    end
    app.LogTextArea.Value = [app.LogTextArea.Value; {char("[calibrate_phase_position.m] Launched calibration with run: " + run + ", experiment: " + exp)}]; 

    PV_range = [-Inf Inf];    
    [data_struct, header] = getDataSet(app, run, exp);
    cam = data_struct.params.camNames{1};
    
    % TODO: here print list of PVs to choose what to filter on
    PV_name  = 'BSA_List_S10.BPMS_IN10_771_TMIT'; % hardcoded for now
    
    % units: [mm/pixel]
    R2 = eval(['data_struct.metadata.' cam '.RESOLUTION']);
    
    % get list of matched indices (MATCH) field in elog entry
    comIndImg = eval(['data_struct.images.' cam '.common_index']);
    comIndScal = data_struct.scalars.common_index;
    N = length(comIndImg);
    
    % Load the matched images
    inds = 1:N;
    [img, x, y, res, xmm, ymm, bkgd] = load_images(app, data_struct, header, cam, inds);
    
    % this filters images based on a given pv falling into a given range
    try
        PV_data = eval(['data_struct.scalars.' PV_name]);
    catch
        error('Specified PV does not exist in the data structure');
    end
    if any(isnan(PV_data))
        app.LogTextArea.Value = [app.LogTextArea.Value; {char(PV_data + " array contains NaNs. Using all matched indices")}];
        valid_indices = comIndScal;
    else
        app.LogTextArea.Value = [app.LogTextArea.Value; {char("[calibrate_phase_position.m] Filtering matched indices based on " + PV_name + " range: [" + num2str(PV_range(1)) + ", " + num2str(PV_range(2)) + "]")}];
        valid_indices = find(PV_data(comIndScal) >= PV_range(1) & PV_data(comIndScal) <= PV_range(2));
    end
    
    %% process images
    xpos = [];
    dxpos = [];
    phase = [];
    sigx = [];

    for i = valid_indices'
        vec1 = sum(img{i}, 2);
        
        if 0
            [yfit, q, dq, chisq_ndf] = gauss_fit(1:length(vec1), vec1);
            
            
            try
                xpos(end + 1) = q(3) * R2;
                dxpos(end+1)   = dq(3) * R2;
                sigx(end + 1) = q(4) * R2;
                phase(end + 1) = data_struct.scalars.BSA_List_S20.TCAV_LI20_2400_P(comIndScal(i));
                
                
            catch
            end
            
        else
            try
                [pks, ix] = findpeaks(vec1, 'MinPeakProminence', 1000);
                
                % convert pixel value to mm
                xpos(end+1) = min(ix)*R2;
                dxpos(end+1) = 0;
                sigx(end+1) = 0;
                
                % RBV phase [deg] should be around desired phase
                phase(end + 1) = eval(['data_struct.scalars.' PV_name '(valid_indices(i))']);
            catch
                app.LogTextArea.Value = [app.LogTextArea.Value, ['i = ' num2str(i) ' didn''t work']];
            end
            
        end
    end
    
    %% create plots
    
    f = 11.424e9; % [Hz]
    c = 3e8; % [m/s]  
    um_per_degRF = c / f / 360 * 1e6; % [um/deg]
    
    ifit = xpos < mean(xpos) * 2;  
    ifit = sigx < 0.1e4 ;
    
    % top subplot with line fit
    %figure
    %nexttile
    hold(app.UIAxesPhaseCalib, 'on');
    
    errorbar(app.UIAxesPhaseCalib, phase(ifit), xpos(ifit), sigx(ifit), sigx(ifit), [], [],  'o') 
    fitresult  = fit_linear(app, phase(ifit), xpos(ifit), app.UIAxesPhaseCalib);
    p = fitresult.p;
    
    xlabel(app.UIAxesPhaseCalib, 'Readback phase [deg]'); 
    ylabel(app.UIAxesPhaseCalib, [cam ' x_0 [\mum]']);
    
    % plot slope and its error on figure
    cal = abs(p(1)); % slope of fitted line [um/deg]
    cal_scaled = cal / um_per_degRF; % [um/um]

    dcal = abs(fitresult.dp(1)); % slope error [um/deg]
    dcal_scaled = dcal / um_per_degRF; % [um/um]
    
    txt = {[ 'cal = ' num2str(cal, 4) ' +/- ' num2str(dcal, 4) ' um/deg'],...
           [' cal = ' num2str(cal_scaled, 4) ' +/- ' num2str(dcal_scaled, 2) ' um/um' ]};
    %text_Left(txt);
    text(app.UIAxesPhaseCalib, 0.02, 0.98, txt, 'Units', 'Normalized', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'top', 'Interpreter', 'none');
    
    titletext = {['DAQ ' exp '_' num2str(run, '%05d')]};
    title(app.UIAxesPhaseCalib, textwrap(titletext,50), 'Interpreter', 'none')
     
    hold(app.UIAxesPhaseCalib, 'off');
        
    %% bottom subplot with PV filtering
    
    hold(app.UIAxesPhaseCalibPVFilter, 'on');
    plot(app.UIAxesPhaseCalibPVFilter, comIndScal, PV_data(comIndScal), 'o');
    plot(app.UIAxesPhaseCalibPVFilter, comIndScal(valid_indices), PV_data(comIndScal(valid_indices)), 'ro')
    xlabel(app.UIAxesPhaseCalibPVFilter, 'Shot Number');
    ylabel(app.UIAxesPhaseCalibPVFilter, PV_name);
    hold(app.UIAxesPhaseCalibPVFilter, 'off');
  
end

