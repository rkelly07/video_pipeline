profile off, profile on
% myclear, clc
format compact

disp(repmat('=',1,80));
disp('Testing signal coreset algorithm:')

VERBOSE = true;
DRAW = true;
plot_dim = 5;

PS_GENERATE  = 1;
PS_VIDEO     = 2;
PS_BTC       = 3;
PS_GPS       = 4;
POINT_SOURCE = PS_VIDEO ;

FIGURE_HND = 100*POINT_SOURCE;
figure(FIGURE_HND), clf

leaf_size = 100;
save_tree = true;

test_start_time = tic;

%%
disp(repmat('-',1,60))
switch POINT_SOURCE
  
  case PS_GENERATE
    %% generate data
    disp('Generating data ...')
    
    k = 10
    n = 2000
    d = 20
    
    a = 10
    b = 2
    c = 0.5
    w = 0.99
    
    spread = 1;
    
    add_gaussian_noise        = true;
    gaussian_noise_mean       = 0;
    gaussian_noise_gain       = 0.1;
    gaussian_post_spread      = false;
    
    add_salt_pepper_noise     = true;
    snp_noise_prob            = 0.05;
    snp_noise_gain            = 2;
    salt_pepper_post_spread   = false;
    
    T = (1:n)';
    [X,Lx,x_endpoints] = generate_ksegment_points(T,d,k,spread);
    
    signal_start = x_endpoints(1,2);
    signal_end = x_endpoints(end-1,2);
    
    % add gaussian noise
    if add_gaussian_noise
      G = gaussian_noise_mean+gaussian_noise_gain*randn(size(X));
      %G(setdiff(1:size(G,1),signal_start:signal_end),:) = 0;
      X = X+G;
    end
    
    % add salt and pepper noise
    if add_salt_pepper_noise
      E = ((randi((1/snp_noise_prob)-1,size(X))-1)==0).*snp_noise_gain.*(2*rand(size(X))-1);
      %E(setdiff(1:size(E,1),signal_start:signal_end),:) = 0;
      X = X+E;
    end
    
  case PS_VIDEO
    %% video data
    disp('Loading video data ...')
    
    a = 10
    b = 2
    c = 0.5
    w = 0.99
    
    bow_filename = 'test_bow';
    
    load(bow_filename)
    
    X = bags_of_words;
    T = processed_frame_idx;
    
  case PS_BTC
    %% BTC data
    disp('Loading BTC data ...')
    
    a = 50
    b = 2
    c = 0.1
    w = 0.99
    
    import_mtgoxusd
    %approx_tols = [95 0.1 172 0.999];
    
    plot_dim = 1;
    
  case PS_GPS
    %% GPS data
    disp('Loading GPS data:');
    
    a = 5
    b = 2
    c = 0.5
    w = 0.99
    
    import_gps
    %approx_tols = [0.11 0.01 0.135 0.004];
    
    taxi_id = 1;
    
    ts = timeseries(X_all{taxi_id}(:,1:2),T_all{taxi_id});
    sample_interval = 60;
    Tr = 1:sample_interval:max(T_all{taxi_id});
    ts = resample(ts,Tr);
    
    X = ts.Data;
    T = (1:length(ts.Time))';

    plot_dim = 2;
    
  otherwise
    %% error
    error('Invalid point source!')
    
end
disp('Done!')

n = size(X,1)
d = size(X,2)

%% create signal point set
P = SignalPointSet(X,T);
disp('Constructing signal point set ...')

if DRAW
  
  figure(FIGURE_HND)
  %subplot(4,4,4),subplot(411)
  subplot(4,4,2),subplot(421)
  P.plot('PlotDim',plot_dim,'Title','P = source data')
  
  if POINT_SOURCE == PS_GENERATE
    for i = 1:k-1
      line([x_endpoints(i,2) x_endpoints(i,2)],get(gca,'ylim'),'Color','k','LineWidth',2,'LineStyle','--')
    end
  end
  
  if POINT_SOURCE == PS_BTC
    close(20)
    hold on
    plot(T,Low,'rv')
    plot(T,High,'g^')
    plot(T,Close,'k')
    set(gca,'xgrid','on')
    %datetick('x','yyyy-mmm')
    %set(gca,'xlim',[min(T0) max(T0)])
    ylabel('USD')
    title('MTGOXUSD')
  end
  
  if POINT_SOURCE == PS_GPS
