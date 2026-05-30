classdef ROI_sel_gui < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure             matlab.ui.Figure
        GridLayout           matlab.ui.container.GridLayout
        LeftPanel            matlab.ui.container.Panel
        SaveallROIsButton    matlab.ui.control.Button
        DeletethisROIButton  matlab.ui.control.Button
        ROIsListBox          matlab.ui.control.ListBox
        ROIsListBoxLabel     matlab.ui.control.Label
        RightPanel           matlab.ui.container.Panel
        drawROIButton        matlab.ui.control.Button
        UIAxes               matlab.ui.control.UIAxes
    end

    % Properties that correspond to apps with auto-reflow
    properties (Access = private)
        onePanelWidth = 576;
    end

    
    properties (Access = public)
        current_roi
        rects={}
        saver_obj
        p
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: DeletethisROIButton
        function delete_this_roi(app, event)
            roi_to_del = app.current_roi;
            idx = find(strcmp(app.ROIsListBox.Items, roi_to_del ));
            app.ROIsListBox.Items(idx)=[];
            delete (app.rects{idx});
            app.rects(idx)=[];

            % defaultvalue is set as empty because the callback fn can 
            % only listen value changed , when select an roi, the 
            % current_roi will replace the empty value
            if ~isempty(app.ROIsListBox.Items)
                app.ROIsListBox.Value = {};
            end
        end

        % Button pushed function: SaveallROIsButton
        function save_all_rois(app, event)
%             disp(app.ROIsListBox.Items)
            pix_positions = app.ROIsListBox.Items;
            app.saver_obj.batch_save(app.p,pix_positions)
        end

        % Value changed function: ROIsListBox
        function select_roi(app, event)
            value = app.ROIsListBox.Value;
            app.current_roi = value;
        end

        % Button down function: UIAxes
        function draw_srimage(app, event)
            imagesc(app.UIAxes);
        end

        % Button pushed function: drawROIButton
        function draw_rect(app, event)
            rect_mannual=drawrectangle(app.UIAxes);
            rect_tmppos = rect_mannual.Position;
            rect_tmppos_1=round(rect_tmppos);
%             app.current_rect = rect_mannual;

            roi_num = length(app.ROIsListBox.Items)+1;
            app.ROIsListBox.Items{end+1} = ['roi',num2str(roi_num),':',...
                num2str(rect_tmppos_1(1)),',',num2str(rect_tmppos_1(2)),',',...
                num2str(rect_tmppos_1(3)),',',num2str(rect_tmppos_1(4))];
            app.rects{end+1}=rect_mannual;
        end

        % Changes arrangement of the app based on UIFigure width
        function updateAppLayout(app, event)
            currentFigureWidth = app.UIFigure.Position(3);
            if(currentFigureWidth <= app.onePanelWidth)
                % Change to a 2x1 grid
                app.GridLayout.RowHeight = {480, 480};
                app.GridLayout.ColumnWidth = {'1x'};
                app.RightPanel.Layout.Row = 2;
                app.RightPanel.Layout.Column = 1;
            else
                % Change to a 1x2 grid
                app.GridLayout.RowHeight = {'1x'};
                app.GridLayout.ColumnWidth = {220, '1x'};
                app.RightPanel.Layout.Row = 1;
                app.RightPanel.Layout.Column = 2;
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Position = [100 100 640 480];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.SizeChangedFcn = createCallbackFcn(app, @updateAppLayout, true);

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {220, '1x'};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.Scrollable = 'on';

            % Create LeftPanel
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;

            % Create ROIsListBoxLabel
            app.ROIsListBoxLabel = uilabel(app.LeftPanel);
            app.ROIsListBoxLabel.HorizontalAlignment = 'right';
            app.ROIsListBoxLabel.Position = [14 260 32 22];
            app.ROIsListBoxLabel.Text = 'ROIs';

            % Create ROIsListBox
            app.ROIsListBox = uilistbox(app.LeftPanel);
            app.ROIsListBox.Items = {};
            app.ROIsListBox.ValueChangedFcn = createCallbackFcn(app, @select_roi, true);
            app.ROIsListBox.Position = [61 34 130 250];
            app.ROIsListBox.Value = {};

            % Create DeletethisROIButton
            app.DeletethisROIButton = uibutton(app.LeftPanel, 'push');
            app.DeletethisROIButton.ButtonPushedFcn = createCallbackFcn(app, @delete_this_roi, true);
            app.DeletethisROIButton.Position = [60 394 100 22];
            app.DeletethisROIButton.Text = 'Delete this ROI';

            % Create SaveallROIsButton
            app.SaveallROIsButton = uibutton(app.LeftPanel, 'push');
            app.SaveallROIsButton.ButtonPushedFcn = createCallbackFcn(app, @save_all_rois, true);
            app.SaveallROIsButton.Position = [60 342 100 22];
            app.SaveallROIsButton.Text = 'Save all ROIs';

            % Create RightPanel
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 2;

            % Create UIAxes
            app.UIAxes = uiaxes(app.RightPanel);
            title(app.UIAxes, 'Overview FOV')
            xlabel(app.UIAxes, 'X')
            ylabel(app.UIAxes, 'Y')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.ButtonDownFcn = createCallbackFcn(app, @draw_srimage, true);
            app.UIAxes.Position = [7 57 408 367];

            % Create drawROIButton
            app.drawROIButton = uibutton(app.RightPanel, 'push');
            app.drawROIButton.ButtonPushedFcn = createCallbackFcn(app, @draw_rect, true);
            app.drawROIButton.Position = [7 439 100 22];
            app.drawROIButton.Text = 'draw ROI';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = ROI_sel_gui(img_in,saver_obj,p)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)
            
            imagesc(img_in,'Parent',app.UIAxes)
            axis(app.UIAxes,'equal')

            app.saver_obj = saver_obj;
            app.p = p;

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end