%% Part 2 – KL Divergence Through Sampling (no toolbox needed)

clear; clc; rng('shuffle');

% True Poisson PMF
lambda = 4;
k = 0:15;
true_pmf = (lambda.^k .* exp(-lambda)) ./ factorial(k);
true_pmf = true_pmf / sum(true_pmf);  % renormalise

sample_sizes = [10, 25, 50, 100, 175, 250];
num_experiments = 100;

KL_means = zeros(size(sample_sizes));
KL_se = zeros(size(sample_sizes));
example_empirical = cell(size(sample_sizes));

% Loop through sample sizes
for i = 1:length(sample_sizes)
    N = sample_sizes(i);
    KL_vals = zeros(1, num_experiments);
    for exp_idx = 1:num_experiments
        % Generate sample
        sample = inv_transform_sample(true_pmf, k, N);
        % Empirical PMF
        emp_counts = histcounts(sample, -0.5:1:15.5);
        emp_pmf = emp_counts / sum(emp_counts);
        emp_pmf = max(emp_pmf, 1e-10);  % avoid log(0)
        % Compute KL divergence
        KL_vals(exp_idx) = sum(true_pmf .* log(true_pmf ./ emp_pmf));
        % Save first empirical PMF as example
        if exp_idx == 1
            example_empirical{i} = emp_pmf;
        end
    end
    KL_means(i) = mean(KL_vals);
    KL_se(i) = std(KL_vals)/sqrt(num_experiments);
end

% Figure 1
figure;
errorbar(sample_sizes, KL_means, KL_se, 'o-', 'LineWidth', 1.5, 'MarkerSize',8);
xlabel('Sample size'); ylabel('KL Divergence');
title('Mean KL Divergence vs Sample Size');
grid on;

% Figure 2
figure;
for i = 1:length(sample_sizes)
    subplot(2,3,i);
    bar(k, [true_pmf' example_empirical{i}'], 'grouped');
    xlabel('k'); ylabel('Probability');
    title(sprintf('Sample size N = %d', sample_sizes(i)));
    legend('True PMF','Example Empirical PMF');
end

%% Local function at the end of the script
function samples = inv_transform_sample(pmf, k, N)
    cdf = cumsum(pmf);
    r = rand(1,N);
    samples = arrayfun(@(x) k(find(cdf>=x,1,'first')), r);
end
