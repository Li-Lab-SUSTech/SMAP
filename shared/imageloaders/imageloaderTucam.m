classdef imageloaderTucam<interfaces.imageloaderSMAP
    %imageloaderMM image loader for micromanager  tiff stack files
    %   Detailed explanation goes here
    
    properties
%         reader
        numfiles
        filename
        fileFrames
        tiffHandle
        dirIndex
    end
    
    methods
        function obj=imageloaderTucam(varargin)
            obj@interfaces.imageloaderSMAP(varargin{:});
        end
        function openi(obj,file)
        
            obj.file=file;
            md=obj.getmetadata; % TODO: fill obj.allmetadatatags

            % set path to parent path and remove '_pos' postfix
            [p,f] = fileparts(file);
%             idp = strfind(p,'\');
%             parent_path = p(1:idp(end)-1);
%             idf = strfind(f,'_');
%             trim_filename = f(1:idf(end)-1);
            ide = strfind(file,'.');
            ext = file(ide:end);
%             obj.metadata.basefile=[parent_path filesep trim_filename ext];
            obj.metadata.basefile=[p ext]; %lu
            


            
        end
        
        function image = getimagei_by_tiff(obj, frame)
            image = [];
            n = frame;
            for i = 1:obj.numfiles
                if (n <= str2double(obj.fileFrames{i}))
                    if ~isempty(obj.tiffHandle{i})
                        if n ~= obj.dirIndex{i}
                            obj.tiffHandle{i}.setDirectory(n);
                        end
                        image = obj.tiffHandle{i}.read();
                        try
                            obj.tiffHandle{i}.nextDirectory()
                        catch
                            disp("last directory")
                        end
                        obj.dirIndex{i} = n + 1;
                    end
                    return
                else
                    n = n - str2double(obj.fileFrames{i});
                end
            end
        end
        
        function image=getimagei(obj,frame)
            image = getimagei_by_tiff(obj, frame);
            if ~isempty(image)
                return;
            end
            
            fileId = frame;
            for ii = 1:obj.numfiles
                if(fileId <= str2double(obj.fileFrames{ii}))
                    try
                        filepath = fileparts(obj.file);
                        filename = strcat(filepath,'\',obj.filename{ii}{1});
                        image = imread(filename,'Index',fileId);
                        
                        if ~isequal(image1, image)
                            disp("not equal")
                        end

                        return;
                    catch
                        image = [];
                    end
                    break;
                else
                    fileId = fileId - str2double(obj.fileFrames{ii});
                end
            end
            image = [];
        end
        
        function closei(obj)
%             obj.reader.close
%             clear(obj.reader)
        end
        
        function image=getimageonline(obj,number)
            image=obj.getimage(number);
            if isempty(image)&&obj.onlineAnalysis 
                    disp('wait')
                    pause(obj.waittime*2)
                    image=obj.getimage(number);
            end
        end
        
        function allmd=getmetadatatagsi(obj)
            filepath_sep = split(obj.file,filesep);
            filepath = fileparts(obj.file);

            f = fopen(strjoin([filepath_sep(1:end-1);{'metadata.cfg'}],filesep));
            allmd = {};
            i=1;
            while(feof(f)==0)
                s = fgetl(f);
                if(~isempty(s) && s(1)~='[')
                    item = split(s,'=');
                    allmd(i,:) = strtrim(item)';
                    i = i+1;
                end
            end
            
%             allmd(end+1,:)={'Format','TucamTif'};
            imtest=imread(obj.file,'Index',1);
            allmd(end+1,:)={'Width info',size(imtest,2)};
            allmd(end+1,:)={'Height info',size(imtest,1)};
            allmd(end+1,:)={'FileName',obj.file};

            numf = str2double(allmd{find(strcmp('TotalFrames',allmd),1),2});
            allmd(end+1,:)={'Frames',numf+1};
            allmd(end+1,:)={'frames direct',numf};
            obj.allmetadatatags=allmd;
            obj.metadata.numberOfFrames = numf-1;
            obj.numfiles = str2double(allmd{find(strcmp('NumberOfFiles',allmd),1),2});
            for ii = 1:obj.numfiles
                obj.filename{ii} = {allmd{find(strcmp(strcat('Filename',num2str(ii)),allmd),1),2}};
                obj.fileFrames{ii} = {allmd{find(strcmp(strcat('NumberOfFrames',num2str(ii)),allmd),1),2}};
                filename = strcat(filepath,'\',obj.filename{ii}{1});
                try
                    obj.tiffHandle{ii} = Tiff(filename)
                    obj.dirIndex{ii} = 1
                catch
                    obj.tiffHandle{ii} = {}
                    obj.dirIndex{ii} = 0
                end
            end
        end
    end
end


