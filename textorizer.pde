/* textorizer12: vectorises a picture into an SVG using text strings
 * see: http://lapin-bleu.net/software/textorizer
 * Copyright Max Froumentin 2009
 * This software is distributed under the
 * W3C(R) SOFTWARE NOTICE AND LICENSE:
 * http://www.w3.org/Consortium/Legal/2002/copyright-software-20021231
 */

import guicomponents.*;
import java.util.List;
import java.io.*;
import javax.swing.*;

GWindow canvas;

// ====== Controls ======
int SliderWidth = 150;
String[] fontList = PFont.list();

// common controls
GHorzSlider bgOpacitySlider, outputWidthSlider;
GLabel imageNameLabel, svgFileLabel, outputImgFileLabel, currentFontLabel, aboutLabel;
GButton changeImageButton, outputImageChangeButton, svgChangeButton;
GCombo fontSelector;

// textorizer1 controls
GLabel textorizer1label, t1wordsFileName;
GHorzSlider t1numSlider, t1thresholdSlider, t1FontScaleMin, t1FontScaleMax;
GButton t1goButton, t1changeWordsButton;

// textorizer2 controls
GLabel textorizer2label, t2textFileName, t2textFileLabel; 
GHorzSlider t2lineHeight, t2textSize, t2colorAdjustment, t2kerningSlider, t2fontScaleFactorSlider;
GButton t2goButton, t2changeTextButton;



// ====== Input Image ======
PImage InputImage;
String InputImageFileName="jetlag.jpg";

// ====== visible frame (showing the output) ======
int FrameWidth=500, FrameHeight=350;

// ====== Output Image ======
CanvasWinData canvasData = new CanvasWinData();
PGraphics OutputImage = canvasData.img;
int OutputImageWidth = FrameWidth, OutputImageHeight = FrameHeight;
int OutputBackgroundOpacity=30;
String OutputImageFileName="textorizer.png";

String FontName="FFScala";
String T1WordsFileName="textorizer.txt";
String T2TextFileName="textorizer2.txt";
PFont Font;
String[] Words;
int NStrokes = 1000;
float Threshold=100;
float minFontScale=5;
float maxFontScale=30;

float T2LineHeight=1.0;
float T2FontSize=12.0;
float T2ColourAdjustment=0;
float T2Kerning=0;
float T2FontScaleFactor=1.5;


// =========================
int TextorizerMode=2; 
// 0: do nothing
// 1,2,3: textorizer version

Boolean NeedsRerendering = true;

// =========================

// Sobel convolution filter
float[][] Sx = {{-1,0,1}, {-2,0,2}, {-1,0,1}};
float[][] Sy = {{-1,-2,-1}, {0,0,0}, {1,2,1}};

// SVG export
String SvgFileName = "textorizer.svg";
StringBuffer SvgBuffer;
String[] SvgOutput;

// ========================
// Labels
String LabelChange = "change";
String LabelInputImageFileName = "Input image: ";
String LabelOutputWidth = "OUTPUT IMAGE SIZE";
String LabelBackgroundOpacity = "BACKGROUND OPACITY";
String LabelSVGOutputFileName = "SVG output file: ";
String LabelOutputImageFileName = "Output image: ";
String LabelFont = "Font: ";
String LabelSelectFont = "Select Font";
String LabelT1SeparatorIdle =  "---------------------- Textorizer 1 --------------------";
String LabelT2SeparatorIdle =  "---------------------- Textorizer 2 --------------------";
String LabelT1SeparatorRunning="----------------------- RENDERING --------------- ";
String LabelT2SeparatorRunning="----------------------- RENDERING --------------- ";
String LabelT1WordsFile = "Words file (TXT format): ";
String LabelT1NbStrokes = "Number of Strokes";
String LabelT1Threshold = "Threshold";
String LabelT1FontRange = "Font Range";
String LabelT1Go = "Textorize!";
String LabelT2Go = "Textorize2!";
String LabelT2TextSize = "Text Size";
String LabelT2LineHeight = "Line Height";
String LabelT2ColourSaturation = "Colour Saturation";
String LabelT2Kerning = "Kerning";
String LabelT2FontScale = "Font Scale";
String LabelT2TextFile = "Text file (TXT format): ";
String LabelInfo = "-- http://lapin-bleu.net/software/textorizer - max@lapin-bleu.net --";

