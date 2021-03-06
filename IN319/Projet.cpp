#include "CImg.h"
#include <iostream>

#define cosd(x) (cos(fmod((x),360) * M_PI / 180))
#define sind(x) (sin(fmod((x),360) * M_PI / 180))

using namespace std;
using namespace cimg_library;

CImg<unsigned short> BestPlaneT(CImg<unsigned short> imgRef, int value, int sigma); // Translation
CImg<unsigned short> BestPlaneR(CImg<unsigned short> imgRef, int value, int sigma, unsigned int centre[3]); // Rotation

int main(int argc,char **argv)
{
	CImg<unsigned short> img;
	float voxelsize[3];
	img.load_analyze(argv[1],voxelsize);

    unsigned int dim[]={img.width(),img.height(),img.depth()}; 
	printf("Reading %s. Dimensions=%d %d %d\n",argv[1],dim[0],dim[1],dim[2]);
	printf("Voxel size=%f %f %f\n",voxelsize[0],voxelsize[1],voxelsize[2]);
	CImgDisplay disp(512,512,"");
	
	int displayedSlice[3]={dim[0]/2,dim[1]/2,dim[2]/2}; 
		
	unsigned int coord[3]={0,0,0};
	int plane=2;
	bool redraw=true;
	
	while (!disp.is_closed() && !disp.is_keyESC())
	{
		disp.wait(1);
		if (disp.is_resized()) 
		{
			disp.resize();
		}

		/* Movement of the mouse */
		if(disp.mouse_x()>=0 && disp.mouse_y()>=0) 
		{
			
			unsigned int mX = disp.mouse_x()*(dim[0]+dim[2])/disp.width();
			unsigned int mY = disp.mouse_y()*(dim[1]+dim[2])/disp.height();
			
			if (mX>=dim[0] && mY<dim[1]) 
			{ 
				plane = 0; 
				coord[1] = mY; 
				coord[2] = mX - dim[0];   
				coord[0] = displayedSlice[0]; 
			}
			else 
			{
				if (mX<dim[0] && mY>=dim[1]) 
				{ 
					plane = 1; 
					coord[0] = mX; 
					coord[2] = mY - dim[1];   
					coord[1] = displayedSlice[1]; 
				}
				else 
				{
					if (mX<dim[0] && mY<dim[1])       
					{ 
						plane = 2; 
						coord[0] = mX; 
						coord[1] = mY;     
						coord[2] = displayedSlice[2]; 
					}
					else 
					{
						plane = -1; 
						coord[0] = 0;
						coord[1] = 0;
						coord[2] = 0;
					}
				}
			}
			redraw = true;
		}
		
		/* Click Left */
		if (disp.button()&1  && (plane!=-1))  
		{
			cout << coord << endl;
			int sigma = 20, value = img.atXYZ(coord[0], coord[1], coord[2]);
			BestPlaneT(img, value, sigma).display();
		}
		
		/* Click Right */
		if (disp.button()&2  && (plane!=-1))  
		{
			cout << coord << endl;
			int sigma = 20, value = img.atXYZ(coord[0], coord[1], coord[2]);
			BestPlaneR(img, value, sigma, coord).display();
		}
		
		/* Click Middle */
		if (disp.button()&4  && (plane!=-1))  
		{
			for(unsigned int i=0;i<3;i++) 
			{
				displayedSlice[i]=coord[i];
			}
			redraw = true;
		}

		/* Wheel */
		if (disp.wheel()) 
		{
			displayedSlice[plane]=displayedSlice[plane]+disp.wheel();
			
			if (displayedSlice[plane]<0) 
			{
				displayedSlice[plane] = 0;
			}
			else 
			{
				if (displayedSlice[plane]>=(int)dim[plane])
				{
					displayedSlice[plane] = (int)dim[plane]-1;
				}
			}
			
		/* Flush */
		disp.set_wheel();
			
		redraw = true;
		}
		
		/* Redraw */
		if (redraw)
		{
			CImg<> mpr_img=img.get_projections2d(displayedSlice[0],displayedSlice[1],displayedSlice[2]);
			//mpr_img.resize(512,512); 
			disp.display(mpr_img);
			redraw=false;
		}
	}
	//img.save_raw("saved.raw");
	return 0;
}

// =======================================================================================================
// =========================================== BestPlane =================================================
// =======================================================================================================

