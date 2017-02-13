% -------------------------------------------------------------------------------------------------
function coreset_tree_gui(varargin)

parser = inputParser;
parser.addOptional('Filename','coreset_tree.mat',@isstr)
parser.addOptional('FigureID',100,@isnumeric)
parser.parse(varargin{:})
filename = parser.Results.Filename;
figure_id = parser.Results.FigureID;

load(filename)

hnd = figure(figure_id);
set(gcf,'Position',[80 280 1480 800])

% init tree
subplot(131)
treeplot(coreset_tree.Nodes,'ko','k-')
axis off
BAR_HEIGHT = 0.08;
tiny_margin = 0.05;
rectangle('Position',[0-tiny_margin 0 1+2*tiny_margin BAR_HEIGHT],'EdgeColor','black','LineWidth',2);

% init display
subplot(1,3,2:3)
rectangle('Position',[0 0 1 1],'EdgeColor','black','LineWidth',10);
axis off

% setup handle
user_data.coreset_tree = coreset_tree;
set(hnd,'UserData',user_data);
set(hnd,'WindowButtonDownFcn',@on_click)

end

% -------------------------------------------------------------------------------------------------
% handle click events
function on_click(hnd,~)

persistent coreset_tree
persistent selected_node_hnd
persistent children_nodes_hnd
persistent selected_rect_hnd
persistent children_rect_hnd
persistent t1x
persistent t2x
persistent gui_initialized
persistent this_node
persistent this_num_keyframes
persistent this_keyframes
persistent this_key_idx
persistent this_border_colors
persistent show_details

% init persistent variables
if isempty(coreset_tree)
    user_data = get(hnd,'UserData');
    coreset_tree = user_data.coreset_tree;
    t1x = 0;
    t2x = 1;
    show_details = false;
    gui_initialized = false;
    
    % make sure the coreset tree data is loaded
    waitbar_h = waitbar(0,'Caching coreset tree data: ','Position',[480 200 288 60]);
    for i = 1:coreset_tree.NumNodes
        waitbar(i/coreset_tree.NumNodes,waitbar_h,sprintf('Caching coreset tree data: %d %%',ceil(i/coreset_tree.NumNodes*100)))
        assert(boolean(not(isempty(coreset_tree.Data{i}))))
    end
    delete(waitbar_h)
    
end

%% get click event

% get click position on current figure
click_pos = get(hnd,'CurrentPoint');
cx = click_pos(1);
cy = click_pos(2);

% get width of current figure
fig_pos = get(hnd,'Position');
fig_w = fig_pos(3);
fig_h = fig_pos(4);

% get axes limits in figure
axes_hnd = subplot(131);
axes_pos = get(axes_hnd,'Position');
x1 = axes_pos(1)*fig_w;
y1 = axes_pos(2)*fig_h;
x2 = x1+axes_pos(3)*fig_w;
y2 = y1+axes_pos(4)*fig_h;

% get relative position of click within axes
rx = (cx-x1)/(x2-x1);
ry = (cy-y1)/(y2-y1);

% get node positions from tree lines
lines_hnd = findobj(axes_hnd,'type','line');
nodes_xy = get(lines_hnd(end));
nodes_x = nodes_xy.XData;
nodes_y = nodes_xy.YData;

%% check clicks

is_bar_clicked = false;
is_node_clicked = false;
is_display_clicked = false;

% check bar click
BAR_HEIGHT = 0.08;
if rx > 0 && rx < 1 && ry > 0 && ry < BAR_HEIGHT
    sel_type = get(hnd,'SelectionType');
    if strcmp(sel_type,'normal') || strcmp(sel_type,'alt')
        is_bar_clicked = true;
    end
end

% check node click
if not(is_bar_clicked)
    % find index of nearest node to within precision
    CLICK_PRECISION = 0.05;
    dx = find(abs(nodes_x-rx) < CLICK_PRECISION);
    dy = find(abs(nodes_y-ry) < CLICK_PRECISION);
    click_idx = intersect(dx,dy);
    if not(isempty(click_idx))
        is_node_clicked = true;
    end
