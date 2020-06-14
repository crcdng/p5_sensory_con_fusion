/** //<>//
 * Sensory Con-Fusion experiment 1 by @crcdng
 * audio confuses video (unidirectional)
 * requirements: camera, microphone
 * starting points: various processing samples (AudioInput, FFTSpectrum, Mirror by Daniel Shiffman) 
 * switch modes: 1 = amplitude (size) only, 2 = amplitude + frequency (rotation)
 * -
 * known issues:
 * - the sketch can take a few seconds to initialize. During this time the screen is grey. 
 * - the fullscreen mode does not exit until you click Stop on the IDE.
 * - performance
 * -
 * - to run with Processing 3.5.4 on Mac OSX 15 Catilina follow
 * - https://gist.github.com/i3games/b063987dfb62baf5d0afda422631b480
 * - to run with the old Video library 1.0.1 see setup()
 */

import processing.video.*;
import processing.sound.*;

int mode, MODE_AMPLITUDE = 1, MODE_AMP_FREQ = 2;

int cellSize = 1, diffCellSize = 0, minimumCellSize = 2; // for performance reasons 
int cols, rows;
Capture video;
int videoWidth;

AudioIn audioInA, audioInB;
Amplitude rms;
float volumeIn = 1.0; // [0.0, 1.0]

FFT fft;
int bands = 128;
float[] spectrum = new float[bands];

int sampleInterval = 12;
int updateInterval = 3;

void setup() {
  // best in:
  // fullScreen();
  // alternative 
  size(800, 600);
  frameRate(30);
  colorMode(RGB, 255, 255, 255, 100);

  // to select the microphone, use this:
  // Sound s = new Sound(this);
  // Sound.list();
  // s.inputDevice(0); // replace 0 by the number of your microphone
  
  // Video library 2.0-beta-4, Mac OSX 15 Catilina
  String[] cameras = Capture.list();
  video = new Capture(this, width, height, cameras[0]);

  // Video library 1.0.1 
  video = new Capture(this, width, height);

  video.start();   
  videoWidth = video.width;
  cols = width / cellSize;
  rows = height / cellSize;

  // two separate AudioIn are needed
  audioInA = new AudioIn(this, 0);
  audioInB = new AudioIn(this, 0);
  audioInA.start(volumeIn);
  audioInB.start(volumeIn);

  fft = new FFT(this, bands);
  fft.input(audioInA);
  rms = new Amplitude(this);
  rms.input(audioInB);
  
  mode = MODE_AMPLITUDE;
}

void draw() {   
  if (video.available()) {
    video.read();
    video.loadPixels();

    if (frameCount % sampleInterval == 0) { // sample audio 
      diffCellSize = calcDiffCellSize(rms.analyze(), cellSize, (sampleInterval / updateInterval));
      if (mode == MODE_AMP_FREQ) { fft.analyze(spectrum); }
    }

    if (frameCount % updateInterval == 0) { // update size
      cellSize = calcCellSize(cellSize, diffCellSize);
      cols = width / cellSize;
      rows = height / cellSize;
    }

     for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
  
        int x = c * cellSize;
        int y = r * cellSize;
        int loc = (videoWidth - x - 1) + y * videoWidth; // mirror the image

        color videocolor = video.pixels[loc];      
        color fillcolor = color(red(videocolor), green(videocolor), blue(videocolor), 75); // add transparency

        // Using translate in order for rotation to work properly
        pushMatrix();
        translate(x + cellSize / 2, y + cellSize / 2);

        if (mode == MODE_AMP_FREQ) { 
          if (frameCount % updateInterval == 0) { // update rotation
            int band = int(map(c + r * cols, 0, rows * cols, 0, bands - 1)); // map row, column to a frequency band       
            float s = map(spectrum[band], 0.000001, 0.001, 0, 1); // then scale the spectrum values 
            rotate(PI/4 * s); // then rotate [0..45] degrees 
          }
        }

        rectMode(CENTER);
        fill(fillcolor);
        noStroke();
        // Rects are larger than the cell for some overlap
        rect(0, 0, cellSize+6, cellSize+6);
        popMatrix();
      }
    }
  }
}

void exit() {
  video.stop();
}

void keyPressed() {
  if (keyCode == '1') {
    mode = MODE_AMPLITUDE;
  } else if (keyCode == '2') {
    mode = MODE_AMP_FREQ;  
  }
}

int calcCellSize(int current, int diff) { 
  int result = max(minimumCellSize, current + diff); 
  // println(" diff: " + diff + " new cell size: " + result);
  return result; // return new cell size
}

int calcDiffCellSize(float in, int current, int steps) { 
  int lower = 1, upper = 1500;
  float target = map(in, 0, 1, lower, upper);
  int diff = round((target - current) / float(steps));
  // println(" in: " + in + " targetCellSize: " + result);
  return diff; // return new target cell size
}
