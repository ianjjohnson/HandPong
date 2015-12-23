import processing.video.*;

// Global variables
PImage prevFrame=null;
Capture currFrame=null;
PImage indicatorImage=null;
int captureFrameRate = 15;
float paddleHeight=100;
float leftPaddleX;
float leftPaddleY;
float rightPaddleX;
float rightPaddleY;
float leftToppestMotion;
float rightToppestMotion;
float prevLeftToppestMotion;
float prevRightToppestMotion;

float ballX;
float ballY;
float ballSize = 30;
float ballSpeedX = 1;
float ballSpeedY = 0.5;
// @TODO Start in a random direction, so it's fair to both players
float ballDirectionX = 10;
float ballDirectionY = 7;

void setup()
{
  size(640,480);
  
  frameRate(15);
  
  // We declare a capture (to hold the current frame) and a PImage (to hold the previous frame)
  currFrame = new Capture(this,width,height,captureFrameRate);
  currFrame.start();
  PImage prevFrame = null;
  
  // set up paddles to start in middle of each section
  leftPaddleX = width*0.15;
  leftPaddleY = height/2;
  rightPaddleX = width*0.85;
  rightPaddleY = height/2;
  
  // initialize toppest variables to height (lowest point)
 
 print("setup!");
  
  ballX = width/2;
  ballY = height/2;
}

void draw()
{
  
  println("draw");
  // every time around draw loop, reset toppest, so toppest doesn't get stuck at the top
  leftToppestMotion = height-1;
  rightToppestMotion = height-1;
  prevLeftToppestMotion = height-1;
  prevRightToppestMotion = height-1; 
  
  boolean gotAToppestLeft = false;
  boolean gotAToppestRight = false;
  
  background(0);
  
  // Check to see if a new video capture frame is available
  if (currFrame.available())
  {
    // If so, then read it and load the pixesl
    currFrame.read();
    
    /*
     * If we have a previous frame (prevFrame), then ...
     * 
     * Walk through all of the pixels of this frame (currFrame) and compare
     * them to the previous frame (prevFrame).  For each pixel, 
     * call the pixelDifference function to get the difference in the 
     * current pixel between prevFrame and this one.
     */
    if (prevFrame != null)
    {
      currFrame.loadPixels();
      prevFrame.loadPixels();
      loadPixels();
      
      // This is for testing Idea #1:
      // we set booleans for motionTopLeft, motionBottomLeft, motionTopRight, motionBottomRight
      
      for (int x = 0; x < width; x+=3)
      {
        if (x > width*0.3 && x < width*0.7) { continue; }
        for (int y = 0; y < height; y+=3)
        {
          // Turn 2D coordinate into 1D coordinate for pixels array
          int loc = width*y + (width-1-x);
           
           /* 
            * Here we get the pixel difference by calling the pixelDifference function and 
            * passing the RGB of this pixel in the current frame
            * and the RGB of this pixel in the previous frame to it, 
            */
            
          /*
           * We're going to calculate the average red in the "neighborhood" of this pixel
           * by looping over all pixels within 5 pixels (left/up to right/down).
           */
          float neighborhoodSumPrevRed = 0;
          float neighborhoodSumPrevGreen = 0;
          float neighborhoodSumPrevBlue = 0;
          float neighborhoodSumCurrRed = 0;
          float neighborhoodSumCurrGreen = 0;
          float neighborhoodSumCurrBlue = 0;
          float numberOfPixels = 0;
          
          int neighborhoodSize = 3;
          
          int leftMostNeighbor = x-neighborhoodSize; if (x-neighborhoodSize < 0) { leftMostNeighbor = 0; }
          int rightMostNeighbor = x+neighborhoodSize; if (x+neighborhoodSize >= width) { rightMostNeighbor = width-1; }
          int topMostNeighbor = y-neighborhoodSize; if (y-neighborhoodSize < 0) { topMostNeighbor = 0; }
          int bottomMostNeighbor = y+neighborhoodSize; if (y+neighborhoodSize >= height) { bottomMostNeighbor = height-1; }
          
          for (int x2 = leftMostNeighbor; x2 <= rightMostNeighbor; x2++)
          {  
            for (int y2 = topMostNeighbor; y2 < bottomMostNeighbor; y2++)
            {
              numberOfPixels++;
              int loc2 = width*y2 + x2;
              neighborhoodSumPrevRed += red(prevFrame.pixels[loc2]);
              neighborhoodSumPrevGreen += green(prevFrame.pixels[loc2]);
              neighborhoodSumPrevBlue += blue(prevFrame.pixels[loc2]);
              neighborhoodSumCurrRed += red(currFrame.pixels[loc2]);
              neighborhoodSumCurrGreen += green(currFrame.pixels[loc2]);
              neighborhoodSumCurrBlue += blue(currFrame.pixels[loc2]);
            }
          }

          float pixDiff = pixelDifference(neighborhoodSumPrevRed/numberOfPixels, 
                                          neighborhoodSumPrevGreen/numberOfPixels, 
                                          neighborhoodSumPrevBlue/numberOfPixels, 
                                          neighborhoodSumCurrRed/numberOfPixels, 
                                          neighborhoodSumCurrGreen/numberOfPixels,
                                          neighborhoodSumCurrBlue/numberOfPixels);                                      
            
          /*
           * Update toppest Y on each side -- remember left/right are flipped for mirroring in camera
           */          
          if (x < width*0.3 && y < rightToppestMotion && pixDiff > 0.3) { rightToppestMotion = y; gotAToppestRight = true; }
          if (x > width*0.7 && y < leftToppestMotion && pixDiff > 0.3) { leftToppestMotion = y; gotAToppestLeft = true; }
                      
          /*
           * If the pixel difference is greater than zero,
           * we set the current pixel in the indicator frame to white (255,255,255)
           * else we turn it black (0,0,0)
           */
          color c = color(pixDiff*255,pixDiff*255,pixDiff*255);
          pixels[loc] = c;
        }
      }
      updatePixels();    
      // image(currFrame, 0, 0); if (1==1) return;
    }
    else
    {
      // prevFrame is null, so this is the first time around in this loop
      prevFrame = createImage(width, height, RGB);
    }

          
    /*
     * Now we've moved the paddles, check they didn't go out of bounds
     */
    if (gotAToppestLeft) { leftPaddleY = leftPaddleY - (leftPaddleY - leftToppestMotion)/5; }
    if (gotAToppestRight) { rightPaddleY = rightPaddleY - (rightPaddleY - rightToppestMotion)/5; }


    /*
     * In this motion difference experiment, 
     * we only draw the paddles for testing, not complete pong.
     *
     * 
     * 
     */
    rect(leftPaddleX, leftPaddleY, 20, paddleHeight);
    rect(rightPaddleX, rightPaddleY, 20, paddleHeight);

    // move and draw the ball
    moveAndDrawBall();

    // for the next time around the loop, set prevFrame to currFrame
    prevFrame.copy(currFrame, 0, 0, width, height, 0, 0, width, height);
  } else {
    print("no good");
  }
}

