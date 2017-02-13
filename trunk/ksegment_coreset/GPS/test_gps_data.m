myclear, close all, clc

% load good_idx
% files = dir('GPS/data/new_*');

import_gps

%%
for taxi_id = 376:length(files)
  
  taxi_id
  pause(1)
  
  test_ksegment_coreset
  
  gps_errors{taxi_id,1} = [D_eps_rnd,D_eps_rnd_std,D_eps_rnd_min,D_eps_rnd_max];
  gps_errors{taxi_id,2} = [U_eps_rnd,U_eps_rnd_std,U_eps_rnd_min,U_eps_rnd_max];
  gps_errors{taxi_id,3} = [R_eps_rnd,R_eps_rnd_std,R_eps_rnd_min,R_eps_rnd_max];
  gps_errors{taxi_id,4} = [G_eps_rnd,G_eps_rnd_std,G_eps_rnd_min,G_eps_rnd_max];
  gps_errors{taxi_id,5} = [H_eps_rnd,H_eps_rnd_std,H_eps_rnd_min,H_eps_rnd_max];
  gps_errors{taxi_id,6} = [J_eps_rnd,J_eps_rnd_std,J_eps_rnd_min,J_eps_rnd_max];
  gps_errors{taxi_id,7} = [K_eps_rnd,K_eps_rnd_std,K_eps_rnd_min,K_eps_rnd_max];
  
end

% load gps_errors_1-126
% gps_errors1 = gps_errors;
% load gps_errors_128-343
% gps_errors2 = gps_errors;
% load gps_errors_345-373
% gps_errors3 = gps_errors;
% load gps_errors_376-536
% gps_errors4 = gps_errors;
% clear gps_errors
% for i = 1:536
% if i>=1 && i<=126
% gps_errors(i,:) = gps_errors1(i,:);
% elseif i>=128 && i<=343
% gps_errors(i,:) = gps_errors2(i,:);
% elseif i>=345 && i<=373
% gps_errors(i,:) = gps_errors3(i,:);
% elseif i>=376 && i<=536
% gps_errors(i,:) = gps_errors4(i,:);
% end
% end
% gps_errors = [gps_errors1(1:126,:); gps_errors2(128:343,:); gps_errors3(345:373,:); gps_errors4(376:536,:)];

%%
for j = 1:7
  s1 = 0;
  s2 = 0;
  for i = 1:size(gps_errors,1)
    c = gps_errors{i,j};
    s1 = s1+c(1);
    s2 = s2+c(2);
  end
  s1 = s1/size(gps_errors,1)
  s2 = s2/size(gps_errors,1)
end
