function camstat=camstat_struct_from_P(P)
camstat=[];
camstat.P=P;
    [r1,q1]=rq(P(1:3,1:3));
    idx1=find(sign(diag(r1))<0);
    r1(:,idx1)=-r1(:,idx1);
    q1(idx1,:)=-q1(idx1,:);
    if (det(q1)<0)
        q1=-q1;
        P=-P;
    end
    camstat.K=r1;
    camstat.P=P;
    camstat.R=q1;
    camstat.t=pinv(camstat.K)*P(:,4);
P1=camstat.K*[camstat.R,camstat.t];
norm(P1-P);

end