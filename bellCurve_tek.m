%{
MIT License

Copyright (c) 2022 akainami

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
%}
clc; clear; close; tic;

global AA BA BB CB CC DC DD;

% z scores for letterGrades
AA = 1.5;
BA = 1;
BB = 0.5;
CB = 0;
CC = -0.5;
DC = -1;
DD = -1.5;

kisi_sayisi = 100;
visapass = 30; % VF alma notu, 30/100
finalweight = 0.5; % Final Yüzdesi
% Final notu = VisaGrade * (1-FinalWeight) + FinalExam * FinalWeight

fid = fopen('donemnotlari.csv','r');
rawdata = textscan(fid,'%f %f' , 'Delimiter', ';',...
        'HeaderLines',1,'MultipleDelimsAsOne', true,...
        'EndOfLine', '\r\n');
fclose(fid);
visanotes = rawdata{1};
finalnotes = rawdata{2};

classroom = table();
population = length(visanotes);
classroom.id = (1 : population)';
classroom.visagrade = visanotes;
classroom = visafail(classroom,finalnotes,visapass,finalweight);
classroom = zscores(classroom);
classroom = letterGrades(classroom);
plotGrade(classroom);

toc;

%% visafail
function TABLE = visafail(TABLE,finalnotes,visapass,finalweight)
for i = 1 : height(TABLE)
    if TABLE.visagrade(i) < visapass
        TABLE.letterGrade(i) = 0; % VF
        TABLE.finalgrade(i) = -1; % N/A
    else
        TABLE.letterGrade(i) = -1; % N/A
        TABLE.finalgrade(i) = finalnotes(i)*finalweight + TABLE.visagrade(i)*(1-finalweight);
    end
end
end

%% zscores
function TABLE = zscores(TABLE)
id = zeros(length(find(TABLE.letterGrade == -1)),1);
finalgrade = zeros(length(find(TABLE.letterGrade == -1)),1);
j = 1;
for i = 1 : height(TABLE)
    if TABLE.letterGrade(i) ~= 0
        id(j) = TABLE.id(i);
        finalgrade(j) = TABLE.finalgrade(i);
        j = j + 1;
    end
end
means = mean(finalgrade);
stds = std(finalgrade);
TABLE.z = (TABLE.finalgrade-means)/stds;
end

%% letterGrades
function TABLE = letterGrades(TABLE)
global AA BA BB CB CC DC DD;

% Classification
for i = 1 : length(TABLE.id)
    if TABLE.letterGrade(i) == -1
        % AA
        if (TABLE.z(i) >= AA)
            TABLE.letterGrade(i) = 4;
        end
        % BA
        if (TABLE.z(i) >= BA) && (TABLE.z(i) < AA)
            TABLE.letterGrade(i) = 3.5;
        end
        % BB
        if (TABLE.z(i) >= BB) && (TABLE.z(i) < BA)
            TABLE.letterGrade(i) = 3;
        end
        % CB
        if (TABLE.z(i) >= CB) && (TABLE.z(i) < BB)
            TABLE.letterGrade(i) = 2.5;
        end
        % CC
        if (TABLE.z(i) >= CC) && (TABLE.z(i) < CB)
            TABLE.letterGrade(i) = 2;
        end
        % DC
        if (TABLE.z(i) >= DC) && (TABLE.z(i) < CC)
            TABLE.letterGrade(i) = 1.5;
        end
        % DD
        if (TABLE.z(i) >= DD) && (TABLE.z(i) < DC)
            TABLE.letterGrade(i) = 1;
        end
        % FF
        if (TABLE.z(i) < DD)
            TABLE.letterGrade(i) = 0.5;
        end
    end
end
end

%% plotGrade
function plotGrade(TABLE)
% Anal the table
i = 1;
data = zeros(1,9);
grade = [4 3.5 3 2.5 2 1.5 1 0.5 0];
strGrade = ["AA" "BA" "BB" "CB" "CC" "DC" "DD" "FF" "VF"];

