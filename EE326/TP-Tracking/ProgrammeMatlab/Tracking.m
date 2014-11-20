clear all ;
NumeroImage = 1 ;
alpha = 0.7 ;
Suffixe = '.tif' ;
NomDeBase = '../SequenceAvecVariation/Image' ; 

Methode = 3 ; % 1 : correlation / 2 : SAD / 3 : flot optique
DomaineDeRecherche = 9 ;

NomImage=strcat(NomDeBase,sprintf('00%d%s',NumeroImage,Suffixe)) ,

NumeroDeFichier=fopen(NomImage) ;
if(NumeroDeFichier<=0)
	oui=0 ; return ;
else
	fclose(NumeroDeFichier) ;
	ImageLue=imread(NomImage) ;	
	[Nlin, Ncol, Nplan] = size(ImageLue) ;
	if(Nplan==1)
		ImageCouleur=0 ; % c'est une sequence d'images a niveau de gris
    else
		ImageCouleur=1 ; % c'est une sequence d'images couleur
	end
    
	if(ImageCouleur) % le traitement est effectue sur l'image de luminance
 		ImageCourante = double(ImageLue(:,:,1)) + double(ImageLue(:,:,2)) + double(ImageLue(:,:,3))  ;
		ImageCourante = uint8( ImageCourante / 3 ) ;
	else
		ImageCourante = ImageLue ;
	end
end

figure(1)
[ Motif, Rectangle ] = imcrop(ImageCourante) ;
Rectangle(1:4) = round(Rectangle(1:4)) ;
x(1) = Rectangle(1) ;
x(2) = Rectangle(1) ;
x(3) = Rectangle(1) + Rectangle(3) ;
x(4) = Rectangle(1) + Rectangle(3) ;
x(5) = x(1) ;
y(1) = Rectangle(2) ;
y(2) = Rectangle(2) + Rectangle(4) ;
y(3) = Rectangle(2) + Rectangle(4) ;
y(4) = Rectangle(2) ;
y(5) = y(1) ;
oui = 1 ;
line(x,y) ;
figure(2) ; imshow(Motif) ;
Motif = double(Motif) ;

[nlin, ncol] = size(Motif) ;
umin = round(Rectangle(1)) ;
vmin = round(Rectangle(2)) ;
delta_u = DomaineDeRecherche ;
delta_v = DomaineDeRecherche ;

if( Methode == 3 ) % flot optique
    [ GradientX, GradientY, GradientXY ] = DeriveImage(Motif, alpha, 2) ;

    MatriceFlotOptique = zeros(nlin*ncol,2) ;
    Difference = zeros(nlin*ncol,1) ;
    k=1 ;
    for lin=1:nlin
        for col=1:ncol
            MatriceFlotOptique(k,1) = GradientX(lin,col) ;
            MatriceFlotOptique(k,2) = GradientY(lin,col) ;
            k = k + 1 ;
        end
    end
    % calcul de la pseudo-inverse de la matrice de flot optique
    MatriceFlotOptique = pinv(MatriceFlotOptique) ;
end

while(oui) % tant qu'on n'est pas a la derniere image
	if(NumeroImage<10)
		NomImage=strcat(NomDeBase,sprintf('00%d%s',NumeroImage,Suffixe)) ;
	else
		if(NumeroImage<100)
			NomImage=strcat(NomDeBase,sprintf('0%d%s',NumeroImage,Suffixe)) ;
		else		
			NomImage=strcat(NomDeBase,sprintf('%d%s',NumeroImage,Suffixe)) ;
		end
	end	
	NomImage ;
	NumeroDeFichier=fopen(NomImage) ;
	if(NumeroDeFichier<=0)
		oui=0 ; return ;
	else
		fclose(NumeroDeFichier) ;
        ImageLue = double(imread(NomImage)) ;	
        if(ImageCouleur)
            ImageCourante = double(ImageLue(:,:,1)) + double(ImageLue(:,:,2)) + double(ImageLue(:,:,3))  ;
            ImageCourante = ImageCourante / 3 ;
	    else
		    ImageCourante = ImageLue ;
        end

        MonImage=uint8(ImageCourante) ; % image pour l'affichage
        
        DifferenceImages = ImageCourante(y(1):y(1)+nlin-1,x(1):x(1)+ncol-1)-Motif ;
        k=1 ;
        for lin=1:nlin
            for col=1:ncol
                Difference(k,1) = DifferenceImages(lin,col) ;
                k = k + 1 ;
            end
        end
        
        if( Methode == 1 ) % Correlation 
            i=1 ; j=1 ;
            u=x(1)-(-delta_u:delta_u) ;
            v=y(1)-(-delta_v:delta_v) ;
            for i=1:length(u)
                for j=1:length(v)
                    Correlation(i,j) = corr2(ImageCourante(v(j):v(j)+nlin-1,u(i):u(i)+ncol-1),Motif) ;
                end
            end
            [u_opt,v_opt] = find(Correlation>=max(max(Correlation))) ;
            deltax = u_opt(1) - delta_u ;
            deltay = v_opt(1) - delta_v ;        
        end

        if( Methode == 2 ) % SAD
            i=1 ; j=1 ;
            u=x(1)-(-delta_u:delta_u) ;
            v=y(1)-(-delta_v:delta_v) ;
            for i=1:length(u)
                for j=1:length(v)
                    SAD(i,j) = sum(sum(abs(ImageCourante(v(j):v(j)+nlin-1,u(i):u(i)+ncol-1)-Motif))) ;
                end
            end
            [u_opt,v_opt] = find(SAD<=min(min(SAD))) ;
            deltax = u_opt(1) - delta_u ;
            deltay = v_opt(1) - delta_v ;        
        end
        
        if( Methode == 3 ) % flot optique
            FlotOptique = MatriceFlotOptique * Difference ;
            deltax = round(FlotOptique(1)) ;
            deltay = round(FlotOptique(2)) ;
        end
        
        x = x - deltax ;
        y = y - deltay ;
        figure(10) ; imshow(MonImage) ;
        line(x,y) ;
		drawnow ;
	end
  	NumeroImage = NumeroImage + 1 ;	
end