/*
Tasnim Shahin. 0892325. 
A4. CIS4820
*/

/* Derived from scene.c in the The OpenGL Programming Guide */
/* Keyboard and mouse rotation taken from Swiftless Tutorials #23 Part 2 */
/* http://www.swiftless.com/tutorials/opengl/camera2.html */

/* Frames per second code taken from : */
/* http://www.lighthouse3d.com/opengl/glut/index.php?fps */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <time.h> 

#include "graphics.h"

extern GLubyte  world[WORLDX][WORLDY][WORLDZ];

	/* mouse function called by GLUT when a button is pressed or released */
void mouse(int, int, int, int);

	/* initialize graphics library */
extern void graphicsInit(int *, char **);

	/* lighting control */
extern void setLightPosition(GLfloat, GLfloat, GLfloat);
extern GLfloat* getLightPosition();

	/* viewpoint control */
extern void setViewPosition(float, float, float);
extern void getViewPosition(float *, float *, float *);
extern void getOldViewPosition(float *, float *, float *);
extern void setOldViewPosition(float, float, float);
extern void setViewOrientation(float, float, float);
extern void getViewOrientation(float *, float *, float *);

	/* add cube to display list so it will be drawn */
extern void addDisplayList(int, int, int);

	/* mob controls */
extern void createMob(int, float, float, float, float);
extern void setMobPosition(int, float, float, float, float);
extern void hideMob(int);
extern void showMob(int);

	/* player controls */
extern void createPlayer(int, float, float, float, float);
extern void setPlayerPosition(int, float, float, float, float);
extern void hidePlayer(int);
extern void showPlayer(int);

	/* tube controls */
extern void createTube(int, float, float, float, float, float, float, int);
extern void hideTube(int);
extern void showTube(int);

	/* 2D drawing functions */
extern void  draw2Dline(int, int, int, int, int);
extern void  draw2Dbox(int, int, int, int);
extern void  draw2Dtriangle(int, int, int, int, int, int);
extern void  set2Dcolour(float []);

	/* flag which is set to 1 when flying behaviour is desired */
extern int flycontrol;
	/* flag used to indicate that the test world should be used */
extern int testWorld;
	/* flag to print out frames per second */
extern int fps;
	/* flag to indicate the space bar has been pressed */
extern int space;
	/* flag indicates the program is a client when set = 1 */
extern int netClient;
	/* flag indicates the program is a server when set = 1 */
extern int netServer; 
	/* size of the window in pixels */
extern int screenWidth, screenHeight;
	/* flag indicates if map is to be printed */
extern int displayMap;
	/* flag indicates use of a fixed viewpoint */
extern int fixedVP;

	/* frustum corner coordinates, used for visibility determination  */
extern float corners[4][3];

	/* determine which cubes are visible e.g. in view frustum */
extern void ExtractFrustum();
extern void tree(float, float, float, float, float, float, int);

	/* allows users to define colours */
extern int setUserColour(int, GLfloat, GLfloat, GLfloat, GLfloat, GLfloat,
	 GLfloat, GLfloat, GLfloat);
void unsetUserColour(int);
extern void getUserColour(int, GLfloat *, GLfloat *, GLfloat *, GLfloat *,
	 GLfloat *, GLfloat *, GLfloat *, GLfloat *); 

/********* end of extern variable declarations **************/

//struct to store the positions of humans in the world
struct HumanObject {
	int xValue;
	int yValue;
	int zValue;
	int capturedByAlien;
	int targeted;
	int dead;
	int heightWithAlien;
	int deadByHeight;
};
//store all human 'legs' block in an array
struct HumanObject theHumans[20];
double lastDrawnTime; //draw time for humans

//store time and movement to determine momentum trigger 
double lastMovementTime;
double lastKeyHitTime;
int momentumLeft; //flag to trigger momentum
int numOfMovement; 
int startMomentumClock;

//flags for momentum direction 
int increasingZ; 
int increasingX;
int increasingY; 

//values to store next position spots for the update function for momentum 
float nextXMove; 
float nextYMove;
float nextZMove;

//struct to store ray info
struct RayObject {
	int ID;
	int active;
	int timeStarted;
	float startPosX;
	float startPosZ;
	float endPosX;
	float endPosZ;
};
//store all rays in an array
struct RayObject theRays[15];
int rayCount;
int numOfRaysInWorld;

//draw time for aliens
double alienDrawnTime; 

//controls colour for alien
int colorChange;

//struct to store the info for the aliens/agents
struct AlienObject {
	int xValue;
	int yValue;
	int zValue;
	int xDirection;
	int zDirection;
	int yDirection;
	int targetX;
	int targetZ;
	int targetY;
	int humanNumFound;
	int complete;
};
//store all alien center blocks in an array
struct AlienObject theAliens[18];
int numOfAliensInWorld; //keep track of number of aliens created

int SPEED = 350;//how quickly aliens and humans update

//functions to control updates for different game objects
void updateHumans();
void updateMomentum();
void updateRays();
void updateAliens();

//functions to control/aid in ai for aliens
int humanNearBy(int alienNum);
int findHumanCaught(int alienXValue,int alienZValue);
void clearAlien(int alienNum);
void processShotHuman(int humanNumberFound);
int findAlienShot(int curXValue,int curZValue);
void processAlienShot(int alienNumberFound);
int alienRayCollision(int xValue, int yValue, int zValue);
int humanRayCollision(int xValue, int yValue, int zValue);
int checkHumanTargeted(int alienNum,int tmpXValue, int tmpZValue);
void clearHuman(int tmpXValue, int tmpZValue);
int getHeightFromGround(int tmpXValue,int tmpYValue,int tmpZValue);
void redrawAlien(int alienNum, int xDirection, int yDirection, int zDirection, int status);
void alienShots(int alienNum);

//functions to control alien collisions
int alienCollision(int alienNum);
int findAlienThatCollided(int curXValue,int curZValue, int alienNum);


	/*** collisionResponse() ***/
	/* -performs collision detection and response */
	/*  sets new xyz  to position of the viewpoint after collision */
	/* -can also be used to implement gravity by updating y position of vp*/
	/* note that the world coordinates returned from getViewPosition()
		will be the negative value of the array indices */
void collisionResponse() {

	if (testWorld != 1) { //if not test world 

		//store current and next positions 
		float curX = 0, curY = 0, curZ = 0;
		float nextX = 0, nextY = 0, nextZ = 0;

		//get 'old' current position 
		getOldViewPosition(&curX, &curY, &curZ);

		//get next position of vp 
		getViewPosition(&nextX, &nextY, &nextZ);

		//check if out of bounds, less than 0 
		if (nextX >= 0 || nextY >= 0 || nextZ >= 0){
			setViewPosition(curX,curY,curZ);
			return;
		}		

		//get absolute value, since positions are negitive 
		nextX = fabs(nextX);
		nextY = fabs(nextY);
		nextZ = fabs(nextZ);

		//cast to integers, since the world array dealing with whole units
		int nextXInt = (int) nextX;
		int nextYInt = (int) nextY;
		int nextZInt = (int) nextZ;

		//check if out of bounds, x,y,z,0-99,0-49,0-99
		if (nextX > 99 || nextY > 48 || nextZ > 99){
			momentumLeft = 0; //hit the boundary, stop momentum 

			setViewPosition(curX,curY,curZ);
			return;
		}

		//check block in world array, if next box is occupied, don't allow next move 
		if (world[nextXInt][nextYInt][nextZInt] != 0) { 
			momentumLeft = 0; //hit the boundary, stop momentum 

			setViewPosition(curX,curY,curZ);
			return; //collision found, exit funtion 
		} 

		//next section looks for momentum to add

		//reset values
		getOldViewPosition(&curX, &curY, &curZ); //get 'old' current position 
		getViewPosition(&nextXMove, &nextYMove, &nextZMove); //get next position of vp 

		//if clock to track movements has not been started  
		if (startMomentumClock == 0) {
			clock_t startTime = clock();
	  		//store time between each movement
			lastKeyHitTime = (double)startTime * 1000.0 / CLOCKS_PER_SEC;
			startMomentumClock = 1;
		} else {
			//get current time 
			clock_t startTime = clock();
			double currentTime = (double)startTime * 1000.0 / CLOCKS_PER_SEC;
			
			//if movements happen within 1 sec of each other 
			if((lastKeyHitTime + 1000) > currentTime){
				numOfMovement++; //add to number of movements 
			} else {
				//movement time from the last move was greater than one sec
				startMomentumClock = 0; //reset flags  
				numOfMovement = 0;
			}
		}

		//if at least 8 moves in a short amount of time, make vp go faster 
		if (numOfMovement == 7){

			if (momentumLeft < 4){ //3 is max acceleration 
				momentumLeft++; //set momentum flag to true, used for acceleration too
			}

			//set time for how long momentum will last, this is start time
			clock_t startTime = clock();
			lastMovementTime = (double)startTime * 1000.0 / CLOCKS_PER_SEC;
		}

		//for constant motion not captured, keep resetting time
		if (momentumLeft > 0){
			//set time for how long momentum will last, this is start time
			clock_t startTime = clock();
			lastMovementTime = (double)startTime * 1000.0 / CLOCKS_PER_SEC;
		}

		//figure out which direction the vp was moving, to determine direction of momentum 
		if (curZ - nextZMove > 0){
			increasingZ = 1;
		} else {
			increasingZ = 0;
		}

		if (curX - nextXMove > 0){
			increasingX = 1;
		} else {
			increasingX = 0;
		}

		if (curY - nextYMove > 0){
			increasingY = 1;
		} else {
			increasingY = 0;
		}

	} 

}

	/******* draw2D() *******/
	/* draws 2D shapes on screen */
	/* use the following functions: 			*/
	/*	draw2Dline(int, int, int, int, int);		*/
	/*	draw2Dbox(int, int, int, int);			*/
	/*	draw2Dtriangle(int, int, int, int, int, int);	*/
	/*	set2Dcolour(float []); 				*/
	/* colour must be set before other functions are called	*/
