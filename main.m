clc; close all;

%% setup
qstar = [pi;0]; % fixed point for system

Q = diag([1 1]); % initial Q
R = 1; % initial R

u_max = 20;

system = Pendulum(qstar, Q, R, u_max); % infinite time LQR controller

N = 10; % number of collocation points

M = 10; % number of nodes to sample in tree 
qs = zeros(2, M); % list of nodes for tree
q_max = [2*pi; 2*pi]; % limits of LQR tree exploration


%% build tree
root = Trajectory(system.S, infinite_SOS(system)); % infinite time to seed tree
for i = 1:M
    qs(:, i) = [rand * q_max(1), rand * q_max(2)];
    if qs(:, i)' * root.S * qs(:, i) >= root.rho
        % generate trajectory and controller
        [x_d, u_d, dt] = collocate_trajectory(qs(:, i), qstar, N, system);
        [K, S, u] = TVLQR(x_d, u_d, dt * N, system);
        
        % simulate and plot
        q_err = [0; 0];
        f = system.dynamics();
        [t, x] = ode45(@(t,x) f(x, u(t,x)), [0 dt*N], x_d(0) + q_err);
        system.plot(t, x);
    end
end