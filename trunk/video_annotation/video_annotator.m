function varargout = video_annotator(varargin)
% VIDEO_ANNOTATOR MATLAB code for video_annotator.fig
%      VIDEO_ANNOTATOR, by itself, creates a new VIDEO_ANNOTATOR or raises the existing
%      singleton*.
%
%      H = VIDEO_ANNOTATOR returns the handle to a new VIDEO_ANNOTATOR or the handle to
%      the existing singleton*.
%
%      VIDEO_ANNOTATOR('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in VIDEO_ANNOTATOR.M with the given input arguments.
%
%      VIDEO_ANNOTATOR('Property','Value',...) creates a new VIDEO_ANNOTATOR or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before video_annotator_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to video_annotator_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help video_annotator

% Last Modified by GUIDE v2.5 21-Aug-2015 11:42:24

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @video_annotator_OpeningFcn, ...
    'gui_OutputFcn',  @video_annotator_OutputFcn, ...
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


% --- Executes just before video_annotator is made visible.
function video_annotator_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to video_annotator (see VARARGIN)

% Choose default command line output for video_annotator
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
ud=guidata(hObject);
ud.files_list=varargin{1};
ud.file_idx=1;
ud.filename=ud.files_list{ud.file_idx};
%load descriptor_representatives_66d;
%ud.VQs=single(descriptor_representatives(:,1:66));
ud.VQs=single([]);
% h=mex_video_processing('init',ud.filename,ud.VQs); %OLD NOTATION
WebcamNo=0;
% h = mex_video_processing('init',ud.filename,'SURF',single([]),66,WebcamNo); % NEW NOTATION
ud.framecount=mex_video_processing('getinfo',ud.filename);
ud.framecount=ud.framecount(1);
% mex_video_processing('deinit',h);
ud.markers={};
% ud.video=VideoStream(ud.filename);

ud.base_frame=0;
ud.frame=1;
if (~exist(ud.filename,'file'))
    error('File does not exist');
end

ud.labels=containers.Map();
for i=1:numel(ud.files_list)
    ud.labels(ud.files_list{i})={};
end
    
ud.frame_step=3000;
ud.frame_step2=ud.frame_step*5;
ud.frame_skip=20; 

instructions_text={};
instructions_text{end+1}='Video Segments Annotator';
instructions_text{end+1}='';
instructions_text{end+1}='Instructions:';
instructions_text{end+1}='- Move slider across video frames';
instructions_text{end+1}='- Set label/activity name in free test area';
instructions_text{end+1}='- Label the frame by pressing the Label button';
instructions_text{end+1}='- To undo your previous label, press Undo';
instructions_text{end+1}='- Press the Delete button to delete the selected label';
instructions_text{end+1}=['- Use the >>, >>x5, buttons to skip to the next set of frames, by jumps of ',num2str(ud.frame_step),' / ',num2str(ud.frame_step2),' frames'];
instructions_text{end+1}='- Click Start or End to go to the Beginning/End of the video';
instructions_text{end+1}='- Switch files using the drop-down list';
instructions_text{end+1}='- When you are done, click the Save botton to save';
% instructions_text{end+1}='- Labels are saved as global variable saved_userdata';
set(ud.text2,'String',instructions_text);

[ud.images,ud.images_idx]=get_images_for_video(ud.filename,ud.VQs,ud.base_frame+1,ud.base_frame+ud.frame_step,ud.frame_skip);
ud.frame_idx=ud.images_idx(ud.frame);
ud.max_images=size(ud.images,4);
set(ud.slider1,'Max',ud.max_images);

ud.I=ud.images(:,:,:,ud.frame);
ud.img_size=size(ud.I);
% pos=get(hObject,'Position');
% ud.pos_img=[pos(1)+30,pos(2)+30, ud.img_size(2), ud.img_size(1)];
% ud.image_axes=axes('Position',ud.pos_img);
% pos=get(ud.axes1,'Position');
% pos(3:4)=round(pos(3:4));
% set(ud.axes1,'Position',pos);
set(ud.label_box,'String','No Labels Yet');
ud.label_text={};

guidata(hObject,ud);

pos=get(ud.axes1,'Position');
imshow(imresize(ud.I,pos(3:4)),[])
imshow(ud.I,[])
frame_desc_text=get_frame_desc_text(ud);
set(ud.fileslist,'String',ud.files_list,'Value',1);
set(ud.text1,'String',frame_desc_text);

set(ud.lefttext,'String',int2str(ud.images_idx(1)));
set(ud.righttext, 'String', int2str(ud.images_idx(end)));


% global saved_userdata
% saved_userdata=[];
% ud.handles=get_handles(hObject);
% UIWAIT makes video_annotator wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = video_annotator_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
ud=guidata(hObject);
try
    ud.frame=max(1,round(get(hObject,'Value')));
    ud.frame_idx=ud.images_idx(ud.frame);
    ud.I=ud.images(:,:,:,ud.frame);
catch
    ud.frame=[];
end
% ud.video;
pos=get(ud.axes1,'Position');
imshow(imresize(ud.I,pos(3:4)),[])
imshow(ud.I,[])
frame_desc_text=get_frame_desc_text(ud);
set(ud.text1,'String',frame_desc_text);
global saved_userdata
saved_userdata=ud;
guidata(hObject,ud);

% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
set(hObject,'String','Label Name');
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');

end


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ud=guidata(hObject);
if (~isfield(ud,'labels'))
    ud.labels={};
end
label_string=get(ud.edit1,'String');
newlabel=[];
newlabel.frame=ud.frame_idx;
newlabel.label=label_string;
if (~ud.labels.isKey(ud.filename))
    ud.labels(ud.filename)={};
end
labels=ud.labels(ud.filename);
labels{end+1}=newlabel;
ud.labels(ud.filename)=labels;

frame_desc_text=get_frame_desc_text(ud);
ud.label_text{end+1}=[ud.filename ', Frame:' int2str(ud.frame_idx) ', ' label_string];
set(ud.text1,'String',frame_desc_text);
set(ud.label_box,'String',ud.label_text);
set(ud.label_box,'Value',get(ud.label_box, 'Max'));

global saved_userdata
saved_userdata=ud;
guidata(hObject,ud);

% --- Executes on button press in pushbutton2. (<<)
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ud=guidata(hObject);
ud.base_frame=min(ud.framecount,max(0,ud.base_frame-ud.frame_step));
[ud.images,ud.images_idx]=get_images_for_video(ud.filename,ud.VQs,ud.base_frame+1,ud.base_frame+ud.frame_step,ud.frame_skip);
% ud.frame_idx=ud.images_idx(ud.frame);
ud.max_images=size(ud.images,4);
%set(ud.slider1,'Max',ud.max_images);
%ud.frame=max(1, ud.frame-ud.frame_step);
%set(ud.slider1,'Value', ud.frame);
%change the text to Frame X
set(ud.slider1, 'Min', 0);
set(ud.slider1,'Max',ud.max_images);
set(ud.slider1,'Value', get(ud.slider1, 'Max'));
set(ud.lefttext,'String', ud.images_idx(1));
set(ud.righttext,'String', ud.images_idx(end));
ud.frame=ud.max_images;
ud.frame_idx=ud.images_idx(ud.frame);

ud.I=ud.images(:,:,:,ud.frame);
ud.img_size=size(ud.I);

pos=get(ud.axes1,'Position');
imshow(imresize(ud.I,pos(3:4)),[])
imshow(ud.I,[])


frame_desc_text=get_frame_desc_text(ud);
set(ud.text1,'String',frame_desc_text);
guidata(hObject,ud);


% --- Executes on button press in pushbutton3. (>>)
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ud=guidata(hObject);
ud.base_frame=min(ud.framecount,ud.images_idx(end));
[ud.images,ud.images_idx]=get_images_for_video(ud.filename,ud.VQs,ud.base_frame+1,ud.base_frame+ud.frame_step,ud.frame_skip);
%ud.frame_idx=ud.images_idx(ud.frame);
ud.max_images=size(ud.images,4);

set(ud.slider1, 'Min', 0);
set(ud.slider1,'Max',ud.max_images);
set(ud.slider1,'Value', get(ud.slider1, 'Min'));
set(ud.lefttext,'String', ud.images_idx(1));
set(ud.righttext,'String', ud.images_idx(end));
% ud.frame=min(ud.frame, ud.max_images);
ud.frame=1;
ud.frame_idx=ud.images_idx(ud.frame); 

ud.I=ud.images(:,:,:,ud.frame);
ud.img_size=size(ud.I);

pos=get(ud.axes1,'Position');
imshow(imresize(ud.I,pos(3:4)),[])
imshow(ud.I,[])


frame_desc_text=get_frame_desc_text(ud);
set(ud.text1,'String',frame_desc_text);
guidata(hObject,ud);

function [images,images_idx]=get_images_for_video(video_filename,VQs,start_frame,end_frame,skip_steps)
% max_frames=100;
fprintf('Loading images..');
WebcamNo=0;
h = mex_video_processing('init',video_filename,'SURF',single([]),66,WebcamNo);

% vs=[];
% for j=1:start_frame
%     mex_video_processing('skipframe',h);
% end
mex_video_processing('setframe',h,start_frame);
images=[];
images_idx=[];
frame_num=ceil((end_frame-start_frame)/(1+skip_steps));
for i=1:frame_num;
    if (mod(i,round(frame_num/100))==0)
        fprintf('.');
    end
    try
        [v,img,idx]=mex_video_processing('newframe',h);
        img=imresize(img, [200, NaN]);
        if (isempty(images))
            images=zeros(size(img,1),size(img,2),3,frame_num);
        end
        images(:,:,:,i)=double(img)/255;
        images_idx(i)=idx;
    catch
        break
    end
    for j=1:skip_steps
        mex_video_processing('skipframe',h);
    end
end
images=images(:,:,:,1:i);
mex_video_processing('deinit',h);
fprintf(' Done\n');

function existing_labels=find_frame_labels(labels,idx)
existing_labels={};
for i=1:numel(labels)
    if (labels{i}.frame==idx)
        existing_labels{end+1}=labels{i}.label;
    end
end

function frame_desc_text=get_frame_desc_text(ud)
frame_desc_text=['Frame ',num2str(ud.frame_idx), '/', num2str(ud.framecount)];
labels=ud.labels(ud.filename);

if (~isempty(ud.labels))
    existing_labels=find_frame_labels(labels,ud.frame_idx);
    for j=1:numel(existing_labels)
        frame_desc_text=[frame_desc_text,', ',existing_labels{j}];
%         frame_desc_text=cell2mat([frame_desc_text,', ',existing_labels{j}]);
    end
end


% --- Executes on selection change in fileslist.
function fileslist_Callback(hObject, eventdata, handles)
% hObject    handle to fileslist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns fileslist contents as cell array
%        contents{get(hObject,'Value')} returns selected item from fileslist
ud=guidata(hObject);
ud.file_idx=get(ud.fileslist,'Value');
ud.filename=ud.files_list{ud.file_idx};
ud.framecount=mex_video_processing('getinfo',ud.filename);
ud.framecount=ud.framecount(1);
ud.base_frame=0;
% ud.base_frame=max(0,ud.base_frame-ud.frame_step);
[ud.images,ud.images_idx]=get_images_for_video(ud.filename,ud.VQs,ud.base_frame+1,ud.base_frame+ud.frame_step,ud.frame_skip);
ud.frame=ud.base_frame+1;
ud.frame_idx=ud.images_idx(ud.frame);
ud.max_images=size(ud.images,4);
%set(ud.slider1,'Max',ud.max_images);
ud.I=ud.images(:,:,:,ud.frame);
ud.img_size=size(ud.I);

pos=get(ud.axes1,'Position');
imshow(imresize(ud.I,pos(3:4)),[])
imshow(ud.I,[])

set(ud.slider1, 'Min', 0);
set(ud.slider1,'Max',ud.max_images);
set(ud.slider1,'Value', get(ud.slider1, 'Min'));
set(ud.lefttext,'String', ud.images_idx(1));
set(ud.righttext,'String', ud.images_idx(end));

frame_desc_text=get_frame_desc_text(ud);
set(ud.text1,'String',frame_desc_text);
guidata(hObject,ud);


% --- Executes during object creation, after setting all properties.
function fileslist_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fileslist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% 
% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton4. (<< x5)
function pushbutton4_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ud=guidata(hObject);
ud.base_frame=min(ud.framecount,max(0,ud.base_frame-ud.frame_step2));
[ud.images,ud.images_idx]=get_images_for_video(ud.filename,ud.VQs,ud.base_frame+1,ud.base_frame+ud.frame_step2,ud.frame_skip);
%ud.frame_idx=ud.images_idx(ud.frame);
ud.max_images=size(ud.images,4);

set(ud.slider1, 'Min', 0);
set(ud.slider1,'Max',ud.max_images);
set(ud.slider1,'Value', get(ud.slider1, 'Max'));
set(ud.lefttext,'String', ud.images_idx(1));
set(ud.righttext,'String', ud.images_idx(end));
ud.frame=ud.max_images;
ud.frame_idx=ud.images_idx(ud.frame); 

ud.I=ud.images(:,:,:,ud.frame);
ud.img_size=size(ud.I);

pos=get(ud.axes1,'Position');
imshow(imresize(ud.I,pos(3:4)),[])
imshow(ud.I,[])


frame_desc_text=get_frame_desc_text(ud);
set(ud.text1,'String',frame_desc_text);
guidata(hObject,ud);


% --- Executes on button press in pushbutton5. (>> x5)
function pushbutton5_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ud=guidata(hObject);
ud.base_frame=min(ud.framecount,max(0,ud.images_idx(end)));
[ud.images,ud.images_idx]=get_images_for_video(ud.filename,ud.VQs,ud.base_frame+1,ud.base_frame+ud.frame_step2,ud.frame_skip);
%ud.frame_idx=ud.images_idx(ud.frame);
ud.max_images=size(ud.images,4);
%set(ud.slider1,'Max',ud.max_images);

set(ud.slider1, 'Min', 0);
set(ud.slider1,'Max',ud.max_images);
set(ud.slider1,'Value', get(ud.slider1, 'Min'));
set(ud.lefttext,'String', ud.images_idx(1));
set(ud.righttext,'String', ud.images_idx(end));
ud.frame=1;
ud.frame_idx=ud.images_idx(ud.frame); 

ud.I=ud.images(:,:,:,ud.frame);
ud.img_size=size(ud.I);

pos=get(ud.axes1,'Position');
imshow(imresize(ud.I,pos(3:4)),[])
imshow(ud.I,[])


frame_desc_text=get_frame_desc_text(ud);
set(ud.text1,'String',frame_desc_text);
guidata(hObject,ud);


% --- Executes on button press in pushbutton6.
function pushbutton6_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
userdata=guidata(hObject);
FilterSpec='*.mat';
[FileName,PathName,FilterIndex] = uiputfile(FilterSpec);
if ~isequal(FileName,0) && ~isequal(PathName,0)
save([PathName,filesep,FileName],'userdata');
end


% --- Executes on button press in start_button.
function start_button_Callback(hObject, eventdata, handles)
% hObject    handle to start_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ud=guidata(hObject);
ud.base_frame=0;
[ud.images,ud.images_idx]=get_images_for_video(ud.filename,ud.VQs,ud.base_frame+1,ud.base_frame+ud.frame_step,ud.frame_skip);
%ud.frame_idx=ud.images_idx(ud.frame);
ud.max_images=size(ud.images,4);

set(ud.slider1, 'Min', 0);
set(ud.slider1,'Max',ud.max_images);
set(ud.slider1,'Value', get(ud.slider1, 'Min'));
set(ud.lefttext,'String', ud.images_idx(1));
set(ud.righttext,'String', ud.images_idx(end));
ud.frame=min(ud.frame, ud.max_images);
ud.frame_idx=ud.images_idx(ud.frame); 

ud.I=ud.images(:,:,:,ud.frame);
ud.img_size=size(ud.I);

pos=get(ud.axes1,'Position');
imshow(imresize(ud.I,pos(3:4)),[])
imshow(ud.I,[])


frame_desc_text=get_frame_desc_text(ud);
set(ud.text1,'String',frame_desc_text);
guidata(hObject,ud);

% --- Executes on button press in end_button.
function end_button_Callback(hObject, eventdata, handles)
% hObject    handle to end_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ud=guidata(hObject);
ud.base_frame=max(ud.framecount-ud.frame_step,0);
[ud.images,ud.images_idx]=get_images_for_video(ud.filename,ud.VQs,ud.base_frame+1,ud.base_frame+ud.frame_step,ud.frame_skip);
%ud.frame_idx=ud.images_idx(ud.frame);
ud.max_images=size(ud.images,4);

set(ud.slider1, 'Min', 0);
set(ud.slider1,'Max',ud.max_images);
set(ud.slider1,'Value', get(ud.slider1, 'Max'));
set(ud.lefttext,'String', ud.images_idx(1));
set(ud.righttext,'String', ud.images_idx(end));
ud.frame=min(ud.frame, ud.max_images);
ud.frame_idx=ud.images_idx(ud.frame); 

ud.I=ud.images(:,:,:,ud.frame);
ud.img_size=size(ud.I);

pos=get(ud.axes1,'Position');
imshow(imresize(ud.I,pos(3:4)),[])
imshow(ud.I,[])


frame_desc_text=get_frame_desc_text(ud);
set(ud.text1,'String',frame_desc_text);
guidata(hObject,ud);


% --- Executes on button press in undo_button.
function undo_button_Callback(hObject, eventdata, handles)
% hObject    handle to undo_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ud=guidata(hObject);
labels=ud.labels(ud.filename);
try
    labels=labels(1:(end-1));
    ud.label_text(end)=[];
end
set(ud.label_box,'Value',1);
set(ud.label_box,'String',ud.label_text);
ud.labels(ud.filename)=labels;

frame_desc_text=get_frame_desc_text(ud);
set(ud.text1,'String',frame_desc_text);

global saved_userdata
saved_userdata=ud;
guidata(hObject,ud);



% --- Executes on selection change in label_box.
function label_box_Callback(hObject, eventdata, handles)
% hObject    handle to label_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns label_box contents as cell array
%        contents{get(hObject,'Value')} returns selected item from label_box


% --- Executes during object creation, after setting all properties.
function label_box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to label_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in delete_button.
function delete_button_Callback(hObject, eventdata, handles)
% hObject    handle to delete_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ud=guidata(hObject);
label_number=get(ud.label_box, 'Value');
% text=strsplit(ud.label_text{label_number}, {',' ':'});
text = regexp(ud.label_text{label_number},'[:,]','split');
file=text{1};
frame=str2num(text{3});
label=text{4}(2:end);
labels=ud.labels(file);
for i=1:numel(labels)
    if (labels{i}.frame==frame) && strcmp(labels{i}.label,label)
        labels(i)=[];
        ud.label_text(label_number)=[];
        break
    end
end

ud.labels(file)=labels;
frame_desc_text=get_frame_desc_text(ud);
set(ud.text1,'String',frame_desc_text);


if isempty(ud.label_text)
    set(ud.label_box,'String','No Labels');
    set(ud.label_box, 'Value', 1);
elseif label_number>1
    set(ud.label_box,'Value',label_number-1);
    set(ud.label_box,'String',ud.label_text);
else
    set(ud.label_box, 'Value', 1);
    set(ud.label_box,'String',ud.label_text);
end

global saved_userdata
saved_userdata=ud;
guidata(hObject,ud);