void draw2D() {

	if (testWorld) {
		/* draw some sample 2d shapes */
		if (displayMap == 1) {
			GLfloat green[] = {0.0, 0.5, 0.0, 0.5};
			set2Dcolour(green);
			draw2Dline(0, 0, 500, 500, 15);
			draw2Dtriangle(0, 0, 200, 200, 0, 200);

			GLfloat black[] = {0.0, 0.0, 0.0, 0.5};
			set2Dcolour(black);
			draw2Dbox(500, 380, 524, 388);
		}
	} else {
		//draw mini map of world
		if (displayMap == 1){

			GLfloat blue[] = {0.4, 0.1, 1.0, 0.6};
			set2Dcolour(blue);

			//scale mini map based on screen size 
			int mapTopStartPointX = screenWidth-250;
			int mapTopEndPointX =  screenWidth-50;

			int mapTopStartPointY = screenHeight-50;
			int mapTopEndPointY =  screenHeight-250;

			int originX = screenWidth-250;
			int originY = screenHeight-250;

			//x is x
			//y is z
			draw2Dline(mapTopStartPointX, mapTopStartPointY, mapTopEndPointX, mapTopStartPointY, 7); //top line of map
			draw2Dline(mapTopStartPointX, mapTopEndPointY, mapTopEndPointX, mapTopEndPointY, 7); //bottom line of map

			draw2Dline(mapTopStartPointX, mapTopStartPointY, mapTopStartPointX, mapTopEndPointY, 7); //left side of map 
			draw2Dline(mapTopEndPointX, mapTopStartPointY, mapTopEndPointX, mapTopEndPointY, 7); //right sode of map 


			//look for humans to add to map
			for (int xValue = 0;xValue<99;xValue++) {

				for (int zValue = 0;zValue<99;zValue++){

					for(int yValue=0;yValue<50;yValue++){

						if (world[xValue][yValue][zValue] == 1){ //one human value in world 

							GLfloat black[] = {0.0, 0.0, 0.0, 0.6};
							set2Dcolour(black);
							draw2Dbox(originX+(xValue*2), originY+(zValue*2), originX+(xValue*2) + 2 , originY+(zValue*2) + 2 );
						}

					}
				}
			}
			
			//add viewpoint to map
			float curX, curY, curZ;	
			getViewPosition(&curX, &curY, &curZ); //get current position of vp
			curX = curX * -1;
			curY = curY * -1;
			curZ = curZ * -1;
			GLfloat red[] = {0.5, 0.0, 0.0, 0.6};
			set2Dcolour(red);
			draw2Dtriangle(originX+(curX*2)+2, originY+(curZ*2)-2, originX+(curX*2), originY+(curZ*2), originX+(curX*2)-2, originY+(curZ*2)-2);


			//add rays to map, they will be red
			for (int i=0;i<numOfRaysInWorld;i++){
				if (theRays[i].active == 1){
					//using start and end positions of rays
					draw2Dline(originX+(theRays[i].startPosX * 2),originY+(theRays[i].startPosZ * 2), originX+(theRays[i].endPosX * 2), originY+(theRays[i].endPosZ * 2), 3);
				} 
			}

			//add aliens to map 
			for (int xValue = 0;xValue<99;xValue++) {

				for (int zValue = 0;zValue<99;zValue++){

					for(int yValue=0;yValue<50;yValue++){

						if (world[xValue][yValue][zValue] == 8){ //aliens of 8, color yellow 

							GLfloat yellow[] = {1.0, 1.0, 0.0, 0.6};
							set2Dcolour(yellow);
							draw2Dbox(originX+(xValue*2), originY+(zValue*2), originX+(xValue*2) + 2 , originY+(zValue*2) + 2 );
						}

					}
				}
			}

			//add transformed aliens to map 
			for (int xValue = 0;xValue<99;xValue++) {

				for (int zValue = 0;zValue<99;zValue++){

					for(int yValue=0;yValue<50;yValue++){

						if (world[xValue][yValue][zValue] == 10){ //aliens of 10, color red 

							GLfloat red[] = {1.0, 0.0, 0.1, 0.6};
							set2Dcolour(red);
							draw2Dbox(originX+(xValue*2), originY+(zValue*2), originX+(xValue*2) + 2 , originY+(zValue*2) + 2 );
						}

					}
				}
			}

		} else if (displayMap == 2){ //large map in center

			GLfloat blue[] = {0.4, 0.1, 1.0, 0.6};
			set2Dcolour(blue);

			int scale = 3;

			//scale to larger size in center of screen
			int mapTopStartPointX = (screenWidth/3)+350;
			int mapTopEndPointX =  (screenWidth/3)+50;

			int mapTopStartPointY = (screenHeight/3)+50;
			int mapTopEndPointY =  (screenHeight/3)+350;

			int originX = (screenWidth/3)+50;
			int originY = (screenHeight/3)+50;

			//x is x
			//y is z
			draw2Dline(mapTopStartPointX, mapTopStartPointY, mapTopEndPointX, mapTopStartPointY, 8); //top line of map
			draw2Dline(mapTopStartPointX, mapTopEndPointY, mapTopEndPointX, mapTopEndPointY, 8); //bottom line of map

			draw2Dline(mapTopStartPointX, mapTopStartPointY, mapTopStartPointX, mapTopEndPointY, 8); //left side of map 
			draw2Dline(mapTopEndPointX, mapTopStartPointY, mapTopEndPointX, mapTopEndPointY, 8); //right sode of map 


			//add humans to map
			for (int xValue = 0;xValue<99;xValue++) {

				for (int zValue = 0;zValue<99;zValue++){

					for(int yValue=0;yValue<50;yValue++){

						if (world[xValue][yValue][zValue] == 1){ //look for humans 

							GLfloat black[] = {0.0, 0.0, 0.0, 0.6};
							set2Dcolour(black);
							draw2Dbox(originX+(xValue*scale), originY+(zValue*scale), originX+(xValue*scale) + 3, originY+(zValue*scale) + 3);
						}

					}
				}
			}
			
			//add viewpoint to large map
			float curX, curY, curZ;	
			getViewPosition(&curX, &curY, &curZ); //get current position of vp
			curX = curX * -1;
			curY = curY * -1;
			curZ = curZ * -1;
			GLfloat red[] = {0.5, 0.0, 0.0, 0.6};
			set2Dcolour(red);
			draw2Dtriangle(originX+(curX*scale)+3, originY+(curZ*scale)-3, originX+(curX*scale), originY+(curZ*scale), originX+(curX*scale)-3, originY+(curZ*scale)-3);


			//add rays to large map 
			for (int i=0;i<numOfRaysInWorld;i++){
				if (theRays[i].active == 1){
					//get start and end positions of ray from struct 
					draw2Dline(originX+(theRays[i].startPosX * scale),originY+(theRays[i].startPosZ * scale), originX+(theRays[i].endPosX * scale), originY+(theRays[i].endPosZ * scale), 3);
				} 
			}

			//add aliens to map 
			for (int xValue = 0;xValue<99;xValue++) {

				for (int zValue = 0;zValue<99;zValue++){

					for(int yValue=0;yValue<50;yValue++){

						if (world[xValue][yValue][zValue] == 8){ //aliens are yellow 

							GLfloat yellow[] = {1.0, 1.0, 0.0, 0.6};
							set2Dcolour(yellow);
							draw2Dbox(originX+(xValue*scale), originY+(zValue*scale), originX+(xValue*scale) + 3 , originY+(zValue*scale) + 3 );
						}

					}
				}
			}

			//add transformed aliens to map 
			for (int xValue = 0;xValue<99;xValue++) {

				for (int zValue = 0;zValue<99;zValue++){

					for(int yValue=0;yValue<50;yValue++){

						if (world[xValue][yValue][zValue] == 10){ //aliens are red 

							GLfloat yellow[] = {1.0, 0.0, 0.1, 0.6};
							set2Dcolour(yellow);
							draw2Dbox(originX+(xValue*scale), originY+(zValue*scale), originX+(xValue*scale) + 3 , originY+(zValue*scale) + 3 );
						}

					}
				}
			}
		}

	}

}

	/*** update() ***/
	/* background process, it is called when there are no other events */
	/* -used to control animations and perform calculations while the  */
	/*  system is running */
	/* -gravity must also implemented here, duplicate collisionResponse */
