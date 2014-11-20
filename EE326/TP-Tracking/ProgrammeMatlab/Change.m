NomDeBaseSource = '/Volumes/Data/SequencesImages/BalleAvecVariation/Balle0' ;
NomDeBaseCible = '/Volumes/Utilisateurs/Olivier/Enseignement/M1/ModuleVision/SequenceAvecVariation/Image' ;
SuffixeSource = '.bmp' ;
SuffixeCible = '.tif' ;
NumeroSource = 0 ;
NumeroCible = 0 ;
oui = 1 ;

while(oui)
	if(NumeroSource<10)
		NomSource=strcat(NomDeBaseSource,sprintf('00%d%s',NumeroSource,SuffixeSource)) ;
	else
		if(NumeroSource<100)
			NomSource=strcat(NomDeBaseSource,sprintf('0%d%s',NumeroSource,SuffixeSource)) ;
		else		
			NomSource=strcat(NomDeBaseSource,sprintf('%d%s',NumeroSource,SuffixeSource)) ;
		end
	end	
    
	NumeroDeFichier=fopen(NomSource) ;
    NumeroSource = NumeroSource + 1 ;
    NomSource ,
    
	if(NumeroDeFichier<=0)
		oui=0 ;
	else
		fclose(NumeroDeFichier) ;
        ImageCourante = imread(NomSource) ;
        [Nlin, Ncol, Nplan] = size(ImageCourante) ;
	    if(Nplan~=1)
		    ImageCourante = double(ImageCourante(:,:,1)) + double(ImageCourante(:,:,2)) + double(ImageCourante(:,:,3))  ;
		    ImageCourante = uint8( ImageCourante / 3 ) ;
        end
        luminance = 0 * sin( NumeroSource / 20 ) ;
        ImageCourante = double(ImageCourante) + round(luminance) ; 
        ImageCourante = min( ImageCourante , 255 ) ;
        ImageCourante = max( ImageCourante , 0 ) ;
        ImageCourante = uint8( ImageCourante ) ;

       	if(NumeroCible<10)
       		NomCible=strcat(NomDeBaseCible,sprintf('00%d%s',NumeroCible,SuffixeCible)) ;
        else
   		    if(NumeroCible<100)
   			    NomCible=strcat(NomDeBaseCible,sprintf('0%d%s',NumeroCible,SuffixeCible)) ;
       		else		
  			    NomCible=strcat(NomDeBaseCible,sprintf('%d%s',NumeroCible,SuffixeCible)) ;
       		end
   	    end
		imwrite(ImageCourante,NomCible,'tif') ; 
        NumeroCible = NumeroCible + 1 ;
	end
end
