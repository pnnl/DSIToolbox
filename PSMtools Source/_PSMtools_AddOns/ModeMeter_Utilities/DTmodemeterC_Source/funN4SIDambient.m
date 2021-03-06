function [Poles,Energy,rAuto,rAutohat] = funN4SIDambient(y,n,m,M);
% [Poles,Energy,rAuto,rAutohat] = funMEYWambient(y,n,m,M)
% Estimates the poles and the relative energy of each pole of an MIMO
% ARMA system where the ith output is defined by
%
%   A(z)y-sub-i = sum[B-sub-ij(z)e-sub-j]
%                  j
% where e-sub-j is unobserved white noise and y-sub-i is the ith signal.
% The Poles are estimated using the N4SID algorithm.
%
% The relative energy of each pole is estimated by solving the Vandermonde
% problem applied to the autocorrelation function of each output.
% The relative energy is calculated from the residue and pole.
%
% INPUT:
%   y = matrix of measured outputs.  kth column is kth output.
%   n = AR order.
%   m = max MA order (each B-sub-ij(z) is assumed to have order m or less).
%   M = number of data points to be included from the autocorrlation.
%
% OUTPUT:
%   Poles = Vector of discrete-time poles.  I.e., the roots of
%       the characteristic equation is given by
%       1 + a(1)z^(-1) + ... + a(n)z^(-n)
%   Energy = Matrix of relative energy.  Energy(i,k) estimates the 
%       energy in the ith signal due to the Poles(k).  Each column of Energy
%       is normalized so the max term is unity.
%   rAuto = Matrix of auto-correlation functions.  The kth column is the 
%       estimated autocorrelation vector for the kth y.
%   rAutohat = Matrix of auto-correlation functions estimated by the ARMA 
%       model.

% copyright 2006, Contributors:  Montana Tech, University of Wyoming, Pacific Northest
% National Laboratory.

[Nd,Nout] = size(y);
if Nd<=M+m; error('Note enough data'); end

%Estimate modes using N4SID algorithm
x = n4sid(iddata(y,[],1),n,'InitialState','Estimate','Cov','None');
Poles = eig(x.a);  
clear x

%Build autocorrelation matrix
rAuto = [];
for k = 1:Nout
    %Autocorrelation estimate for y(:,k) using a biased estimate
    c = [];
    for kk = 1:m+M+1
        c(kk) = (1/Nd)*sum(y(kk:Nd,k).*y(1:Nd-kk+1,k));
    end
    c = [c(m+M+1:-1:1) c(2:m+M+1)]';
    rAuto(:,k)=c(2*m+M+2:2*m+2*M+1);
end

%Solve for Residues
Np = size(rAuto,1);
ZMatrix = zeros(Np,n);
for k=1:Np
    ZMatrix(k,:) = (Poles.').^(k-1);
end
B = [];
for k=1:Nout
    B(:,k) = ZMatrix\rAuto(:,k);
end

%Solve for relative pseudo mode energy
PoleEnergy = zeros(n,1);
for kk=1:n
    for k=1:Np
        PoleEnergy(kk) = PoleEnergy(kk) + (Poles(kk)^k) * (conj(Poles(kk))^k);
    end
end
Energy = [];
for k=1:Nout
    Energy(:,k) = (B(:,k).*conj(B(:,k))) .* PoleEnergy;
    Energy(:,k) = Energy(:,k)./max(Energy(:,k));
end
clear PoleEnergy

%Simulate;
rAutohat = zeros(size(rAuto));
for k=1:Nout
    for kk=1:Np;
        for kkk=1:n;
            rAutohat(kk,k) = rAutohat(kk,k) + B(kkk,k)*(Poles(kkk)^(kk-1));
        end
    end;
end;
rAutohat = real(rAutohat);