void update() {
	int i, j, k;
	float *la;
	float x, y, z;

	/* sample animation for the test world, don't remove this code */
	/* demo of animating mobs */
	if (testWorld) {

	/* update old position so it contains the correct value */
	/* -otherwise view position is only correct after a key is */
	/*  pressed and keyboard() executes. */
      getViewPosition(&x, &y, &z);
      setOldViewPosition(x,y,z);

	/* sample of rotation and positioning of mob */
	/* coordinates for mob 0 */
		static float mob0x = 50.0, mob0y = 25.0, mob0z = 52.0;
		static float mob0ry = 0.0;
		static int increasingmob0 = 1;
	/* coordinates for mob 1 */
		static float mob1x = 50.0, mob1y = 25.0, mob1z = 52.0;
		static float mob1ry = 0.0;
		static int increasingmob1 = 1;
	/* counter for user defined colour changes */
		static int colourCount = 0;
		static GLfloat offset = 0.0;

	/* move mob 0 and rotate */
	/* set mob 0 position */
		setMobPosition(0, mob0x, mob0y, mob0z, mob0ry);

	/* move mob 0 in the x axis */
		if (increasingmob0 == 1)
			mob0x += 0.2;
		else 
			mob0x -= 0.2;
		if (mob0x > 50) increasingmob0 = 0;
		if (mob0x < 30) increasingmob0 = 1;

	/* rotate mob 0 around the y axis */
		mob0ry += 1.0;
		if (mob0ry > 360.0) mob0ry -= 360.0;

	/* move mob 1 and rotate */
		setMobPosition(1, mob1x, mob1y, mob1z, mob1ry);

	/* move mob 1 in the z axis */
	/* when mob is moving away it is visible, when moving back it */
	/* is hidden */
		if (increasingmob1 == 1) {
			mob1z += 0.2;
			showMob(1);
		} else {
			mob1z -= 0.2;
			hideMob(1);
		}
		if (mob1z > 72) increasingmob1 = 0;
		if (mob1z < 52) increasingmob1 = 1;

	/* rotate mob 1 around the y axis */
		mob1ry += 1.0;
		if (mob1ry > 360.0) mob1ry -= 360.0;

	/* change user defined colour over time */
		if (colourCount == 1) offset += 0.05;
		else offset -= 0.01;
		if (offset >= 0.5) colourCount = 0;
		if (offset <= 0.0) colourCount = 1;
		setUserColour(9, 0.7, 0.3 + offset, 0.7, 1.0, 0.3, 0.15 + offset, 0.3, 1.0);

	/* sample tube creation  */
	/* draws a purple tube above the other sample objects */
       createTube(1, 45.0, 30.0, 45.0, 50.0, 30.0, 50.0, 6);

    /* end testworld animation */


	} else {

		//update animations for humans 
		updateHumans();

		//see if momentum needed, control acceleration/decelertion speed
		updateMomentum();

		//control ray appearance timings
		updateRays();

		//call function to update alien actions
		updateAliens();

	}
}


	/* called by GLUT when a mouse button is pressed or released */
	/* -button indicates which button was pressed or released */
	/* -state indicates a button down or button up event */
	/* -x,y are the screen coordinates when the mouse is pressed or */
	/*  released */ 
void mouse(int button, int state, int x, int y) {

	if (button == GLUT_LEFT_BUTTON && state == GLUT_UP){
		
		float curX, curY, curZ;	
		getViewPosition(&curX, &curY, &curZ); //get current position of vp 
		float endPtX = curX;
		float endPtY = curY;
		float endPtZ = curZ;

		//figure out end points for ray 
		if (increasingZ == 1) {
			endPtZ = curZ - 8; 
		} else {
			endPtZ = curZ + 8;
		}

		if (increasingX == 1){
			endPtX = curX - 8; 
		} else {
			endPtX = curX + 8;
		}

		//create tube for ray using past movements
		createTube(rayCount, curX *-1, curY*-1, curZ*-1, endPtX*-1, endPtY*-1, endPtZ*-1, 3);

		//set time for how long momentum will last, this is start time
		clock_t rayStartTime = clock();
		double startTime = (double)rayStartTime * 1000.0 / CLOCKS_PER_SEC;

		//keep track of which rays have been activated, to control timing of it
		theRays[rayCount].active = 1;
		theRays[rayCount].timeStarted = startTime;

		//save points for map drawing 
		theRays[rayCount].startPosX = curX *-1;
		theRays[rayCount].startPosZ = curZ *-1;
		theRays[rayCount].endPosX = endPtX*-1;
		theRays[rayCount].endPosZ = endPtZ*-1;

		rayCount++; //increase ray id 

		//9 rays in array, cycle through them 
		if (rayCount > 14){ 
			rayCount = 0;
		}

		//look for collisions for rays, depending on ray direction 
		if (curX < endPtX && curZ < endPtZ ) {

			for (int i=0;i<=8;i++){

				//cast to integers, since the world array dealing with whole units
				int XInt = (int) curX;
				int YInt = (int) curY;
				int ZInt = (int) curZ;

				//get absolute value, since positions are negitive 
				XInt = abs(XInt);
				YInt = abs(YInt);
				ZInt = abs(ZInt);

				//subtract position, to get entire ray length 
				XInt = XInt - i;
				ZInt = ZInt - i;

				//no need to check collisions when out of world space 
				if (XInt > 99 || ZInt > 99 || YInt > 49){
					break;
				}

				//check for ray collisions with aliens, using whole unit squares
				int retVal = alienRayCollision(XInt,YInt,ZInt);
				if (retVal == 1){ //collision with alien found 
					break;
				}

				//check for ray collisions with humans, using whole unit squares
				retVal = humanRayCollision(XInt,YInt,ZInt);
				if (retVal == 1){ //collision with human found 
					break;
				}

			}
		} else if (curX > endPtX && curZ > endPtZ ) {

			for (int i=0;i<=8;i++) {

				//cast to integers, since the world array dealing with whole units
				int XInt = (int) curX;
				int YInt = (int) curY;
				int ZInt = (int) curZ;

				//get absolute value, since positions are negitive 
				XInt = abs(XInt);
				YInt = abs(YInt);
				ZInt = abs(ZInt);

				//add to ray length, since 3 units in length
				XInt = XInt + i;
				ZInt = ZInt + i;

				//no need to check collisions when out of world space 
				if (XInt > 99 || ZInt > 99 || YInt > 49){
					break;
				}

				//check for ray collisions with aliens, using whole unit squares
				int retVal = alienRayCollision(XInt,YInt,ZInt);
				if (retVal == 1){ //collision with alien found 
					break;
				}

				//check for ray collisions with humans, using whole unit squares
				retVal = humanRayCollision(XInt,YInt,ZInt);
				if (retVal == 1){ //collision with human found 
					break;
				}

			}
		} else if (curX < endPtX && curZ > endPtZ ) {

			for (int i=0;i<=8;i++) {

				//cast to integers, since the world array dealing with whole units
				int XInt = (int) curX;
				int YInt = (int) curY;
				int ZInt = (int) curZ;

				//get absolute value, since positions are negitive 
				XInt = abs(XInt);
				YInt = abs(YInt);
				ZInt = abs(ZInt);

				//add to ray length, since 3 units in length
				XInt = XInt - i;
				ZInt = ZInt + i;

				//no need to check collisions when out of world space 
				if (XInt > 99 || ZInt > 99 || YInt > 49){
					break;
				}

				//check for ray collisions with aliens, using whole unit squares
				int retVal = alienRayCollision(XInt,YInt,ZInt);
				if (retVal == 1){ //collision with alien found 
					break;
				}

				//check for ray collisions with humans, using whole unit squares
				retVal = humanRayCollision(XInt,YInt,ZInt);
				if (retVal == 1){ //collision with human found 
					break;
				}
			

			} //end of for loop 

		} else if (curX > endPtX && curZ < endPtZ ) {

			for (int i=0;i<=8;i++) {

				//cast to integers, since the world array dealing with whole units
				int XInt = (int) curX;
				int YInt = (int) curY;
				int ZInt = (int) curZ;

				//get absolute value, since positions are negitive 
				XInt = abs(XInt);
				YInt = abs(YInt);
				ZInt = abs(ZInt);

				//add/subtract to ray length, since 3 units in length
				XInt = XInt + i;
				ZInt = ZInt - i;

				//no need to check collisions when out of world space 
				if (XInt > 99 || ZInt > 99 || YInt > 49){
					break;
				}

				//check for ray collisions with aliens, using whole unit squares
				int retVal = alienRayCollision(XInt,YInt,ZInt);
				if (retVal == 1){ //collision with alien found 
					break;
				}

				//check for ray collisions with humans, using whole unit squares
				retVal = humanRayCollision(XInt,YInt,ZInt);
				if (retVal == 1){ //collision with human found 
					break;
				}
				
			} //end of for loop 
		}

	} //end of GLUT_LEFT_BUTTON
}

void createHumans(int xValue, int yValue, int zValue,int humanNumber){
	
	//temp struct, to store in global array 
	struct HumanObject tempHuman;

	//set human coordinates (of their feet)
	tempHuman.xValue = xValue;
	tempHuman.yValue = yValue;
	tempHuman.zValue = zValue;

	//change y value to make humans start of the floor
	int newYValue = 35;
	while (world[xValue][newYValue-1][zValue] == 0){
		newYValue--;
	}
	tempHuman.yValue = newYValue;

	//set human to uncaught and undead status 
	tempHuman.capturedByAlien = -1;
	tempHuman.dead = 0;
	tempHuman.targeted = -1;
	tempHuman.heightWithAlien = 0;
	tempHuman.deadByHeight = 0;
	
	//store human in global array 
	theHumans[humanNumber] = tempHuman;

}

void fillHumanArray() {

	//x,y,z value, then human number in array 
	createHumans(9, 35, 46,0);
	createHumans(7, 35, 8,1);
	createHumans(14, 35, 40,2);
	createHumans(18, 35, 7,3);
	createHumans(21, 35, 83,4);
	createHumans(27, 35, 25,5);
	createHumans(30, 35, 88,6);
	createHumans(36, 35, 22,7);
	createHumans(43, 35, 76,8);
	createHumans(48, 35, 38,9);
	createHumans(59, 35, 72,10);
	createHumans(51, 35, 87,11);
	createHumans(66, 35, 62,12);
	createHumans(69, 35, 90,13);
	createHumans(74, 35, 67,14);
	createHumans(71, 35, 95,15);
	createHumans(80, 35, 52,16);
	createHumans(85, 35, 13,17);
	createHumans(90, 35, 57,18);
	createHumans(94, 35, 38,19);
}

