function [res,template_info]=find_correspondence_color(I1,I2,RANSAC_ATTEMPTS)

[~,template_info]=find_magic_marker(I1,I1,0);
[res,template_info]=find_magic_marker(template_info,I2,RANSAC_ATTEMPTS);

end