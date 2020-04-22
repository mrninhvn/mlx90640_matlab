clear;
clc;
D = 12.2;
global com;
com = serial('COM10','BaudRate',250000,'Terminator','CR');
com.InputBufferSize = 10000;
fopen(com);
% for n = 1:20
    raw = fscanf(com);
    cell = split(raw,",");
    img = zeros(24,64);
    imgL = zeros(24,32);
    imgR = zeros(24,32);
    for i = 0:23
        for j = 1:32
            imgR(i+1, j) = str2num(cell2mat(cell(64*i+j+1,1)));
        end
        for k = 33:64
            imgL(i+1, k-32) = str2num(cell2mat(cell(64*i+k+1,1)));
        end
    end
    
    senRight = axes(figure(1));    
    imagesc(imgR, 'Parent', senRight);
%     colorbar;
    title(senRight, 'Sensor right');
    drawnow;
    FR = getframe;
    
    senLeft = axes(figure(2));
    imagesc(imgL, 'Parent', senLeft);
%     colorbar;
    title(senLeft, 'Sensor left');
    drawnow;
    FL = getframe;
    
    imgL = imresize(imgL,[360 480]);
    imgR = imresize(imgR,[360 480]);
    
    sigma = 5;
    imageL = imgaussfilt(frame2im(FL),sigma);
    imageR = imgaussfilt(frame2im(FR),sigma);
    imageL = imresize(imageL,[360 480]);
    imageR = imresize(imageR,[360 480]);
    
%     figure(3);    
%     imageL = imadjust(imageL,[0.75 1],[]);
%     imageL = imsharpen(imageL,'Radius',2,'Amount',50);
%     imageR = imadjust(imageR,[0.75 1],[]);
%     imageR = imsharpen(imageR,'Radius',2,'Amount',50);
%     imshowpair(imageL, imageR,'montage');
%     title('Image 1 (left); Image 2 (right)');
    
    Lgray = rgb2gray(imageL);
    Rgray = rgb2gray(imageR);
    
    blobs1 = detectSURFFeatures(Lgray, 'MetricThreshold', 2000);
    blobs2 = detectSURFFeatures(Rgray, 'MetricThreshold', 2000);
    
    figure(4);
    imshow(imageR);
    hold on;
    plot(selectStrongest(blobs2, 30));
    title('Thirty strongest SURF features in right sensor');
    
    figure(5);
    imshow(imageL);
    hold on;
    plot(selectStrongest(blobs1, 30));
    title('Thirty strongest SURF features in left sensor');
    
    [features1, validBlobs1] = extractFeatures(Lgray, blobs1);
    [features2, validBlobs2] = extractFeatures(Rgray, blobs2);
    indexPairs = matchFeatures(features1, features2, 'Metric', 'SAD', ...
        'MatchThreshold', 5);
    matchedPoints1 = validBlobs1(indexPairs(:,1),:);
    matchedPoints2 = validBlobs2(indexPairs(:,2),:);
    
    figure(6);
    showMatchedFeatures(imageL, imageR, matchedPoints1, matchedPoints2);
    legend('Putatively matched points in left', ...
        'Putatively matched points in right');
    title('Putatively matched points');
    
    if blobs1.Count > 0 && blobs2.Count > 0
        xL = blobs1.Location(1,1);
        yL = blobs1.Location(1,2);
        xR = blobs2.Location(1,1);
        yR = blobs2.Location(1,2);
        
        temp = (imgL(round(yL),round(xL))+imgR(round(yR),round(xR)))/2
        
        alphaL = (xL - 240)*(55/480)
        alphaR = (xR - 240)*(55/480)
        beta = ((yR+yL)/2 - 180)*(35/360)
    end
    
%     if matchedPoints1.Count > 0 && matchedPoints2.Count > 0
%         xL = round(matchedPoints1.Location(1,1));
%         yL = round(matchedPoints1.Location(1,2));
%         xR = round(matchedPoints2.Location(1,1));
%         yR = round(matchedPoints2.Location(1,2));
% 
%         temp = (imgL(yL,xL)+imgR(yR,xR))/2
%     end
    
%     [fMatrix, epipolarInliers, status] = estimateFundamentalMatrix(...
%         matchedPoints1, matchedPoints2, 'Method', 'RANSAC', ...
%         'NumTrials', 10000, 'DistanceThreshold', 0.1, 'Confidence', 99.99);
    
%     if status ~= 0 || isEpipoleInImage(fMatrix, size(imageL)) ...
%             || isEpipoleInImage(fMatrix', size(imageR))
%         error(['Either not enough matching points were found or '...
%                'the epipoles are inside the images. You may need to '...
%                'inspect and improve the quality of detected features ',...
%                'and/or improve the quality of your images.']);
%     end

% end
fclose(com);