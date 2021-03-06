clear all ; % on efface toutes les variables deja crees

Suffixe = '.TIF' ; % suffixe des images
% Nom comprenant l'endroit ou se trouvent les images et le nom de base des images
NomDeBase = 'SequenceSansVariation/Image' ; 
NumeroImage = 1 ; % numero de l'image courante

% pour creer le nom d'une image il suffit de faire :
NomImage=strcat(NomDeBase,sprintf('00%d%s',NumeroImage,Suffixe)) ;

% pour voir si l'image existe il suffit de faire :
NumeroDeFichier=fopen(NomImage) ;
if(NumeroDeFichier<=0)
	oui=0 ; return ; % la premiere image n?existe pas alors ce n'est pas la peine de continuer
end

fclose(NumeroDeFichier) ; % on ferme le fichier
ImageCourante = imread(NomImage) ;	 % et on l?ouvre a nouveau en tant qu?image

% pour obtenir la taille de l?image :
[Nlin, Ncol] = size(ImageCourante) ;

figure(1) ; title('Selectionnez un motif a poursuivre') ;
% pour selectionner un motif il faut utiliser la commande imcrop
[ Motif, Rectangle ] = imcrop(ImageCourante) ; 
figure(2) ; imshow(Motif) ; title('Motif a poursuivre') ; % Motif c'est l'imagette du motif a poursuivre

% Rectangle c'est la zone dans laquelle se trouve le motif dans l'image
% Rectangle(1) est la coordonnee du coin en haut a gauche en colonne, Rectangle(2) est sa coordonnee en ligne,
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
delta_col = Rectangle(3);

y(1) = Rectangle(2) ;
y(2) = Rectangle(2) + Rectangle(4) ;
y(3) = Rectangle(2) + Rectangle(4) ;
y(4) = Rectangle(2) ;
y(5) = y(1) ;
delta_lin = Rectangle(4);

% la position courante des points du rectange :
x_courant = x ;
y_courant = y ;

% On dessine le rectangle sur l'image (en bleu)
figure(1) ; 
hold off ;
imshow(uint8(ImageCourante)) ; 
hold on ;
title('Image Courante') ;
line(x,y) ; 
drawnow ;
Motif = double(Motif) ; % il faut convertir le format du motif pour pouvoir faire des calculs en virgule flottante (nombres reels)
ImagettePrecedente = Motif ;

%extracteur des gradients Ix et Iy
[Ix,Iy] = gradient(Motif) ;
A = ones(delta_col*delta_lin,2) ;
B = ones(delta_col*delta_lin,1) ;
for j=0:delta_lin-1
    for i=0:delta_col-1
        A(j*delta_col+i+1,:) = [Ix(j+1,i+1),Iy(j+1,i+1)] ;
    end
end

[nlin, ncol] = size(Motif);% nlin, ncol c'est la taille du motif

oui = 1 ; % tant que oui vaudra 1 on continuera de lire les images

methode = 3;
K = 5;

while(oui)
    %oui = 0
    % on fabrique le nom de l'image courante
	if(NumeroImage<10)
		NomImage=strcat(NomDeBase,sprintf('00%d%s',NumeroImage,Suffixe)) ;
    else %on s arrete apres dix images; sinon, retirer le commentaire plus bas
%         oui = 0;
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
        
