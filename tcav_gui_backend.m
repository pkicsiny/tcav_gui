classdef tcav_gui_backend < handle

    properties
        guihan
        PVtoPlot
        PVtimer
        
        % camera plot attributes
        PVtimerCam
        cameraPV
        firstPush logical = true
        plottingOnUIAxes2 logical = false
        fileData
        pois % points of interest on the plot: rtcl_ctr, beam etc
        plotRaw logical = false
        showBMOn logical = false
        showRawOn logical = false
        calEOn logical = false
        calTOn logical = false
        newPlot logical = true
        selectBeamOn logical = false
        subtractBGOn logical = false
        bg_image
        xticks_mm
        yticks_mm
        procSteps
        bitDepth
        clim_def = [0,1] % plot colormap limits
        rowSum
        colSum
        
        % Add a property that stores application data here
        data
        plottingOn logical = false
    end
    
    properties (Constant)
        % This section contains properties that remain constant
        numPlotPts = 50;
    end

    methods
        % This section contains functions that are needed to run the app
        
        function obj = tcav_gui_backend(apphandle)
            % This is the constructor method. This function is run when
            % an instance of the class is created. Property values are
            % initialized here.

            % Associate class with GUI
            obj.guihan = apphandle;       
            obj.cameraPV = obj.guihan.PVDisplay.Value;
            
            %%%%%%%%%%%%%%%%%%%%%%%%
            % Create timer objects %
            %%%%%%%%%%%%%%%%%%%%%%%%
            
            obj.PVtimerCam = timer("ExecutionMode","fixedRate","Period",1, ...
                "BusyMode","queue","TimerFcn",@obj.PVtimerFcnCam);
            
            %%%%%%%%%%%%%%%
            % Start timer %
            %%%%%%%%%%%%%%%
            
            if strcmp(obj.PVtimerCam.Running,"off")
                start(obj.PVtimerCam);
                disp('Timer for camera started')
            end
         
        end
        
        function x = mmToPix(obj, x)
          um_per_pixel = obj.fileData.res;  % [um/pixel]
           x = x / um_per_pixel * 1e3;
        end
        
        function x = pixToMm(obj, x)
          um_per_pixel = obj.fileData.res;  % [um/pixel]
           x = x * um_per_pixel * 1e-3;
        end
        
        function ImageProcToRaw(obj)
            
            if obj.fileData.orientX
               obj.fileData.img = fliplr(obj.fileData.img); 
            end
            
            if obj.fileData.orientY
               obj.fileData.img = flipud(obj.fileData.img); 
            end
            
            if obj.fileData.isRot
                obj.fileData.img = obj.fileData.img';
            end
        end
        
        function [x, y] = RelCoordRawToProc(obj, x, y)    
            
            if obj.fileData.isRot
               x_temp = x;
               x = y;
               y = x_temp;
            end
            
            if obj.fileData.orientX
               x = - x; 
            end
            
            if obj.fileData.orientY
               y = - y;
            end
            
        end
        
        function [x, y] = RelCoordProcToRaw(obj, x, y)     
            
            if obj.fileData.orientY
               y = - y;
            end
            
            if obj.fileData.orientX
               x = - x; 
            end
            
            if obj.fileData.isRot
               x_temp = x;
               x = y;
               y = x_temp;
            end
        end
        
        function [x, y] = CoordRawToProc(obj, x, y, offset_x, offset_y)
            if nargin < 5
                offset_y = 0;
            end
            if nargin < 4
                offset_x = 0;
            end
    
            if obj.fileData.isRot
               x_temp = x;
               x = y;
               y = x_temp;
            end
            
            if obj.fileData.orientX
               x = obj.fileData.nCol - x - offset_x; 
            end
            
            if obj.fileData.orientY
               y = obj.fileData.nRow - y - offset_y;
            end
            
        end

        function [x, y] = CoordProcToRaw(obj, x, y)     
            
            if obj.fileData.orientY
               y = obj.fileData.nRow - y;
            end
            
            if obj.fileData.orientX
               x = obj.fileData.nCol - x; 
            end
            
            if obj.fileData.isRot
               x_temp = x;
               x = y;
               y = x_temp;
            end
        end
        
        function image = subtractBG(obj, image)
            
            % enable shutter, take an bg image, subtract this from imaga
            
            obj.bg_image = 1000*double(ones(size(image))).*sin(linspace(0, pi, size(image, 2)));
            
            image = double(image) - obj.bg_image;        
        end
        
        function printPOIs(obj)
                    % for printing on the gui
                    obj.guihan.EditField11.Value = num2str(obj.pois.raw.x_glob);
                    obj.guihan.EditField12.Value = num2str(obj.pois.raw.y_glob);
                    obj.guihan.EditField13.Value = num2str(obj.pois.raw.units);
                    obj.guihan.EditField14.Value = num2str(obj.pois.raw.isRaw);
                    
                    obj.guihan.EditField21.Value = num2str(obj.pois.raw.roiX);
                    obj.guihan.EditField22.Value = num2str(obj.pois.raw.roiY);
                    obj.guihan.EditField23.Value = num2str(obj.pois.raw.units);
                    obj.guihan.EditField24.Value = num2str(obj.pois.raw.isRaw);
                    
                    obj.guihan.EditField31.Value = num2str(obj.pois.raw.roiXNP);
                    obj.guihan.EditField32.Value = num2str(obj.pois.raw.roiYNP);
                    obj.guihan.EditField33.Value = num2str(obj.pois.raw.units);
                    obj.guihan.EditField34.Value = num2str(obj.pois.raw.isRaw);
                    
                    obj.guihan.EditField41.Value = num2str(obj.pois.rtcl_ctr.x);
                    obj.guihan.EditField42.Value = num2str(obj.pois.rtcl_ctr.y);
                    obj.guihan.EditField43.Value = num2str(obj.pois.rtcl_ctr.units);
                    obj.guihan.EditField44.Value = num2str(obj.pois.rtcl_ctr.isRaw);
                    
                    obj.guihan.EditField51.Value = num2str(obj.pois.defaultBeam.x);
                    obj.guihan.EditField52.Value = num2str(obj.pois.defaultBeam.y);
                    obj.guihan.EditField53.Value = num2str(obj.pois.defaultBeam.units);
                    obj.guihan.EditField54.Value = num2str(obj.pois.defaultBeam.isRaw);
                    
                    obj.guihan.EditField61.Value = num2str(obj.pois.beam.x);
                    obj.guihan.EditField62.Value = num2str(obj.pois.beam.y);
                    obj.guihan.EditField63.Value = num2str(obj.pois.beam.units);
                    obj.guihan.EditField64.Value = num2str(obj.pois.beam.isRaw);   
        end
                    
        function SetAxesOrigin(obj)
            
            % rescale x and y axes from pixel to mm
            % also flip the y axis labels to start from bottom right

            %obj.guihan.UIAxes2.YTick = obj.guihan.UIAxes2.YTick
            %r = obj.fileData.nRow;
            %bottom_gap = r - obj.guihan.UIAxes2.YTick(end);
            %obj.guihan.UIAxes2.YTick = [bottom_gap, obj.guihan.UIAxes2.YTick + bottom_gap];
            %obj.guihan.UIAxes2.YTick = obj.guihan.UIAxes2.YTick(1:end-1);
            %obj.guihan.UIAxes2.YTickLabel = string(flip(top_gap:top_gap:top_gap*length(obj.guihan.UIAxes2.YTick)));

            
            % YTick and pois.rtcl_ctr.y both counted from top of the image
            % if ecal on less bend is always higher energy
            xticks_pixel = obj.guihan.UIAxes2.XTick - obj.pois.rtcl_ctr.x;
            yticks_pixel = obj.pois.rtcl_ctr.y - obj.guihan.UIAxes2.YTick;
            
            obj.xticks_mm = obj.pixToMm(xticks_pixel);
            obj.yticks_mm = obj.pixToMm(yticks_pixel);          
            
            obj.guihan.UIAxes2.XTickLabel = arrayfun(@(x) sprintf('%.2f', x), obj.xticks_mm, 'UniformOutput', false);
            obj.guihan.UIAxes2.YTickLabel = arrayfun(@(x) sprintf('%.2f', x), obj.yticks_mm, 'UniformOutput', false);
            
        end
        
        function doCalE(obj)
            e_0 = 10; % [GeV] ref energy
            d_0 = 60; % [mm] ref disp at screen, has to be bigger than y size to xhair from top of plot otherwise  get negative y ticks
            %beam_y_mm_from_bottom = obj.pixToMm(obj.fileData.nRow-obj.pois.beam.y);
            %dy = d_0 + beam_y_mm_from_bottom; % [mm] from 0 disp axis to bottom of screen
            
            yticks_mm_rel_to_crosshair = obj.yticks_mm + obj.pixToMm(obj.pois.beam.y - obj.pois.rtcl_ctr.y); % [mm]
            yticks_gev = e_0 * d_0 ./ (d_0 - yticks_mm_rel_to_crosshair); % [GeV]
            obj.guihan.UIAxes2.YTickLabel = arrayfun(@(x) sprintf('%.2f', x), yticks_gev, 'UniformOutput', false);   
        end

        function doCalT(obj)
            c = 10;
            obj.guihan.UIAxes2.XTickLabel = arrayfun(@(x) sprintf('%.2f', x), c * obj.xticks_mm, 'UniformOutput', false);   
        end
        
        function PVtimerFcnCam(obj, ~, event)

          %%%%%%%%%%%%%%%
          % set buttons %
          %%%%%%%%%%%%%%%
          
          if ~obj.calEOn && ~obj.calTOn
              obj.guihan.ShowRawCheckBox.Enable = 'on';
          else
              obj.guihan.ShowRawCheckBox.Enable = 'off';
          end
          
          if obj.showRawOn
              obj.guihan.CalibrateEnergyCheckBox.Enable = 'off';
              obj.guihan.CalibrateTimeCheckBox.Enable = 'off';
          else
              obj.guihan.CalibrateEnergyCheckBox.Enable = 'on';
              obj.guihan.CalibrateTimeCheckBox.Enable = 'on';              
          end
          
          % set plot intensity limit even when live stream is stopped
          if ~obj.newPlot
              if obj.bitDepth>0
                  obj.guihan.UIAxes2.CLim = [0, 2^obj.bitDepth];
              else
                  obj.guihan.UIAxes2.CLim = obj.clim_def;
              end
          end
          
          %%%%%%%%%%%%%%%%%%%%%%%%%
          % select beam crosshair %
          %%%%%%%%%%%%%%%%%%%%%%%%%
          
          %if obj.selectBeamOn
          %    obj.SelectBeam(x, y);
          %end
          
          %%%%%%%%%%%%%%%%
          % refresh plot %
          %%%%%%%%%%%%%%%%
          
          if obj.plottingOnUIAxes2

              %%%%%%%%%%%%%%%%%%%%%%%%%
              % load new camera image %
              %%%%%%%%%%%%%%%%%%%%%%%%%
                  
              % this is processed uses lcagrab inside it might be slower
              obj.fileData = profmon_grab(obj.cameraPV); % slow bc loads all attributes there is a faster way just loads the image
                  
              %%%%%%%%%%%%%%%%%
              % get raw image %
              %%%%%%%%%%%%%%%%%
                  
              if obj.showRawOn
                assert(~obj.calEOn, 'E calibration not supported in raw mode!');
                assert(~obj.calTOn, 'Time calibration not supported in raw mode!');

                obj.ImageProcToRaw();
              end
                  
              %%%%%%%%%%%%%%%
              % fetch image %
              %%%%%%%%%%%%%%%
                  
              imageData = obj.fileData.img;

              if imageData == 0
                % If there's a problem reading image, display error message
                uialert(obj.guihan.UIAxes2,"Failed to load FACET image","Image Error");
              else
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%
                % background subtraction %
                %%%%%%%%%%%%%%%%%%%%%%%%%%
                
                if obj.subtractBGOn
                    imageData = obj.subtractBG(imageData);
                end
                
                %%%%%%%%
                % plot %
                %%%%%%%%
                
                hook = imagesc(obj.guihan.UIAxes2, imageData);
                colormap(obj.guihan.UIAxes2, 'jet');
                obj.clim_def = [min(imageData(:)), max(imageData(:))]; % get current colormap limits
                
                % colormap limits when live stream runs
                if obj.newPlot
                    obj.guihan.LogTextArea.Value = [obj.guihan.LogTextArea.Value; {char("[tcav_gui_backend.m] Selected camera PV: " + obj.cameraPV)}];
                    obj.newPlot = false;
                    
                    % set default colorap limits
                    if obj.bitDepth>0
                        obj.guihan.UIAxes2.CLim = [0, 2^obj.bitDepth];
                    else
                        obj.guihan.UIAxes2.CLim = obj.clim_def;
                    end
                end
                
                colorbar(obj.guihan.UIAxes2); 
                
                %%%%%%%%%%%%%
                % lock plot %
                %%%%%%%%%%%%%
                
                hold(obj.guihan.UIAxes2, 'on');
                
                %%%%%%%%%%%%%%%%%%%%%%%
                % get beamline coords %
                %%%%%%%%%%%%%%%%%%%%%%%
                
                % lcaGetvars are always in raw frame in pixel units
                % counted from top left corner
                % varnames are written in toolbox/profmon_propNames.m
                % or in terminal: findpv <pvname>
                % or in facethome: FACET home --> LI20 --> Profile Monitor --> PyDM All Cameras
                
                % reticular beam center on global (unzoomed) plot
                RTCL_CTR_=lcaGetSmart(strcat(obj.cameraPV,{':X';':Y'},'_RTCL_CTR'));
                [raw.x_glob,raw.y_glob,raw.units,raw.isRaw]=deal(RTCL_CTR_(1),RTCL_CTR_(2),'pixel',1);
                
                % relevant when showing zoomed image: base and extent vars
                % pv names: ROI_X is MinX_RBV and ROI_XNP is SizeX_RBV
                ROI_=lcaGetSmart(strcat(obj.cameraPV, {':MinX';':MinY';':SizeX';':SizeY'} ,'_RBV'));
                [raw.roiX,raw.roiY,raw.roiXNP,raw.roiYNP]=deal(ROI_(1),ROI_(2),ROI_(3),ROI_(4));
                          
                if ~obj.showRawOn
                    
                    % these are wrt top left corner of unzoomed processed plot
                    [raw.x_glob,raw.y_glob] = obj.CoordRawToProc(raw.x_glob,raw.y_glob);
                    
                    % only transposing matters, sign changes from flipping
                    % are omitted later by abs()
                    [raw.roiXNP,raw.roiYNP] = obj.RelCoordRawToProc(raw.roiXNP,raw.roiYNP);
                    
                    % roi base changes when flipping ie doesnt remain the 
                    % top left corner -> offset with size pvs
                    % now roi var is the top left corner on the processed
                    % zoomed plot
                    [raw.roiX,raw.roiY] = obj.CoordRawToProc(raw.roiX,raw.roiY, abs(raw.roiXNP), abs(raw.roiYNP));
                    raw.isRaw = 0;
                end
                
                % make this accessible globally
                obj.pois.raw = raw;
                
                % reticular center (0,0) of plot
                [obj.pois.rtcl_ctr.x, obj.pois.rtcl_ctr.y, obj.pois.rtcl_ctr.units, obj.pois.rtcl_ctr.isRaw] = deal(raw.x_glob-raw.roiX, raw.y_glob-raw.roiY, 'pixel', raw.isRaw);
                
                %%%%%%%%%%%%%%%%%%%
                % set axes origin %
                %%%%%%%%%%%%%%%%%%%
                
                % flips y axis inside
                obj.SetAxesOrigin();
                xlabel(obj.guihan.UIAxes2, 'x [mm]');
                ylabel(obj.guihan.UIAxes2, 'y [mm]');
                
                %%%%%%%%%%%%%%%%%%
                % beam crosshair %
                %%%%%%%%%%%%%%%%%%
                
                % beam arc is relative to reticular arc in mm in
                % processed frame ie not always at (0,0) on the plot
                crossBM_=lcaGetSmart(strcat(obj.cameraPV,{':X';':Y'},'_BM_CTR'));
                [crossBM.x,crossBM.y,crossBM.units,crossBM.isRaw]=deal(crossBM_(1),-crossBM_(2),'mm',0); % flip y axis here
                  
                % convert mm to pixel
                crossBM.x = obj.mmToPix(crossBM.x);
                crossBM.y = obj.mmToPix(crossBM.y);

                if obj.showRawOn
                  [crossBM.x,crossBM.y] = obj.RelCoordProcToRaw(crossBM.x,crossBM.y);
                  crossBM.isRaw = 1;
                end
                
                % beam crosshair in pixels counted from top left of plot. do ecal wrt this, in pixels
                [obj.pois.defaultBeam.x, obj.pois.defaultBeam.y, obj.pois.defaultBeam.units, obj.pois.defaultBeam.isRaw] = deal(obj.pois.rtcl_ctr.x + crossBM.x, obj.pois.rtcl_ctr.y + crossBM.y, 'pixel', crossBM.isRaw);
                
                %%%%%%%%%%%%%%%%%%%%%%%
                % update clickability %
                %%%%%%%%%%%%%%%%%%%%%%%
                
                if obj.selectBeamOn
                    hook.ButtonDownFcn = @(src, event) obj.guihan.imageClicked(src, event);
                    hook.PickableParts = 'all';
                    hook.HitTest = 'on';

                    % here it can occur that the point was selected in one
                    % frame and later the frame changed
                    if obj.pois.beam.isRaw && ~obj.showRawOn
                        [obj.pois.beam.relx, obj.pois.beam.rely] = obj.RelCoordRawToProc(obj.pois.beam.relx, obj.pois.beam.rely);
                    elseif ~obj.pois.beam.isRaw && obj.showRawOn
                        [obj.pois.beam.relx, obj.pois.beam.rely] = obj.RelCoordProcToRaw(obj.pois.beam.relx, obj.pois.beam.rely);
                    end
                    obj.pois.beam.isRaw = obj.showRawOn;
                else
                    
                    hook.ButtonDownFcn = [];
                    hook.PickableParts = 'none';
                    hook.HitTest = 'off';
                    [obj.pois.beam.relx, obj.pois.beam.rely, obj.pois.beam.isRaw] = deal(0,0, obj.pois.defaultBeam.isRaw);
                end

                [obj.pois.beam.x, obj.pois.beam.y, obj.pois.beam.units] = deal(obj.pois.defaultBeam.x+obj.pois.beam.relx, obj.pois.defaultBeam.y+obj.pois.beam.rely, obj.pois.defaultBeam.units);
                
                %%%%%%%%%%%%%%%%%%%%%%%
                % plot beam crosshair %
                %%%%%%%%%%%%%%%%%%%%%%%
                
                if obj.showBMOn
                    
                    % only draw crosshair if inside zoomed region
                    if obj.pois.defaultBeam.x > 0 && obj.pois.defaultBeam.x <= abs(obj.pois.raw.roiXNP) ...
                            && obj.pois.defaultBeam.y > 0 && obj.pois.defaultBeam.y <= abs(obj.pois.raw.roiYNP) 
                       plot(obj.guihan.UIAxes2, obj.pois.defaultBeam.x, obj.pois.defaultBeam.y, 'w+', 'MarkerSize', 20, 'LineWidth', 2);
                    end
                                            
                    if obj.pois.beam.x > 0 && obj.pois.beam.x <= abs(obj.pois.raw.roiXNP) ...
                            && obj.pois.beam.y > 0 && obj.pois.beam.y <= abs(obj.pois.raw.roiYNP)
                        plot(obj.guihan.UIAxes2, obj.pois.beam.x, obj.pois.beam.y, 'y+', 'MarkerSize', 10, 'LineWidth', 2);
                    end
                    
                    obj.printPOIs();
                
                end
                
                %%%%%%%%%%%%%%%%%%%%%%%%%
                % do energy calibration %
                %%%%%%%%%%%%%%%%%%%%%%%%%
                
                if obj.calEOn
                    assert(~obj.showRawOn, 'E calibration not supported in raw mode!');
                    ylabel(obj.guihan.UIAxes2, 'E [GeV]');
                    obj.doCalE();
                end
                
                %%%%%%%%%%%%%%%%%%%%%%%
                % do time calibration %
                %%%%%%%%%%%%%%%%%%%%%%%
                
                if obj.calTOn
                    assert(~obj.showRawOn, 'Time calibration not supported in raw mode!');
                    xlabel(obj.guihan.UIAxes2, 'z [mm]');
                    obj.doCalT();
                end
                
                %%%%%%%%%%%%%%%%
                % release hold %
                %%%%%%%%%%%%%%%%
                
                hold(obj.guihan.UIAxes2, 'off');
                
                %%%%%%%%%%%%%%%%%
                % profile plots %
                %%%%%%%%%%%%%%%%%
                
                obj.colSum = sum(imageData, 1);
                obj.rowSum = sum(imageData, 2);
                
                obj.guihan.updateTopProfilePlot(obj.colSum, 'b');
                obj.guihan.updateRightProfilePlot(obj.rowSum, 'b');
                
              end  
          end
        end
        
        %select point on plot to mark new beam crosshair
        function [x, y] = SelectBeam(obj, x, y)
           hImg = findobj(app.UIAxes2, 'Type', 'image');
           if isempty(hImg)
               uialert(app.UIFigure, 'No image to select from!', 'Error');
               return;
           end
           CData = hImg.CData;
           f = figure;
           ax = axes('Parent', f);
           imshow(CData, 'Parent', ax);
           [x, y] = ginput(1);
           
        end

        function imageData = loadFacetImage(obj)
            try
                %fileData = load('/u1/facet/matlab/data/2025/2025-06/2025-06-02/ProfMon-CAMR_LI20_107-2025-06-02-235512.mat');
                fileData = profmon_grab("CAMR:LI20:302"); % slow bc loads all attributes there is a faster way just loads the image
                %imageData = fileData.data.img; [um/pixel]
                % orient X and Y: flip hor and vert
                % isRot: transpoes image data.img' if it is 1
                % rotX and Y, roiXN, YN: size of field of view, zoom
                imageData = fileData.img;
                
                
                % kdeering/gitwork/TCAV_GUI/test_gui.mlapp
                % apply e calibration longitudinal cal
                % BM: beamline CAMR:LI20:302:X_BM_CTR in reference to the 0
                % on screen see below
                % matlab support pvs 301-350
                % DTOTR2_CAMR:107_eta nominal dispersion PV, dnom in
                % formula
                % y_10gev: position on screen where 10GeV is located ie
                % centroid of image ofr a 10 GeV beam
                % CAMR:LI20:302:X_RTCL_CTR: defines where 0 is on screen
                
            catch
                imageData = 0;
            end
        end
        
        function closeApp(obj)
        end
    end
end