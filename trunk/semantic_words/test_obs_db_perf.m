

cfg=[];
cfg.server = 'localhost';
cfg.instance = 'postgres';
cfg.username = 'postgres';
cfg.password = '?D8yr5^5';
cfg.db_name = 'postgres';

A=observations_db(cfg);
A.open_db();

%add rows to test table

num_rows_to_add = 500;
start_int = 1;
disp(['Adding ' int2str(num_rows_to_add) ' rows in test table']);
A.add_data_to_test_table(num_rows_to_add, start_int)


%% test retrieval times

%we increase the range exponentially
base_num = 2; %we retrieve powers of base_num rows
highest_pow = 20;
start_row = 1;
highest_row_nums = num_rows_to_add;
range = base_num;
range_time_mat = [];
for pow = 1:highest_pow
    num_rows_to_retrieve = base_num ^ pow;
    if (start_row + num_rows_to_retrieve)>highest_row_nums
        break
    end
    disp(['Retrieving ' int2str(num_rows_to_retrieve) ' int_cols']);
    tic
    try
        A.get_range_rows_from_test('int_col', [start_row, start_row + num_rows_to_retrieve]);
    catch e
        warning(e.identifier, 'Retrieving rows failed');
        break;
    end
    time_taken = toc*1000; %milliseconds
    range_time_col = [pow time_taken];
    if isempty(range_time_mat)
        range_time_mat = range_time_col;
    else
        range_time_mat = [range_time_mat;range_time_col];
    end
end

%plot the matrix
range_time_mat

figure

plot(range_time_mat(:,1),range_time_mat(:,2),'Color',[0,0.7,0.9]);

title(['Range vs. retrieval time with ' int2str(num_rows_to_add) ' rows on table']);
xlabel('Log_2 of range of query, i.e. num rows retrieved');
ylabel('Time taken to retrieve in milliseconds');

%{
tic
disp('Retrieving 10 int_cols');
A.get_range_rows_from_test('int_col', [100000 100010]);
toc


tic
disp('Retrieving 100 int_cols');
A.get_range_rows_from_test('int_col', [100000 100100]);
toc

tic
disp('Retrieving 1000 int_cols');
A.get_range_rows_from_test('int_col', [100000 101000]);
toc

tic
disp('Retrieving 10000 int_cols');
A.get_range_rows_from_test('int_col', [100000 110000]);
toc

tic
disp('Retrieving 100000 int_cols');
A.get_range_rows_from_test('int_col', [100000 200000]);
toc

tic
disp('Retrieving 1000000 int_cols');
A.get_range_rows_from_test('int_col', [100000 1100000]);
toc


tic
disp('Retrieving int_cols 1 to 11');
A.get_range_rows_from_test('int_col', [1 11]);
toc

tic
disp('Retrieving int_cols 1000 to 1010');
A.get_range_rows_from_test('int_col', [1000 1010]);
toc

tic
disp('Retrieving int_cols 1 to 101');
A.get_range_rows_from_test('int_col', [1 101]);
toc

tic
disp('Retrieving int_cols 5000 to 5100');
A.get_range_rows_from_test('int_col', [5000 5100]);
toc

tic
disp('Retrieving int_cols 1 to 501');
A.get_range_rows_from_test('int_col', [1 501]);
toc

tic
disp('Retrieving int_cols 2500 to 3000');
A.get_range_rows_from_test('int_col', [2500 3000]);
toc

tic
disp('Retrieving int_cols 1 to 1001');
A.get_range_rows_from_test('int_col', [1 1001]);
toc

tic
disp('Retrieving int_cols 3000 to 4000');
A.get_range_rows_from_test('int_col', [3000 4000]);
toc

tic
disp('Retrieving int_cols 1 to 5001');
A.get_range_rows_from_test('int_col', [1 5001]);
toc

tic
disp('Retrieving int_cols 2000 to 7000');
A.get_range_rows_from_test('int_col', [2000 7000]);
toc

tic
disp('Retrieving int_cols 1 to 10000');
A.get_range_rows_from_test('int_col', [1 10000]);
toc
%}
A.close_db();

