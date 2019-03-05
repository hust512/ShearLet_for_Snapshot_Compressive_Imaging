%       1,  1/2s
% Phi = 0,  1-1/s
%       -1, 1/2s

% 先对图像的局部进行测试
function rec  = random_projection(L,s,n,iteration,mask,captured,orig)
    [width, height, frames] = size(orig);
    N = n*n;
    
    % 预处理，将mask中的0转化为1，这里因为mask中0和1个数大致相同，可以先对0/1个数不做考虑
    captured = captured(:);
    captured = 2*(captured-mean(captured));
    mask(mask==0) = -1;
    
    % 单位根
    w = exp(-2*pi*(1i)/n);
    % 对每个ite和k，psi都一样，都是fft2的矩阵
    dft = ones(n,n);
    for i=2:n
        for j=2:n
            dft(i,j) = w^((i-1)*(j-1));
        end
    end
    psi = kron(dft,dft);
    theta = zeros(N*frames,1);
    y = zeros(L,1);
    nonzero_num = zeros(L,1);
    x = zeros(L,N,frames);
    % 做iteration次，求取期望
    for ite = 1:iteration
        disp(ite)
        % 拆开对k个二维图片分别操作
        for j = 1:L
            [phi,y(j),nonzero_num(j)] = generate(N,frames,s,mask,captured);
            for i =1:N
                for k = 1:frames
                    x(j,i,k) = phi(:,:,k)*(psi(i,:)).';
                end
            end
        end
        for i = 1:N
            for k = 1:frames
                theta((k-1)*N+i) = theta((k-1)*N+i) + y'*x(:,i,k)/sqrt(L);
            end
        end
    end
    real_s = L*frames*N/sum(nonzero_num);
    theta = sqrt(real_s)*theta/iteration;
    rec = reshape(theta,[width, height, frames]);
    rec = real(ifft2(rec));
end