// ########################

void loadWords(int mode) {
  String newWordsFileName;
  String[] newWords;

  switch(mode) {
  case 1: // textorizer 1
    newWordsFileName = selectInputFile(T1WordsFileName);
    newWords = loadStrings(newWordsFileName);
    if (newWords != null) {
      T1WordsFileName = newWordsFileName;
      Words = newWords;
      setTextLabelValue(t1wordsFileName, LabelT1WordsFile+T1WordsFileName);
    }
    break;
  case 2: // textorizer 2
    newWordsFileName = selectInputFile(T2TextFileName);
    newWords = loadStrings(newWordsFileName);
    if (newWords != null) {
      T2TextFileName = newWordsFileName;
      Words = newWords;
      setTextLabelValue(t2textFileName, LabelT2TextFile+T2TextFileName);
    }
    break;
  }
}

PImage loadInputImage(String filename) {
  String newImageFileName = selectInputFile(filename);
  PImage newImage = loadImage(newImageFileName);

  if (newImage!=null && newImage.width!=-1 && newImage.height!=-1) {
    InputImageFileName=newImageFileName;
    loadPixels(); 
    changeImageButton.setText(newImageFileName.substring(newImageFileName.lastIndexOf("/")+1));
  }
  return newImage;
}

void setup() {
  int ypos = 10;

  // Size has to be the very first statement, or setup() will be run twice
  size(300,515);

//  frame.setResizable(true);  // call draw() when the window is resized
//  frame.addComponentListener(new ComponentAdapter() { 
//    public void componentResized(ComponentEvent e) { 
//      if(e.getSource()==frame) { 
//        redraw();
//      } 
//    } 
//  });

//  background(0);
//  stroke(1);
//  fill(0);
//  imageMode(CENTER);
//  smooth();
//  noLoop();


  InputImage = loadImage(InputImageFileName);
  loadPixels();
  Font = createFont(FontName, 32);


  //  G4P.setFont(this, "Serif", 14);
  G4P.setColorScheme(this, GCScheme.GREEN_SCHEME);
  canvas = new GWindow(this,"Textorizer",500,0,FrameWidth,FrameHeight,false,P2D);
  canvas.addData(canvasData);
  canvas.addDrawHandler(this,"canvasDraw");
  //  controlWindow.setUpdateMode(ControlWindow.NORMAL);
  //  controlWindow.addDrawHandler(this,"controlWindowDraw");

  // common controls
  imageNameLabel  = new GLabel(this,LabelInputImageFileName,10,ypos,100);
  changeImageButton  = new GButton(this,InputImageFileName,83,ypos,200,12);
  changeImageButton.setTextAlign(GAlign.LEFT);

  ypos+=20; 
  outputWidthSlider = new GHorzSlider(this,10,ypos,SliderWidth,15);
  outputWidthSlider.setLimits((float)OutputImageWidth,100.0,5000.0);

  ypos+=20; 
  bgOpacitySlider = new GHorzSlider(this,10,ypos,SliderWidth,15);
  bgOpacitySlider.setLimits((float)OutputBackgroundOpacity,0.0,255.0);

  ypos+=25; 
  svgFileLabel = new GLabel(this,LabelSVGOutputFileName+SvgFileName,50,ypos,50);
  svgChangeButton = new GButton(this,LabelChange,10,ypos-3,37,12); 

  ypos+=20; 
  outputImgFileLabel = new GLabel(this,LabelOutputImageFileName+OutputImageFileName,50, ypos, 50); 
  outputImageChangeButton = new GButton(this,LabelChange,10,ypos-3,37,12);

  ypos+=20;
  currentFontLabel = new GLabel(this,LabelFont+FontName,10,ypos,50); 

  ypos+=20; 
  fontSelector = new GCombo(this,fontList,fontList.length,10,ypos,200);


  // Textorizer 1 controls
  ypos+=110;
  textorizer1label = new GLabel(this,LabelT1SeparatorIdle, 10,ypos,50);

  ypos+=20;
  t1numSlider = new GHorzSlider(this,10,ypos,SliderWidth,15);
  t1numSlider.setLimits(1000.0,100.0,10000.0);

  ypos+=20; 
  t1thresholdSlider = new GHorzSlider(this,10,ypos,SliderWidth,15);
  t1thresholdSlider.setLimits((float)SliderWidth,0.0,200.0);

  ypos+=20;
  t1FontScaleMin = new GHorzSlider(this,10,ypos,SliderWidth,15);
  t1FontScaleMin.setLimits(minFontScale,0.0,50.0);
  

  ypos+=20;
  t1FontScaleMax = new GHorzSlider(this,10,ypos,SliderWidth,15);
  t1thresholdSlider.setLimits(maxFontScale,0.0,50.0);

  ypos+=20; 
  t1changeWordsButton = new GButton(this,LabelChange,10,ypos-3,37,12); 

  t1wordsFileName = new GLabel(this,((T1WordsFileName==null)?"":LabelT1WordsFile+T1WordsFileName),50,ypos, 50);

  ypos+=15;
  t1goButton = new GButton(this, LabelT1Go, 240,300, 50,20);


  // Textorizer 2 controls
  ypos+=10;
  textorizer2label = new GLabel(this, LabelT2SeparatorIdle, 10,ypos,100);

  ypos+=20;
  t2textSize = new GHorzSlider(this,10,ypos,SliderWidth,15);
  t2textSize.setLimits(T2FontSize,4.0,50.0);
  
  ypos+=20;
  t2lineHeight = new GHorzSlider(this,10,ypos,SliderWidth,15);
  t2lineHeight.setLimits(T2LineHeight,0.5,3.0);

  ypos+=20;
  t2colorAdjustment = new GHorzSlider(this,10,ypos,SliderWidth,15);
  t2colorAdjustment.setLimits(T2ColourAdjustment,0.0,255.0);

  ypos+=20;
  t2kerningSlider = new GHorzSlider(this,10,ypos, SliderWidth,15);
  t2kerningSlider.setLimits(T2Kerning,-.5,.5);

  ypos+=20;
  t2fontScaleFactorSlider = new GHorzSlider(this,10,ypos, SliderWidth,15);
  t2fontScaleFactorSlider.setLimits(T2FontScaleFactor,0.0,5.0);

  ypos+=27; 
  t2changeTextButton = new GButton(this,LabelChange,10,ypos-3, 37, 12); 
  t2textFileName = new GLabel(this,((T2TextFileName==null)?"":LabelT2TextFile+T2TextFileName), 50,ypos, 50);

  t2goButton=new GButton(this,LabelT2Go,235,440, 55,20); 

  // info label
  ypos+=25; 
  aboutLabel = new GLabel(this,LabelInfo, 0,ypos,100);

}

