function biased_random_walk_main()
    % Change rng for reproducibility or leave shuffled
    rng('shuffle');

    % Domain size
    L = 99; % 99 x 99 grid

    % Define probability cases (s,w,e)
    cases = {
        [1/3, 1/3, 1/3], ... % (i)
        [2/3, 1/6, 1/6], ... % (ii)
        [3/5, 3/10, 1/10], ... % (iii)
        [3/5, 1/10, 3/10] ... % (iv)
    };

    case_titles = {"(i) s=w=e=1/3","(ii) s=2/3,w=1/6,e=1/6",...
                   "(iii) s=3/5,w=3/10,e=1/10","(iv) s=3/5,w=1/10,e=3/10"};

    % Start position P: numeric 1 -> fixed at column 50, 'rand' -> random along top
    start_positions = {1, 'rand'}; % correspond to P=1 and P=rand
    start_titles = {"P = 1 (col 50)", "P = rand (uniform)"};

    Ns = [100, 200]; % N values

    % Run through combinations and create 4 figures (one per P & N pair)
    figcount = 1;
    for p_idx = 1:2
        for n_idx = 1:2
            P = start_positions{p_idx};
            N = Ns(n_idx);
            figure('Name',sprintf('Figure %d: %s, N=%d',figcount,start_titles{p_idx},N), 'NumberTitle','off','Units','normalized','Position',[0.1 0.1 0.7 0.7]);

            for c = 1:4
                s = cases{c}(1); w = cases{c}(2); e = cases{c}(3);
                % Simulate
                heights = simulate_biased_walk(N, P, s, w, e, L);

                % Plot in a 2x2 grid
                subplot(2,2,c)
                bar(1:L, heights, 'EdgeColor','none')
                xlabel('Column (1..99)','FontSize',12)
                ylabel('Height (occupied cells)','FontSize',12)
                title(case_titles{c},'FontSize',13)
                xlim([1 L])
                ylim([0 max(ceil(max(heights)*1.1),1)])
                set(gca,'FontSize',11)
            end

            suptitle_str = sprintf('%s, N = %d', start_titles{p_idx}, N);
            sgtitle(suptitle_str,'FontSize',16);

            % Save the figure as PNG for inclusion in report
            saveas(gcf, sprintf('Figure_P%d_N%d.png', p_idx, N));

            figcount = figcount + 1;
        end
    end

    fprintf('All simulations complete. Figures saved as PNG files in current folder.\n');
end


function heights = simulate_biased_walk(N, P, s, w, e, L)
    % simulate_biased_walk simulates N particles on an LxL grid
    % Inputs:
    %   N - number of particles
    %   P - start position: if numeric 1 => column 50, if 'rand' => uniform random
    %   s,w,e - probabilities for South, West, East
    %   L - grid size (assume square L x L)
    % Output:
    %   heights - 1 x L vector of number of occupied cells from bottom in each column

    % Initialize occupancy grid: rows 1..L (top to bottom), cols 1..L (left to right)
    occ = false(L,L);

    % Precompute CDF for direction sampling
    cdf = [s, s+w, s+w+e];

    for p = 1:N
        % Determine start column
        if ischar(P) && strcmp(P,'rand')
            col = randi(L);
        else
            % P==1 -> start in column 50 (as specified in the brief)
            col = 50;
        end
        row = 1; % top row

        walking = true;
        while walking
            % Sample direction according to probabilities s,w,e
            r = rand();
            if r <= cdf(1)
                dir = 'S';
            elseif r <= cdf(2)
                dir = 'W';
            else
                dir = 'E';
            end

            switch dir
                case 'S'
                    if row == L
                        occ(row,col) = true;
                        walking = false;
                    else
                        if occ(row+1,col)
                            occ(row,col) = true;
                            walking = false;
                        else
                            row = row + 1;
                        end
                    end

                case {'W','E'}
                    moved = false;
                    attempts = 0;
                    while ~moved
                        attempts = attempts + 1;
                        if dir == 'W'
                            newcol = col - 1;
                        else
                            newcol = col + 1;
                        end

                        % wrap-around boundaries
                        if newcol < 1
                            newcol = L;
                        elseif newcol > L
                            newcol = 1;
                        end

                        if ~occ(row,newcol)
                            col = newcol;
                            moved = true;
                        else
                            r2 = rand();
                            if r2 <= cdf(1)
                                dir = 'S';
                                break;
                            elseif r2 <= cdf(2)
                                dir = 'W';
                            else
                                dir = 'E';
                            end
                        end

                        if attempts > 1000
                            occ(row,col) = true;
                            walking = false;
                            break;
                        end
                    end
            end
        end
    end

    heights = sum(occ,1); % 1 x L
end
