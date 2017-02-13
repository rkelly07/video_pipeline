function res=gather_voc_data(OUTDIR)
FILESPEC=[OUTDIR,filesep,'VOC_descriptors_*.mat'];
files=dir(FILESPEC);
res.descriptors={};
res.object_instance_types=[];
for i = 1:numel(files)
    tmpinfo=load([OUTDIR,filesep,files(i).name],'res');
    if (isfield(tmpinfo,'res'))
    tmpinfo=tmpinfo.res;
    end
    if (isfield(tmpinfo,'object_instance_types'))
    res.descriptors={res.descriptors{:},tmpinfo.D_saved{:}};
    res.object_instance_types=[res.object_instance_types(:);tmpinfo.object_instance_types(:)];
    end
    clear tmpinfo;
end

end