clear all ; % on efface toutes les variables deja crees

Suffixe = '.tif' ; % suffixe des images
% Nom comprenant l�endroit ou se trouvent les images et le nom de base des images
NomDeBase = '/Volumes/Utilisateurs/Olivier/Enseignement/M1/ModuleVision/SequenceAvecVariation/Image' ; 
NumeroImage = 0 ; % numero de l�image courante

% pour creer le nom d�une image il suffit de faire :
NomImage=strcat(NomDeBase,sprintf('00%d%s',NumeroImage,Suffixe)) ,

% pour voir si l�image existe il suffit de faire :
NumeroDeFichier=fopen(NomImage) ;
if(NumeroDeFichier<=0)
    oui=0 ; return ; % la premiere image n�existe pas alors ce n'est pas la peine de continuer
end

fclose(NumeroDeFichier) ; % on ferme le fichier
ImageCourante = imread(NomImage) ;	 % et on l�ouvre a nouveau en tant qu�image

% pour obtenir la taille de l�image :
[Nlin, Ncol] = size(ImageCourante) ;

figure(1) ; title('Selectionnez un motif a poursuivre') ;
% pour selectionner un motif il faut utiliser la commande imcrop
[ Motif, Rectangle ] = imcrop(ImageCourante) ; 
figure(2) ; imshow(Motif) ; title('Motif a poursuivre') ; % Motif c'est l'imagette du motif a poursuivre

% Rectangle c'est la zone dans laquelle se trouve le motif dans l'image
% Rectangle(1) est la coordonnee du coin en haut � gauche en colonne, Rectangle(2) est sa coordonnee en ligne,
% Rectangle(3) est la taille du rectangle en colonne, Rectangle(4) est la taille du rectangle en ligne, 
Rectangle(1:4) = round(Rectangle(1:4)) ; % on transforme le rectangle de facon a ce que ses coordonnees soient entieres

% Si le rectangle a une dimension inferieure a 3 pixel, c'est qu'on a fait
% une erreur de manipulation sur le clic de la zone

if min(Rectangle(3:4) < 3 ) return ; end ;

% On va creer maintenant une liste de points correspondant au contour ferme du rectangle.
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

% On dessine le rectangle sur l'image (en bleu)
figure(1) ; 
hold off ;
imshow(uint8(ImageCourante)) ; 
hold on ;
title('Image Courante') ;
line(x,y) ; 

Motif = double(Motif) ; % il faut convertir le format du motif pour pouvoir faire des calcul en virgule flottante (nombres reels)

[nlin, ncol] = size(Motif) ; % nlin, ncol c'est la taille du motif

% on recherche le motif dans un rectangle de + ou - 50 pixels autour du rectangle initial
delta_u = 50 ;
delta_v = 50 ;
u_min = Rectangle(1) ;
v_min = Rectangle(2) ;

oui = 1 ; % tant que oui vaudra 1 on continuera de lire les images

while(oui)
    if(TravailAvecLaCamera)    
        ImageCourante = GetImage() ;	 % On acquiert l'image a partir de la camera pan-tilt    
    else

        % on fabrique le nom de l'image courante
    	if(NumeroImage<10)
    		NomImage=strcat(NomDeBase,sprintf('00%d%s',NumeroImage,Suffixe)) ;
    	else
    		if(NumeroImage<100)
    			NomImage=strcat(NomDeBase,sprintf('0%d%s',NumeroImage,Suffixe)) ;
    		else		
    			NomImage=strcat(NomDeBase,sprintf('%d%s',NumeroImage,Suffixe)) ;
    		end
    	end	
 
        % on regarde si l'image existe
        NumeroDeFichier=fopen(NomImage) ;
    	if(NumeroDeFichier<=0)
    		oui=0 ;
    	else % si elle existe
    		fclose(NumeroDeFichier) ;
            % on la lit et on la transforme en image "reelle"
            ImageCourante = double(imread(NomImage)) ; 	
        end
    end
    
    if(oui)        
        SAD = zeros(Nlin-nlin;Ncol-ncol) ;
        for lin=1:Nlin-nlin
            RectangleCourant(2) = lin ;
            for col=1:Ncol-ncol
                RectangleCourant(1) = col ;
                Imagette = ImageCourante(lin:lin+nlin, col:col+ncol) ;
                Difference = Motif - Imagette ;
                SAD(lin,col) = sum(sum(abs(Difference
                figure(3) ; imshow(uint8(Imagette)) ; title('Fenetre a comparer') ; % Zone dont on regarde la correspondance avec le motif
                drawnow ;
            end
        end
        % on cherche la valeur de u et v qui maximise la distance SAD
        [i_opt,j_opt] = find(SAD<=min(min(SAD))) ; 

        % la variation de position en x et y est alors donnee par :
        deltax = ( ( max(u(i_opt)) + min(u(i_opt)) ) / 2 ) ;
        deltay = ( ( max(v(j_opt)) + min(v(j_opt)) ) / 2 ) ;    
        % car il se peut qu'il y ait plusieurs maxima auquel cas on prend
        % la moyenne des maxima

        % la nouvelle position des points du rectange est alors :
        x_courant = round( x + deltax ) ;
        y_courant = round( y + deltay ) ;
        % On dessine le rectangle sur l'image (en bleu)
        figure(1) ; 
        hold off ;
        imshow(uint8(ImageCourante)) ; 
        hold on ;
        line(x_courant,y_courant) ; 
        title('Image Courante') ;
		drawnow ; % pour s'assurer que le dessin se fait immediatement
	end
  	NumeroImage = NumeroImage + 1 ;	% on incremente le numero de l'image a lire
end