%     close(401)
%     close(402)
  end
  
  drawnow
  
end

%%
disp(repmat('-',1,60))
disp('Testing k-segment coreset stream ...')
tic

coreset_alg = KSegmentCoresetAlg();
coreset_alg.a = a;
coreset_alg.b = b;
coreset_alg.c = c;
coreset_alg.w = w;
coreset_alg.verbose = VERBOSE;

stream = Stream();
stream.coresetAlg = coreset_alg;
stream.leafSize = leaf_size;
stream.saveTree = save_tree;
stream.verbose = VERBOSE;

stream.addPointSet(P);
D = stream.getUnifiedCoreset();
mx = D.totalCoresetSize();

disp([' D segments = ' num2str(D.m)])
disp([' D total size = ' num2str(mx)])

toc
disp('Done!')

if DRAW
  figure(FIGURE_HND)
  %subplot(4,4,8),subplot(412)
  subplot(4,4,4),subplot(422)
  D.plot('PlotDim',plot_dim,'Title',['D = k-segment coreset (m = ' num2str(D.m) ')'])
  drawnow
end

%%
disp(repmat('-',1,60))
disp('Computing uniform sample coreset ...')

U = UniformSampleCoreset(P,mx);
disp([' size U = ' num2str(U.m)])

if DRAW
  figure(FIGURE_HND)
  %subplot(4,4,12),subplot(413)
  subplot(4,4,6),subplot(423)
  U.plot('PlotDim',plot_dim,'Title',['U = uniform sample coreset (m = ' num2str(U.m) ')'])
  drawnow
end

disp('Done!')

%%
disp(repmat('-',1,60))
disp('Computing random sample coreset ...')

R = RandomSampleCoreset(P,mx);
disp([' size R = ' num2str(R.m)])

if DRAW
  figure(FIGURE_HND)
  %subplot(4,4,16),subplot(414)
  subplot(4,4,8),subplot(424)
  R.plot('PlotDim',plot_dim,'Title',['R = random sample coreset (m = ' num2str(R.m) ')'])
  drawnow
end

disp('Done!')

%%
% disp(repmat('-',1,60))
% disp('Computing RDP on P ...')
% 
% tol = 10;
% mult = 1.1;
% fprintf('size G = ')
% while 1
%   G = RDPCoreset(P,tol);
%   fprintf('%d -> ',G.m)
%   if G.m <= mx
%     fprintf('\n')
%     break
%   else
%     tol = tol*mult;
%   end
% end
% 
% if DRAW
%   figure(FIGURE_HND)
%   %subplot(4,4,12),subplot(413)
%   subplot(4,4,10),subplot(425)
%   G.plot('PlotDim',plot_dim,'Title',['G = RamerDouglasPeucker on P (m = ' num2str(G.m) ')'])
%   drawnow
% end
% 
% disp('Done!')
% 
% %%
% disp(repmat('-',1,60))
% disp('Computing RDP on D ...')
% 
% tol = 0.001;
% 
% H = RDPCoreset(D,tol);
% disp([' size H = ' num2str(H.m)])
% 
% if DRAW
%   figure(FIGURE_HND)
%   %subplot(4,4,12),subplot(413)
%   subplot(4,4,12),subplot(426)
%   H.plot('PlotDim',plot_dim,'Title',['H = RamerDouglasPeucker on D (m = ' num2str(H.m) ')'])
%   drawnow
% end
% 
% disp('Done!')
% 
% %%
% disp(repmat('-',1,60))
% disp('Computing DeadRec on P ...')
% 
% tol = 0.1;
% mult = 1.1;
% fprintf('size J = ')
% while 1
%   J = DeadRecCoreset(P,tol);
%   fprintf('%d -> ',J.m)
%   if J.m <= mx
%     fprintf('\n')
%     break
%   else
%     tol = tol*mult;
%   end
% end
% 
% if DRAW
%   figure(FIGURE_HND)
%   %subplot(4,4,16),subplot(414)
%   subplot(4,4,14),subplot(427)
%   J.plot('PlotDim',plot_dim,'Title',['J = DeadReckoning on P (m = ' num2str(J.m) ')'])
%   drawnow
% end
% 
% disp('Done!')
% 
% %%
% disp(repmat('-',1,60))
% disp('Computing DeadRec on D ...')
% 
% tol = 0.001;
% 
% K = DeadRecCoreset(D,tol);
% disp([' size K = ' num2str(K.m)])
% 
% if DRAW
%   figure(FIGURE_HND)
%   %subplot(4,4,16),subplot(414)
%   subplot(4,4,16),subplot(428)
%   K.plot('PlotDim',plot_dim,'Title',['K = DeadReckoning on D (m = ' num2str(K.m) ')'])
%   drawnow
% end
% 
% disp('Done!')