CImg<unsigned short> BestPlaneT(CImg<unsigned short> imgRef, int value, int sigma) {
	cout << endl << "=============================================================================" << endl;
	int step = 1;
	int bestTx = 0, bestTy = 0, bestTz = 0, bestCount = 0;
	int bestWidth = 0, bestHeight = 0;
	
	int tmp, count, x, y, z;
	
	for(int tx = 0; tx < imgRef.width(); tx+=step) { //cout << "Translation X : " << tx << endl;
		cout << "\rTranslation en cours... " << 100*(tx)/(imgRef.width()+imgRef.height()+imgRef.depth()) << "%" << flush;
		
		count = 0;
		
		// Traitement du plan courant
		for(int i = 0; i < imgRef.depth(); i++) {
			for(int j = 0; j < imgRef.height(); j++) {
				
				// Test de valeur
				tmp = imgRef.atXYZ(tx, j, i);
				if(value - sigma < tmp && tmp < value + sigma) {
					count++;
				}
				
			}
		}
		
		// Mise à jour de la meilleure translation
		if(count > bestCount) {
			bestCount = count;
			bestTx = tx;
			bestTy = 0;
			bestTz = 0;
			bestWidth = imgRef.depth();
			bestHeight = imgRef.height();
		}
	}
		
	for(int ty = 0; ty < imgRef.height(); ty+=step) { //cout << "Translation Y : " << ty << endl;
		cout << "\rTranslation en cours... " << 100*(imgRef.width()+ty)/(imgRef.width()+imgRef.height()+imgRef.depth()) << "%" << flush;
		
		count = 0;
		
		// Traitement du plan courant
		for(int i = 0; i < imgRef.width(); i++) {
			for(int j = 0; j < imgRef.depth(); j++) {
				
				// Test de valeur
				tmp = imgRef.atXYZ(i, ty, j);
				if(value - sigma < tmp && tmp < value + sigma) {
					count++;
				}
				
			}
		}
		
		// Mise à jour de la meilleure translation
		if(count > bestCount) {
			bestCount = count;
			bestTx = 0;
			bestTy = ty;
			bestTz = 0;
			bestWidth = imgRef.width();
			bestHeight = imgRef.depth();
		}
	}

	for(int tz = 0; tz < imgRef.depth(); tz+=step) { //cout << "Translation Z : " << tz << endl;
		cout << "\rTranslation en cours... " << 100*(imgRef.width()+imgRef.depth()+tz)/(imgRef.width()+imgRef.height()+imgRef.depth()) << "%" << flush;
		
		count = 0;
		
		// Traitement du plan courant
		for(int i = 0; i < imgRef.width(); i++) {
			for(int j = 0; j < imgRef.height(); j++) {
				
				// Test de valeur
				tmp = imgRef.atXYZ(i, j, tz);
				if(value - sigma < tmp && tmp < value + sigma) {
					count++;
				}
				
			}
		}
		
		// Mise à jour de la meilleure translation
		if(count > bestCount) {
			bestCount = count;
			bestTx = 0;
			bestTy = 0;
			bestTz = tz;
			bestWidth = imgRef.width();
			bestHeight = imgRef.height();
		}
	}
	
	// Création du meilleur plan
	CImg<unsigned short> bestPlane(bestWidth, bestHeight, 1, 1);
	
	for(int i = 0; i < bestWidth; i++) {
		for(int j = 0; j < bestHeight; j++) {
			
			// Remplissage
			if(bestTx != 0) {
				*(bestPlane.data(i,j,0)) = imgRef.atXYZ(bestTx, j, i);
			}
			else if(bestTy != 0) {
				*(bestPlane.data(i,j,0)) = imgRef.atXYZ(i, bestTy, j);
			}
			else if(bestTz != 0) {
				*(bestPlane.data(i,j,0)) = imgRef.atXYZ(i, j, bestTz);
			}
			
		}
	}
	
	cout << "\rTranslation en cours... 100%"<< flush;
	cout << endl << "Meilleure translation : " << bestTx << ", " << bestTy << ", " << bestTz << endl;
	cout << "=============================================================================" << endl;
	
	return bestPlane;
}

