function [S, AB, u] = TVLQR(Q, R, Qf, tf, x_d, u_d, u_max, system)
    L0square = chol(Qf)';

    % ode45() must take L as a vector, so we reshape it
    L0 = reshape(L0square, [length(L0square)^2 1]);
    opts = odeset('MaxStep', 1);
    
    % L must be integrated backwards; we integrate L(tf - t) from 0 to tf
    [t, L] = ode45(@(t,L) dLdtminus(t, L, Q, R, x_d, u_d, system), [0 tf], L0, opts);
    
    % now we flip backwards time to be forwards...
    t = tf - t;
    
    % and rearrange (t, L) to be increasing in time 
    t = flipud(t);
    L = spline(t, flipud(L)');
    
    S = @(t) s(ppval(L,t));
    AB = @(t) ab(system, x_d(t));
    u = @(t,x) feedback(system, t, x, ppval(L, t), R, x_d, u_d,u_max);
end

function Ldotminus = dLdtminus(t, L, Q, R, x_d, u_d, system)
    % reshape L to a square
    L = reshape(L,[sqrt(length(L)) sqrt(length(L))]);

    sys_i = system.new(x_d(t));

    A = sys_i.A;
    B = sys_i.B;

    dLdt = -.5*(Q*inv(L'))-(A'*L)+.5*(L*L'*B*inv(R)*B'*L);
    
    % set derivative to -\dot L reshaped as a vector
    Ldotminus = -reshape(dLdt,[length(dLdt)^2 1]);
end

function S = s(L)
    Lsquare = reshape(L, [sqrt(length(L)) sqrt(length(L))]);
    S = (Lsquare*Lsquare');
end

function [A, B] = ab(system, q)
    sys_i = system.new(q);
    A = sys_i.A;
    B = sys_i.B;
end

function u = feedback(system, t, x, L, R, x_d, u_d,u_max)
    [~, B] = ab(system, x_d(t));
    S = s(L);
    u =-inv(R)*B'*S *(x - x_d(t)) + u_d(t);
    u(u>u_max) = u_max;
    u(u<-u_max)= -u_max;
end