end

% check display click
if rx > 1 && ry >= 0 && ry <= 1
    is_display_clicked = true;
end

%% check update

update_tree = false;

if is_node_clicked || is_bar_clicked
    
    % initialize gui
    if gui_initialized == false
        gui_initialized = true;
    end
    
    % update tree
    update_tree = true;
    
end

if not(gui_initialized)
    
    % nothing to update or plot
    return
    
end

%% update tree

if update_tree
    
    if is_node_clicked
        % node click update
        
        % find node index
        click_idx_ssd = sqrt((nodes_x(click_idx)-rx).^2+(nodes_y(click_idx)-ry).^2);
        click_idx = click_idx(click_idx_ssd==min(click_idx_ssd));
        this_node = click_idx(1);
        
        % find time interval
        t1 = coreset_tree.T12(this_node,1);
        t2 = coreset_tree.T12(this_node,2);
        t1x = t1/coreset_tree.NumSpannedFrames;
        t2x = t2/coreset_tree.NumSpannedFrames;
        
    elseif is_bar_clicked
        % bar click update
        
        sel_type = get(hnd,'SelectionType');
        
        if strcmp(sel_type,'normal')
            % left click
            t1x = rx;
            
        elseif strcmp(sel_type,'alt')
            % right click
            t2x = rx;
            
        end
        
        if t1x > t2x
            temp = t1x;
            t1x = t2x;
            t2x = temp;
        end
        
        % find time interval
        t1 = max(1,floor(t1x*coreset_tree.NumSpannedFrames));
        t2 = min(coreset_tree.NumSpannedFrames-1,ceil(t2x*coreset_tree.NumSpannedFrames-1));
        
        % find node index
        t12 = coreset_tree.T12(coreset_tree.T12(:,1)<=t1 & coreset_tree.T12(:,2)>=t2,:);
        t12 = t12(t12(:,1)==max(t12(:,1)),:);
        t12 = t12(t12(:,2)==min(t12(:,2)),:);
        this_node = find(coreset_tree.T12(:,1) == t12(1) & coreset_tree.T12(:,2) == t12(2));
        
    end
    
    % find children nodes
    children = find(coreset_tree.Nodes==this_node);
    children_T12 = coreset_tree.T12(children,:);
    
    children_colors = hsv(max(length(children),3));
    children_colors(2,:) = [0 0.8 0];
    
    if not(isempty(children))
        node_t1 = children_T12(1,1);
        node_t2 = children_T12(end,2);
    else
        node_t1 = coreset_tree.T12(this_node,1);
        node_t2 = coreset_tree.T12(this_node,2);
    end
    
    % update keyframe collage
    this_num_keyframes = coreset_tree.Data{this_node}.NumKeyframes;
    this_keyframes = coreset_tree.Data{this_node}.Keyframes;
    this_key_idx = coreset_tree.Data{this_node}.KeyframeAbsIdx;
    this_border_colors = cell(1,this_num_keyframes);
    
    if not(isempty(children))
        for i = 1:this_num_keyframes
            kxi = this_key_idx(i);
            xx1 = find(kxi>=children_T12(:,1));
            xx2 = find(kxi<=children_T12(:,2));
            ixx = intersect(xx1,xx2);
            this_border_colors{i} = children_colors(ixx,:);
        end
    else
        for i = 1:this_num_keyframes
            this_border_colors{i} = [1 0.8 0.2];
        end
    end
    
end

%% draw tree

