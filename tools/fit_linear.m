function [fitresult ] = fit_linear(app, x, y, doplot)

    % Check for nans
    ix = ~isnan(x);
    x=x(ix); y=y(ix);
    iy = ~isnan(y);
    x=x(iy); y=y(iy);
    

    xout = [];
    yout = [];
    outliers = []
    find_out = true;

    while find_out

        mdl = fitlm(x,y);
        residuals = mdl.Residuals.Raw;
        threshold = 2*std(residuals);   %threshold for outliers
        outl = abs(residuals) > threshold;
    
        xout = [xout x(outl)];
        yout = [yout y(outl)];
        x = x(~outl);
        y = y(~outl);


        app.LogTextArea.Value = [app.LogTextArea.Value; {char("[fit_linear.m] Removed outlier image: " + num2str(length(outl)))}];
        
%hold on
%plot(xout, yout, 'x')

        if sum(outl)==0
            find_out = false;
        end
    end

    % Fit a linear polynomial
    [p, S] = polyfit(x, y, 1);

    % Generate values for the fit line
    x_fit = linspace(min(x), max(x), 100);
    y_fit = polyval(p, x_fit);

    % Calculate the standard error of the regression
    y_pred = polyval(p, x);
    residuals = y - y_pred;
    n = length(x); % number of data points
    mean_x = mean(x); % mean of x values
    S_xx = sum((x - mean_x).^2); % sum of squares of differences from mean

    s = sqrt(sum(residuals.^2) / (n-2)); % standard error of the estimate

    % Confidence interval calculations
    alpha = 0.05; % 95% confidence interval
 
    t = tinv(1 - alpha/2, n-2); % T-distribution critical value for n-2 degrees of freedom
    conf_interval = t * s * sqrt(1/n + (x_fit - mean_x).^2 / S_xx); % 95% confidence interval

   
    % Calculate standard errors of the coefficients
    R_inv = inv(S.R);
    C = (R_inv * R_inv.') * (S.normr^2 / S.df);
    standard_errors = sqrt(diag(C));

    % Store the fit results in a structure
    fitresult.p = p;
    fitresult.dp = standard_errors;
    fitresult.conf_interval = conf_interval;
    
    
    %% Plot the data and the fit line
    if exist('doplot')
        ax1 = findobj(doplot, 'Type', 'ErrorBar');

        ax2 = plot(doplot, x_fit, y_fit, 'r-', 'LineWidth', 2); % Fit line

        if ~isempty(xout)
            ax3 = plot(doplot, xout, yout, 'cx');
        end

        % Plot confidence intervals
        plot(doplot, x_fit, y_fit + conf_interval, 'r--', 'LineWidth', 1); % Upper CI
        plot(doplot, x_fit, y_fit - conf_interval, 'r--', 'LineWidth', 1); % Lower CI

         % Fill the area between the confidence intervals
         x_poly = [x_fit, fliplr(x_fit)];
         y_poly = [y_fit + conf_interval, fliplr(y_fit - conf_interval)];

         fill(doplot, x_poly, y_poly, 'r', 'FaceAlpha', 0.2, 'EdgeColor', 'none'); % Filled area

        
        legend(doplot, [ax1, ax2], {'Data', 'Fit'});
        if ~isempty(xout)
            legend(doplot, [ax1, ax2 ax3], {'Data', 'Fit', 'Outliers'});
        end

    end
end