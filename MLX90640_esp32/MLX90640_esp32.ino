#include <Adafruit_MLX90640.h>
#include <Wire.h>

Adafruit_MLX90640 mlxLeft;
Adafruit_MLX90640 mlxRight;
float frameLeft[32*24];
float frameRight[32*24];
float frame[1536];
float finalFrame[1536];


#define SDA_1 27
#define SCL_1 26

#define SDA_2 33
#define SCL_2 32

TwoWire I2Cone = TwoWire(0);
TwoWire I2Ctwo = TwoWire(1);

void setup() {

  I2Cone.begin(SDA_1, SCL_1, 800000); 
  I2Ctwo.begin(SDA_2, SCL_2, 800000);
  
  while (!Serial) delay(10);
  Serial.begin(250000);
  delay(100);


  if (! mlxLeft.begin(MLX90640_I2CADDR_DEFAULT, &I2Cone) || ! mlxRight.begin(MLX90640_I2CADDR_DEFAULT, &I2Ctwo)) {
    Serial.println("MLX90640 not found!");
    while (1) delay(10);
  }
  

  mlxLeft.setMode(MLX90640_CHESS);
  mlxLeft.setResolution(MLX90640_ADC_18BIT);
  mlxLeft.setRefreshRate(MLX90640_16_HZ);

  mlxRight.setMode(MLX90640_CHESS);
  mlxRight.setResolution(MLX90640_ADC_18BIT);
  mlxRight.setRefreshRate(MLX90640_16_HZ);

}

void loop() {
  mlxLeft.getFrame(frameLeft);
  mlxRight.getFrame(frameRight);
  for (int i = 0; i < 24; i++)
  {
    for (int j = 0; j < 32; j++)
    {
      frame[64*i + j] = frameRight[32*i + j];;
    }
  }

  for (int i = 0; i < 24; i++)
  {
    for (int j = 0; j < 32; j++)
    {
      frame[64*i + 32 + j] = frameLeft[32*i + j];
    }
  }

  Serial.print(",");
  for (int i = 0; i < 1536; i++)
  {
    finalFrame[i] = frame[1535-i];
    Serial.print(finalFrame[i], 2);
    Serial.print(",");
  }
  Serial.println("");

}
