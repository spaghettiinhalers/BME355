function [PW_f, PW_e, i_term, prev_error] = FESController(x_hat, r, y, K, kU, kP, kI, kD, dt, i_term, prev_error)
% FESController - Compute FES control input for an antagonist muscle pair.
%
% Syntax:  u = FESController(x_hat, r, y, K, kP)
%
% Inputs:
%    x  - State vector (4x1) from the Hammerstein muscle model (or its estimate)
%    r  - Reference force (desired grip force, scalar)
%    y  - Measured force (actual grip force, scalar)
%    K  - Feedback gain matrix (2x4) where K = [Kf; Ke] (designed via LQR)
%    kP - Proportional gain for output error (scalar)
%
% Outputs:
%    u  - Input vector for FES [uf; ue] where:
%           uf is the stimulation command for the flexor muscle,
%           ue is the stimulation command for the extensor muscle.
%
% The controller computes an intermediate control signal:
%    uc = [1 -1] * (-K * x) + kP*(r - y)
%
% Then it applies a switching rule:
%    if uc >= 0, then uf = uc and ue = 0,
%    else,         uf = 0 and ue = abs(uc).
%
% This premultiplication by [1 -1] avoids coactivation of both muscles.
%
% Example:
%    % x: current state (4x1), r: desired force, y: measured force
%    % K: feedback gain matrix, kP: proportional gain
%    u = FESController(x, r, y, K, kP);
%

    % Compute the error between reference and measured force
    error = r - y;

    % Integral term: update using Euler integration
    integral_term = i_term + error * dt;
    I = kI * integral_term;
    
    % Derivative term: based on difference in error
    D = kD * (error - prev_error) / dt;
    
    % Compute the state feedback term
    % Then premultiply by [1 -1] to get a scalar intermediate control signal.
    disp(x_hat);
    u_intermediate = [1, -1] * (-K * x_hat); % (1,1)
    
    % Add the proportional term based on force error (The sum circle)
    uc = kU * u_intermediate + (kP * error) + I + D; %(kP * error) + y;
    prev_error = error;
    
    % Apply switching rule to separate stimulation for flexor and extensor:
    fprintf('Error (r-y): %.2f, u_int: %.2f, P: %.2f, I: %.2f, D: %.2f, uc: %.2f\n', ...
         error, kU*u_intermediate, kP*error, I, D, uc);

    if uc >= 0
        % flexor receives positive control signal
        uf = uc;  
        ue = 0;
    else
        % extensor receives the magnitude of the negative control signal
        uf = 0; 
        ue = abs(uc); 
    end
    ubar = [uf ue];
    ubar = transpose(ubar);
    fprintf("Generate Ubar: %d\n", ubar);

    [PW_f, PW_e] = InverseIRC(uf, ue);

end
