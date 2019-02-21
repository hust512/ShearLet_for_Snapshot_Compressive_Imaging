function output = nsample(M,x,codedNum,positive,negtive)
    output = zeros(size(x,1),size(x,2)/2); % 32768
    temp = zeros(size(x,1),size(x,2)); % 65536
    for i = 1:codedNum
        temp = temp + M(:,:,i).*x(:,:,i);
    end
    for i=1:32768
        output(i) = temp(positive(i))-temp(negtive(i));
    end
end