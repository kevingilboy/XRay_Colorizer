function varargout = Main(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @main_OpeningFcn, ...
                   'gui_OutputFcn',  @main_OutputFcn, ...
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

% --- Executes just before main is made visible.
function main_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for main
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

%Initialize images to black
axes(handles.axesOriginalImage);
imshow(zeros(512));

axes(handles.axesWindowedImage);
imshow(zeros(512));

axes(handles.axesOutputImage);
imshow(zeros(512));

% UIWAIT makes main wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = main_OutputFcn(hObject, eventdata, handles) 
% Get default command line output from handles structure
varargout{1} = handles.output;

% ------------------------------
%
%       COMPONENT ONLOADERS
%
% ------------------------------

% --- Executes during object creation, after setting all properties.
function sliderCenter_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes during object creation, after setting all properties.
function textboxCenter_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function sliderWidth_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes during object creation, after setting all properties.
function textboxWidth_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function textboxColor_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% ------------------------------
%
%       COMPONENT LISTENERS
%
% ------------------------------

    %~~~~~~~~~~
    %   LEFT
    %~~~~~~~~~~

% --- Executes on button press in btnImportImage.
function btnImportImage_Callback(hObject, eventdata, handles)
%Clear instructions
delete(handles.leftInstruction)
delete(handles.midInstruction)
delete(handles.rightInstruction)
delete(handles.buttonInstruction)

%Load image
[filename] = uigetfile('*.dcm','Select the XRAY picture');
I = dicomread(filename);
I = uint16(I);
[m,n] = size(I);
J = I;
for a=2:m-1
    for b=2:n-1
        neigh = [J(a-1,b),J(a+1,b),J(a,b-1),J(a-1,b+1)];
        neighEqZero = neigh(find(neigh<=6));
        neighNotZero = neigh(find(neigh>6));
        if (length(neighEqZero)==2 && sum( J(a,b) < (neighNotZero*.9) )==2)
            I(a,b) = 0;
        end
    end
end

%Update sliders
set(handles.sliderCenter,'Max',max(max(I)));
set(handles.sliderWidth,'Max',max(max(I)));

%Show image
axes(handles.axesOriginalImage);
imshow(I*255,[]);

%Locally store image
set(handles.axesOriginalImage,'UserData',I);

setappdata(handles.tableLayers, 'layers', [])

%Display DICOM info
info = dicominfo(filename);
infoToShow = sprintf(   'Modality: %s\n',...
                        'Date: %s\n',...                        
                        '[Height, Width] = %d,%d\n',...
                        'Bit Depth: %d\n',...
                        info.Modality,...
                        info.StudyDate,...
                        info.Height, info.Width,...
                        info.BitDepth);
infoToShow = sprintf('Modality: %s\nDate: %s\n[Height, Width] = %d,%d\nBit Depth: %d\n',info.Modality,info.StudyDate,info.Height,info.Width,info.BitDepth);                    
set(handles.infoText,'String',infoToShow);

%Enable applyCW button
set(handles.btnApplyCW,'Enable','on');

%Update other axes with image
updateWindowedImage(handles);
updateOutputImage(handles);



    %~~~~~~~~~~
    %   CENTER
    %~~~~~~~~~~

% --- Executes on Center slider movement.
function sliderCenter_Callback(hObject, eventdata, handles)
set(handles.textboxCenter,'String',get(hObject,'Value'));
updateWindowedImage(handles);

% --- Executes on Center textbox update.
function textboxCenter_Callback(hObject, eventdata, handles)
set(handles.sliderCenter,'Value',str2double(get(hObject,'String')));
updateWindowedImage(handles);

% --- Executes on Width slider movement.
function sliderWidth_Callback(hObject, eventdata, handles)
set(handles.textboxWidth,'String',get(hObject,'Value'));
updateWindowedImage(handles);

% --- Executes on Width textbox update.
function textboxWidth_Callback(hObject, eventdata, handles)
set(handles.sliderWidth,'Value',str2double(get(hObject,'String')));
updateWindowedImage(handles);

% --- Executes on color textbox update.
function textboxColor_Callback(hObject, eventdata, handles)
updateWindowedImage(handles);

% --- Executes on button press in btnOpenColorPicker.
function btnOpenColorPicker_Callback(hObject, eventdata, handles)
existingColor = get(handles.textboxColor,'String');
if(length(existingColor)==6)
    existingColor = [existingColor(1:2),existingColor(3:4),existingColor(5:6)];
else
    existingColor=['FF','FF','FF'];
end

newColor = uisetcolor(existingColor);

r = dec2hex(round(newColor(1)*255),2);
g = dec2hex(round(newColor(2)*255),2);
b = dec2hex(round(newColor(3)*255),2);

set(handles.textboxColor,'String',[r,g,b]);
updateWindowedImage(handles);

% --- Executes on button press in btnApplyCW.
function btnApplyCW_Callback(hObject, eventdata, handles)
tableData = handles.tableLayers.Data;
blankRows = getBlankRows(tableData);
nextBlankRow = blankRows(1);

%If adding the last row, disable this button
if(nextBlankRow == 4)
    set(hObject,'Enable','off');
end

%Add the row to the table
tableData(nextBlankRow,:) = {
    get(handles.textboxCenter,'String') 
    get(handles.textboxWidth,'String') 
    get(handles.textboxColor,'String') 
    '+' 
    '-' 
    'X'};
set(handles.tableLayers, 'Data', tableData);

%Add the pixel info to the table data
layers = getappdata(handles.tableLayers, 'layers');
layers(:,:,:,nextBlankRow) = get(handles.axesWindowedImage,'UserData');
setappdata(handles.tableLayers, 'layers', layers)

%Enable the export button
set(handles.btnExportImage,'Enable','on');

%Reset parameters
set(handles.textboxCenter,'String','0');
set(handles.sliderCenter,'Value',0);
set(handles.textboxWidth,'String','0');
set(handles.sliderWidth,'Value',0);
set(handles.textboxColor,'String','FFFFFF');

%Repaint
updateWindowedImage(handles);
updateOutputImage(handles);


    %~~~~~~~~~~
    %   RIGHT
    %~~~~~~~~~~

% --- Executes when selected cell(s) is changed in tableLayers.
function tableLayers_CellSelectionCallback(hObject, eventdata, handles)
%Check if false trigger
if(size(eventdata.Indices,1)==0)
    return
end

%Get row and column
row = eventdata.Indices(1);
col = eventdata.Indices(2);

%Make sure row is occupied
tableData = handles.tableLayers.Data;
blankRows = getBlankRows(tableData);
if(ismember(row,blankRows))
   return 
end

%Perform operation
if(col==4 && row ~= 1) %Up
    if(~ismember(row-1,blankRows))
        %Swap the rows
        tempRow = tableData(row,:);
        tableData(row,:) = tableData(row-1,:);
        tableData(row-1,:) = tempRow;
        set(handles.tableLayers, 'Data', tableData);
        
        %Swap the pixel data
        layers(:,:,:,:) = getappdata(handles.tableLayers, 'layers');
        tempPixels(:,:,:) = layers(:,:,:,row);
        layers(:,:,:,row) = layers(:,:,:,row-1);
        layers(:,:,:,row-1) = tempPixels; 
        setappdata(handles.tableLayers, 'layers', layers);
        
        %Repaint
        updateOutputImage(handles);
    end
elseif(col==5 && row ~=4) %Dn
    if(~ismember(row+1,blankRows))
        %Swap the rows
        tempRow = tableData(row,:);
        tableData(row,:) = tableData(row+1,:);
        tableData(row+1,:) = tempRow;
        set(handles.tableLayers, 'Data', tableData);
        
        %Swap the pixel data
        layers(:,:,:,:) = getappdata(handles.tableLayers, 'layers');
        tempPixels(:,:,:) = layers(:,:,:,row);
        layers(:,:,:,row) = layers(:,:,:,row+1);
        layers(:,:,:,row+1) = tempPixels;
        setappdata(handles.tableLayers, 'layers', layers);
        
        %Repaint
        updateOutputImage(handles);
    end
elseif(col==6) %Del
    %Delete the row
    tableData(row,:) = [];
    tableData(4,:) = {'' '' '' '' '' ''};    
    set(handles.tableLayers, 'Data', tableData);
    
    %Delete the pixel data
    layers(:,:,:,:) = getappdata(handles.tableLayers, 'layers');
    layers(:,:,:,row) = [];
    setappdata(handles.tableLayers, 'layers', layers)
    
    %Re-enable the add layer button in case it was disabled
    set(hObject,'Enable','on');
    
    %Disable the export button if the last layer was deleted
    if(row==1)
        set(handles.btnExportImage,'Enable','off');
    end
    
    %Repaint
    updateOutputImage(handles);
end

%Repaint
updateOutputImage(handles)

% --- Executes on button press in btnExportImage.
function btnExportImage_Callback(hObject, eventdata, handles)
I = get(handles.axesOutputImage,'UserData');
imwrite(I,'OutputFile.png')


% ------------------------------
%
%       INTERNAL FUNCTIONS
%
% ------------------------------
function [low, high] = getIntensityBounds(c,w)
r = w/2;
low = c-r;
high = c+r;
if low<0
   low = 0; 
end
if low==high
   high = high+.00001;
end

function [blankRows] = getBlankRows(tableData)
blankData = cellfun(@isempty,tableData);
blankRows = find(blankData(:,1)==1);

function updateWindowedImage(handles)
%Calc params
center = str2double(get(handles.textboxCenter,'String'));
width = str2double(get(handles.textboxWidth,'String'));
[low,high] = getIntensityBounds(center,width);

%Load image
I = get(handles.axesOriginalImage,'UserData');

%Update contrast
[m,n] = size(I);
J = zeros(m,n);
for a=1:m
  for b=1:n
      P=I(a,b); %This contain the information of the image
      if(P>=low && P<=high) % Make the condition that allows compare the information in the variable "P"
          J(a,b) = P; % This transform the value of P that contain the image information
      end
  end
end

%Filter with 3x3 kernel
J = medfilt2(J,[3 3]);

%Apply color
shade_color = get(handles.textboxColor,'String');
if(length(shade_color)==6)
    shade_color = [shade_color(1:2),shade_color(3:4),shade_color(5:6)];
    
    J = repmat(J,[1,1,3]);
    J(:,:,1) = J(:,:,1) .* (hex2dec(shade_color(1:2)) / 255);
    J(:,:,2) = J(:,:,2) .* (hex2dec(shade_color(3:4)) / 255);
    J(:,:,3) = J(:,:,3) .* (hex2dec(shade_color(5:6)) / 255);
end

%Get the max of the image
normalizing_factor = max(max(max(J)));

%Display image
axes(handles.axesWindowedImage);
J = J./normalizing_factor;
imshow(J);

%Locally store image
set(handles.axesWindowedImage,'UserData',J);

function updateOutputImage(handles)
layers = getappdata(handles.tableLayers, 'layers');
if(isempty(layers))
    imshow(zeros(512));
    return
end

[m,n] = size(get(handles.axesOriginalImage,'UserData'));
I = zeros(m,n,3);

for i=size(layers,4):-1:1
    layer(:,:,:) = layers(:,:,:,i);
    for a=1:m
        for b=1:n
            if(layer(a,b,1)~=0 || layer(a,b,2)~=0 || layer(a,b,3)~=0)
                I(a,b,1) = layer(a,b,1); %r
                I(a,b,2) = layer(a,b,2); %g
                I(a,b,3) = layer(a,b,3); %b
            end
        end

    end
end

%Display image
axes(handles.axesOutputImage);
imshow(I);

%Locally store image
set(handles.axesOutputImage,'UserData',I);