void createAlien(int xValue, int yValue, int zValue,int alienArrayNum) {
	
	//random number used for direction 
	int ranNumX = rand() % 100;
	int ranNumZ = rand() % 100;

	//store alien coordinates (of center bottom block)
	struct AlienObject tempAlien;

	tempAlien.xValue = xValue;
	tempAlien.yValue = yValue;
	tempAlien.zValue = zValue;

	//initialize targets 
	tempAlien.targetX = 0;
	tempAlien.targetZ = 0;
	tempAlien.targetY = 0;

	//set inital x direction of alien 
	if (ranNumX % 2 == 0){
		tempAlien.xDirection = 1;
	} else {
		tempAlien.xDirection = -1;
	}

	//set inital y direction of alien 
	if (ranNumZ % 2 == 0){
		tempAlien.zDirection = 1;
	} else {
		tempAlien.zDirection = -1;
	}

	//no movement in height yet 
	tempAlien.yDirection = 0;

	//no human found yet 
	tempAlien.humanNumFound = -1;
	tempAlien.complete = 0;
	
	//store alien in global array 
	theAliens[alienArrayNum] = tempAlien;

}

void fillAlienArray() {

	//create 18 aliens in global array 

	//force aliens to be next to each other and some close to the ground to display game functionality 
	createAlien(50, 30, 50,0);
	createAlien(30, 30, 30,1);
	createAlien(40, 30, 40,2);
	createAlien(30, 30, 35,3);
	createAlien(50, 30, 29,4);
	createAlien(28, 30, 48,5);
	createAlien(20, 10, 20,6);
	createAlien(25, 10, 50,7);
	createAlien(20, 10, 15,8);
	createAlien(40, 10, 27,9);

	createAlien(60, 10, 9,10);
	createAlien(65, 10, 78,11);
	createAlien(73, 10, 84,12);
	createAlien(10, 10, 20,13);
	createAlien(14, 10, 48,14);
	createAlien(33, 10, 89,15);
	createAlien(84, 10, 28,16);
	createAlien(28, 10, 83,17);


}

void updateHumans() {

	//start time
	clock_t startTime = clock();

	//figure out how many seconds past since last time, draw human movement once every 0.7 sec
	double elapsed = (double)startTime * 1000.0 / CLOCKS_PER_SEC;

	if (elapsed > (lastDrawnTime + SPEED)){ //if its time for another screen update 
		lastDrawnTime = elapsed;
		for (int k = 0;k<20;k++) {

			//current position of human legs
			int tmpXValue = theHumans[k].xValue;
			int tmpYValue = theHumans[k].yValue;
			int tmpZValue = theHumans[k].zValue;

			//humans move down whenever not caught by alien 
			if (theHumans[k].dead == 1) { //dead, shot by ray 

				//remove colors from before and don't recreate
				clearHuman(tmpXValue,tmpZValue);

			} else if (theHumans[k].capturedByAlien == -1) { //free fall state

				//make sure current spot human is at is not the floor  
				if (world[tmpXValue][tmpYValue][tmpZValue] != 6 && tmpYValue > 0) {

					//remove colors from before 
					clearHuman(tmpXValue,tmpZValue);

					//set legs of human, orange  
					world[tmpXValue][tmpYValue][tmpZValue] = 7;

					//set body of human, red
					world[tmpXValue][tmpYValue+1][tmpZValue] = 3;

					//set head of human, green
					world[tmpXValue][tmpYValue+2][tmpZValue] = 1; 

					//move lower if next spot below human is not the floor 
					if (world[tmpXValue][tmpYValue-1][tmpZValue] == 0 && tmpYValue > 0) {

						//move human lower, for next time it is drawn, decrease y value
						theHumans[k].yValue = theHumans[k].yValue - 1;

					} else if (theHumans[k].deadByHeight == 1){ //fell from alien at high height

						//human should be dead when it reaches ground due to height it fell
						theHumans[k].dead = 1;
						theHumans[k].targeted = -2;

						printf("Human Number %d Lost, fell at height of %d\n",k,theHumans[k].heightWithAlien );
			
					}

				}

			} else { //caught by alien, move up 

				if (theAliens[theHumans[k].capturedByAlien].complete == 1 || theAliens[theHumans[k].capturedByAlien].complete == 2) {
					
					//human is taken by alien to sky, clear human   
					//remove colors from before and don't recreate
					clearHuman(tmpXValue,tmpZValue);
					

				} else if (tmpYValue < 45) { //has not reached sky yet, keep moving up 

					//remove colors from before 
					clearHuman(tmpXValue,tmpZValue);

					//set legs of human, orange  
					world[tmpXValue][tmpYValue][tmpZValue] = 7;

					//set body of human, red
					world[tmpXValue][tmpYValue+1][tmpZValue] = 3;

					//set head of human, green
					world[tmpXValue][tmpYValue+2][tmpZValue] = 1; 

					//set height away from ground
					theHumans[k].heightWithAlien = getHeightFromGround(tmpXValue,tmpYValue,tmpZValue);

					//move human higher, for next time it is drawn, increase y value
					theHumans[k].yValue = theHumans[k].yValue + 1;
				}
			} //end of else caught by alien 

		}
	} //end of if statement for human movement time frame 
}

//function to control acceleration and deceleration 
void updateMomentum() {

	//start time
	clock_t startTime = clock();

	//figure out how many seconds past since last time, draw human movement once every 0.7 sec
	double elapsed = (double)startTime * 1000.0 / CLOCKS_PER_SEC;

	//see if momentum needed
	if (momentumLeft > 0){

		//move during acceleration lasts 0.2 secs without movement update, moves 0.06 units + acceleration
		if ( elapsed < (lastMovementTime + 200)) {

			//determine which direction to move vp during momentum, using flags
			if (increasingZ == 1) {
				if (nextZMove - 1 > -98){
					nextZMove = nextZMove - 0.06 * momentumLeft; //technically adding, since numbers are negitive 
				}
			} else {
				if (nextZMove + 1 < 0){
					nextZMove = nextZMove + 0.06 * momentumLeft;
				}
			}

			if (increasingX == 1){
				if (nextXMove - 1 > -98){
					nextXMove = nextXMove - 0.06 * momentumLeft; //technically adding, since numbers are negitive 
				}
			} else {
				if (nextXMove + 1 < 0){
					nextXMove = nextXMove + 0.06 * momentumLeft;
				}
			}

			if (increasingY == 1){
				if (nextYMove - 1 > -48){
					nextYMove = nextYMove - 0.02 * momentumLeft; //technically adding, since numbers are negitive 
				}
			} else {
				if (nextXMove + 1 < 0){
					nextYMove = nextYMove + 0.02 * momentumLeft;
				}
			}

			//check for collisions before update 

			//cast to integers, since the world array dealing with whole units
			int nextXInt = (int) nextXMove;
			int nextYInt = (int) nextYMove;
			int nextZInt = (int) nextZMove;
			//get absolute value, since positions are negitive 
			nextXInt = abs(nextXInt);
			nextYInt = abs(nextYInt);
			nextZInt = abs(nextZInt);

			//check next block in world array, if next box is occupied, don't allow next move 
			if (world[nextXInt][nextYInt][nextZInt] == 0) {
				setViewPosition(nextXMove,nextYMove,nextZMove);
			}
			else {
				momentumLeft = 0;
			}

		} else if (elapsed < (lastMovementTime + 600)) { //this would be deacceleration, move 0.06 for last .4 secs
			if (increasingZ == 1) {
				if (nextZMove - 1 > -98) {
					nextZMove = nextZMove - 0.04; //technically adding, since numbers are negitive 
				}
			} else {
				if (nextZMove + 1 < 0){
					nextZMove = nextZMove + 0.04;
				}
			}

			if (increasingX == 1){
				if (nextXMove - 1 > -98){
					nextXMove = nextXMove - 0.04; //technically adding, since numbers are negitive 
				}
			} else {
				if (nextXMove + 1 < 0){
					nextXMove = nextXMove + 0.04;
				}
			}

			if (increasingY == 1){
				if (nextYMove - 1 > -48){
					nextYMove = nextYMove - 0.01; //technically adding, since numbers are negitive 
				}
			} else {
				if (nextXMove + 1 < 0){
					nextYMove = nextYMove + 0.01;
				}
			}

			//check for collisions before update 

			//cast to integers, since the world array dealing with whole units
			int nextXInt = (int) nextXMove;
			int nextYInt = (int) nextYMove;
			int nextZInt = (int) nextZMove;
			//get absolute value, since positions are negitive 
			nextXInt = abs(nextXInt);
			nextYInt = abs(nextYInt);
			nextZInt = abs(nextZInt);

			//check next block in world array, if next box is occupied, don't allow next move 
			if (world[nextXInt][nextYInt][nextZInt] == 0) {
				setViewPosition(nextXMove,nextYMove,nextZMove);
			}
			else {
				momentumLeft = 0;
			}

		} else {
			momentumLeft = 0;//end momentum motion 
		}
	}

}

