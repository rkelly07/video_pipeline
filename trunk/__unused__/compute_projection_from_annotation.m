%
% res=compute_projection_from_annotation(userdata,dim,regularization)
%  
% For example:
%
% res=compute_projection_from_annotation(saved_userdata,200,0.000001)
%
function res=compute_projection_from_annotation(userdata,dim,regularization,VQs)
if (exist('VQs','var')==0)
    VQs=randn(500,66);
end
res=[];
vals=userdata.labels.values;
keys=userdata.labels.keys;
num_files=numel(userdata.files_list);
classes={};
for i=1:num_files
    filename=keys{i};
    h=mex_video_processing('init',filename,VQs);
    labs=cell2mat(vals{i});
    ls={};
    for j=1:numel(labs)
        ls{j}=labs(j).label{1};
    end
    ls1=unique(ls);
    for j=1:numel(ls1)
        %        ls1{j}
        
        idx=find(strcmp(ls,ls1{j}));
        idx=max(1,(min(idx)-3):(max(idx)+3));
        X=[];
        for k=1:numel(idx)
            mex_video_processing('setframe',h,idx(k));
            [v,~,~]=mex_video_processing('newframe',h);
%             v=v(1:100);
            X(:,k)=v;
        end
        classes{end+1}=X;
    end
    %   l=cell2mat(labs)
end
sig_i=0;sig_o=0;
for i = 1:numel(classes)
    mu_i=mean(classes{i},2);
    Xi=bsxfun(@minus,classes{i},mu_i);
    sig_i=sig_i+Xi*Xi';
    Xi2=(Xi(:,2:end)+Xi(:,1:(end-1)))/2;
    sig_i=sig_i+Xi2*Xi2';
% for j = (i+1):numel(classes)
%     mu_j=mean(classes{j},2);
%     Xj=bsxfun(@minus,classes{j},mu_j);
%     
% end
end
X=[];
for i = 1:numel(classes)
    X=cat(2,X,classes{i});
end
sig_i=sig_i+eye(length(sig_i))*regularization;
mu=mean(X,2);
X=bsxfun(@minus,X,mu);
sig_o=sig_o+X*X';
sig_o=sig_o+eye(length(sig_o))*regularization;
[res.V,res.D]=eigs(sig_i,sig_o,dim,'sm');
res.sig_o=sig_o;
res.sig_i=sig_i;
% res=pinv(sig_i);
end