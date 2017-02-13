% using reference given by X(t), find 3D rigid transform and time offset to best align query Y(t+delta_t) to reference
%
% input: reference X_{Kx3}, in correspondence with time ticks given by t_{Kx1}, closely corresponding with query Y_{Kx3}
% output: time offset delta_t, transformed query Y_hat, RMSE, resids
%
% NOTE: currently set to use extrapolation, so trajectory endpoints might go a bit haywire
function [delta_t,Y_hat,rmse,resids] = coordinate_temporal_alignment(X,Y,t,delta_t_range)

    VIZ = true;

    opts = optimset('fminbnd');
    f = @(delta_t) fit_3D_transform(X,Y,t,t-delta_t); % function to optimize; first return value must be error metric
    [delta_t,f_min] = fminbnd(f,min(delta_t_range),max(delta_t_range),opts);
    rmse = f_min;
    
    if VIZ

        [rmse,resids,txform,Y_hat] = fit_3D_transform(X,Y,t,t); % no time-offset
        
        figure(91); scatter3(X(:,1),X(:,2),X(:,3),50,'r.'); hold on; scatter3(Y_hat(:,1),Y_hat(:,2),Y_hat(:,3),50,'bs'); hold off;
        axis equal;
        title('Geo-registration of Camera Positions');
        legend('GPS readings','vSfM results');

        hold on;
        line([X(:,1),Y_hat(:,1)]',[X(:,2),Y_hat(:,2)]',[X(:,3),Y_hat(:,3)]','LineStyle','--');
        hold off;

        resid_norms = sqrt(sum( resids.^2, 2 ));
        figure(72); hist(resid_norms,100); title('Histogram of residual distances');
        
    end
    
    % re-fit using best, get all output data fields
    [rmse,resids,txform,Y_hat] = fit_3D_transform(X,Y,t,t-delta_t);
    %[rmse,resids,txform,Y_hat] = fit_3D_transform(X,Y,t+delta_t,t); % equivalent
    % [rmse,resids,txform,Y_hat] = fit_3D_transform([interp1(t,X(:,1),t-delta_t,'pchip','extrap'),interp1(t,X(:,2),t-delta_t,'pchip','extrap'),interp1(t,X(:,3),t-delta_t,'pchip','extrap')],Y,t,t); % equivalent
    
    if VIZ

        figure(92); scatter3(X(:,1),X(:,2),X(:,3),50,'r.'); hold on; scatter3(Y_hat(:,1),Y_hat(:,2),Y_hat(:,3),50,'bs'); hold off;
        axis equal;
        title('Spatio-temporal Geo-registration of Camera Positions');
        legend('GPS readings','vSfM results');

        hold on;
        line([X(:,1),Y_hat(:,1)]',[X(:,2),Y_hat(:,2)]',[X(:,3),Y_hat(:,3)]','LineStyle','--');
        hold off;

        resid_norms = sqrt(sum( resids.^2, 2 ));
        figure(73); hist(resid_norms,100); title('Histogram of residual distances');
        
    end
    
    %%%%%%%%%%%%%%%%
    % Old method below, not using MATLAB built-in fminsearch and instead brute-forcing via exhaustive search
    %%%%%%%%%%%%%%%%
    
%     RMSEs = zeros(length(dt),1);
%     for i=1:length(dt)
% 
%         fprintf('Working on %d of %d (%.2f%%)\n',i,length(dt),100*i/length(dt));
%         
%         delta_t = dt(i);
%         [rmse,txform] = fit_3D_transform(X,Y,t,t+delta_t);
%         RMSEs(i) = rmse;
% 
%         fprintf('delta_t = %.2f , RMSE = %.2f\n', delta_t, rmse);
%         
% %         x = interp1(t,X(:,1),t+dt(i),'pchip','extrap')';
% %         y = interp1(t,X(:,2),t+dt(i),'pchip','extrap')';
% %         z = interp1(t,X(:,3),t+dt(i),'pchip','extrap')';
% % 
% %         [D, Y_hat, txform] = procrustes([x(:),y(:),z(:)], Y);
% % 
% %         resids = [x(:),y(:),z(:)]-Y_hat;
% %         resid_norms = sqrt(sum( resids.^2, 2 ));
% %         RMSEs(i) = mean(resid_norms);
% % 
% %         if VIZ
% %             figure(92); scatter3(x,y,z,5,'red'); hold on; scatter3(Y_hat(:,1),Y_hat(:,2),Y_hat(:,3),5,'blue'); hold off;
% %             axis equal;
% %             title('Geo-registration of Camera Positions');
% %             legend('GPS readings','vSfM results');
% % 
% %             hold on;
% %             line([x,Y_hat(:,1)]',[y,Y_hat(:,2)]',[z,Y_hat(:,3)]');
% %             hold off;
% %             
% %             figure(73); hist(resid_norms,100); title('Histogram of residual distances');
% %         end
% % 
% %         fprintf('dt = %.2f , RMSE = %.2f\n', dt(i), RMSEs(i));
% 
%     end
% 
%     % now just show / compute the best one
%     [~,i] = min(RMSEs);
% 
%     x = interp1(t,X(:,1),t+dt(i),'pchip','extrap')';
%     y = interp1(t,X(:,2),t+dt(i),'pchip','extrap')';
%     z = interp1(t,X(:,3),t+dt(i),'pchip','extrap')';
% 
%     [~, Y_hat, txform] = procrustes([x(:),y(:),z(:)], Y);
% 
%     resids = [x(:),y(:),z(:)]-Y_hat;
%     resid_norms = sqrt(sum( resids.^2, 2 ));
%     RMSEs(i) = mean(resid_norms);
% 
%     if VIZ
%         figure(92); scatter3(x,y,z,5,'red'); hold on; scatter3(Y_hat(:,1),Y_hat(:,2),Y_hat(:,3),5,'blue'); hold off;
%         axis equal;
%         title('Geo-registration of Camera Positions');
%         legend('GPS readings','vSfM results');
% 
%         hold on;
%         line([x,Y_hat(:,1)]',[y,Y_hat(:,2)]',[z,Y_hat(:,3)]');
%         hold off;
% 
%         figure(73); hist(resid_norms,100); title('Histogram of residual distances');
% 
%     end
% 
%     %figure(46); plot(dt,RMSEs); xlabel('Time Offset (secs)'); ylabel('Mean Residual Distance'); title('Time Sync of GPS and Photos to Improve Geo-registration Accuracy');
%     figure(46); plot(dt,RMSEs); xlabel('Time Offset (secs)'); ylabel('Mean Residual Distance'); title('Time Sync via Brute-force Search');
% 
%     delta_t = dt(i);
%     rmse = RMSEs(i);
    
    fprintf('\nBest: dt = %.2f , RMSE = %.2f\n\n', delta_t, rmse);
    
    function [rmse,resids,txform,Y_hat] = fit_3D_transform(X,Y,t_X,t_Y)
        
        % shift time: interpolate to find values of X at time points t_Y
        x = interp1(t_X,X(:,1),t_Y,'pchip','extrap')';
        y = interp1(t_X,X(:,2),t_Y,'pchip','extrap')';
        z = interp1(t_X,X(:,3),t_Y,'pchip','extrap')';

        [~, Y_hat, txform] = procrustes([x(:),y(:),z(:)], Y);

        resids = [x(:),y(:),z(:)]-Y_hat;
        resid_norms = sqrt(sum( resids.^2, 2 ));
        %RMSEs(i) = mean(resid_norms);
        rmse = mean(resid_norms);

%         if VIZ
%             figure(92); scatter3(x,y,z,5,'red'); hold on; scatter3(Y_hat(:,1),Y_hat(:,2),Y_hat(:,3),5,'blue'); hold off;
%             axis equal;
%             title('Geo-registration of Camera Positions');
%             legend('GPS readings','vSfM results');
% 
%             hold on;
%             line([X(:,1),Y_hat(:,1)]',[X(:,2),Y_hat(:,2)]',[X(:,3),Y_hat(:,3)]');
%             hold off;
%             
%             figure(73); hist(resid_norms,100); title('Histogram of residual distances');
%         end
        
        % unshift time: interpolate to find values of Y_hat at time points t_X
        x_hat = interp1(t_Y,Y_hat(:,1),t_X,'pchip','extrap')';
        y_hat = interp1(t_Y,Y_hat(:,2),t_X,'pchip','extrap')';
        z_hat = interp1(t_Y,Y_hat(:,3),t_X,'pchip','extrap')';
        Y_hat = [x_hat(:),y_hat(:),z_hat(:)];

    end
    
end