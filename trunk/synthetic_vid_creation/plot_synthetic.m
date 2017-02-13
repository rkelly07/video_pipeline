function plot_synthetic( coreset_x,coreset_y, uni_x,uni_y, db_x, db_y )
%PLOT_SYNTHETIC Summary of this function goes here
%   Detailed explanation goes here
    normalize = 0;
    if normalize
        min_coreset_x = min(coreset_x);
        min_coreset_y = min(coreset_y);
        range_coreset_x = max(coreset_x) - min(coreset_x);
        range_coreset_y = max(coreset_y) - min(coreset_y);
        coreset_x = mat2gray(coreset_x);
        coreset_y = mat2gray(coreset_y);
        uni_x = mat2gray(uni_x);
        uni_y = mat2gray(uni_y);
        db_x = (db_x - min_coreset_x)/range_coreset_x;
        %db_y = (db_y - min_coreset_y)/range_coreset_y;
        db_y = 1.0;
    end
    figure;
    plot(coreset_x,coreset_y,uni_x,uni_y);
    hold on;
    plot(db_x,db_y, 'r*');
    xlabel('Time');
    ylabel('Importance');
    legend('Coreset', 'Uniform', 'DB');
    hold off;
end

