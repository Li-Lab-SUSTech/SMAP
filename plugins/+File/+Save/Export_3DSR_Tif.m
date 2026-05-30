classdef Export_3DSR_Tif<interfaces.DialogProcessor
    % add by fushuang 2022.8.27 this plugin aims to export a 3D 
    % super-resolution tiff for imagej analysis
    properties
        %define class properties if needed
    end
    methods
        function obj=Export_3DSR_Tif(varargin)   %replace by filename        
            obj@interfaces.DialogProcessor(varargin{:});
            obj.inputParameters={'filelist_long','mainfile','mainGui','numberOfLayers',...
                'sr_layerson','sr_pixrec','layers','sr_image','sr_pos','sr_size',...
                'group_dt','group_dx'};
        end       
          
        function out=save(obj,p)
            if ~p.batch_export
                p2=obj.getGuiParameters;
                obj.status('save SR stack tiff')
                fn=p.filelist_long.selection;
                [path,file]=fileparts(fn);
                of=[path, filesep, file, '_', num2str(p.pixsize_lat), '_', num2str(p.z_step), p2.img_ext.selection];
                ind=2;
                while exist(of,'file')
                    of=[path filesep file '_' num2str(ind) p2.img_ext.selection];
                    ind=ind+1;
                end
                            
                serchstr={['*' p2.img_ext.selection];['*' strjoin(p2.img_ext.String,';*')]};
                [f,path]=uiputfile(serchstr,'select output file for image', of);
                
                if f
                    lochere=obj.locData.copy;
                    layers=find(obj.getPar('sr_layerson'));
                    pk=obj.getLayerParameters(layers,renderSMAP);                    
                    lochere.filter('channel',layers,'inlist',pk.channels) 
                    pk.sr_pixrec=p.pixsize_lat;
                    pk.render_colormode.selection='normal';
                    
                    z_min = min(lochere.loc.znm(:));
                    z_max = max(lochere.loc.znm(:));
                    if p.is_3D
                        zrange = z_min:p.z_step:z_max;
                    else
                        zrange = [z_min,z_max];
                    end
    
                    imagetosave = uint8(zeros(round(pk.sr_size(2)*2/pk.sr_pixrec),...
                        round(pk.sr_size(1)*2/pk.sr_pixrec),length(zrange)-1));
                    

                    lochere.filter('znm',layers,'minmax',[z_min,z_max]) 
                    image_tmp = renderSMAP(lochere,pk,layers);
                    [~,norm]=normalizeImage(image_tmp.image,pk.imaxtoggle,pk.imax_min,image_tmp.image);


                    for j=1:length(zrange)-1
                        zrange_tmp = [zrange(j), min(z_max, zrange(j+1)+p.z_overlap)];
                        lochere.filter('znm',layers,'minmax',[zrange_tmp(1),zrange_tmp(2)]) 
                        image_tmp = renderSMAP(lochere,pk,layers);
                        [img_tmp,norm]=normalizeImage(image_tmp.image,0,norm);
                        imagetosave(:,:,j) = uint8(img_tmp*255);
                    end
    
                    if p.is_3D
                        imageslicer(permute(imagetosave,[2 1 3]));
                    else
                        figure;imagesc(imagetosave);axis square
                    end
                    
                    saveastiff(imagetosave,[path,f]);
                    obj.status('save done')     
                end   
            else
                img=obj.getPar('sr_image');
                roi_sel_gui=ROI_sel_gui(img.image,obj,p);
                obj.status('manually select roi to save')   
            end
                 
        end
        
        function batch_save(obj,p,pix_positions)
            % called by the ROI_sel_gui
%             disp(pix_positions)
            obj.status('saving SR tiff')  
            
            p2=obj.getGuiParameters;
            
            fn=p.filelist_long.selection;
            [path,file]=fileparts(fn);
            of=[path, filesep, file, p2.img_ext.selection];
            ind=2;
            while exist(of,'file')
                of=[path,filesep,file,'_',num2str(ind),p2.img_ext.selection];
                ind=ind+1;
            end
                    
            serchstr={['*' p2.img_ext.selection];['*' strjoin(p2.img_ext.String,';*')]};
            [f,path]=uiputfile(serchstr,'select output file for image', of);
            
            if f
                lochere=obj.locData.copy;
                layers=find(obj.getPar('sr_layerson'));
                pk=obj.getLayerParameters(layers,renderSMAP);                    
                lochere.filter('channel',layers,'inlist',pk.channels) 
                pk.sr_pixrec=p.pixsize_lat;
                pk.render_colormode.selection='normal';
                
                z_min = min(lochere.loc.znm(:));
                z_max = max(lochere.loc.znm(:));
                if p.is_3D
                    zrange = z_min:p.z_step:z_max;
                else
                    zrange = [z_min,z_max];
                end
                
                wait_bar=waitbar(0,['saving tiffs...']);
                for k=1:length(pix_positions)
                    disp(['saving SR stack tiff ',num2str(k),'/',...
                        num2str(length(pix_positions))]);
                    waitbar(k/length(pix_positions),wait_bar,...
                        [num2str(k),'/',num2str(length(pix_positions))]);

                    pix_pos_tmp = roiparser(pix_positions{k});
                    pos_tmp = translate_pos(pix_pos_tmp,p);
                    pk.sr_pos = pos_tmp(1:2);
                    pk.sr_size = pos_tmp(3:4);

                    imagetosave = uint8(zeros(round(pk.sr_size(2)*2/pk.sr_pixrec),...
                        round(pk.sr_size(1)*2/pk.sr_pixrec),length(zrange)-1));
                    

                    lochere.filter('znm',layers,'minmax',[z_min,z_max]) 
                    image_tmp = renderSMAP(lochere,pk,layers);
                    [~,norm]=normalizeImage(image_tmp.image,pk.imaxtoggle,pk.imax_min,image_tmp.image);


                    for j=1:length(zrange)-1
                        zrange_tmp = [zrange(j), min(z_max, zrange(j+1)+p.z_overlap)];
                        lochere.filter('znm',layers,'minmax',[zrange_tmp(1),zrange_tmp(2)]) 
                        image_tmp = renderSMAP(lochere,pk,layers);
                        [img_tmp,norm]=normalizeImage(image_tmp.image,0,norm);
                        imagetosave(:,:,j) = uint8(img_tmp*255);
                    end
                    

                    [path_tmp,fn_tmp,ext_tmp]=fileparts([path,f]);
                    saveastiff(imagetosave,[path_tmp,filesep,fn_tmp,'_',num2str(k),ext_tmp]);
                    
