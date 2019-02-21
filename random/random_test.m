%% Reference
% https://people.rennes.inria.fr/Cedric.Herzet/Cedric.Herzet/Sparse_Seminar/Entrees/2012/11/12_A_Fast_Iterative_Shrinkage-Thresholding_Algorithmfor_Linear_Inverse_Problems_(A._Beck,_M._Teboulle)_files/Breck_2009.pdf

%% COST FUNCTION
% x^* = argmin_x { 1/2 * || A(X) - Y ||_2^2 + lambda * || X ||_1 }
%
% x^k+1 = threshold(x^k - 1/L*AT(A(x^k)) - Y), lambda/L)

%%
clear ;
close all;
home;

bFig = true;
bGPU = false;
%% DATASET
% load("4fan14_cacti.mat") % meas,mask % 0.5/1e5
% codedNum = 14;
% test_data = 1;

% load("traffic8_cacti.mat") % orig,meas,mask
% codedNum = 8;
% test_data = 1;
% 
load("kobe32_cacti.mat") % orig,meas,mask
codedNum = 8;
test_data = 1;
% 
% load("4park8_cacti.mat") % orig,meas,mask
% codedNum = 8;
% test_data = 1;
% clear orig

%% Generate random matrix
random_order = randperm(65536);
positive = random_order(1:32768);
negtive = random_order(32769:65536);

for k = test_data
%% DATA PROCESS
    if exist('orig','var')
        bOrig   = true;
        x       = orig(:,:,(k-1)*codedNum+1:(k-1)*codedNum+codedNum);
        if max(x(:))<=1
            x       = x * 255;
        end
    else
        bOrig   = false;
        x       = zeros(size(mask));
    end
    N       = 256;
    M = mask; 
    if bGPU 
        M = gpuArray(single(M));
    end
    bShear = true;
    sigma = 1;
    LAMBDA  = 12;
    L       = 10;
    niter   = 200; 
    A       = @(x) nsample(M,ifft2(x),codedNum,positive,negtive);
    AT      = @(y) fft2(nsampleH(M,y,codedNum,positive,negtive));

    %% INITIALIZATION
    if bOrig
        y       = nsample(M,x,codedNum,positive,negtive);
    else
        y       = meas(:,:,1);
    end
    x0      = zeros(size(x));
    if bGPU 
        y = gpuArray(single(y));
        x0 = gpuArray(single(x0));
    end
    L1              = @(x) norm(x, 1);
    L2              = @(x) power(norm(x, 'fro'), 2);
    COST.equation   = '1/2 * || A(X) - Y ||_2^2 + lambda * || X ||_1';
    COST.function	= @(X) 1/2 * L2(A(X) - y) + LAMBDA * L1(X(:));

%% RUN
    tic
    x_ista	= NMFISTA(A, AT, x0, y, LAMBDA, L, sigma, niter, COST, bFig, bGPU,bShear);
    time = toc;
    x_ista = real(ifft2(x_ista));
    if bGPU
        x_ista = gather(x_ista);
    end
    x_ista = TV_denoising(x_ista/255,0.05,10)*255;
    nor         = max(x(:));
    psnr_x_ista = zeros(codedNum,1);
    ssim_x_ista = zeros(codedNum,1);
%% DISPLAY
    figure(1); 
    for i=1:codedNum
        if bOrig
            colormap gray;
            subplot(121);   
            imagesc(x(:,:,i));
            set(gca,'xtick',[],'ytick',[]);
            title('orig');

            subplot(122);   
            imagesc(x_ista(:,:,i));  	
            set(gca,'xtick',[],'ytick',[]); 

            psnr_x_ista(i) = psnr(x_ista(:,:,i)./nor, x(:,:,i)./nor); % Ӧ����ƽ��ֵ�������������Ѿ���show���޸���
            ssim_x_ista(i) = ssim(x_ista(:,:,i)./nor, x(:,:,i)./nor);
            title({['frame : ' num2str(i, '%d')], ['PSNR : ' num2str(psnr_x_ista(i), '%.4f')], ['SSIM : ' num2str(ssim_x_ista(i), '%.4f')]});
        else 
            colormap gray;
            imagesc(x_ista(:,:,i));  	
            set(gca,'xtick',[],'ytick',[]); 
            title(['frame : ' num2str(i, '%d')]);
        end
        pause(1);
    end
    psnr_ista = mean(psnr_x_ista);
    ssim_ista = mean(ssim_x_ista);

    %save(sprintf("results/traffic/ours_traffic%d.mat",k))
end