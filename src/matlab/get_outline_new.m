
function datacell = get_outline_new(datacell, videocell, halfCropSize, whichChannel, detectParams, pathToDir, expName)
% save the cropped image of the cell with the outline depending on the chosen channel

% loop through each cellpath and each frame therein
% -------------------------------------------------

for cp = 1 : size(datacell, 2)
    %display(cp);
	for pos = 1 : size(datacell{cp}, 1)
        %display(pos);
        frame = datacell{cp}(pos, 1) + pos -1;
        center_x = round(datacell{cp}(pos, 3)); % rounded to nearest integer
        center_y = round(datacell{cp}(pos, 4));
        
        halfcropXsize = halfCropSize; %size influences how watershed works (because the size determines the gradient)
        halfcropYsize = halfCropSize;
        if center_x<=halfcropXsize
            halfcropXsize=center_x-1;
        elseif center_x+halfcropXsize>=size(videocell{frame},2)
            halfcropXsize=size(videocell{frame},2)-center_x; % column value corresponds to x-coordinate of the pixel
        end % to account for centroids that are too close the edges of the frames
        if center_y<=halfcropYsize
            halfcropYsize=center_y-1;
        elseif center_y+halfcropYsize>=size(videocell{frame},1)
            halfcropYsize=size(videocell{frame},1)-center_y; % row value corresponds to y-coordinate of the pixel
        end % to account for centroids that are too close the edges of the frames

        if(length(size(videocell{1,frame})) == 3)
            I=rgb2gray(videocell{frame});
        else I=videocell{frame};
        end 

        medianFrmInt=mean(median(I));
        I = imcrop(I, [uint16(center_x-halfcropXsize) uint16(center_y-halfcropYsize) halfcropXsize*2 halfcropYsize*2]);
        % the first pixel in the cropped image corresponds to center_y-halfcropsize and center_x-halfcropsize in the original image
        % actual size of the cropped image is twice the halfcropsize plus 1
        % thus centroid pixel(halfcropYsize+1,halfcropXsize+1) is the absolute center pixel and there are equal number of pixels on all sides
        % unit16 converts to unsigned 16-bit integer type
        
        % process based on the channel
        % ------------------------------------
        if whichChannel==4 %if DIC/transmitted channel
          
            [Ie,thresh] = edge(I,'canny'); %[temp,thresh] = edge(Ifilt,'canny');
            %Ie = edge(I, 'canny', 0.7*thresh, 0.8); %0.7*thresh for exp1
            Ie = edge(I, 'canny', 1.3*thresh, 0.8); %1.3*thresh for exp5
            %Ie=edge(I, 'canny', detectParams(2), 0.8); % using input edgevalue didn't help
            Icht = im2uint8(Ie); % needed for CircularHough_Grd function
            
            % structural elements
            se90 = strel('line', 3, 90);
            se0 = strel('line', 3, 0);
            disk3 = strel('disk', 3);  % 4/3 for exp1 and 3 for exp5; 4/3 worked well overall and didn't cause cells to merge after dilation
            disk2 = strel('disk', 2);

            % take canny image and dilate, fill, erode, and dilate
            Id = imdilate(Ie, [se90, se0]);
            If = imfill(Id, 'holes');
            Ir = imerode(If, disk3);
            img = imdilate(Ir, disk2);
            centerBlob = imerode(img, disk2);
            
            % circular hough transform
            %[accum, circen, cirrad] = CircularHough_Grd(test, [rad_min rad_max], gradientThresh, searchRadius);  % function call format
            accum=CircularHough_Grd(Icht, [round(detectParams(3)/detectParams(1)) round(detectParams(4)/detectParams(1))], detectParams(5), detectParams(6)); % [7 15]
            %accum1=imhmax(accum,300); % 1000 appeared to worked well; 
            %ultimately I didn't need to suppress local maxima as there was no difference with and without suppression 
            imgDist=imimposemin(-accum,centerBlob); % forces the minimum to be on the centerBlob
        
        elseif whichChannel==1 %if IRM channel
            Ifilt = medfilt2(I);
            [threshLevel EM] = graythresh(Ifilt); %doing min-max normalization might help with higher EM values, but I didn't implement it
            if EM > 0.001 % for majority a value higher than 0.3 works; but even very low value didn't give spurious outlines
                Ibw = not(im2bw(Ifilt,threshLevel)); 
            else 
                break
            end    
            img = imfill(Ibw,'holes');
            seD=strel('disk',1); % 1 works very well with imhmax(higher likely creates more merges); 2 worked well without imhmax
            img = imdilate(img, seD); % initially it looked like some IRM was observed slightly outside the outline, hence the fix.
            imgDist=bwdist(~img, 'euclidean'); % euclidean was better than chessboard or cityblock
            imgDist=imhmax(imgDist, 2); % will suppress the maxima if lower than 2. 2 worked well, higher started merging cells; without suppression you get oversegmentation
            imgDist=-imgDist; % need to create catchment for watershed, hence -ve  
            
        elseif whichChannel==2 || whichChannel==3 %if flur channel
            Ifilt = medfilt2(I, [4 4]); % [3 3] for medfilt2, but [4 4] worked well 
            [threshLevel EM] = graythresh(Ifilt); %doing min-max normalization might help with higher EM values, but I didn't implement it
            if EM > 0.001 % for majority 0.1 works; had to go very low for some, but still this doesn't give spurious outlines
                Ibw = im2bw(Ifilt,threshLevel);
            else 
                break
            end    
            img = imfill(Ibw,'holes');
            seD=strel('disk',1); % 3 worked well without imhmax; 1 worked reasonable with imhmax
            img = imdilate(img, seD); % initially it looked like the cell flourescence was observed slightly outside the outline, hence the fix.
            imgDist=bwdist(~img, 'euclidean'); 
            imgDist=imhmax(imgDist, 1); % will suppress the maxima if lower than 1. 1 worked reasonably; without suppression you get oversegmentation
            imgDist=-imgDist; % need to create catchment for watershed, hence -ve      
        end 
        
        imgDist(~img)=-inf; % '~' inverts the image; sets zero values to negative infinity which ensures that the background doesn't get segmented by watershed
        imgLabel=watershed(imgDist)>0; 
        %watershed assigns 0 values to all the boundary pixels and positive integers (labels) to regions
        % but by having '>0' only non-zero values are stored in imgLabel.
        % This allows me to do the .* operation (because of compatible data-type) later on so that I can use bwlabel function. This will eliminate the need to handle background as a component.
        bwLabel=img.*imgLabel;
        imgLabel=bwlabel(bwLabel);
        
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
 
        boundary=zeros(size(imgLabel));
        if length(dist) >= 2 % if there are two or more components, pick the foreground component based on multiple conditions
        
        % showing the outline of the box was necessary only for code development purposes.    
        %if length(dist) == 1 %if there is only one component (background only) pick it
            %boundary = bwperim(imgLabel,8); %the outline will be the box edges;
            % bwperim gives the outer edges of the objects as an image and doesn't draw a boundary outside the object
            % bwboundaries gives the outer edges of the objects as a cell array containing the pixel positions (row/col indices) 
        %elseif length(dist) >= 2 % if there are two or more components, pick the foreground component based on multiple conditions
            if whichChannel==4 % DIC
                [temp,index]=sort([stats.Area], 'descend'); %sorts in the descending order of area
                % index holds the indices of the elements that were sorted 
                for i=1:length(dist) % to pick based on proximity to the center of the cropped image
                    if dist(index(i))<10 % closer to the center of the cropped image
                        imgLabel(imgLabel~=index(i))=0; % set the rest to zero to make it a binary image
                        boundary=bwperim(imgLabel,8);
                        break
                    end
                end
            elseif whichChannel==1 %IRM
                [temp,index]=sort([stats.Area], 'descend'); %sorts in the descending order of area
                % index holds the indices of the elements that were sorted 
                for i=1:length(dist) % consider the component based on larger area
                    if mean2(I(imgLabel==index(i)))+8 < medianFrmInt && dist(index(i))<10
                    % low overlap with background, lower intensity than background and closer to the center of the cropped image
                        imgLabel(imgLabel~=index(i))=0; % set the rest to zero to make it a binary image 
                        boundary = bwperim(imgLabel,8);
                        break
                    end
                end
            elseif whichChannel==2 || whichChannel==3 %flur
                [temp,index]=sort([stats.Area], 'descend'); %sorts in the descending order of area
                % index holds the indices of the elements that were sorted 
                for i=1:length(dist) % consider the component based on larger area
                    if mean2(I(imgLabel==index(i))) > medianFrmInt+8 && dist(index(i))<10
                    % low overlap with background, higher intensity than background and closer to the center of the cropped image
                        imgLabel(imgLabel~=index(i))=0; % set the rest to zero to make it a binary image 
                        boundary = bwperim(imgLabel,8);
                        break
                    end
                end
            end              
        end

        if whichChannel==4 || whichChannel==1 %DIC or IRM channel
            I(boundary == 1) = 0; % the pixels identified as boundary pixels (value 1) in 'boundary' are set to 0 in I giving a black outline
        elseif whichChannel==2 || whichChannel==3 %flur channel
            I(boundary ==1) = 255; % gives white outline
        end
        
        videocell{frame}(uint16(center_y-halfcropYsize):uint16(center_y+halfcropYsize), uint16(center_x-halfcropXsize):uint16(center_x+halfcropXsize))=I;
        %datacell{cp}(pos,20) = I; % can't write a matrix into an entry in the matrix!
    end
    % display information
	fprintf('outline extraction complete for cell-track: %d/%d \n',cp,size(datacell,2));
    
end    

% write the images with outline to a tiff file
tiffFileName = [pathToDir,'ws/', expName,'_outline.tif'];
I=videocell{1};
imwrite(I,tiffFileName);
for frame = 2 : size(videocell, 2)
    I=videocell{frame};
    imwrite(I,tiffFileName,'WriteMode','append'); % append images into a tiff-series file
end
  