/*
 * this function calculates the difference in a pixel between two frames.
 */

float pixelDifference (float prevRed, float prevGreen, float prevBlue, float currRed, float currGreen, float currBlue)
{
  float redDifference = Math.abs(prevRed-currRed);
  float greenDifference = Math.abs(prevGreen-currGreen);
  float blueDifference = Math.abs(prevBlue-currBlue);

  // if (redDifference > 50 && greenDifference > 50 && blueDifference > 50) { return 1; } else { return 0; }
  return (redDifference + greenDifference + blueDifference)/765;
}
 void keyPressed()
 {
 if (key=='e')
 { paddleHeight = 150 ;}
 if  (key== 'm')
 { paddleHeight = 100; }
 if (key== 'h')
 { paddleHeight = 50; }
 }
void moveAndDrawBall()
{
   
  ballX = ballX + ballDirectionX * ballSpeedX;
  ballY = ballY + ballDirectionY * ballSpeedY;
  
  // collision detection with walls
  if (ballX < 0 + ballSize/2) { ballX = ballSize; ballDirectionX *= -1; }
  if (ballX > width - ballSize/2) { ballX = width - ballSize; ballDirectionX *= -1; }
  if (ballY < 0 + ballSize/2) { ballY = ballSize; ballDirectionY *= -1; }
  if (ballY > height - ballSize/2) { ballY = height - ballSize; ballDirectionY *= -1; }
  
  // collision detection with paddles
  if (ballDirectionX < 0 && ballX < leftPaddleX + 20 + ballSize/2 && ballX > leftPaddleX && ballX<leftPaddleX+paddleHeight) { ballX = leftPaddleX + 20 + ballSize; ballDirectionX *= -1; }
  if (ballDirectionX > 0 && ballX > rightPaddleX - ballSize/2 && ballX > rightPaddleX && ballX<rightPaddleX+paddleHeight ) { ballX = rightPaddleX - ballSize; ballDirectionX *= -1; }
  
  ellipse(ballX, ballY, ballSize, ballSize);
}