void updateRays() {

	for (int i=0;i<numOfRaysInWorld;i++){
		if (theRays[i].active == 1){
			//get current time
			clock_t curTime = clock();

			//figure out how many seconds past since ray was drawn
			double curTimeD = (double)curTime * 1000.0 / CLOCKS_PER_SEC;

			if (curTimeD > (theRays[i].timeStarted + 2000)) { //keep ray 3.5 secs on screen
				hideTube(theRays[i].ID);
				theRays[i].active = 0;
			} 
		} 
	}

}

void updateAliens() {

	//start time
	clock_t startTime = clock();

	//figure out how many seconds past since last time, draw alien movement once every 0.7 sec
	double elapsed = (double)startTime * 1000.0 / CLOCKS_PER_SEC;

	if (elapsed > (alienDrawnTime + SPEED)){ 
		alienDrawnTime = elapsed;
		for (int k = 0;k<numOfAliensInWorld;k++) {

			if (theAliens[k].complete == 1) {

				//change colour randomly 
				if (colorChange == 0){
					setUserColour(10, 0.8, 0, 0.3, 1.0, 0.2, 0.2, 0.2, 1.0); //red
					colorChange = 1;
				} else {
					colorChange = 0;
					setUserColour(10, 0.8, 0, 0.8, 1.0, 0.2, 0.2, 0.2, 1.0); //pink
				}

				//if alien is transformed, have them shoot at player
				alienShots(k);

			}
			else if (theAliens[k].complete == 3) { //alien shot or taken human
				
				//clear alien off screen
				clearAlien(k);

				//set new status for alien  
				theAliens[k].complete = 2;
				continue;

			} else if (theAliens[k].complete == 2) {
				//skip, alien already completed, either shoot or taken human 
				continue;
			} 

			//current alien coordinates
			int tmpXValue = theAliens[k].xValue;
			int tmpYValue = theAliens[k].yValue;
			int tmpZValue = theAliens[k].zValue;

			//current alien direction
			int xDirection = theAliens[k].xDirection;
			int zDirection = theAliens[k].zDirection;
			int yDirection = theAliens[k].yDirection;

			if (humanNearBy(k) == 1 && theAliens[k].complete != 1) { //human near by and alien is not transformed 

				int targetX = theAliens[k].targetX;
				int targetZ = theAliens[k].targetZ;

				//change x direction depending on human location 
				if (tmpXValue < targetX) {
					theAliens[k].xDirection = 1;
					xDirection = theAliens[k].xDirection;
				} else {
					theAliens[k].xDirection = -1;
					xDirection = theAliens[k].xDirection;
				}

				//change z direction depending on human location 
				if (tmpZValue < targetZ) {
					theAliens[k].zDirection = 1;
					zDirection = theAliens[k].zDirection;
				} else {
					theAliens[k].zDirection = -1;
					zDirection = theAliens[k].zDirection;
				}

				//if target matched, stop moving in x direction 
				if (tmpXValue == targetX) {
					theAliens[k].xDirection = 0;
					xDirection = theAliens[k].xDirection;
				}

				//if target matched, stop moving in z direction
				if (tmpZValue == targetZ) {
					theAliens[k].zDirection = 0;
					zDirection = theAliens[k].zDirection;
				}

			} else if (humanNearBy(k) == 2 && theAliens[k].complete != 1) { //human right underneath and alien not transformed

				//cancel directions when alien right above human 
				theAliens[k].xDirection = 0;
				xDirection = theAliens[k].xDirection;
				theAliens[k].zDirection = 0;
				zDirection = theAliens[k].zDirection;

				//figure out which human is underneath 
				int humanNumCaught = findHumanCaught(tmpXValue,tmpZValue);

				//set human number caught in alien struct 
				theAliens[k].humanNumFound = humanNumCaught;

				//get y target, right above human
				int targetY = theAliens[k].targetY;  

				//change y direction depending on human location 
				if (tmpYValue < targetY) {
					theAliens[k].yDirection = 1;
					yDirection = theAliens[k].yDirection;
				} else {
					theAliens[k].yDirection = -1;
					yDirection = theAliens[k].yDirection;
				}

				if (tmpYValue == 47 && theAliens[k].humanNumFound != -1) { //alien made it to the top with human
					
					printf("Human Number %d Lost, taken by Alien\n", theAliens[k].humanNumFound);

					//cancel direction
					theAliens[k].yDirection = 0;
					yDirection = theAliens[k].yDirection;

					//set alien to complete, new status of transformed 
					theAliens[k].humanNumFound = -1;
					theAliens[k].complete = 1;

					//give it new direction 
					int ranNum = rand() % 100;

					if (ranNum % 2 == 0) { //randomly change direction of alien 
						theAliens[k].xDirection = 1;
						theAliens[k].zDirection = 1;
					} else {
						theAliens[k].xDirection = -1;
						theAliens[k].zDirection = -1;
					}

				} else if (tmpYValue == targetY) { //if y targets matched, alien is right above

					//set human struct as caught, so that its motion chnages, and it knows which alien has it
					theHumans[theAliens[k].humanNumFound].capturedByAlien = k;

					//update target to sky 
					theAliens[k].targetY = 47;
					targetY = theAliens[k].targetY;

				}

			} 

			//free movement for alien, depends on current directions/state 
			if (theAliens[k].xDirection != 0 || theAliens[k].zDirection != 0 || theAliens[k].yDirection != 0) {
				
				//control direction if alien hit border
				if (tmpZValue < 2){
					theAliens[k].zDirection = 1;
					zDirection = theAliens[k].zDirection;
				}

				if (tmpXValue < 2){
					theAliens[k].xDirection = 1;
					xDirection = theAliens[k].xDirection;
				}

				if (tmpZValue > 97){
					theAliens[k].zDirection = -1;
					zDirection = theAliens[k].zDirection;
				}

				if (tmpXValue > 97){
					theAliens[k].xDirection = -1;
					xDirection = theAliens[k].xDirection;
				}

				//clear alien previous location 
				clearAlien(k);

				//check for collision before drawing
				int alienCollided = alienCollision(k); 
				if (alienCollided == 1){ //alien collided, direction changed 
	
					xDirection = theAliens[k].xDirection; //updated modified alien directions
					zDirection = theAliens[k].zDirection;

				} else if (alienCollided == 2) { //cancel movement and move up for one move, if colleision with ground
					yDirection = 1;
					xDirection = 0;
					zDirection = 0;
				}

				redrawAlien(k,xDirection, yDirection,zDirection,theAliens[k].complete);
				
				//set new current coordinate values of center bottom cube 
				theAliens[k].xValue = tmpXValue+xDirection;
				theAliens[k].zValue = tmpZValue+zDirection;
				theAliens[k].yValue = tmpYValue+yDirection;

			} //end of if for free movement 

		} //end of for loop 
	}

}

int checkHumanTargeted(int alienNum,int tmpXValue, int tmpZValue){
	
	//figure out which human is targeted 
	int humanNumCaught = findHumanCaught(tmpXValue,tmpZValue);

	//no human found, let alien ignore it
	if (humanNumCaught == -1){
		return 1;
	}
    
    //if human dead, ignore
    if (theHumans[humanNumCaught].dead == 1){
        return 1;
    }

	//if human targeted by current alien or not targeted at all, continue target
	if (theHumans[humanNumCaught].targeted == -1 || theHumans[humanNumCaught].targeted == alienNum){

		//set human struct as targeted so that other aliens don't target it
		theHumans[humanNumCaught].targeted = alienNum;

		return 0;

	} else {

		//ignore human, its already been targeted by a different alien
		return 1;
	}

	
}