CImg<unsigned short> BestPlaneR(CImg<unsigned short> imgRef, int value, int sigma, unsigned int centre[3]) {
	cout << endl << "=============================================================================" << endl;
	int step = 30; // in degrees
	int bestRx = 0, bestRy = 0, bestRz = 0, bestCount = 0;
	
	int tmp, count;
	double x, y, z, x1, y1, z1, x2, y2, z2, x3, y3, z3, c, s;
	
	for(int rx = 0; rx < 180; rx+=step) {
		
		for(int ry = 0; ry < 180; ry+=step) {
			
			for(int rz = 0; rz < 180; rz+=step) { //cout << "Rotation : " << rx << ", " << ry << ", " << rz << endl;
				cout << "\rRotation en cours... " << 100*((rx+1)*180*180+(ry+1)*180+(rz+1))/(180*180*180) << "%    " << flush;
				
				count = 0;
				
				// Traitement du plan courant
				for(int i = 0; i < imgRef.width(); i++) {
					for(int j = 0; j < imgRef.height(); j++) {
						
						// Passer dans le repère de centre "centre"
						x = i - (int)centre[0];
						y = j - (int)centre[1];
						z = centre[2];
						
						// Rotation autour de l'axe X
						c = cosd(rx); s = sind(rx);
						x1 = x;
						y1 = y * c - z * s;
						z1 = y * s + z * c;
						
						// Rotation autour de l'axe Y
						c = cosd(ry); s = sind(ry);
						
						x2 = x1 * c + z1 * s;
						y2 = y1;
						z2 = z1 * c - x1 * s;
						
						// Rotation autour de l'axe Z
						c = cosd(rz); s = sind(rz);
						
						x3 = x2 * c - y2 * s;
						y3 = x2 * s + y2 * c;
						z3 = z2;
						
						// Repasser dans le repère de centre (0,0,0)
						x = x3 + (int)centre[0];
						y = y3 + (int)centre[1];
						z = z3;
						
						// Test de valeur
						if(x < 0 || y < 0 || z < 0 || x > imgRef.width() || y > imgRef.height() || z > imgRef.depth()) {
							tmp = 0;
						}
						else {
							tmp = imgRef.atXYZ(x, y, z);
						}
						if(value - sigma < tmp && tmp < value + sigma) {
							count++;
						}
						
					}
				}
				
				// Mise à jour de la meilleure rotation
				if(count > bestCount) {
					bestCount = count;
					bestRx = rx;
					bestRy = ry;
					bestRz = rz;
				}
			}
		}
	}
	cout << "\rRotation en cours... 100%" << endl;
	
	// Création du meilleur plan
	int size = (int)(sqrt(2) * max(imgRef.width(), max(imgRef.height(), imgRef.depth())));
	//int offseti = (size - imgRef.width())/2, offsetj = (size - imgRef.height())/2;
	CImg<unsigned short> bestPlane(size, size, 1, 1);
	
	cout << "Meilleure Rotation : " << bestRx << ", " << bestRy << ", " << bestRz << endl;
	cout << "=============================================================================" << endl;
	
	for(int i = 0; i < size; i++) {
		for(int j = 0; j < size; j++) {
			
			// Passer dans le repère de centre "centre"
			x = i - (int)centre[0];
			y = j - (int)centre[1];
			z = (int)centre[2];
			
			// Rotation autour de l'axe X
			c = cosd(bestRx); s = sind(bestRx);
			x1 = x;
			y1 = y * c - z * s;
			z1 = y * s + z * c;
			
			// Rotation autour de l'axe Y
			c = cosd(bestRy); s = sind(bestRy);
			
			x2 = x1 * c + z1 * s;
			y2 = y1;
			z2 = z1 * c - x1 * s;
			
			// Rotation autour de l'axe Z
			c = cosd(bestRz); s = sind(bestRz);
			
			x3 = x2 * c - y2 * s;
			y3 = x2 * s + y2 * c;
			z3 = z2;
			
			// Repasser dans le repère de centre (0,0,0)
			x = x3 + (int)centre[0];
			y = y3 + (int)centre[1];
			z = z3;
			
			// Remplissage
			if(x < 0 || y < 0 || z < 0 || x > imgRef.width() || y > imgRef.height() || z > imgRef.depth()) {
				*(bestPlane.data(i, j, 0)) = 0;
			}
			else {
				*(bestPlane.data(i, j, 0)) = imgRef.atXYZ(x, y, z);
			}
		}
	}
	
	return bestPlane;
}