for iGrade = grade % AA BA BB CB CC DC DD FF VF
    data(i) = length(find(TABLE.letterGrade == iGrade));
    i = i + 1;
end
%data(end) = ceil(data(end-1)/2); % VF FF is shared %atakanýn kodunda VF yi
%modifiye eden yer burasýydý
data(end-1) = floor(data(end-1)); % VF FF is shared %atakanýn kodunda data(end-1)/2 idi.
percdata = data./sum(data)*100;
maxdata = max(data);
% Plot the table
figure('units','normalized','outerposition',[-10 0 0.4*0.9 0.9*0.6]);
hold on;
for i = 1 : length(grade)
    line(4-[grade(i) grade(i)],[0 data(i)/maxdata],...
        'LineWidth',20,...
        'Color',[51/255 103/255 153/255]);
    text(4-grade(i)-0.2, data(i)/maxdata+0.05, strcat(string(data(i)),{' '},'Kiþi'));
    text(4-grade(i)-0.1, -0.05, strGrade{i});
end
hold off;
xticks([]);
yticks([]);
ylim([0 max(TABLE.id)/maxdata/2]);
title('MUK204E: Strength of Materials II Not Daðýlýmý')
set(gca,'Color',240/255*ones(3,1),...
    'XColor',240/255*ones(3,1),...
    'YColor',240/255*ones(3,1));
% Save the format
saveas(gcf,'distributiongraph.png');
close;

% Plot the Table
figure('units','normalized','outerposition',[-10 0 0.25 0.25*1.62*2]);
ax = axes('Position',[0 0 1 1]);
axes(ax)
hold on;
% Rectangles
fsize = 23;
for i = 0 : 4
    rectangle('Position',[0 2*i+0 1.2 1], 'FaceColor',[216 238 216]/255,'EdgeColor',[1 1 1]);
    rectangle('Position',[0 2*i+1 1.2 1], 'FaceColor',[191 223 255]/255,'EdgeColor',[1 1 1]);
end
% Texts
text(0.03,9.5,'Not','FontWeight','bold','FontSize',fsize);
rectangle('Position',[0.25 0 0.0001 10], 'FaceColor',[216 238 216]/255,'EdgeColor',[1 1 1]);
text(0.27,9.5,'Kiþi Sayýsý','FontWeight','bold','FontSize',fsize);
rectangle('Position',[0.8 0 0.0001 10], 'FaceColor',[216 238 216]/255,'EdgeColor',[1 1 1]);
text(0.83,9.5,'Yüzde','FontWeight','bold','FontSize',fsize);
for i = 0 : 8
    text(0.05,i+0.5,strGrade(9-(i)),'FontSize',fsize);
    
    if data(9-i) < 10
        text(0.37,i+0.5,strcat(string(data(9-i)),{' '},'Kiþi'),'FontSize',fsize);
    else
        text(0.34,i+0.5,strcat(string(data(9-i)),{' '},'Kiþi'),'FontSize',fsize);
    end
    textdata = sprintf('%2.2f',percdata(9-i));
    if percdata(9-i) > 10
        text(0.82,i+0.5,strcat('%',{' '},textdata),'FontSize',fsize-1);
    else
        text(0.85,i+0.5,strcat('%',{' '},textdata),'FontSize',fsize-1);
    end
end
hold off;
xticks([]);
yticks([]);
saveas(gcf,'distributiontable.png');

close;
% Plot all
% Reopen
figure('units','normalized','outerposition',[0.1 0.1 0.8 0.8]);

% Table
ax2 = axes('Position',[0.05 0.15 0.3 0.7],'Box','off');
axes(ax2)
image(imread('distributiontable.png'));
set(gca, 'XColor',240/255*ones(3,1),...
    'YColor',240/255*ones(3,1));
xticks([]);
yticks([]);
axis image;

% Graph
ax1 = axes('Position',[0.3 0.15 0.7 0.7],'Box','on');
axes(ax1)
image(imread('distributiongraph.png'));
set(gca, 'XColor',240/255*ones(3,1),...
    'YColor',240/255*ones(3,1));
xticks([]);
yticks([]);
axis image;
end
