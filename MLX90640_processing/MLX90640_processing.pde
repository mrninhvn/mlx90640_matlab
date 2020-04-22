import processing.serial.*;

String myString = null;
Serial myPort;  // The serial port

float[] temps = new float[1536];
String splitString[] = new String[2000];
float maxTemp = 0;
float minTemp = 500;

// The statements in the setup() function 
// execute once when the program begins
void setup() {
  size(1280, 520);  // Size must be the first statement
  noStroke();
  frameRate(30);
  
  // Print a list of connected serial devices in the console
  printArray(Serial.list());
  // Depending on where your sensor falls on this list, you
  // may need to change Serial.list()[0] to a different number
  myPort = new Serial(this, Serial.list()[0], 250000);
  myPort.clear();
  // Throw out the first chunk in case we caught it in the 
  // middle of a frame
  myString = myPort.readStringUntil(13);
  myString = null;
  // change to HSB color mode, this will make it easier to color
  // code the temperature data
  colorMode(HSB, 360, 100, 100);
}

// The statements in draw() are executed until the 
// program is stopped. Each statement is executed in 
// sequence and after the last line is read, the first 
// line is executed again.
void draw() { 
  
  // When there is a sizeable amount of data on the serial port
  // read everything up to the first linefeed
  if(myPort.available() > 10000){
  myString = myPort.readStringUntil(13);
  
  // Limit the size of this array so that it doesn't throw
  // OutOfBounds later when calling "splitTokens"
  //if(myString.length() > 9216){
  //myString = myString.substring(0, 9216);}
  
  // generate an array of strings that contains each of the comma
  // separated values
  splitString = splitTokens(myString, ",");
  
  // Reset our min and max temperatures per frame
  maxTemp = 0;
  minTemp = 500;
  
  // For each floating point value, double check that we've acquired a number,
  // then determine the min and max temperature values for this frame
  for(int q = 0; q < 1536; q++){
    
    if(!Float.isNaN(float(splitString[q])) && float(splitString[q]) > maxTemp){
      maxTemp = float(splitString[q]);
    }else if (!Float.isNaN(float(splitString[q])) && float(splitString[q]) < minTemp){
      minTemp = float(splitString[q]);
    }
    
  }  
  
  // for each of the 1536 values, map the temperatures between min and max
  // to the blue through red portion of the color space
  for(int q = 0; q < 1536; q++){
    
    if(!Float.isNaN(float(splitString[q]))){
    temps[q] = constrain(map(float(splitString[q]), minTemp, maxTemp, 180, 360),160,360);}
    else{
    temps[q] = 0;
    }
    
  }
  }
  
  
  // Prepare variables needed to draw our heatmap
  int x = 0;
  int y = 0;
  int i = 0;
  background(0);   // Clear the screen with a black background
  
  

  while(y < 480){
  
    
  // for each increment in the y direction, draw 8 boxes in the 
  // x direction, creating a 64 pixel matrix
  while(x < 1280){
  // before drawing each pixel, set our paintcan color to the 
  // appropriate mapped color value
  fill(temps[i], 100, 100);
  rect(x,y,20,20);
  x = x + 20;
  i++;
  }
  
  y = y + 20;
  x = 0;
  }
  
  // Add a gaussian blur to the canvas in order to create a rough
  // visual interpolation between pixels.
  filter(BLUR,7);
  
  // Generate the legend on the bottom of the screen
  textSize(32);
  
  // Find the difference between the max and min temperatures in this frame
  float tempDif = maxTemp - minTemp; 
  // Find 5 intervals between the max and min
  int legendInterval = round(tempDif / 5); 
  // Set the first legend key to the min temp
  int legendTemp = round(minTemp);
  
  // Print each interval temperature in its corresponding heatmap color
  for(int intervals = 0; intervals < 6; intervals++){
  fill(constrain(map(legendTemp, minTemp, maxTemp, 180, 360),160,360), 100, 100);
  text(legendTemp+"°", 70*intervals, 510);
  legendTemp += legendInterval;
  }
  
} 