%% compute approximation costs (source)
if POINT_SOURCE == PS_GENERATE
  disp(repmat('-',1,60))
  disp('Testing coreset: source k-segment query ...')
  
  Q_src = SourceKSegmentQuery(T,Lx,x_endpoints);
  
  cost_PQ_src = P.ComputeQueryCost(Q_src);
  disp([' src cost(P,Q) = ' num2str(cost_PQ_src)])
  
  cost_DQ_src = D.ComputeQueryCost(Q_src);
  disp([' src cost(D,Q) = ' num2str(cost_DQ_src)])
  
  cost_UQ_src = U.ComputeQueryCost(Q_src);
  disp([' src cost(U,Q) = ' num2str(cost_UQ_src)])
  
  cost_RQ_src = R.ComputeQueryCost(Q_src);
  disp([' src cost(R,Q) = ' num2str(cost_RQ_src)])
  
  cost_GQ_src = G.ComputeQueryCost(Q_src);
  disp([' src cost(G,Q) = ' num2str(cost_GQ_src)])
  
  cost_HQ_src = H.ComputeQueryCost(Q_src);
  disp([' src cost(H,Q) = ' num2str(cost_HQ_src)])
  
  cost_JQ_src = J.ComputeQueryCost(Q_src);
  disp([' src cost(J,Q) = ' num2str(cost_JQ_src)])
  
  cost_KQ_src = K.ComputeQueryCost(Q_src);
  disp([' src cost(K,Q) = ' num2str(cost_KQ_src)])
  
  [D_eps_src] = compute_error_estimate(cost_PQ_src,cost_DQ_src);
  [U_eps_src] = compute_error_estimate(cost_PQ_src,cost_UQ_src);
  [R_eps_src] = compute_error_estimate(cost_PQ_src,cost_RQ_src);
  [G_eps_src] = compute_error_estimate(cost_PQ_src,cost_GQ_src);
  [H_eps_src] = compute_error_estimate(cost_PQ_src,cost_HQ_src);
  [J_eps_src] = compute_error_estimate(cost_PQ_src,cost_JQ_src);
  [K_eps_src] = compute_error_estimate(cost_PQ_src,cost_KQ_src);
  
  disp([' coreset eps_src = ' num2str(D_eps_src)])
  disp([' uniform eps_src = ' num2str(U_eps_src)])
  disp([' random eps_src = ' num2str(R_eps_src)])
  disp([' RDP on points eps_src = ' num2str(G_eps_src)])
  disp([' RDP on ksegment eps_src = ' num2str(H_eps_src)])
  disp([' DeadRec on points eps_src = ' num2str(J_eps_src)])
  disp([' DeadRec on ksegment eps_src = ' num2str(K_eps_src)])
  
  % if DRAW
  %   figure(FIGURE_HND),subplot(4,4,12),subplot(413)
  %   Q.plot('Title','Q1 = source k-segment query')
  %   for i = 1:k-1
  %     line([Q.endpoints(i,2) Q.endpoints(i,2)],get(gca,'ylim'),'Color','k','LineWidth',2,'LineStyle','--')
  %   end
  %   drawnow
  % end
  
  disp('Done!')