%                     if p.is_3D
%                         imageslicer(permute(imagetosave,[2 1 3]));
%                     else
%                         figure;imagesc(imagetosave);axis equal
%                     end

                end
                close(wait_bar);
                obj.status('save done')     
        
            end   

        end


        function pard=guidef(obj)
            pard.plugininfo.type='SaverPlugin';
            pard.plugininfo.description=['Saves reconstructed SR 3D images in specified voxelsize (x,y,z) ' ...
                'as gray scale stacked tiff format for downstream imageJ analysis, if choose...' ...
                'batch export, it will start a gui for user to manually select rois ...' ...
                'and export them as stacks by batch'];
           
            pard.img_ext.object=struct('Style','popupmenu','String',{{'.tif','.png'}});
            pard.img_ext.position=[1,1];
            pard.img_ext.Width=1;
            
            
            pard.pixsize_latt.object=struct('String','lateral pixsize(nm) =','Style','text');
            pard.pixsize_latt.position=[1,2];
            pard.pixsize_latt.Width=1.5;

            pard.pixsize_lat.object=struct('String','50','Style','edit','Visible','on');
            pard.pixsize_lat.position=[1,3];
            pard.pixsize_lat.Optional=true;
            pard.pixsize_lat.Width=0.9;


            pard.is_3D.object=struct('String','is 3D','Style','checkbox','Visible','on','Value',1);
            pard.is_3D.position=[2,1];

            pard.z_stept.object=struct('String','z step(nm)=','Style','text');
            pard.z_stept.position=[2,2];
            pard.z_stept.Width=2;

            pard.z_step.object=struct('String','100','Style','edit','Visible','on');
            pard.z_step.position=[2,3];
            pard.z_step.Optional=true;
            pard.z_step.Width=0.9;
            
            pard.batch_export.object=struct('String','batch export','Style','checkbox','Visible','on','Value',0);
            pard.batch_export.position=[3,1];

            pard.z_overlapt.object=struct('String','z overlap(nm)=','Style','text');
            pard.z_overlapt.position=[3,2];
            pard.z_overlapt.Width=2;

            pard.z_overlap.object=struct('String','0','Style','edit','Visible','on');
            pard.z_overlap.position=[3,3];
            pard.z_overlap.Optional=true;
            pard.z_overlap.Width=0.9;


        end
                
        function out=run(obj,p)
            out=[];
            obj.save(p)
        end        

    end
end

function [imout,norm]=normalizeImage(img,imaxtoggle,imax,imgnorm)
    if imaxtoggle %quantile
        if imax<0
            imax=1-10^imax;
        end
         norm=myquantilefast(imgnorm(:),imax,30/(1-imax));
        if norm==0
            norm=max(imgnorm(:));
        end
    else
        norm=imax;
    end
    if norm~=0
    imout=img/norm;
    imout(imout>1)=1;
    else
        imout=img;
    end
end

function out_pos=roiparser(intxt)
    k = strfind(intxt,':');
    pos_txt=intxt(k+1:end);
    comma_pos = regexp(pos_txt,',[1234567890-]');
    out_pos = [str2num(pos_txt(1:comma_pos(1)-1)),...
        str2num(pos_txt(comma_pos(1)+1:comma_pos(2)-1)),...
        str2num(pos_txt(comma_pos(2)+1:comma_pos(3)-1)),...
        str2num(pos_txt(comma_pos(3)+1:end))];
end

function outpos=translate_pos(pix_pos_tmp,p)
    sr_pixrec = p.sr_pixrec;
    sr_pos = p.sr_pos;
    sr_size = p.sr_size;
    sr_szrec=[round(p.sr_size(1)*2/p.sr_pixrec),round(p.sr_size(2)*2/p.sr_pixrec)];
    
    outpos = [ pix_pos_tmp(1)+pix_pos_tmp(3)/2, pix_pos_tmp(2)+pix_pos_tmp(4)/2,...
        pix_pos_tmp(3)/2, pix_pos_tmp(4)/2] * p.sr_pixrec;

    start_sr_pos=sr_pos-sr_size;
    outpos(1:2) = outpos(1:2)+start_sr_pos;

end










