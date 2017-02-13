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
