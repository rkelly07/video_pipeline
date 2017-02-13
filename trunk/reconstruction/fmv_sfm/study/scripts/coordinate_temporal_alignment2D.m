%function [delta_t,X_hat,rmse,resids] = coordinate_temporal_alignment(X,Y,t,t_Y,dt)
function [delta_t,X_hat,rmse,resids,txform] = coordinate_temporal_alignment(X,Y,t,dt)

    VIZ = false;

    RMSEs = zeros(length(dt),1);
    for i=1:length(dt)

        fprintf('Working on %d of %d (%.2f%%)\n',i,length(dt),100*i/length(dt));
        
        x = interp1(t,X(:,1),t+dt(i),'pchip','extrap')'; x = x(:);
        y = interp1(t,X(:,2),t+dt(i),'pchip','extrap')'; y = y(:);

        [D, X_hat, txform] = procrustes([x,y], Y(:,1:2), 'Reflection',true);

        resids = [x,y]-X_hat;
        resid_norms = sqrt(sum( resids.^2, 2 ));
        RMSEs(i) = mean(resid_norms);

        if VIZ
            figure(92); scatter(x,y,5,'red'); hold on; scatter(X_hat(:,1),X_hat(:,2),5,'blue'); hold off;
            axis equal;
            title('Geo-registration of Camera Positions');
            legend('GPS readings','vSfM results');

            hold on;
            line([x,X_hat(:,1)]',[y,X_hat(:,2)]');
            hold off;
            
            figure(73); hist(resid_norms,100); title('Histogram of residual distances');
        end

        fprintf('dt = %.2f , RMSE = %.2f\n', dt(i), RMSEs(i));

    end

    % now just show / compute the best one
    [~,i] = min(RMSEs);

    x = interp1(t,X(:,1),t+dt(i),'pchip','extrap')'; x = x(:);
    y = interp1(t,X(:,2),t+dt(i),'pchip','extrap')'; y = y(:);
    z = interp1(t,X(:,3),t+dt(i),'pchip','extrap')'; z = z(:);

    [D, X_hat, txform] = procrustes([x,y], Y(:,1:2), 'Reflection',true);
    [~,z_hat,txformz] = procrustes(z, txform.b.*Y(:,3), 'Reflection',true,'Scaling',false);
    X_hat = [X_hat,z_hat]; % z is unchanged by 2D transform
    %X_hat = [X_hat,z]; % z is unchanged by 2D transform
    %Y_hat = [Y_hat,Y(:,3)]; % z is unchanged by 2D transform

    resids = [x,y,z]-X_hat;
    resid_norms = sqrt(sum( resids.^2, 2 ));
    RMSEs(i) = mean(resid_norms);

    %if VIZ
        figure(92); scatter3(x,y,z,5,'red'); hold on; scatter3(X_hat(:,1),X_hat(:,2),X_hat(:,3),5,'blue'); hold off;
        axis equal;
        title('Geo-registration of Camera Positions');
        legend('GPS readings','vSfM results');

        hold on;
        line([x,X_hat(:,1)]',[y,X_hat(:,2)]',[z,X_hat(:,3)]');
        hold off;

        figure(73); hist(resid_norms,100); title('Histogram of residual distances');

    %end

    %figure(46); plot(dt,RMSEs); xlabel('Time Offset (secs)'); ylabel('Mean Residual Distance'); title('Time Sync of GPS and Photos to Improve Geo-registration Accuracy');
    figure(46); plot(dt,RMSEs); xlabel('Time Offset (secs)'); ylabel('Mean Residual Distance'); title('Time Sync via Brute-force Search');

    delta_t = dt(i);
    rmse = RMSEs(i);
    fprintf('\nBest: dt = %.2f , RMSE = %.2f\n\n', delta_t, rmse);
    
end