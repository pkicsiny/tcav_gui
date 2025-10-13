
function [img, x, y, res, xmm, ymm, bkgd] = read_HDF5steps(app, data_struct, header, cam, ind_analyse, doplot);

% [img, x, y, res, xmm, ymm] = read_img(data_struct, header, cam, n, doplot, isrot)
%
% data_struct and header come from findDAQ function
% cam is camera name, i.e. LFOV, DTOTR2, etc
% n is index from dataset
% doplot = 1 plots the image
% isrot = 1 rotates the image. Use trial and error. Could be written in as a if loop

%image data
comIndImg  = data_struct.images.(cam).common_index;
comIndScal = data_struct.scalars.common_index;
imgmeta = data_struct.metadata.(cam);
nsteps = max( [data_struct.params.totalSteps 1]); 
n_shot = data_struct.params.n_shot;

try
    isrot = imgmeta.IS_ROTATED;
catch
    isrot = 1;
end

res = imgmeta.RESOLUTION;


% Load the BG
if data_struct.backgrounds.getBG==1
    try
        bkgd = uint16(data_struct.backgrounds.(cam))';
    catch
        warning('Bkgd image does not exist!');
        bkgd=[];
    end
elseif data_struct.backgrounds.getBG==0
    bkgd=[];
elseif exist('bkgdfile')
    load(bkgdfile)
end

bkgd = uint16(bkgd);

app.LogTextArea.Value = [app.LogTextArea.Value; {char("[read_HDF5steps.m] Loading " + cam + " HDF5 files...")}];

h5fn = sprintf('%s%s',header,data_struct.images.(cam).loc{1});
for s = 1:max([nsteps 1])
    h5fnstep = sprintf('%s%s%s', h5fn(1:(end-5)), num2str(s, '%02d'), h5fn((end-2):end));
    app.LogTextArea.Value = [app.LogTextArea.Value; {char(h5fnstep)}];
    imData{s} = h5read(h5fnstep,'/entry/data/data');
end

app.LogTextArea.Value = [app.LogTextArea.Value; {'[read_HDF5steps.m] Loading images...'}];

% Loop through h5 files
for s = 1:max([nsteps 1])
    
    % equals number of shots with given phase value
    N_inStep = size(imData{s},3);

    % Loop through the images in each h5 file 
    for ns = 1:N_inStep

        % calculate index
        index = (s-1)*n_shot + ns;

        %disp(index/(nsteps*n_shot)*100);

        [inIndex, loc] = ismember(index, comIndImg(ind_analyse));
        if inIndex
            n = ind_analyse(loc);
            indImg  = comIndImg(n);
            indScal = comIndScal(n);


            img{n} = imData{s}(:,:,ns)';


            if length(bkgd)>0
                img{n} = img{n}-bkgd;
            end

            % Check orientations
            if strcmp(imgmeta.X_ORIENT, 'Positive')
                img{n}  = flipud(img{n});
            end
            if strcmp(imgmeta.Y_ORIENT, 'Positive')
                img{n} =  fliplr(img{n});
            end

            % rotate image if required
            if ~isrot
                img{n} = img{n}';
            end

            % Do some basic filtering
            img{n} = medfilt2(img{n});


            if strcmp(cam, 'CHER')
                x = 660:1395;
                x = 227:1300; % after 2024-10
                x = 227:1000; % after 2024-11

                img{n} = img{n}(x,:);

                img{n}(640:643, 1660:1668) = img{n}(640:643, 1660:1668)*0;
                img{n}(656:659, 1713:1716) = img{n}(656:659, 1713:1716)*0;
                img{n}(659:663, 1722:1727) = img{n}(659:663, 1722:1727)*0;
                img{n}(665:670, 1739:1750) = img{n}(665:670, 1739:1750)*0;

            end
        end
    end
end

app.LogTextArea.Value = [app.LogTextArea.Value; {'[read_HDF5steps.m] Images successfully loaded!'}];

if strcmp(cam, 'CHER') || strcmp(cam, 'DTOTR1')
    x = 1:2040;
    y = 1:2040; % Force the ROI to be full ROI
else
    % Get ROI details
    minXROI = imgmeta.MinY_RBV;
    maxXROI = minXROI+imgmeta.ROI_SizeY_RBV-1;
    x = minXROI:maxXROI;
    minYROI = imgmeta.MinX_RBV;
    maxYROI = minYROI+imgmeta.ROI_SizeX_RBV-1;
    y = minYROI:maxYROI;
end

% rotate image if required
if ~isrot
    xold = x;
    x = y;
    y = xold;
end
xmm = x*res*1e-3;  ymm = y*res*1e-3;
% the orientation should now be image(xpixel, ypixel), and use imagesc(x,y,img)


if strcmp(cam, 'CHER')
    x = 660:1395;
    x = 227:1300; % after 2024-10
    x = 227:1000; % after 2024-11
    xmm = xmm(x);
end






end


