function res=crop_image_box(I,box_param)
res=I(round(box_param(2)):round(box_param(4)),round(box_param(1)):round(box_param(3)),:);
end