lc=LoopClosure;
lc.create_new_page();
frame=lc.getFrame(1,1);
frame.img=randn(1);
lc.setFrame(1,1,frame);
lc.create_new_page();
for i = 1:10
    t_frame=[];
    t_frame.img=randn(1);
    lc=lc.setFrame(i+1,1,t_frame);
end
frame2=lc.getFrame(1,1);
lc.advance_timer();
for i = 1:10
    l=ceil(rand(1)*3);
    for i2=1:l
        lc.clear_old_page();
    end
    l=ceil(rand(1)*3);
    for i2=1:l
        [page,idx]=lc.swap_random_page('random',[]);
    end
    disp(numel(lc.working_memory.pages_ids))
end