int humanNearBy(int alienNum) {
	
	//current alien coordinates
	int tmpXValue = theAliens[alienNum].xValue;
	int tmpYValue = theAliens[alienNum].yValue;
	int tmpZValue = theAliens[alienNum].zValue;

	for (int tmpY=0;tmpY<48;tmpY++){
		//check for near by humans, with search radius of 4
		if (world[tmpXValue][tmpY][tmpZValue] == 7) {

			//check if human is targeted, if not, set target, if target by a different alien, ignore human
			int retVal = checkHumanTargeted(alienNum,tmpXValue,tmpZValue);

			if (retVal == 0) {

				//if no human found yet, set target for current human 
				if (theAliens[alienNum].humanNumFound == -1){
					theAliens[alienNum].targetY = tmpY + 5; //stop 5 spots above human legs
				}

				return 2;

			} else {
				return 0;
			}
			
		} 

		for (int k=0;k<7;k++){
			if (world[tmpXValue+k][tmpY][tmpZValue] == 7) {

				//check if human is targeted, if not, set target, if target by a different alien, ignore human
				int retVal = checkHumanTargeted(alienNum,tmpXValue+k,tmpZValue);

				if (retVal == 0){ //human target set

					theAliens[alienNum].targetX = tmpXValue+k;
					theAliens[alienNum].targetZ = tmpZValue;

					return 1;

				} else {
					return 0;
				}

			} else if (world[tmpXValue][tmpY][tmpZValue+k] == 7){

				//check if human is targeted, if not, set target, if target by a different alien, ignore human
				int retVal = checkHumanTargeted(alienNum,tmpXValue,tmpZValue+k);

				if (retVal == 0) { //human target set

					theAliens[alienNum].targetX = tmpXValue;
					theAliens[alienNum].targetZ = tmpZValue+k;

					return 1;

				} else {
					return 0;
				}

			} else if (world[tmpXValue+k][tmpY][tmpZValue+k] == 7){

				//check if human is targeted, if not, set target, if target by a different alien, ignore human
				int retVal = checkHumanTargeted(alienNum,tmpXValue+k,tmpZValue+k);

				if (retVal == 0) { //human target set
					
					theAliens[alienNum].targetX = tmpXValue+k;
					theAliens[alienNum].targetZ = tmpZValue+k;

					return 1;

				} else {
					return 0;
				}

			} if (world[tmpXValue-k][tmpY][tmpZValue] == 7) {

				//check if human is targeted, if not, set target, if target by a different alien, ignore human
				int retVal = checkHumanTargeted(alienNum,tmpXValue-k,tmpZValue);

				if (retVal == 0) { //human target set

					theAliens[alienNum].targetX = tmpXValue-k;
					theAliens[alienNum].targetZ = tmpZValue;

					return 1;

				} else {
					return 0;
				}

			} else if (world[tmpXValue][tmpY][tmpZValue-k] == 7){

				//check if human is targeted, if not, set target, if target by a different alien, ignore human
				int retVal = checkHumanTargeted(alienNum,tmpXValue,tmpZValue-k);

				if (retVal == 0) { //human target set

					theAliens[alienNum].targetX = tmpXValue;
					theAliens[alienNum].targetZ = tmpZValue-k;

					return 1;
				} else {
					return 0;
				}

			} else if (world[tmpXValue-k][tmpY][tmpZValue-k] == 7){

				//check if human is targeted, if not, set target, if target by a different alien, ignore human
				int retVal = checkHumanTargeted(alienNum,tmpXValue-k,tmpZValue-k);

				if (retVal == 0) { //human target set

					theAliens[alienNum].targetX = tmpXValue-k;
					theAliens[alienNum].targetZ = tmpZValue-k;

					return 1;
				} else {
					return 0;
				}

			} else if (world[tmpXValue+k][tmpY][tmpZValue-k] == 7){

				//check if human is targeted, if not, set target, if target by a different alien, ignore human
				int retVal = checkHumanTargeted(alienNum,tmpXValue+k,tmpZValue-k);

				if (retVal == 0) { //human target set 

					theAliens[alienNum].targetX = tmpXValue+k;
					theAliens[alienNum].targetZ = tmpZValue-k;

					return 1;
				} else {
					return 0;
				}

			} else if (world[tmpXValue-k][tmpY][tmpZValue+k] == 7){

				//check if human is targeted, if not, set target, if target by a different alien, ignore human
				int retVal = checkHumanTargeted(alienNum,tmpXValue-k,tmpZValue+k);

				if (retVal == 0){ //human target set 

					theAliens[alienNum].targetX = tmpXValue-k;
					theAliens[alienNum].targetZ = tmpZValue+k;

					return 1;

				} else {
					return 0;
				}

			}
		}
	}

	return 0;
}

int findHumanCaught(int alienXValue,int alienZValue) {
	
	//loop through human array, find which human is in sent coordinates
	for (int k = 0;k<20;k++) {

		int humanXValue = theHumans[k].xValue;
		int humanZValue = theHumans[k].zValue;

		if (alienXValue == humanXValue && alienZValue == humanZValue) {
			return k;
		}
	}

	return -1;
}

void clearHuman(int tmpXValue, int tmpZValue) {

	for (int tmpY=0;tmpY<48;tmpY++){
		//check for human cubes to clear 
		if (world[tmpXValue][tmpY][tmpZValue] == 7 || world[tmpXValue][tmpY][tmpZValue] == 3 || world[tmpXValue][tmpY][tmpZValue] == 1) {
			world[tmpXValue][tmpY][tmpZValue] = 0;
		}
	}

}


void processShotHuman(int humanNumberFound) {

	//set human as dead
	theHumans[humanNumberFound].dead = 1;
	theHumans[humanNumberFound].targeted = -2;

	//if human was caught by an alien when shot 
	if (theHumans[humanNumberFound].capturedByAlien != -1 ) {

		int alienNum = theHumans[humanNumberFound].capturedByAlien;

		//reset values for alien  so they continue moving
		theAliens[alienNum].humanNumFound = -1;
		theAliens[alienNum].xDirection = 1;
		theAliens[alienNum].zDirection = 1;
		theAliens[alienNum].yDirection = 0;
		theAliens[alienNum].targetX = 0;
		theAliens[alienNum].targetZ = 0;
		theAliens[alienNum].targetY = 0;

	}
}

int findAlienShot(int curXValue,int curZValue) { 
	//curValues are cubes from alien
	//loop through alien structs to figure out which was shot by ray 
	for (int k = 0;k<numOfAliensInWorld;k++) {

		int alienXValue = theAliens[k].xValue;
		int alienZValue = theAliens[k].zValue;

		if (curXValue == alienXValue && curZValue == alienZValue) {
			return k;
		} 

		//alien is several blocks, loop through to find which alien the block shot belongs to 
		for (int i=-3;i<3;i++){
			for (int j=-3;j<3;j++){
				if (curXValue == alienXValue+i && curZValue == alienZValue+j) {
					return k;
				}
			}
		}
	}

	return -1;
}

int alienRayCollision(int xValue, int yValue, int zValue) {

	//check for ray collisions with aliens, using whole unit squares
	if (world[xValue][yValue][zValue] == 8 || world[xValue][yValue][zValue] == 9 || world[xValue][yValue][zValue] == 10) {
		
		//find which alien was shot
		int alienNumberFound = findAlienShot(xValue,zValue);

		printf("Alien %d Lost, hit by ray\n",alienNumberFound );

		processAlienShot(alienNumberFound);

		return 1;

	} 

	return 0;
}

int humanRayCollision(int xValue, int yValue, int zValue) {

	//collision based off color values used for humans 
	if (world[xValue][yValue][zValue] == 7 || world[xValue][yValue][zValue] == 3 || world[xValue][yValue][zValue] == 1) {

		int humanNumberFound = findHumanCaught(xValue,zValue);

		printf("Human Number %d Lost, hit by ray\n", humanNumberFound);

		processShotHuman(humanNumberFound);

		return 1;

	} 

	return 0;
}

void processAlienShot(int alienNumberFound) {
	//set alien with shot status 
	theAliens[alienNumberFound].complete = 3;

	if (theAliens[alienNumberFound].humanNumFound != -1){ //if alien had a human when shot
		int humanNum = theAliens[alienNumberFound].humanNumFound;

        if (theHumans[humanNum].capturedByAlien != -1){
            theHumans[humanNum].yValue = theHumans[humanNum].yValue + 1;
        }
        
		//reset values so human falls back down 
		theHumans[humanNum].capturedByAlien = -1;
		theHumans[humanNum].targeted = -1;

		//set height human fell at 
		if (theHumans[humanNum].heightWithAlien > 13){
			theHumans[humanNum].deadByHeight = 1;
		}
	}
	
}

int getHeightFromGround(int tmpXValue,int tmpYValue,int tmpZValue){

	//start from spot underneath human
	tmpYValue--;

	int groundHeight = 0; //set inital ground height

	while (world[tmpXValue][tmpYValue][tmpZValue] != 6 && tmpYValue >= 0){
		groundHeight++; //increase ground height until floor is found
		tmpYValue--;
	}

	return groundHeight;

}

int alienCollision(int alienNum) {

	//current alien coordinates
	int tmpXValue = theAliens[alienNum].xValue;
	int tmpYValue = theAliens[alienNum].yValue;
	int tmpZValue = theAliens[alienNum].zValue;

	//current alien direction
	int xDirection = theAliens[alienNum].xDirection;
	int zDirection = theAliens[alienNum].zDirection;
	int yDirection = theAliens[alienNum].yDirection;

	//check (slightly bigger) box around alien for collisions with aliens
	for (int i =-2;i<2;i++){ //x value
		for (int j=-2;j<2;j++){ // z value
			for (int h = -1;h<3;h++){ //y valye

				if (tmpXValue+xDirection+i < 0 && tmpXValue+xDirection+i > 99 && tmpZValue+zDirection+j < 0 && tmpZValue+zDirection+j > 99){ //out of bounds
					continue;
				}

				if (world[tmpXValue+xDirection+i][tmpYValue+yDirection+h][tmpZValue+zDirection+j] == 9 || world[tmpXValue+xDirection+i][tmpYValue+yDirection+h][tmpZValue+zDirection+j] == 8){
						
					//change direction of first alien collided
					theAliens[alienNum].xDirection = theAliens[alienNum].xDirection * -1;
					theAliens[alienNum].zDirection = theAliens[alienNum].zDirection * -1;

					//find the alien it hit and move that one too in the opposite direction
					int alienNumFound = findAlienThatCollided(tmpXValue+xDirection+i,tmpZValue+zDirection+j, alienNum);
					if (alienNumFound > -1){ //alien found 
							theAliens[alienNumFound].xDirection = theAliens[alienNumFound].xDirection * -1;
							theAliens[alienNumFound].zDirection = theAliens[alienNumFound].zDirection * -1;
					} 

					return 1;
				}

				//collisions with transformed aliens 
				if (world[tmpXValue+xDirection+i][tmpYValue+yDirection+h][tmpZValue+zDirection+j] == 10 ){
						
					//change direction of first alien collided
					theAliens[alienNum].xDirection = theAliens[alienNum].xDirection * -1;
					theAliens[alienNum].zDirection = theAliens[alienNum].zDirection * -1;

					//find the alien it hit and move that one too in the opposite direction
					int alienNumFound = findAlienThatCollided(tmpXValue+xDirection+i,tmpZValue+zDirection+j, alienNum);
					if (alienNumFound > -1){ //alien found 
							theAliens[alienNumFound].xDirection = theAliens[alienNumFound].xDirection * -1;
							theAliens[alienNumFound].zDirection = theAliens[alienNumFound].zDirection * -1;
					} 

					return 1;
				}
			}
			
		}
	}

	//check collisions with ground 
	for (int i =-2;i<2;i++){ //x value
		for (int j=-2;j<2;j++){ // z value
			for (int h = -1;h<3;h++){ //y valye

				if (tmpXValue+xDirection+i < 0 && tmpXValue+xDirection+i > 99 && tmpZValue+zDirection+j < 0 && tmpZValue+zDirection+j > 99){ //out of bounds
					continue;
				}

				if (world[tmpXValue+xDirection+i][tmpYValue+yDirection+h][tmpZValue+zDirection+j] == 6){
					return 2; //signal alien to move up 
				}
			}
		}
	}

	return 0;

}