if update_tree
    
    subplot(131)
    
    % delete previous handles
    if ishandle(selected_node_hnd)
        delete(selected_node_hnd)
    end
    
    for i = 1:length(children_nodes_hnd)
        if ishandle(children_nodes_hnd(i))
            delete(children_nodes_hnd(i))
        end
    end
    children_nodes_hnd = zeros(1,length(children));
    
    if ishandle(selected_rect_hnd)
        delete(selected_rect_hnd)
    end
    
    for i = 1:length(children_rect_hnd)
        if ishandle(children_rect_hnd(i))
            delete(children_rect_hnd(i))
        end
    end
    children_rect_hnd = zeros(1,length(children));
    
    % draw selected node
    nx = nodes_x(this_node);
    ny = nodes_y(this_node);
    selected_node_radius = 0.08;
    selected_node_hnd = rectangle(...
        'Position',[nx-selected_node_radius/2 ny-selected_node_radius/4 selected_node_radius selected_node_radius/2], ...
        'Curvature',[1 1],'LineWidth',3,'EdgeColor','black');
    
    % draw children nodes
    children_node_radius = 0.08;
    for i = 1:length(children)
        nxi = nodes_x(children(i));
        nyi = nodes_y(children(i));
        children_nodes_hnd(i) = rectangle(...
            'Position',[nxi-children_node_radius/2 nyi-children_node_radius/4 children_node_radius children_node_radius/2], ...
            'Curvature',[0 0],'LineWidth',2,'EdgeColor',children_colors(i,:));
    end
    
    % draw children rectangles
    if not(isempty(children))
        for i = 1:length(children)
            t1i = coreset_tree.T12(children(i),1)-1;
            t2i = coreset_tree.T12(children(i),2);
            t1ix = t1i/coreset_tree.NumSpannedFrames;
            t2ix = t2i/coreset_tree.NumSpannedFrames;
            children_rect_hnd(i) = rectangle('Position',[t1ix 0 t2ix-t1ix BAR_HEIGHT], ...
                'FaceColor',children_colors(i,:),'LineStyle','none');
        end
    end
    if isempty(children) || is_bar_clicked
        % draw selected rectangle
        selected_rect_hnd = rectangle('Position',[t1x 0 t2x-t1x BAR_HEIGHT], ...
            'FaceColor',[1 0.8 0.2],'LineStyle','none');
    end
    
    gui_title_str = {' '};
    gui_title_str = cat(1,gui_title_str,['LEAF SIZE: ' num2str(coreset_tree.LeafSize)]);
    gui_title_str = cat(1,gui_title_str,['SELECTED TIME SPAN: ' num2str(t1) '--' num2str(t2)]);
    gui_title_str = cat(1,gui_title_str,['KEYFRAME TIME SPAN: ' num2str(node_t1) '--' num2str(node_t2)]);
    gui_title_str = cat(1,gui_title_str,['NUM SEGMENTS: ' num2str(coreset_tree.Data{this_node}.NumSegments)]);
    title(gui_title_str,'FontName','Arial','FontSize',16)
    
end

%% draw display

if is_display_clicked
    show_details = not(show_details);
end

if show_details
    subplot(132)
else
    subplot(1,3,2:3)
end

% draw keyframe collage
draw_keyframe_collage(this_keyframes,this_border_colors);

collage_title_str = {'KEYFRAMES:'};
collage_title_str = cat(1,collage_title_str,num2str(this_key_idx(1:min(3,this_num_keyframes))));
collage_title_str = cat(1,collage_title_str,num2str(this_key_idx(4:min(6,this_num_keyframes))));
collage_title_str = cat(1,collage_title_str,num2str(this_key_idx(7:min(9,this_num_keyframes))));
collage_title_str = cat(1,collage_title_str,' ');
title(collage_title_str,'FontName','Arial','FontSize',16)

% draw keyframe selection data
if show_details
    
    subplot(133);
    subplot_idx1 = 233;
    subplot_idx2 = 236;
    
    keyframe_sel_idx = coreset_tree.Data{this_node}.KeyframeSelIdx;
    D = coreset_tree.Data{this_node}.Metrics.D;
    w = coreset_tree.Data{this_node}.Metrics.w;
    M = coreset_tree.Data{this_node}.Metrics.M;
    f = coreset_tree.Data{this_node}.Metrics.f;
    
    draw_keyframe_metrics(keyframe_sel_idx,D,w,M,f,subplot_idx1,subplot_idx2)
    
%     fig = gcf;
%     figure(fig.Number+1)
%     draw_kx_metrics_3d(keyframe_sel_idx,D,w,M,f,subplot_idx1,subplot_idx2)
%     figure(fig)
    
