function [spline, PSF]=vectorPSF2cspline(zfocus,p)
% Input:
% physical parameters: NA, lambda,... saved in paraSim
% Zernike coefficients saved in paraSim
% Focal z position
% Roisize, dz, z-range of coefficients

p.objStage0=-zfocus; %focal position in nanometer: Objective position = distance of objective traveled that PSF at taget depth looks the same as PSF of molecules on the coverslip
p.zemit0= -1*p.refmed/p.refimm*(p.objStage0);  %arbitrary refernce point. Convenient choice: 'focus position' for objective, but in sample space
p.zemit=-(-ceil(p.zmax/p.dz)*p.dz:p.dz:ceil(p.zmax/p.dz)*p.dz)';
p.xemit=zeros(length(p.zemit),1);p.yemit=zeros(length(p.zemit),1); %later: fitted x, y position to be compatible with dual-channel option
p.objStage=zeros(length(p.zemit),1);
p.Nmol=length(p.zemit);
[PSF,Waberration] = vectorPSF_Final(p);
coeff=single(Spline3D_interp(PSF));
spline.coeff={coeff};
spline.dz=p.dz;
spline.z0=round(size(coeff,3)/2)+1;
spline.x0=round(size(coeff,1)/2)+1;

f=figure(334);
imx(PSF,'Parent',f);
figure(335);
bar(p.aberrations(:,3))
end