void go() 
{
  if (TextorizerMode != 0) {
    OutputImage = createGraphics(OutputImageWidth, OutputImageHeight, P2D);
    OutputImage.beginDraw();
    OutputImage.background(255);
    OutputImage.smooth();
    setupSvg();
    setupFont();
    setupBgPicture();
    
    switch(TextorizerMode) {
      case 1: textorize(); break;
      case 2: textorize2(); break;
    }
    OutputImage.endDraw();
    OutputImage.save(OutputImageFileName);
  }
}

void draw()
{
  background(0,192,0);
}

void canvasDraw(GWinApplet appc, GWinData data)
{
  appc.imageMode(CENTER);
  appc.noLoop();
  appc.background(255);
  appc.cursor(WAIT);
  cursor(WAIT);

  if (NeedsRerendering) {
    go();
    NeedsRerendering=false;
  }

  // fit the image best in the window
  int fittingWidth, fittingHeight;

  if (width >= OutputImageWidth && height >= OutputImageHeight) {
    fittingWidth = OutputImageWidth;
    fittingHeight = OutputImageHeight;
  } else {
    if (float(width)/height > (float)OutputImageWidth/OutputImageHeight) {
      fittingHeight = height;
      fittingWidth = fittingHeight*OutputImageWidth/OutputImageHeight;
    } else {
      fittingWidth = width;
      fittingHeight = fittingWidth*OutputImageHeight/OutputImageWidth;
    }
  }

  appc.image(OutputImage, FrameWidth/2, FrameHeight/2, fittingWidth, fittingHeight);

  appc.cursor(ARROW);
  cursor(ARROW);
}

