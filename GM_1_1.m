% 参考文章
% 《数学建模算法与应用（第2版）》 司守奎 孙兆亮
% https://www.docin.com/p-1122453126.html
% https://baijiahao.baidu.com/s?id=1672165544091262586&wfr=spider&for=pc

%%
close all           % 关闭所有窗口
clear               % 清除所有变量
clc                 % 清空命令窗口
tic                 % 开始程序计时

%% 数据输入
sampleData = [25,37,36,22,103,25,18,16,15,13];  % 示例数据

% 输入原始数据序列
dataSequence = sampleData;                  % dataSequence必须为向量
dataSequence = dataSequence(:);             % 将原始数据强制转换为列向量

% 创建时间序列，用于绘制时间轴，可从文件读取
timeSeries = 1:length(dataSequence);        % 可以为datetime格式

% 向后预测m个值
m = 10;

% 是否保存计算结果
save_data = false;                          % 保存预测数据
save_fig  = false;                          % 将趋势图存储为fig
save_png  = false;                          % 将趋势图存储为png

%% 生成序列并建立GM(1,1)模型
syms a b;
dataLength = length(dataSequence);          % 原始数据个数

% 1.原始数据一次累加,得到1-AGO序列xi(1)
Ago = cumsum(dataSequence);

% 2.构造xi(1)的紧邻均值生成序列Z(i)
for k=1:dataLength-1
    Z(k) = (Ago(k)+Ago(k+1))/2;
end
% 3.构造常数向量Yn
Yn = dataSequence;                          % Yn为常数项向量
Yn(1) = [];                                 % 从第二个数开始，即x(2),x(3)...
Yn = reshape(Yn,1,[]);                      % 将Yn变为行向量

% 4.累加生成数据做均值
B = [-Z;ones(1,dataLength-1)]';

% 5.利用公式求出a,b
c = (B'*B)\(B'*Yn');
a = c(1);                                   % 发展系数
b = c(2);                                   % 灰色作用量
fprintf('发展系数\t\ta = %f\n',a)
fprintf('灰色作用量\tb = %f\n\n',b)

% 6.求出GM(1,1)白化模型公式
whiteModel = [];
whiteModel(1) = dataSequence(1);
for k = 2:dataLength
    whiteModel(k) = (dataSequence(1)-b/a)/exp(a*(k-1)) + b/a;
end

% 7.两者做差还原原序列，得到拟合数据
xi1Forecast = [];
xi1Forecast(1) = dataSequence(1);
for k = 2:dataLength
    xi1Forecast(k) = whiteModel(k) - whiteModel(k-1);
end

%% 对未来m个值进行预测
mForecast = [];                             % 存放预测后的m个值
for k1 = dataLength+1:dataLength+m
    xi1Forecast(end+1) ...
        = ((dataSequence(1)-b/a)/exp(a*(k1-1)) + b/a) ...
        - ((dataSequence(1)-b/a)/exp(a*(k1-1-1)) + b/a);
    mForecast(end+1) = xi1Forecast(end);
end

%% 模型检验
e = dataSequence-reshape(xi1Forecast(1:dataLength),[],1);	% 残差
q = abs(e./dataSequence);                                   % 相对误差
s1 = var(dataSequence);                                     % 原始序列方差
s2 = var(e);                                                % 残差方差
c = s2/s1;                                                  % 后验差
p = length(find(0.6745*s1>e))/length(e);                    % 小误差概率，p = P{0.6745s1>e}

accuracy_grade = {'优秀';'合格';'勉强合格';'不合格'};
p_grade = {'p≥0.95';'0.80≤p＜0.95';'0.7≤p＜0.80';'p＜0.70'};
c_grade = {'c≤0.35';'0.35＜c≤0.50';'0.50＜c≤0.65';'c＞0.65'};
modelAccuracyTable = table(accuracy_grade,p_grade,c_grade);
disp('----模型检验----')
disp(modelAccuracyTable)
fprintf('小误差概率\tp = %f\n',p)
fprintf('后验差\t\tc = %f\n\n',c)

%% 绘制预测结果
fig_GM_1_1 = figure;

% 绘制原始序列图像
tdata = timeSeries;                                 % 指定时间轴范围
ydata = dataSequence;                               % 指定数据范围
plot(tdata,ydata,...
    '-','Color','#808080','LineWidth',0.6,'MarkerSize',4,'MarkerIndices',1:5:length(tdata))
hold on

% 绘制拟合序列图像
tdata = timeSeries;                                 % 指定时间轴范围
ydata = xi1Forecast(1:dataLength);                  % 指定数据范围
plot(tdata,ydata,...
    '--','Color','#0072BD','LineWidth',0.8,'MarkerSize',5,'MarkerIndices',1:5:length(tdata))

% 绘制预测数据图像
tdata = timeSeries(end):timeSeries(end)+m;          % 指定x轴显示范围
ydata = xi1Forecast(dataLength:dataLength+m);       % 指定数据范围
plot(tdata,ydata,...
    '^--','Color','#D95319','LineWidth',0.8,'MarkerSize',4,'MarkerIndices',1:5:length(tdata))
hold off

box off                             % 关闭图像边框
title('预测结果')                   % 添加标题
xlabel('')                          % 添加x轴标签
ylabel('')                          % 添加y轴标签
legend('真实值','拟合值','预测值')	% 添加图例

%% 整理并保存计算结果
% 保存预测数据
if save_data
    writematrix(xi1Forecast,'GM(1,1)Forecast.xlsx')
end

% 保存预测图为.fig格式
if save_fig
    savefig(fig_GM_1_1,'GM(1,1).fig')
end

% 保存预测图为.png格式
if save_png
    saveas(fig_GM_1_1,'GM(1,1).png')
end

%%
toc                     % 显示程序所用时间