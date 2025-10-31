function [img, x, y, res, xmm, ymm, bkgd] = load_images(app, data_struct, header, cam, ind_analyse)

try
    HDF5 = strcmp(data_struct.params.saveMethod, 'HDF5');
catch
    HDF5 = 0;
end

% reads all h5 files in one images/camera folder
app.LogTextArea.Value = [app.LogTextArea.Value; {char("[load_images.m] Reading h5 files for camera: " + cam)}];
[img, x, y, res, xmm, ymm, bkgd] = read_HDF5steps(app, data_struct, header, cam, ind_analyse);

end
