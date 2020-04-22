function varargout = MLX90640_Heat_Camera(varargin)
% MLX90640_HEAT_CAMERA MATLAB code for MLX90640_Heat_Camera.fig
%      MLX90640_HEAT_CAMERA, by itself, creates a new MLX90640_HEAT_CAMERA or raises the existing
%      singleton*.
%
%      H = MLX90640_HEAT_CAMERA returns the handle to a new MLX90640_HEAT_CAMERA or the handle to
%      the existing singleton*.
%
%      MLX90640_HEAT_CAMERA('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MLX90640_HEAT_CAMERA.M with the given input arguments.
%
%      MLX90640_HEAT_CAMERA('Property','Value',...) creates a new MLX90640_HEAT_CAMERA or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before MLX90640_Heat_Camera_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to MLX90640_Heat_Camera_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help MLX90640_Heat_Camera

% Last Modified by GUIDE v2.5 23-Apr-2020 02:05:29

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @MLX90640_Heat_Camera_OpeningFcn, ...
                   'gui_OutputFcn',  @MLX90640_Heat_Camera_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before MLX90640_Heat_Camera is made visible.
function MLX90640_Heat_Camera_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to MLX90640_Heat_Camera (see VARARGIN)

% Choose default command line output for MLX90640_Heat_Camera
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

clear;

% UIWAIT makes MLX90640_Heat_Camera wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = MLX90640_Heat_Camera_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu1


% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in run.
function run_Callback(hObject, eventdata, handles)
% hObject    handle to run (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(handles.status,'string','Running...');

D = 12.2;
H = 4.8;
global com;
port = get(handles.comPort, 'String')
com = serial(port,'BaudRate',250000,'Terminator','CR');
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
    
    axes(handles.axes1);    
    imagesc(imgR);
    colorbar;
    FR = getframe;
    
    axes(handles.axes2);
    imagesc(imgL);
    colorbar;
    drawnow;
    FL = getframe;
    
    imgL = imresize(imgL,[360 480]);
    imgR = imresize(imgR,[360 480]);
    
    sigma = 5;
    imageL = imgaussfilt(frame2im(FL),sigma);
    imageR = imgaussfilt(frame2im(FR),sigma);
    imageL = imresize(imageL,[360 480]);
    imageR = imresize(imageR,[360 480]);
    
    Lgray = rgb2gray(imageL);
    Rgray = rgb2gray(imageR);
    
    blobs1 = detectSURFFeatures(Lgray, 'MetricThreshold', 2000);
    blobs2 = detectSURFFeatures(Rgray, 'MetricThreshold', 2000);
    
    axes(handles.axes3);
    imshow(imageR);
    hold on;
    plot(selectStrongest(blobs2, 30));
    
    axes(handles.axes4);
    imshow(imageL);
    hold on;
    plot(selectStrongest(blobs1, 30));
    
    [features1, validBlobs1] = extractFeatures(Lgray, blobs1);
    [features2, validBlobs2] = extractFeatures(Rgray, blobs2);
    indexPairs = matchFeatures(features1, features2, 'Metric', 'SAD', ...
        'MatchThreshold', 5);
    matchedPoints1 = validBlobs1(indexPairs(:,1),:);
    matchedPoints2 = validBlobs2(indexPairs(:,2),:);
    
    axes(handles.axes5);
    showMatchedFeatures(imageL, imageR, matchedPoints1, matchedPoints2);
    legend('Putatively matched points in left', ...
        'Putatively matched points in right');
    
    set(handles.matchedPoints,'string',num2str(matchedPoints1.Count));
    
    if matchedPoints1.Count > 0 && matchedPoints2.Count > 0
        xL = round(matchedPoints1.Location(1,1));
        yL = round(matchedPoints1.Location(1,2));
        xR = round(matchedPoints2.Location(1,1));
        yR = round(matchedPoints2.Location(1,2));
        
        temp = (imgL(round(yL),round(xL))+imgR(round(yR),round(xR)))/2;
        
        alphaL = (xL - 240)*(55/480);
        alphaR = (xR - 240)*(55/480);
        beta = ((yR+yL)/2 - 180)*(35/360);
        
        if alphaR >= 0 && alphaL <= 0
            aL = 90 - abs(alphaL);
            aR = 90 - alphaR;
            x = ((D*tand(aR))/(tand(aL) + tand(aR)));
            fx = x*tand(aL);
        elseif alphaR >= 0 && alphaL >= 0
            aL = 90 - alphaL;
            aR = 90 - alphaR;
            x = ((D*tand(aR))/(tand(aL) - tand(aR)));
            fx = x*tand(aL);
        else
            aL = 90 - abs(alphaL);
            aR = 90 - abs(alphaR);
            x = ((D*tand(aR))/(tand(aR) - tand(aL)));
            fx = x*tand(aL);
        end
        
        if beta < 0
            fy = H + fx*tand(abs(beta));
        else
            fy = H - fx*tand(beta);
        end
        
        fx = fx/cosd(abs(beta));
        
        temperature = temp*fx/10;
        
        set(handles.distance,'string',num2str(fx));
        set(handles.height,'string',num2str(fy));
        set(handles.tempC,'string',num2str(temperature));
        
    else
        set(handles.distance,'string','-');
        set(handles.height,'string','-');
        set(handles.tempC,'string','-');
    end
    
    set(handles.status,'string','Done');
    fclose(com);



function status_Callback(hObject, eventdata, handles)
% hObject    handle to status (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of status as text
%        str2double(get(hObject,'String')) returns contents of status as a double


% --- Executes during object creation, after setting all properties.
function status_CreateFcn(hObject, eventdata, handles)
% hObject    handle to status (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function matchedPoints_Callback(hObject, eventdata, handles)
% hObject    handle to matched (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of matched as text
%        str2double(get(hObject,'String')) returns contents of matched as a double


% --- Executes during object creation, after setting all properties.
function matchedPoints_CreateFcn(hObject, eventdata, handles)
% hObject    handle to matched (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function distance_Callback(hObject, eventdata, handles)
% hObject    handle to distance (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of distance as text
%        str2double(get(hObject,'String')) returns contents of distance as a double


% --- Executes during object creation, after setting all properties.
function distance_CreateFcn(hObject, eventdata, handles)
% hObject    handle to distance (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function height_Callback(hObject, eventdata, handles)
% hObject    handle to height (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of height as text
%        str2double(get(hObject,'String')) returns contents of height as a double


% --- Executes during object creation, after setting all properties.
function height_CreateFcn(hObject, eventdata, handles)
% hObject    handle to height (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function tempC_Callback(hObject, eventdata, handles)
% hObject    handle to tempC (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tempC as text
%        str2double(get(hObject,'String')) returns contents of tempC as a double


% --- Executes during object creation, after setting all properties.
function tempC_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tempC (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function comPort_Callback(hObject, eventdata, handles)
% hObject    handle to comPort (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of comPort as text
%        str2double(get(hObject,'String')) returns contents of comPort as a double


% --- Executes during object creation, after setting all properties.
function comPort_CreateFcn(hObject, eventdata, handles)
% hObject    handle to comPort (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