% SAD
        if(methode == 1)
            %tableau des SADs pour chaque paire de candidats u, v (il faut
            %chercher le minimum de ce tableau
            SAD = inf(Nlin-nlin,Ncol-ncol) ;
            for lin=max(1,y_courant-round(Rectangle(3)/2)):min(Nlin-nlin,y_courant+round(3*Rectangle(3)/2))
                for col=max(1,x_courant-round(Rectangle(4)/2)):min(Ncol-ncol,x_courant+round(3*Rectangle(4)/2))
                    Imagette = ImageCourante(lin:lin+delta_lin-1, col:col+delta_col-1) ;

                    % calcul de la difference entre l'imagette courante et le
                    % motif de reference.
                    Difference = Motif - Imagette ;
                    % calcul de la somme absolue des differences (SAD(lin, col))
                    SAD(lin,col) = sum(sum(abs(Difference))) ;

                    % si vous voulez voir le motif courant, vous pouvez retirer
                    % le commentaire devant la ligne ci-dessous (mais le
                    % calcul va etre tres long.
                    %figure(3) ; imshow(uint8(Imagette)) ; title('Fenetre a comparer') ; drawnow ; 
                end
            end
            % on cherche la valeur de lin et col qui minimise la distance SAD
            %c'est a dire la valeur minimale dans le tableau
            [lin_opt,col_opt] = find(SAD<=min(min(SAD))) ; 
            lin_opt;
            col_opt;
            % la variation de position en x et y est alors donnee par :
            deltax = ( ( max(col_opt) + min(col_opt) ) / 2 ) - x(1) ;    
            deltay = ( ( max(lin_opt) + min(lin_opt) ) / 2 ) - y(1) ;
            % car il se peut qu'il y ait plusieurs maxima auquel cas on prend
            % la moyenne des maxima
            % la nouvelle position des points du rectange est alors (translation appliquee au vecteurs x et y) :
            x_courant = round( x + deltax ) ;
            y_courant = round( y + deltay ) ;
            
% FLOT OPTIQUE
        elseif (methode == 2)
            Imagette = ImageCourante(y_courant:y_courant+delta_lin-1, x_courant:x_courant+delta_col-1) ;
            
            Difference = Imagette - ImagettePrecedente;
            for j=0:delta_lin-1
                for i=0:delta_col-1
                    B(j*delta_col+i+1,:) = Difference(j+1,i+1) ;
                end
            end
            UV = pinv(A)*B;
            v=-round(K*UV(1)); u=round(K*UV(2));
            
            %tableau des SADs pour chaque paire de candidats u, v (il faut
            %chercher le minimum de ce tableau
            SAD = inf(Nlin-nlin,Ncol-ncol) ;
            for lin=max(1,y_courant-v-10):min(Nlin-nlin,y_courant+v+10)
                for col=max(1,x_courant-u-10):min(Ncol-ncol,x_courant+u+10)
                    Imagette = ImageCourante(lin:lin+delta_lin-1, col:col+delta_col-1) ;

                    % calcul de la difference entre l'imagette courante et le
                    % motif de reference.
                    Difference = Motif - Imagette ;
                    % calcul de la somme absolue des differences (SAD(lin, col))
                    SAD(lin,col) = sum(sum(abs(Difference))) ;

                    % si vous voulez voir le motif courant, vous pouvez retirer
                    % le commentaire devant la ligne ci-dessous (mais le
                    % calcul va etre tres long.
                    %figure(3) ; imshow(uint8(Imagette)) ; title('Fenetre a comparer') ; drawnow ; 
                end
            end
            % on cherche la valeur de lin et col qui minimise la distance SAD
            %c'est a dire la valeur minimale dans le tableau
            [lin_opt,col_opt] = find(SAD<=min(min(SAD))) ; 
            lin_opt;
            col_opt;
            % la variation de position en x et y est alors donnee par :
            deltax = ( ( max(col_opt) + min(col_opt) ) / 2 ) - x(1) ;    
            deltay = ( ( max(lin_opt) + min(lin_opt) ) / 2 ) - y(1) ;
            % car il se peut qu'il y ait plusieurs maxima auquel cas on prend
            % la moyenne des maxima
            % la nouvelle position des points du rectange est alors (translation appliquee au vecteurs x et y) :
            x_courant = round( x + deltax ) ;
            y_courant = round( y + deltay ) ;
            
            ImagettePrecedente = Imagette ;
            
% RANG
        elseif (methode == 3)
            Imagette = ImageCourante(y_courant:y_courant+delta_lin-1, x_courant:x_courant+delta_col-1) ;
            
            n = delta_lin*delta_col;
            R = sort(reshape(ImagettePrecedente,1,n), 'ascend');
            Q = sort(reshape(Imagette,1,n), 'ascend');
            
            rho_max = 0;
            for y_c=y_courant-10:y_courant+10
                for x_c=x_courant-10:x_courant+10
                    Imagette2 = ImageCourante(y_c:y_c+delta_lin-1, x_c:x_c+delta_col-1) ;
                    rho = 0;
                    for j=1:delta_lin
                        for i=1:delta_col
                            val = Imagette2(j,i);
                            Ri = 0; Qi = 0;
                            k = 1;
                            while(k <= n && (Ri == 0 || Qi == 0))
                                if(Ri == 0 && R(1,k) == val)
                                    Ri = k;
                                end
                                if(Qi == 0 && Q(1,k) == val)
                                    Qi = k;
                                end
                                k = k+1;
                            end
                            rho = rho + (Ri - Qi)^2;
                        end
                    end
                    rho = 1 - rho*6/(n^3-n);
                    if(rho > rho_max)
                        rho_max = rho;
                        ImagettePrecedente = Imagette2;
                        x_courant = x_c; y_courant = y_c;
                    end
                end
            end
        end
        
        % On dessine le rectangle sur l'image (en bleu)
        figure(1) ; 
        hold off ;
        imshow(uint8(ImageCourante)) ; 
        hold on ;
        line(x_courant,y_courant) ; 
        title('Image Courante') ;
		drawnow ; % pour s'assurer que le dessin se fait immediatement
        %saveas(gcf,strcat(sprintf('Rendu/'),NomImage),'jpg');
	end
  	NumeroImage = NumeroImage + 1 ;	% on incremente le numero de l'image a lire
end