void setupSvg() {
  SvgBuffer = new StringBuffer(4096);
  SvgBuffer.append("<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1//EN\" \"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd\">\n");
  SvgBuffer.append("<svg width='100%' height='100%' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' viewBox='0 0 "+width+" "+height+"'>\n");
}

void setupFont() {
  // font
  OutputImage.textFont(Font);
  switch(TextorizerMode) {
  case 1:
    textAlign(CENTER);
    SvgBuffer.append("<g style='font-family:"+FontName+";font-size:32' text-anchor='middle'>\n");
    break;
  case 2:
    textAlign(LEFT);
    SvgBuffer.append("<g style='font-family:"+FontName+";font-size:32'>\n");
    break;
  }
}

void setupBgPicture() {
  // add background picture with requested level of opacity
  OutputImage.tint(255,OutputBackgroundOpacity);
  OutputImage.image(InputImage,0,0,OutputImageWidth,OutputImageHeight);
  SvgBuffer.append("<image x='0' y='0' width='"+OutputImageWidth+"' height='"+OutputImageHeight+"' opacity='"+OutputBackgroundOpacity/255.0+"' xlink:href='"+InputImageFileName+"'/>\n");
}

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
void textorize() {
  int x,y,tx,ty, progress;
  float dx,dy,dmag2,vnear,b,textScale,dir,r;
  color v,p;
  String word;
    
  fill(128);
  Words=loadStrings(T1WordsFileName);
  OutputImage.textFont(Font);

  for (int h=0; h<NStrokes;h++) {
    progress = 1+int(100.0*h/NStrokes);
    setTextLabelValue(textorizer1label, LabelT1SeparatorRunning + progress + "%");

    x=int(random(2,InputImage.width-3));
    y=int(random(2,InputImage.height-3));
    v=InputImage.pixels[x+y*InputImage.width];

    OutputImage.fill(v);
    dx=dy=0;
    for (int i=0; i<3; i++) {
      for (int j=0; j<3; j++) {
        p=InputImage.pixels[(x+i-1)+InputImage.width*(y+j-1)];
        vnear=brightness(p);
        dx += Sx[j][i] * vnear;
        dy += Sy[j][i] * vnear;
      }  
    }
    dx/=8; dy/=8;
    
    dmag2=dx*dx + dy*dy;
    
    if (dmag2 > Threshold) {
      b = 2*(InputImage.width + InputImage.height) / 5000.0;
      textScale=minFontScale+sqrt(dmag2)*maxFontScale/80;
      if (dx==0)
        dir=PI/2;
      else if (dx > 0)
        dir=atan(dy/dx);
      else 
        if (dy==0) 
          dir=0;
        else if (dy > 0)
          dir=atan(-dx/dy)+PI/2;
        else
          dir=atan(dy/dx)+PI;
      OutputImage.textSize(textScale);
      
      OutputImage.pushMatrix();
      tx=int(float(x)*OutputImageWidth/InputImage.width);
      ty=int(float(y)*OutputImageHeight/InputImage.height);
      r=dir+PI/2;
      word=(String)(Words[h % Words.length]);
      
      // screen output
      OutputImage.translate(tx,ty);
      OutputImage.rotate(r);
      OutputImage.fill(v);
      OutputImage.text(word, 0,0);
      OutputImage.stroke(1.0,0.,0.);
      OutputImage.popMatrix();
      
      // SVG output
      SvgBuffer.append("<text transform='translate("+tx+","+ty+") scale("+textScale/15.0+") rotate("+r*180/PI+")' fill='rgb("+int(red(v))+","+int(green(v))+","+int(blue(v))+")'>"+word+"</text>\n");
      
    }
  }
  
  SvgBuffer.append("</g>\n</svg>\n");
  SvgOutput=new String[1];
  SvgOutput[0]=SvgBuffer.toString();
  saveStrings(SvgFileName, SvgOutput);
}

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

