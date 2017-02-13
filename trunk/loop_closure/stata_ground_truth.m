%% ground truth

num_frames = 8383;

u = 1;
v = num_frames;

c11 = 1;
c12 = 1600;
c21 = 6800;
c22 = 8383;

r11 = (c11-u)/(v-u);
r12 = (c12-u)/(v-u);
r21 = (c21-u)/(v-u);
r22 = (c22-u)/(v-u);

d = mean([c21-c11 c22-c12]);
loop_tol = 100;

truth = ones(num_frames)*0;
for j = 1:num_frames
    for i = 1:num_frames
        jx = j/num_frames;
        ix = i/num_frames;
        if jx>=r11 && jx<=r12 && ix>=r21 && ix<=r22
            if abs(abs(i-j)-d) < loop_tol
                truth(i,j) = 1;
            end
        end
    end
end

figure(499)
imshow(flipud(truth))
axis on
set(gca,'yticklabel',flipud(get(gca,'yticklabel')))

save('data/stata_ground_truth','truth')
