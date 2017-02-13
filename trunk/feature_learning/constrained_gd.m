function [f_out,u,stats]=constrained_gd(F,proj,u0,opt)
stats=[];
stats.history={};
u=u0;
v=u(:);
if (~exist('opt','var'))
    opt=[];
end
opt=incorporate_defaults(opt,struct('iter',10,'r',50,'outer_iter',20,'ssize',0.00001,'save_history',0));
mu=zeros(size(u(:)));
gap=[];fs=[];
for i2=1:opt.outer_iter
    for i=1:opt.iter
        [f,g]=F(u);
        du=u(:)-v(:);
        g=g+opt.r*(du)+mu;
        f=f+opt.r/2*(du(:)'*du(:))+mu(:)'*du(:);
        u=u(:)-opt.ssize*g;
        u=reshape(u,size(u0));
        v2=u(:)+mu/opt.r;
        v=proj(v2);
        du=u(:)-v(:);
        gap(end+1)=norm(du)/(0.5*(norm(u(:))+norm(v(:))));
        fs(end+1)=f;
        if (mod(i,50))
            subplot(121);plot(gap);drawnow;
            subplot(122);plot(fs);drawnow;
        end
    end
    disp(f)
    mu=mu+opt.r*du;
    if (opt.save_history>0)
        hst_step=max(1,floor(opt.outer_iter/opt.save_history));
        if (mod(i2,hst_step)==0)
            hst=struct('u',u,'v',v,'mu',mu,'i2',i2)
            stats.history{end+1}=hst;
            
        end
    end
end
f_out=f;
stats.fs=fs;
stats.gap=gap;
end