int findAlienThatCollided(int curXValue,int curZValue, int alienNum) { 
	//curValues are cubes from alien
	//loop through alien structs to figure out which was hit by alien 
	for (int k = 0;k<numOfAliensInWorld;k++) {

		int alienXValue = theAliens[k].xValue;
		int alienZValue = theAliens[k].zValue;

		if (curXValue == alienXValue && curZValue == alienZValue && k != alienNum) {
			return k;
		} 

		//alien is several blocks, loop through to find which alien the block shot belongs to 
		for (int i=-3;i<3;i++){
			for (int j=-3;j<3;j++){
				if (curXValue == alienXValue+i && curZValue == alienZValue+j && k != alienNum) {
					return k;
				}
			}
		}
	}

	return -1;
}

void clearAlien(int alienNum) {

	//current alien coordinates
	int tmpXValue = theAliens[alienNum].xValue;
	int tmpYValue = theAliens[alienNum].yValue;
	int tmpZValue = theAliens[alienNum].zValue;

	//remove bottom layer previous location 
	world[tmpXValue][tmpYValue][tmpZValue] = 0;
	world[tmpXValue+1][tmpYValue][tmpZValue+1] = 0;
	world[tmpXValue-1][tmpYValue][tmpZValue-1] = 0;
	world[tmpXValue+1][tmpYValue][tmpZValue-1] = 0;
	world[tmpXValue-1][tmpYValue][tmpZValue+1] = 0;

	world[tmpXValue+1][tmpYValue-1][tmpZValue+1] = 0;
	world[tmpXValue-1][tmpYValue-1][tmpZValue-1] = 0;
	world[tmpXValue+1][tmpYValue-1][tmpZValue-1] = 0;
	world[tmpXValue-1][tmpYValue-1][tmpZValue+1] = 0;

	//remove middle layer 
	world[tmpXValue][tmpYValue+1][tmpZValue] = 0;
	world[tmpXValue+1][tmpYValue+1][tmpZValue] = 0;
	world[tmpXValue][tmpYValue+1][tmpZValue+1] = 0;
	world[tmpXValue-1][tmpYValue+1][tmpZValue] = 0;
	world[tmpXValue][tmpYValue+1][tmpZValue-1] = 0;
	world[tmpXValue+1][tmpYValue+1][tmpZValue+1] = 0;
	world[tmpXValue-1][tmpYValue+1][tmpZValue-1] = 0;
	world[tmpXValue+1][tmpYValue+1][tmpZValue-1] = 0;
	world[tmpXValue-1][tmpYValue+1][tmpZValue+1] = 0;

	//remove top layer 
	world[tmpXValue][tmpYValue+2][tmpZValue] = 0;
	world[tmpXValue+1][tmpYValue+2][tmpZValue] = 0;
	world[tmpXValue][tmpYValue+2][tmpZValue+1] = 0;
	world[tmpXValue-1][tmpYValue+2][tmpZValue] = 0;
	world[tmpXValue][tmpYValue+2][tmpZValue-1] = 0;
	world[tmpXValue+1][tmpYValue+2][tmpZValue+1] = 0;
	world[tmpXValue-1][tmpYValue+2][tmpZValue-1] = 0;
	world[tmpXValue+1][tmpYValue+2][tmpZValue-1] = 0;
	world[tmpXValue-1][tmpYValue+2][tmpZValue+1] = 0;
}

void redrawAlien(int alienNum, int xDirection, int yDirection, int zDirection, int status) {

	//current alien coordinates
	int tmpXValue = theAliens[alienNum].xValue;
	int tmpYValue = theAliens[alienNum].yValue;
	int tmpZValue = theAliens[alienNum].zValue;

	int feetColour = 9;
	int bodyColour = 8;

	if (status == 1){ //different colour for tranformed alien, starts off as red
		feetColour = 10;
		bodyColour = 10;
	}

	//create bottom layer 
	world[tmpXValue+xDirection][tmpYValue+yDirection][tmpZValue+zDirection] = feetColour;
	world[tmpXValue+xDirection+1][tmpYValue+yDirection][tmpZValue+zDirection+1] = feetColour;
	world[tmpXValue+xDirection-1][tmpYValue+yDirection][tmpZValue+zDirection-1] = feetColour;
	world[tmpXValue+xDirection+1][tmpYValue+yDirection][tmpZValue+zDirection-1] = feetColour;
	world[tmpXValue+xDirection-1][tmpYValue+yDirection][tmpZValue+zDirection+1] = feetColour;
	world[tmpXValue+xDirection+1][tmpYValue+yDirection-1][tmpZValue+zDirection+1] = feetColour;
	world[tmpXValue+xDirection-1][tmpYValue+yDirection-1][tmpZValue+zDirection-1] = feetColour;
	world[tmpXValue+xDirection+1][tmpYValue+yDirection-1][tmpZValue+zDirection-1] = feetColour;
	world[tmpXValue+xDirection-1][tmpYValue+yDirection-1][tmpZValue+zDirection+1] = feetColour;

	//create middle layer 
	world[tmpXValue+xDirection][tmpYValue+yDirection+1][tmpZValue+zDirection] = bodyColour;
	world[tmpXValue+xDirection+1][tmpYValue+yDirection+1][tmpZValue+zDirection] = bodyColour;
	world[tmpXValue+xDirection][tmpYValue+yDirection+1][tmpZValue+zDirection+1] = bodyColour;
	world[tmpXValue+xDirection-1][tmpYValue+yDirection+1][tmpZValue+zDirection] = bodyColour;
	world[tmpXValue+xDirection][tmpYValue+yDirection+1][tmpZValue+zDirection-1] = bodyColour;
	world[tmpXValue+xDirection+1][tmpYValue+yDirection+1][tmpZValue+zDirection+1] = bodyColour;
	world[tmpXValue+xDirection-1][tmpYValue+yDirection+1][tmpZValue+zDirection-1] = bodyColour;
	world[tmpXValue+xDirection+1][tmpYValue+yDirection+1][tmpZValue+zDirection-1] = bodyColour;
	world[tmpXValue+xDirection-1][tmpYValue+yDirection+1][tmpZValue+zDirection+1] = bodyColour;

	//create top layer 
	world[tmpXValue+xDirection][tmpYValue+yDirection+2][tmpZValue+zDirection] = bodyColour;
	world[tmpXValue+xDirection+1][tmpYValue+yDirection+2][tmpZValue+zDirection] = bodyColour;
	world[tmpXValue+xDirection][tmpYValue+yDirection+2][tmpZValue+zDirection+1] = bodyColour;
	world[tmpXValue+xDirection-1][tmpYValue+yDirection+2][tmpZValue+zDirection] = bodyColour;
	world[tmpXValue+xDirection][tmpYValue+yDirection+2][tmpZValue+zDirection-1] = bodyColour;
	world[tmpXValue+xDirection+1][tmpYValue+yDirection+2][tmpZValue+zDirection+1] = bodyColour;
	world[tmpXValue+xDirection-1][tmpYValue+yDirection+2][tmpZValue+zDirection-1] = bodyColour;
	world[tmpXValue+xDirection+1][tmpYValue+yDirection+2][tmpZValue+zDirection-1] = bodyColour;
	world[tmpXValue+xDirection-1][tmpYValue+yDirection+2][tmpZValue+zDirection+1] = bodyColour;
}

