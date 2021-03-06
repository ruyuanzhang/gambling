function figrmwhitespace(axhandle,row,col,space)
% figrmwhitespace(axhandle,row,col,space)
%
% remove some redundent white space when using multiple subplot
%
% -------------------------------------------------------------------------
%   Input:
%       axhandle: an array including all handles in a figure. The index in this
%       array should indicate correct order of all subplots. Remember to remove
%           some redundent handles, e.g., suptitle,legend            
%       row,col: number of rows and columns of this multiple plot figures
%    Optional:
%       axhandle:axes handels, could be single or multiple axes,for example
%       h(4);
%       space:a 1 by 4 vector, range from 0~1, specify move distance [left bottom width
%               heigh], for make all subplots closer, use negative
%               value, otherwise,use positive value
%--------------------------------------------------------------------------
% Example:
% x=1:100;y=randn(1,100);
% fig = figure;
% for i=1:6
%     ax(i) = subplot(3,2,i);
%     myplot(x,y);hold on;
%     title(sprintf('figure%d',i));
% end
% fig2 = figure;
% for i=1:6
%     bx(i) = subplot(3,2,i);
%     myplot(x,y);hold on;
%     title(sprintf('figure%d',i));
% end
% fig2=figrmwhitespace(bx,3,2);

if (any(~ishandle(axhandle)) || (isempty(axhandle)))
    axhandle=gca;
end

if(~exist('row','var') || isempty(row))
    error('Please input the rows of those subplot');
end
if(~exist('col','var') || isempty(col))
    error('Please input the columns of those subplot');
end
if(~exist('space','var') || isempty(space))
    space = [0 0 0 0.005];
end



margin=[0 0 0 0];
%test largest TightInset Margin
for i= 1:numel(axhandle)

    %if isa(axhandle(i),'matlab.graphics.axis.Axes') && 
    if ~strcmp(get(axhandle(i),'Tag'),'suptitle')
        margin=[margin;get(axhandle(i),'TightInset')];

    end%only count axis object 
end

margin=max(margin);

H=get(axhandle(i),'Parent');
k=0;
for i= 1:numel(axhandle)
    
    %if ~(isa(axhandle(i),'matlab.graphics.axis.Axes')) && 
    if ~strcmp(get(axhandle(i),'Tag'),'suptitle') %only count axis object
        k=k+1;
        a=1:row*col;
        a=reshape(a,col,row)';
        [row_index,col_index]=find(a==k);

        
        OuterPosition=[1/col*(col_index-1) 1/row*(row-row_index) 1/col 1/row]; 
        
        
        
        Position(1)=OuterPosition(1)+margin(1)+space(1);
        Position(2)=OuterPosition(2)+margin(2)+space(2);
        Position(3)=OuterPosition(3)-margin(1)-margin(3)-space(3);
        Position(4)=OuterPosition(4)-margin(2)-margin(4)-space(4);

        set(axhandle(i),'OuterPosition',OuterPosition,'Position',Position); % It's important to set OuterPosition and Position at the same time
        
    end
end



end