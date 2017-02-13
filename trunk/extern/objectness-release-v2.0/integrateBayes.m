function scoreBayes = integrateBayes(cues,score,params)

likelihood = cell(1,length(cues));
% Guy Rosman: preload all 3 cues at once, also save to /tmp since /tmp/ is an SSD..
if (numel(cues)==3 && strcmp(params.cues{1},'MS')&& strcmp(params.cues{2},'CC')&& strcmp(params.cues{3},'SS'))
    tmpfile='/tmp/MSCCSS.mat';
    if (exist(tmpfile,'file'))
    struct = load(tmpfile);
    likelihood=struct.likelihood;
    else

    struct = load([params.data 'MSCCSS.mat']);
    likelihood=struct.likelihood;
    save(tmpfile,'likelihood');
    end
    
else
for cue_id = 1:length(cues)    
    
    switch upper(cues{cue_id})
        
        case 'MS'                    
            struct = load([params.data 'MSlikelihood.mat']);        
            likelihood{cue_id} = struct.likelihood;
    
        case 'CC'           
            struct = load([params.data 'CClikelihood.mat']);
            likelihood{cue_id} = struct.likelihood;

        case 'ED'            
            struct = load([params.data 'EDlikelihood.mat']);
            likelihood{cue_id} = struct.likelihood;                   
            
        case 'SS'            
            struct = load([params.data 'SSlikelihood.mat']);
            likelihood{cue_id} = struct.likelihood;
            
        otherwise
            display('error: cue name unknown')            
    end
end
end

binNumber = cell(1,length(cues));

for cue_id = 1:length(cues)
    
    switch upper(cues{cue_id})
        
        case 'MS'
            binNumber{cue_id} = max(min(ceil(score(:,cue_id)+0.5),params.MS.numberBins+1),1);
            
        case 'CC'
            binNumber{cue_id} = max(min(ceil(score(:,cue_id)*100+0.5),params.CC.numberBins+1),1);
            
        case 'ED'
            binNumber{cue_id} = max(min(ceil(score(:,cue_id)*2+0.5),params.ED.numberBins+1),1);
                    
        case 'SS'
            binNumber{cue_id} = max(min(ceil(score(:,cue_id)*100+0.5),params.SS.numberBins+1),1);
        otherwise
            display('error: cue name unknown');
    end
end


pObj = params.pobj;
scoreBayes = zeros(size(score,1),1);

    
    tempPoss=[];
    tempNegs=[];
    for cue_id = 1:length(cues)
        tempPoss(cue_id,:) = likelihood{cue_id}(1,binNumber{cue_id});
        tempNegs(cue_id,:) = likelihood{cue_id}(2,binNumber{cue_id});
    end
    tempPos=cumprod(tempPoss,2);
    tempPos=tempPos(3,:);
    tempNeg=cumprod(tempNegs,2);
    tempNeg=tempNeg(3,:);
    denominator = (tempPos * pObj + tempNeg * (1-pObj));
    nonzero=abs(denominator)>1e-10;
    scoreBayes =  pObj ./denominator(nonzero);
    scoreBayes=prod(scoreBayes);
% for bb_id=1:size(score,1)
%     
%     if(denominator)
%         scoreBayes(bb_id) = tempPos * pObj /(tempPos * pObj + tempNeg * (1-pObj));
%     end
%     
% end

scoreBayes = scoreBayes+eps;

end