void alienShots(int alienNum) {
	
	float curX, curY, curZ;	
	getViewPosition(&curX, &curY, &curZ); //get current position of vp 
	
	//current alien coordinates
	float tmpXValue = (float) theAliens[alienNum].xValue;
	float tmpYValue = (float) theAliens[alienNum].yValue;
	float tmpZValue = (float) theAliens[alienNum].zValue;

	//check if ray should be redrawn first  
	if (theRays[rayCount].active == 1) {
		//get current time
		clock_t curTime = clock();

		//figure out how many seconds past since ray was drawn
		double curTimeD = (double)curTime * 1000.0 / CLOCKS_PER_SEC;
		if (curTimeD < (theRays[rayCount].timeStarted + 5000)) { //give player a chance to move before redrawing (5 secs) 
			return;
		}

	}

	//get distance between vp and alien 
	float x=tmpXValue-(curX*-1);
	float y=tmpZValue-(curZ*-1);
	float rangeLength = sqrt((x*x)+(y*y));

	if (rangeLength == 0){ //distance of 0 from alien, don't bother trying to draw ray 
		return;
	}

	float distanceRatio = 20/rangeLength; //used in getting new point on line 

	//get a point between alien and vp that will result in a line 20 in length 
	int newX = (1-distanceRatio)* tmpXValue + distanceRatio*(curX*-1);
	int newZ = (1-distanceRatio)* tmpZValue + distanceRatio*(curZ*-1);

	//use values created above and update ray end points 
	curZ = newZ;
	curX = newX;

	curZ = curZ * -1;
	curX = curX * -1;

	//determine if y value needs to be modifed, let it reach 15 units below alien 
	if (tmpYValue >  (curY*-1) ) {
		if ((tmpYValue -(curY*-1)) > 10){ //greater than 10 units away from alien 
			curY = tmpYValue - 15; 
			curY = curY * -1;
		}
		
	} 

	//convert to int to make them easier to deal with for line intercetions 
	int startX = tmpXValue;
	int startY = tmpYValue;
	int startZ = tmpZValue;

	int endX = curX*-1;
	int endY = curY*-1;
	int endZ = curZ*-1;

	//create tube for ray, aiming for player, colour 3 (red)
	createTube(rayCount, startX, startY, startZ,endX, endY, endZ, 3);

	//save points for ray map drawing 
	theRays[rayCount].startPosX = startX;
	theRays[rayCount].startPosZ = startZ;
	theRays[rayCount].endPosX = endX;
	theRays[rayCount].endPosZ = endZ;

	//set time for how long momentum will last, this is start time
	clock_t rayStartTime = clock();
	double startTime = (double)rayStartTime * 1000.0 / CLOCKS_PER_SEC;

	//keep track of which rays have been activated, to control timing of it
	theRays[rayCount].active = 1;
	theRays[rayCount].timeStarted = startTime;

	rayCount++; //increase ray id 

	//15 rays in array, cycle through them 
	if (rayCount > 14){ 
		rayCount = 0;
	}

	//see if ray hit player, collisions with ray from alien 
	float updateCurX, updateCurY, updateCurZ;	
	getViewPosition(&updateCurX, &updateCurY, &updateCurZ); //get current position of vp again

	int playerX = updateCurX * -1; //make cordinates positive and in ints
	int playerY = updateCurY * -1;
	int playerZ = updateCurZ * -1; 

	//get cross product for vp and alien 
	int playerVectorX = playerX - startX;
	int playerVectorZ = playerZ - startZ;

	int alienVecX = endX - startX;
	int alienVecZ = endZ - startZ;

	int crossProduct = playerVectorX * alienVecZ - playerVectorZ * alienVecX;

	if (crossProduct == 0){ //vp is on the line, now find if in between ray points 

		//verify by y values 
		if (startY < endY){
			if (playerY >= startY && playerY <= endY){
				if (startX < endX){
					if (playerX >= startX && playerX <= endX){
						printf("Alien #%d Ray Hit Player\n", alienNum);
					}
				} else {
					if (playerX <= startX && playerX >= endX){
						printf("Alien #%d Ray Hit Player\n", alienNum);
					}
				}
			}
		} else {
			if (playerY <= startY && playerY >= endY){
				if (startX < endX){
					if (playerX >= startX && playerX <= endX){
						printf("Alien #%d Ray Hit Player\n", alienNum);
					}
				} else {
					if (playerX <= startX && playerX >= endX){
						printf("Alien #%d Ray Hit Player\n", alienNum);
					}
				}
			}
		}
	}

}

int main(int argc, char** argv) {
	int i, j, k;
	/* initialize the graphics system */
	graphicsInit(&argc, argv);

	/* the first part of this if statement builds a sample */
	/* world which will be used for testing */
	/* DO NOT remove this code. */
	/* Put your code in the else statment below */
	/* The testworld is only guaranteed to work with a world of
		with dimensions of 100,50,100. */
	if (testWorld == 1) {
	/* initialize world to empty */
		for(i=0; i<WORLDX; i++)
			for(j=0; j<WORLDY; j++)
				for(k=0; k<WORLDZ; k++)
					world[i][j][k] = 0;

	/* some sample objects */
	/* build a red platform */
		for(i=0; i<WORLDX; i++) {
			for(j=0; j<WORLDZ; j++) {
				world[i][24][j] = 3;
			}
		}
	/* create some green and blue cubes */
		world[50][25][50] = 1;
		world[49][25][50] = 1;
		world[49][26][50] = 1;
		world[52][25][52] = 2;
		world[52][26][52] = 2;

	/* create user defined colour and draw cube */
		setUserColour(9, 0.7, 0.3, 0.7, 1.0, 0.3, 0.15, 0.3, 1.0);
		world[54][25][50] = 9;


	/* blue box shows xy bounds of the world */
		for(i=0; i<WORLDX-1; i++) {
			world[i][25][0] = 2;
			world[i][25][WORLDZ-1] = 2;
		}
		for(i=0; i<WORLDZ-1; i++) {
			world[0][25][i] = 2;
			world[WORLDX-1][25][i] = 2;
		}

	/* create two sample mobs */
	/* these are animated in the update() function */
		createMob(0, 50.0, 25.0, 52.0, 0.0);
		createMob(1, 50.0, 25.0, 52.0, 0.0);

	/* create sample player */
		createPlayer(0, 52.0, 27.0, 52.0, 0.0);
	} else {

	   //start building world 

		// initialize world to empty 
		for(i=0; i<WORLDX; i++){
			for(j=0; j<WORLDY; j++){
				for(k=0; k<WORLDZ; k++){
					world[i][j][k] = 0;
				}
			}
		}
		 
		//set initial view point a little lower than testworld
		setViewPosition(-50,-15,-45);

		//open pgm file to create world 
		FILE *fp;
		char buffer[100];

		fp = fopen("ground.pgm", "r");

		//if file opening failed
		if (fp == NULL) {
			perror("Failed opening file");
			return 1;
		}

		int xAxis = 0; //z value in world is x axis of file
		int yAxis = 0; //x value in world is y axis of file 
		int skipFirst4Lines = 0; //don't save the pgm parameters right now, skip first 4 lines in file

		//loop through lines in file that contain pixels 
		while ((fgets(buffer, 100, fp)) != NULL) {

			if (skipFirst4Lines < 4){
				skipFirst4Lines++;
			} else {
 
				strtok(buffer, "\n"); //remove new line gotten from fgets 

				char *token; //store seperate pixel values

				// get the first token in line (pixel),this is the y value for the world
				token = strtok(buffer, " ");

				//stores how many pixels found, since the file isn't stored at 100x100
				if (xAxis > 99) {
					xAxis = 0; //this is z value in world 
					yAxis++; //increase line number (y axis of file is trying to get 100x100, this is x value in world 
				}

				// walk through other tokens (pixels) in current file line 
				while( token != NULL ) {

					double modifiedY = strtod(token,NULL); //convert string to double
					modifiedY = modifiedY / 23; //may need to be modified, this scales the y value to fit between 0-49
					int newY = (int) modifiedY; //convert to int 
  
  					//fill in the boxes underneath each box, to avoid holes in the landscape, different color for different height (not yet) 
					for (int fill = 0;fill < newY;fill++){
						world[yAxis][fill][xAxis] = 6; //purple world
					}

					xAxis++; //go to next pixel number 

					//if 100 coordinates (pixels) found, increase yAxis of file
					if (xAxis > 99){
						xAxis = 0;
						yAxis++;
					}

					token = strtok(NULL," "); //next token (pixel) in line 
					
				} 

			} //end of else for skipFirst4Lines < 4
			
		} //end of while

		// build a floor, fills in holes as well, this is at level 0 
		for(i=0; i<WORLDX; i++) {
			for(j=0; j<WORLDZ; j++) {
				world[i][0][j] = 6;
			}
		}
		
		fclose(fp); //close file 

		//set human coordinates in global human array 
		fillHumanArray();

		//initalize time for human drawing
		clock_t startTime = clock();
		double elapsed = (double)startTime * 1000.0 / CLOCKS_PER_SEC;
		lastDrawnTime = elapsed;

		//initalize values for acceleration/deceleration
		momentumLeft = 0; //flag for momentum
		//determines momentum direction 
		increasingZ = 0;
		increasingX = 0; 
		increasingY = 0;

		//stores next momentum moves
		nextXMove = 0;
		nextYMove = 0;
		nextZMove = 0;

		//control and stores time for momentum 
		lastMovementTime = elapsed;
		lastKeyHitTime = elapsed;
		startMomentumClock = 0;

		//control and track rays drawn 
		for (i=0;i<numOfRaysInWorld;i++) {

			struct RayObject tempRay;

			tempRay.ID = i;
			tempRay.active = 0;
			tempRay.timeStarted = 0;

			tempRay.startPosX = 0.0;
			tempRay.startPosZ  = 0.0;
			tempRay.endPosX  = 0.0;
			tempRay.endPosZ  = 0.0;
	
			theRays[i] = tempRay;
		}

		rayCount = 0; //ray id, keeps track of which ray to create next

		//get random number generator ready for aliens
		srand(time(NULL));

		//add aliens to world 
		fillAlienArray();

		//initalize time for alien animation time 
		alienDrawnTime = elapsed;

		numOfAliensInWorld = 18; //used for looping for alien array 
		numOfRaysInWorld = 15;//used for looping through ray array 

		//make a new green color for alien
		setUserColour(9, 0.1, 0.5, 0.0, 1.0, 0.2, 0.2, 0.2, 1.0);

		//new colours for transformed aliens, red
		setUserColour(10, 0.8, 0, 0.3, 1.0, 0.2, 0.2, 0.2, 1.0);
		//control flashing colour chane for alien 
		colorChange = 1;

	}

	/* starts the graphics processing loop */
	/* code after this will not run until the program exits */
	glutMainLoop();
	return 0; 
}

