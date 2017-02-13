function res = construct_reweighting_matrix(data,indice_groups)
Vp=[];Vn=[];
for i=1:numel(indice_groups)
    i1=min(indice_groups{i});
    i2=max(indice_groups{i});
    step=round((i2-i1)/40);
    indice_groups{i}=[i1:step:i2];
end
for i = 1:numel(indice_groups)
    V1=data(:,indice_groups{i});
    for i1=1:size(V1,2)
        for i2=1:(i1-1)
            Vp(:,end+1)=V1(:,i1)-V1(:,i2);
        end
    end
    
end
for i = 1:numel(indice_groups)
    for j = (i+1):numel(indice_groups)
        for i1=1:numel(indice_groups{i})
            for i2=1:numel(indice_groups{j})
                Vn(:,end+1)=data(:,indice_groups{i}(i1))-data(:,indice_groups{j}(i2));
            end
        end
        
    end
end
Sp=compute_cov(Vp);
Sn=compute_cov(Vn);
sIp=mean(diag(Sp))*eye(size(Sp))/10;
% sIn=mean(diag(Sn))*eye(size(Sn));
% [P,D]=eig(Sp);
res=pinv(Sp+sIp);

% alp*P*Sn*P'-P*Sp*P'
% [U,D]=eig(Sp);

% res=pinv(Sph);
disp([norm(res*Vn)/norm(res*Vp) norm(Vn)/norm(Vp)]);
end

function Sn=compute_cov(Vn)
% Vn=bsxfun(@minus,Vn,mean(Vn));
Sn=Vn*Vn';
end