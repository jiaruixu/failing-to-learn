% --------------------------------------------------------
% MDP Tracking
% Copyright (c) 2015 CVGL Stanford
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
%
% read KITTI file
function dres = read_kitti2dres(filename, is_preserving_original_format)

if nargin < 2
    is_preserving_original_format = 0;
end

fprintf('loading kitti file %s\n', filename);

threshold_det_car = 0.4;
threshold_det_people = 0.5;

% count columns
fid = fopen(filename, 'r');
l = strtrim(fgetl(fid));
ncols = numel(strfind(l,' '))+1;
fclose(fid);

% <frame>, <id>, <type>, <truncated>, <occluded>, <alpha>, 
% <bb_left>, <bb_top>, <bb_right>, <bb_bottom>, <3D height>, <3D width>, <3D length>
% <3D x>, <3D y>, <3D z>, <rotation y>, <conf>
fid = fopen(filename);
try
    if ncols == 17 % ground truth file
        C = textscan(fid, '%d %d %s %d %d %f %f %f %f %f %f %f %f %f %f %f %f');
    elseif ncols == 18
        C = textscan(fid, '%d %d %s %d %d %f %f %f %f %f %f %f %f %f %f %f %f %f');
    else
        error('This file is not in KITTI tracking format.');
    end
catch
    error('This file is not in KITTI tracking format.');
end
fclose(fid);

% build the dres structure for detections
dres.fr = C{1} + 1;  % 1-based frame
dres.id = C{2} + 1;  % 1-based id
dres.type = C{3};
for i=1:numel(dres.type)
    if strcmp(dres.type{i},'Car') == 1 || strcmp(dres.type{i},'Van') == 1 || strcmp(dres.type{i},'car') == 1
        dres.type{i} = 'car';
    elseif strcmp(dres.type{i},'Truck') == 1 || strcmp(dres.type{i},'bus') == 1
        dres.type{i} = 'bus';
    elseif strcmp(dres.type{i},'Pedestrian') == 1 || strcmp(dres.type{i},'Person_sitting') == 1 || strcmp(dres.type{i},'Person') == 1 || strcmp(dres.type{i},'person') == 1
        dres.type{i} = 'person';
    elseif strcmp(dres.type{i},'Cyclist') == 1 || strcmp(dres.type{i},'bicycle') == 1
        dres.type{i} = 'bicycle';
    elseif strcmp(dres.type{i},'Tram') == 1 || strcmp(dres.type{i},'train') == 1
        dres.type{i} = 'train';
    elseif strcmp(dres.type{i},'Misc') == 1 || strcmp(dres.type{i},'DontCare') == 1
        dres.type{i} = 'DontCare';
    elseif strcmp(dres.type{i},'DontCare') == 0
        fprintf('Unknown label! \n');
        return;
    end
end
dres.x = C{7};
dres.y = C{8};
dres.w = C{9}-C{7}+1;
dres.h = C{10}-C{8}+1;
if ncols == 17
    dres.r = zeros(size(C{1}));
    if is_preserving_original_format
        return
    end
    % substraction
    index = find(dres.id > 0);
    dres = sub(dres, index);    
else
    dres.r = C{18};
    if is_preserving_original_format
        return
    end
    is_car = strcmp('car', dres.type) | strcmp('Car', dres.type) | strcmp('Van', dres.type);
    is_person = strcmp('person', dres.type) | strcmp('Pedestrian', dres.type);
    % substraction
    index_car = find(dres.r > threshold_det_car & is_car);
    index_other = find(dres.r > threshold_det_people & ~is_car);
    index = [index_car; index_other];
    dres = sub(dres, index);
    % remove pedestrian with wrong aspect ratios
    is_person = strcmp('person', dres.type) | strcmp('Pedestrian', dres.type);
    ratios = dres.h ./ dres.w;
    ind = ~(is_person & ratios < 0.9);
    index = find(ind == 1);
    dres = sub(dres, index);    
end