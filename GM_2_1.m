close all
clear
clc
tic

%% 数据输入
policeTable = readtable('Data1.xlsx','Sheet','que2','ReadVariableNames',true);
firstPoint=1;                               %数据起始点
lastPoint=12*(2019-2016+1);                 %数据终止点
timeSeriesData = policeTable.PeriodIII;
rawData = timeSeriesData(firstPoint:lastPoint);
m=1;                                       %向后预测m个值

%% 生成序列并建立GM(2,1)模型
syms a b;
xi0=rawData;                                %原始序列xi0
n=length(xi0);                              %原始数据个数
xi1=cumsum(xi0);                            %原始数据一次累加,得到1-AGO序列xi(1)
xi_1=[];
for k=2:n
    xi_1(k-1)=xi0(k)-xi0(k-1);              %原始数据一次累减，得到xi(-1)
end
for k=2:n
    Z(k-1)=(xi1(k-1)+xi1(k))/2;             %Z(i)为xi(1)的紧邻均值生成序列
end
Y=xi_1';
B=[(-xi0(2:n))';-Z;ones(1,n-1)]';           %累加生成数据做均值
c=(B'*B)\(B'*Y);                            %利用公式求出a，b
c=c';
a1=c(1);                                    %得到a1的值
a2=c(2);                                    %得到a2的值
b=c(3);                                     %得到b的值
r=roots([1,a1,a2]);                         %求解特征方程
if isreal(r(1))                             %1.方程有2个不相等的实根
    %零不是特征方程的根
    if r(1)*r(2)~=0                     
        C=[1,1;exp(r(1)*(n-1)),exp(r(2)*(n-1))]\[xi1(1)-b/a2;xi1(n)-b/a2];
    %零是特征方程的单根    
    elseif r(1)*r(2)==0 && r(1)+r(2)~=0
        C=[1,1;exp(r(1)*(n-1)),exp(r(2)*(n-1))]\[xi1(1);xi1(n)-b/a2*(n-1)];
    %零是特征方程的重根（不存在这种情况）    
    else
    end
elseif r(1)==r(2)                           %2.方程有2个相等的实根
else                                        %3.方程有2个共轭复根
    %零不是特征方程的根
    C=[];
    alpha=real(r(1));
    beta=imag(r(1));
    C(1)=xi1(1)-b/a2;
    C(2)=(xi1(n)/exp(alpha*(n-1))-(xi1(1)-b/a2)*cos(beta*(n-1)))/sin(beta*(n-1));
end
whiteModel=[];
whiteModel(1)=xi0(1);
for k=2:n
    whiteModel(k)=C(1)*exp(r(1)*(k-1))+C(2)*exp(r(2)*(k-1))+b/a2;%求出GM(2,1)模型公式
end
xi1Forecast=[];
xi1Forecast(1)=xi0(1);
for k=2:(n)
    xi1Forecast(k)=whiteModel(k)-whiteModel(k-1);   %累减还原回原序列，得到预测数据
end

%% 对未来m个值进行预测
mForecast=[];                               %存放预测后的m个值
rawData=[rawData;timeSeriesData((lastPoint+1):(lastPoint+m))];%在原始数据后追加m个值
for k=(n+1):(n+m)
    xi1Forecast(end+1)=C(1)*(exp(r(1)*(k-1))-exp(r(1)*(k-2)))+C(2)*(exp(r(2)*(k-1))-exp(r(2)*(k-2)));
    mForecast(end+1)=xi1Forecast(end);
end

%% 后验差检验
e=rawData-xi1Forecast;
q=e/(rawData');                             %相对误差
for k1=(n+1):(n+m)
    q(end+1)=(xi1Forecast(k1-1)-rawData(k1-1))/rawData(k1-1);%在原始数据预测误差后追加新预测值误差
end
s1=var(rawData);
s2=var(e);
c=s2/s1;                                    %方差比
len=length(e);
p=0;                                        %小误差概率
for i=1:len
    if(abs(e(i))<0.6745*s1)
        p=p+1;
    end
end
p=p/len;

%% 绘制预测结果
t1=firstPoint:(lastPoint+m);
t2=firstPoint:(lastPoint+m);
plot(t1,rawData,'bo--');
hold on;
plot(t2,xi1Forecast,'r*-'); 
title('预测结果');
legend('真实值','预测值');

%%
toc