end

%% compute approximation costs (random)
disp(repmat('-',1,60))
disp('Testing coreset: random k-segment query ...')

num_queries = 10;

test_k = ceil(D.m/10)
for i = 1:num_queries
  
  Q = RandomKSegmentQuery(T,d,test_k);
  
  cost_PQ_rnd(i) = P.ComputeQueryCost(Q);
  cost_DQ_rnd(i) = D.ComputeQueryCost(Q);
  cost_UQ_rnd(i) = U.ComputeQueryCost(Q);
  cost_RQ_rnd(i) = R.ComputeQueryCost(Q);
%   cost_GQ_rnd(i) = G.ComputeQueryCost(Q);
%   cost_HQ_rnd(i) = H.ComputeQueryCost(Q);
%   cost_JQ_rnd(i) = J.ComputeQueryCost(Q);
%   cost_KQ_rnd(i) = K.ComputeQueryCost(Q);
  
  % if DRAW
  %   figure(FIGURE_HND),subplot(4,4,16),subplot(414)
  %   Q.plot('Title','Q2 = random k-segment query')
  %   for i = 1:k-1
  %     line([Q.endpoints(i,2) Q.endpoints(i,2)],get(gca,'ylim'),'Color','k','LineWidth',2,'LineStyle','--')
  %   end
  %   drawnow
  % end
  
end

[D_eps_rnd,D_eps_rnd_std,D_eps_rnd_min,D_eps_rnd_max] = compute_error_estimate(cost_PQ_rnd,cost_DQ_rnd);
[U_eps_rnd,U_eps_rnd_std,U_eps_rnd_min,U_eps_rnd_max] = compute_error_estimate(cost_PQ_rnd,cost_UQ_rnd);
[R_eps_rnd,R_eps_rnd_std,R_eps_rnd_min,R_eps_rnd_max] = compute_error_estimate(cost_PQ_rnd,cost_RQ_rnd);
% [G_eps_rnd,G_eps_rnd_std,G_eps_rnd_min,G_eps_rnd_max] = compute_error_estimate(cost_PQ_rnd,cost_GQ_rnd);
% [H_eps_rnd,H_eps_rnd_std,H_eps_rnd_min,H_eps_rnd_max] = compute_error_estimate(cost_PQ_rnd,cost_HQ_rnd);
% [J_eps_rnd,J_eps_rnd_std,J_eps_rnd_min,J_eps_rnd_max] = compute_error_estimate(cost_PQ_rnd,cost_JQ_rnd);
% [K_eps_rnd,K_eps_rnd_std,K_eps_rnd_min,K_eps_rnd_max] = compute_error_estimate(cost_PQ_rnd,cost_KQ_rnd);

disp([' coreset eps_rnd = ' num2str(D_eps_rnd)])
disp([' uniform eps_rnd = ' num2str(U_eps_rnd)])
disp([' random eps_rnd = ' num2str(R_eps_rnd)])
% disp([' RDP on points eps_rnd = ' num2str(G_eps_rnd)])
% disp([' RDP on ksegment eps_rnd = ' num2str(H_eps_rnd)])
% disp([' DeadRec on points eps_rnd = ' num2str(J_eps_rnd)])
% disp([' DeadRec on ksegment eps_rnd = ' num2str(K_eps_rnd)])

disp('Done!')

%%
disp(repmat('-',1,60))
disp('Total test time:')
toc(test_start_time)
disp(repmat('=',1,80))