void handleButtonEvents(GButton button) {

  if(button == changeImageButton) {
    InputImage = loadInputImage(InputImageFileName);
  } else if(button == svgChangeButton) { // 8
    SvgFileName = selectOutputFile(SvgFileName);
    setTextLabelValue(svgFileLabel,"SVG Output File: "+SvgFileName);
  } else if(button == outputImageChangeButton) { //9
    String s;
    OutputImageFileName = selectOutputFile(OutputImageFileName);
    setTextLabelValue(outputImgFileLabel, OutputImageFileName);
  } else if(button == t1goButton) { // 10
    TextorizerMode=1;
    NeedsRerendering=true;
    redraw();
  } else if(button == t1changeWordsButton) { // 11
    loadWords(1);
  } else if(button == t2goButton) { // 103
    TextorizerMode=2;
    NeedsRerendering=true;
    redraw();
  } else if(button == t2changeTextButton) { //104
    loadWords(2);
  }
}

void handleSliderEvents(GSlider slider) {
  if (slider == t1numSlider) { // 1
    NStrokes = slider.getValue();
  } else if (slider == t1thresholdSlider) { // 2
    Threshold = slider.getValuef();
  } else if (slider == bgOpacitySlider) { // 3
    OutputBackgroundOpacity = slider.getValue();
  } else if (slider == outputWidthSlider) { // 5
    OutputImageWidth = slider.getValue();
    OutputImageHeight = OutputImageWidth * InputImage.height / InputImage.width;
  } else if (slider == t1FontScaleMin) { // 4
    minFontScale = slider.getValuef();
    if (minFontScale > maxFontScale) {
      minFontScale=maxFontScale;
      slider.setValue(minFontScale);
    }
  } else if (slider == t1FontScaleMax) { // 4
    maxFontScale = slider.getValuef();
    if (minFontScale > maxFontScale) {
      maxFontScale=minFontScale;
      slider.setValue(maxFontScale);
    }
  } else if (slider == t2lineHeight) { // 100
    T2LineHeight = slider.getValuef();
  } else if (slider == t2textSize) { // 101
    T2FontSize = slider.getValuef();
  } else if (slider == t2colorAdjustment) { // 102
    T2ColourAdjustment = slider.getValuef();
  } else if (slider == t2kerningSlider) { // 105
    T2Kerning = slider.getValuef();
  } else if (slider == t2fontScaleFactorSlider) { // 106
    T2FontScaleFactor = slider.getValuef();
  }  
}

public void handleOptionEvents(GOption selected, GOption deselected){
  ;
};

void handleComboEvents(GCombo combo){
  if (combo == fontSelector) {
    // Get font name and size from
    String[] fs = combo.selectedText().split(" ");
    FontName = fs[0];
    Font = createFont(FontName,32);
  }
}	


String selectInputFile(String defaultName)
{
  String s;
  return ((s=selectInput())!=null) ? s : defaultName;
}

String selectOutputFile(String defaultName)
{
  String s;
  return ((s=selectOutput())!=null) ? s : defaultName;
}


// %%%%% Textorizer 2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