end

end

% -------------------------------------------------------------------------------------------------
% draw keyframe collage
function draw_keyframe_collage(keyframes,border_colors)

margin_width = 40;
frame_size = [size(keyframes{1},1) size(keyframes{1},2)];
collage = ones((frame_size(1)+margin_width*2)*3,(frame_size(2)+margin_width*2)*3,3)*240;

border_width = 20;
for i = 1:length(keyframes)
    r = mod(i-1,3)+1;
    c = ceil(i/3);
    xi = (1:frame_size(1)+border_width*2)+(c-1)*(frame_size(1)+margin_width*2)+margin_width-border_width;
    yi = (1:frame_size(2)+border_width*2)+(r-1)*(frame_size(2)+margin_width*2)+margin_width-border_width;
    for j = 1:3
        collage(xi,yi,j) = ones(size(collage(xi,yi,j)))*border_colors{i}(j)*255;
    end
end

for i = 1:length(keyframes)
    r = mod(i-1,3)+1;
    c = ceil(i/3);
    xi = (1:frame_size(1))+(c-1)*(frame_size(1)+margin_width*2)+margin_width;
    yi = (1:frame_size(2))+(r-1)*(frame_size(2)+margin_width*2)+margin_width;
    collage(xi,yi,:) = keyframes{i};
end

image(collage/255)
axis image, axis off

end

% -------------------------------------------------------------------------------------------------
% draw keyframe metrics
function draw_keyframe_metrics(Kx_sel_idx,D,w,M,f,subplot_idx1,subplot_idx2)

num_candidate_frames = length(f);
num_metrics = length(w);

h_axis = subplot(subplot_idx1);
title('Distance matrix D','FontSize',16)
cla(h_axis)
hold on
Dx = D;
for i = 1:num_candidate_frames
    for j = 1:num_candidate_frames
        if i < j
            Dx(i,j) = nan;
        end
    end
end
if num_candidate_frames > 1
    surf(Dx)
    plot3([1 1],[1 2],Dx(1:2,1),'k')
    plot3([num_candidate_frames-1 num_candidate_frames],[num_candidate_frames num_candidate_frames],Dx(end,end-1:end),'k')
    plot3(1:num_candidate_frames,ones(1,num_candidate_frames),zeros(1,num_candidate_frames),'k')
    plot3(ones(1,num_candidate_frames)*num_candidate_frames,1:num_candidate_frames,zeros(1,num_candidate_frames),'k')
end
stem3(1:num_candidate_frames,1:num_candidate_frames,Dx,'k')
plot3(1:num_candidate_frames,1:num_candidate_frames,zeros(1,num_candidate_frames),'k')
view([0 90])
axis([0 num_candidate_frames+0.99 0 num_candidate_frames+0.99])
set(gca,'xtick',1:num_candidate_frames)
set(gca,'ytick',1:num_candidate_frames)
colormap(summer)

h_axis = subplot(subplot_idx2);
title('Relevance score f*','FontSize',16)
cla(h_axis)
hold on
kx_colors = lines(num_metrics);
% dummy plots for legend
for i = 1:num_metrics
    plot(-1,0,'x','color',kx_colors(i,:),'linewidth',2)
end
plot(f,'k-','linewidth',2)
legend_str = cellstr([[repmat('f',num_metrics,1) num2str((1:num_metrics)')]; 'f*']);
legend(legend_str,'FontSize',12)
for i = 1:num_metrics
    fi = w(i).*M(i,:);
    plot(fi,'x-','color',kx_colors(i,:),'linewidth',1)
end
plot(f,'k-','linewidth',2)
ylims = [0 1];
if not(all(isinf(f))) &&  max(f(not(isinf(f)))) > 0
    ylims = [0 max(f(not(isinf(f))))*1.2];
end
axis([0 num_candidate_frames+1 ylims]) %+ceil(num_candidate_frames/3)
set(gca,'xtick',1:num_candidate_frames)
plot(Kx_sel_idx,f(Kx_sel_idx),'ok','linewidth',4)

end

