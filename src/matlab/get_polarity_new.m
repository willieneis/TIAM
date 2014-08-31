function datacell = get_polarity_new(datacell, videocell, halfCropSize, detectParams)

% this function returns a datacell with polarity in column 41
	% only to be used after get_outline has been called on datacell (filling columns 17-40 with DIC outline data)

for cp = 1 : size(datacell, 2)
	for pos = 1 : size(datacell{cp}, 1)
        eccentricity=1; % 0 for circle 1 for line
        circularity=0; % 1 for circle, 0 for line
        aspectRatio=0; % no axis (is a point); above 1 for deviations from circle
        
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

        I = imcrop(I, [uint16(center_x-halfcropXsize) uint16(center_y-halfcropYsize) halfcropXsize*2 halfcropYsize*2]);
        % the first pixel in the cropped image corresponds to center_y-halfcropsize and center_x-halfcropsize in the original image
        % actual size of the cropped image is twice the halfcropsize plus 1
        % thus centroid pixel(halfcropYsize+1,halfcropXsize+1) is the absolute center pixel and there are equal number of pixels on all sides
        % unit16 converts to unsigned 16-bit integer type
        
        [Ie,thresh] = edge(I,'canny'); %[temp,thresh] = edge(Ifilt,'canny');
        %Ie = edge(I, 'canny', 0.7*thresh, 0.8); %0.7*thresh for exp1
        Ie = edge(I, 'canny', 1.3*thresh, 0.8); % 1.3*thresh for exp5
        %Ie=edge(I, 'canny', detectParams(2), 0.8); % using the input edge value didn't work
        Icht = im2uint8(Ie); % needed for CircularHough_Grd function
            
        % structural elements
        se90 = strel('line', 3, 90);
        se0 = strel('line', 3, 0);
        disk3 = strel('disk', 3); % 4/3 for exp1 and 3 for exp5; 4/3 worked well overall and didn't cause cells to merge after dilation
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
        
        imgDist(~img)=-inf; % '~' inverts the image; sets zero values to negative infinity which ensures that the background doesn't get segmented by watershed
        imgLabel=watershed(imgDist)>0; 
        %watershed assigns 0 values to all the boundary pixels and positive integers (labels) to regions
        % but by having '>0' only non-zero values are stored in imgLabel.
        % This allows me to do the .* operation (because of compatible data-type) later on so that I can use bwlabel function. This will eliminate the need to handle background as a component.
        bwLabel=img.*imgLabel;
        imgLabel=bwlabel(bwLabel);
        
        stats=regionprops(imgLabel,'Area', 'BoundingBox', 'Centroid', 'Eccentricity', 'MajorAxisLength', 'MinorAxisLength', 'Perimeter');
        % the component/label with the largest area appears to be the 1st component, which is also the background;
        % but at times the background is split into two components/labels

        dist=zeros(size([stats.Area]));
        for i=1:length(dist)
            dist(i)=pdist([stats(i).Centroid;halfcropXsize+1,halfcropYsize+1],'euclidean');
            % distance between the centroid of the object and center pixel of the cropped box
            % centroid of the background component also tends to be very close to center pixel of the box
        end
        %save('label','imgLabel', 'stats', 'dist', 'I', 'img');
        
        if length(dist) == 1 %if there is only one component (background only) pick it
            eccentricity=1; circularity=0; aspectRatio=0;
        elseif length(dist) >= 2 % if there are two or more components, pick the foreground component that is closest to the center pixel of the cropped box
            [temp,index]=sort([stats.Area], 'descend'); %sorts in the descending order of area
            % index holds the indices of the elements that were sorted 
            for i=1:length(dist) % to pick based on proximity to the center of the cropped image
                if dist(index(i))<10 % closer to the center of the cropped image   
                   eccentricity=stats(index(i)).Eccentricity; 
                   circularity=(4*pi*stats(index(i)).Area)/(stats(index(i)).Perimeter)^2; 
                   aspectRatio=stats(index(i)).MajorAxisLength/stats(index(i)).MinorAxisLength;
                   break
               end
            end   
        end

        datacell{cp}(pos,17) = eccentricity;
        datacell{cp}(pos,18) = circularity;
        datacell{cp}(pos,19) = aspectRatio;

    end
    
    % display information
	fprintf('polarity calculation complete for cell-track: %d/%d \n',cp,size(datacell,2));
    
end    
