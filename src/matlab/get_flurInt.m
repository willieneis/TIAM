function datacell = get_flurInt(datacell,videocell_flur,halfCropSize_flur,whichFlurChannel)
% this function returns fluorescence data from channel whichFlurChannel within the footprint of each cell.

% default params if not specified
if nargin<4, whichFlurChannel=1; end
if nargin<3, halfCropSize_flur=25; whichFlurChannel=1; end

% for every frame in every cell path, get fluor value for given cell
% ------------------------------------------------------------------
for cp = 1:size(datacell,2)	
	for pos = 1:size(datacell{cp},1)
                
        frame = datacell{cp}(pos, 1) + pos -1;
        center_x = round(datacell{cp}(pos, 3)); % rounded to nearest integer
        center_y = round(datacell{cp}(pos, 4));
        
        halfcropXsize = halfCropSize_flur; %size influences how watershed works (because the size determines the gradient)
        halfcropYsize = halfCropSize_flur;
        if center_x<=halfcropXsize
            halfcropXsize=center_x-1;
        elseif center_x+halfcropXsize>=size(videocell_flur{frame},2)
            halfcropXsize=size(videocell_flur{frame},2)-center_x; % column value corresponds to x-coordinate of the pixel
        end % to account for centroids that are too close the edges of the frames
        if center_y<=halfcropYsize
            halfcropYsize=center_y-1;
        elseif center_y+halfcropYsize>=size(videocell_flur{frame},1)
            halfcropYsize=size(videocell_flur{frame},1)-center_y; % row value corresponds to y-coordinate of the pixel
        end % to account for centroids that are too close the edges of the frames

        if(length(size(videocell_flur{1,frame})) == 3)
            I=rgb2gray(videocell_flur{frame});
        else I=videocell_flur{frame};
        end 

        medianFrmInt = mean(median(I));
        I = imcrop(I, [uint16(center_x-halfcropXsize) uint16(center_y-halfcropYsize) halfcropXsize*2 halfcropYsize*2]);
        meanFlurInt=I(halfcropYsize+1,halfcropXsize+1);
        % the first pixel in the cropped image corresponds to center_y-halfcropsize and center_x-halfcropsize in the original image
        % actual size of the cropped image is twice the halfcropsize plus 1
        % thus centroid pixel(halfcropYsize+1,halfcropXsize+1) is the absolute center pixel and there are equal number of pixels on all sides
        % unit16 converts to unsigned 16-bit integer type
        
        Ifilt = medfilt2(I, [4 4]); % going from default [3 3] helped too
        [threshLevel EM] = graythresh(Ifilt); %doing min-max normalization might help with higher EM values, but I didn't implement it
        if EM > 0.001 % for majority 0.1 works; had to go very low for some, but still this doesn't give spurious outlines
            Ibw = im2bw(Ifilt,threshLevel);
        else 
            break
        end    
        img = imfill(Ibw,'holes');
        seD=strel('disk',1); % 3 worked well without imhmax;  1 worked reasonable with imhmax
        img = imdilate(img, seD); % initially it looked like the cell flourescence was observed slightly outside the outline, hence the fix.
        imgDist=bwdist(~img, 'euclidean'); 
        imgDist=imhmax(imgDist, 1); % will suppress the maxima if lower than 1. 1 worked reasonably; without suppression you get oversegmentation
        imgDist=-imgDist; % need to create catchment for watershed, hence -ve   
        imgDist(~img)=-inf; % '~' inverts the image; sets zero values to negative infinity which ensures that the background doesn't get segmented by watershed
        imgLabel=watershed(imgDist); 
        %assigns 0 values to all the boundary pixels and positive integers (labels) to regions

        stats=regionprops(imgLabel,'basic');
        % the component/label with the largest area appears to be the 1st component, which is also the background;
        % but at times the background is split into two components/labels

        dist=zeros(size([stats.Area]));
        for i=1:length(dist)
            dist(i)=pdist([stats(i).Centroid;halfcropXsize+1,halfcropYsize+1],'euclidean');
            % distance between the centroid of the object and center pixel of the cropped box
            % centroid of the background component also tends to be very close to center pixel of the box
        end
        %save('label','imgLabel', 'stats', 'dist', 'I', 'img');
        
        count=zeros(size([stats.Area])); % counts the number of background pixels in a component
        overlap=zeros(size([stats.Area])); % counts the fraction of background pixels in a component
        for x=1:size(imgLabel,2)
           for y=1:size(imgLabel,1)
               if img(y,x)==0 % if background pixel; y corresponds to row and x to column
                   label=imgLabel(y,x); 
                   count(label)=count(label)+1;
               end
           end
        end
        for label=1:length([stats.Area])
            overlap(label)=count(label)/stats(label).Area;
        end    
        %display(overlap);
               
        if length(dist) == 1 %if there is only one component (background only) take average from the background
            meanFlurInt=mean2(I);
        elseif length(dist) >= 2 % if there are two or more components, pick the foreground component based on multiple conditions
            [temp,index]=sort([stats.Area],'descend'); %sorts in the descending order of area
            % index holds the indices of the elements that were sorted 
            for i=1:length(dist) % consider the component based on larger area
                if overlap(index(i))<0.1 && mean2(I(imgLabel==index(i))) > medianFrmInt+8 && dist(index(i))<10 
                % low overlap with background, at least some contact area, higher intensity than background and closer to the center of the cropped image
                   meanFlurInt=mean2(I(imgLabel==index(i))); % only consider the pixels corresponding to the chosen component for mean intensity, as a mask
                   break
               end
            end   
        end
        
        if whichFlurChannel==1
            datacell{cp}(pos,6) = meanFlurInt;
        elseif whichFlurChannel==2
            datacell{cp}(pos,7) = meanFlurInt;
        else
            fprintf('Neither whichFlurChannel=1 nor whichFlurChannel=2 was specified. Datacell not updated.\n');
        end
	end
	fprintf('fluorescence calculation complete for cell-track: %d/%d \n',cp,size(datacell,2));
end