void textorize2()
{
  StringBuffer textbuffer = new StringBuffer();
  String text;

  Words=loadStrings(T2TextFileName);
  fill(128);

  textbuffer.append(Words[0]);
  for (int i=1;i<Words.length;i++) {
    textbuffer.append(' ');
    textbuffer.append(Words[i]);
  }
  text=textbuffer.toString();

  OutputImage.textFont(Font);

  int nbletters = text.length();
  int ti=0, progress;
  float x,y;
  float scale, r,g,b;
  char c, charToPrint;
  color pixel;
  float imgScaleFactorX = float(InputImage.width)/OutputImageWidth;
  float imgScaleFactorY = float(InputImage.height)/OutputImageHeight;

  for (y=0; y < OutputImageHeight; y+=T2FontSize*T2LineHeight) {
    progress = 1+int(100*y/OutputImageHeight);
    //    setTextLabelValue(textorizer2label, LabelT2SeparatorRunning + progress + "%");

    x=0;

    // skip any white space at the beginning of the line
    while (text.charAt(ti%nbletters) == ' ') ti++; 


    while (x<OutputImageWidth) {

      pixel = pixelAverageAt(int(x*imgScaleFactorX), int(y*imgScaleFactorY), int(T2FontSize*T2FontScaleFactor/6));

      r=red(pixel); g=green(pixel); b=blue(pixel);

      scale=2-brightness(pixel)/255.0;
      c=text.charAt(ti%nbletters);

      if (r+g+b<3*255) { // eliminate white 

        charToPrint=c;
        color charColour = color(r,g,b);
        if (T2ColourAdjustment>0) {
          float saturation = OutputImage.saturation(charColour);
          float newSaturation = (saturation+T2ColourAdjustment)>255?255:(saturation+T2ColourAdjustment);
          OutputImage.colorMode(HSB,255);
          charColour = color(hue(charColour), newSaturation, brightness(charColour));
          OutputImage.fill(charColour);
          OutputImage.colorMode(RGB,255);
        } else {
          OutputImage.fill(charColour);
        }

        // empirically shift letter to the top-left, since sampled pixel is on its top-left corner
        float realX = x-T2FontSize/2.0, realY = y+3+T2FontSize*T2LineHeight-T2FontSize/4.0;

        OutputImage.textSize(T2FontSize * (1 + T2FontScaleFactor*pow(scale-1,3)));
        OutputImage.text(charToPrint, int(realX), int(realY));

        r=red(charColour); g=green(charColour); b=blue(charColour);
        SvgBuffer.append("<text x='"+realX+"' y='"+realY+"' font-size='"+(T2FontSize*scale)+"' fill='rgb("+int(r)+","+int(g)+","+int(b)+")'>"+charToPrint+"</text>\n");
        
        x+=OutputImage.textWidth(Character.toString(c)) * (1+T2Kerning);
        ti++; // next letter
      } 
      else {
        // advance one em 
        x+=OutputImage.textWidth(" ") * (1+T2Kerning);
      }
    }
  }

  // framing rectangle
  // 1. processing
  // 4 rectangles, etc.

  // 2. SVG
  // Should be a clipping path, but no FF support
  float outerFrameWidth=200;
  float innerFrameWidth=2;
  r=(outerFrameWidth-innerFrameWidth)/2;

  SvgBuffer.append("</g>\n<rect x='-"+r+"' y='-"+r+"' width='"+(OutputImageWidth+2*r)+"' height='"+(OutputImageHeight+2*r)+"' fill='none' stroke='white' stroke-width='"+(outerFrameWidth+innerFrameWidth)+"'/>\n\n</svg>\n");

  SvgOutput=new String[1];
  SvgOutput[0]=SvgBuffer.toString();
  saveStrings(SvgFileName, SvgOutput);
}

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// return the image's pixel value at x,y, averaged with its radiusXradius neighbours.

color pixelAverageAt(int x, int y, int radius) 
{
  color pixel;
  float resultR=0.0, resultG=0.0, resultB=0.0;
  int count=0;
  for (int i=-radius; i<=radius; i++) {
    for (int j=-radius; j<=radius; j++) {
      if (x+i>=0 && x+i<InputImage.width && y+j>=0 && y+j<InputImage.height) {
        count++;
        pixel=InputImage.pixels[(x+i)+InputImage.width*(y+j)]; 
        resultR+=red(pixel);
        resultG+=green(pixel);
        resultB+=blue(pixel);
      }
    }
  }
  return color(resultR/count, resultG/count, resultB/count);
}

/*
 * This function should be used instead of TextLabel.setValue which will throw an exception when passed a non-ascii string
 */
void setTextLabelValue(GLabel label, String text) {
  label.setText(text.replaceAll("[^\\p{ASCII}]", " "));
}


class CanvasWinData extends GWinData {
  public PGraphics img;
}
