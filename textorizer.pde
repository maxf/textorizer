/* textorizer12: vectorises a picture into an SVG using text strings
 * see: http://lapin-bleu.net/software/textorizer
 * Copyright Max Froumentin 2009
 * This software is distributed under the
 * W3C(R) SOFTWARE NOTICE AND LICENSE:
 * http://www.w3.org/Consortium/Legal/2002/copyright-software-20021231
 */

import controlP5.*;
import java.util.List;
import java.io.*;
import javax.swing.*;

// ====== Controls ======
ControlP5 controlP5;
ControlWindow controlWindow; // the controls must be in a separate window, since the controls window must refresh constantly, while the rendering window only refreshes when you tell it to.
int SliderWidth = 150;
String[] fontList = PFont.list();
// common controls
Controller bgOpacitySlider, imageNameLabel, svgFileLabel, outputImgFileLabel, changeImageButton, outputImageChangeButton, svgChangeButton, textorizer1label, textorizer2label, currentFontLabel, outputWidthSlider;
ScrollList fontSelector;

// textorizer1 controls
Controller t1numSlider, t1thresholdSlider, t1FontScaleRange, t1goButton, t1wordsFileName, t1changeWordsButton;

// textorizer2 controls
Controller t2lineHeight, t2textSize, t2colorAdjustment, t2goButton, t2textFileName, t2textFileLabel, t2changeTextButton, t2kerningSlider, t2fontScaleFactorSlider;



// ====== Input Image ======
PImage InputImage;
String InputImageFileName="jetlag.jpg";

// ====== visible frame (showing the output) ======
int FrameWidth=500, FrameHeight=350;

// ====== Output Image ======
PGraphics OutputImage;
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
String LabelChange = "CHANGE";
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
      setTextLabelValue((Textlabel)t1wordsFileName, LabelT1WordsFile+T1WordsFileName);
    }
    break;
  case 2: // textorizer 2
    newWordsFileName = selectInputFile(T2TextFileName);
    newWords = loadStrings(newWordsFileName);
    if (newWords != null) {
      T2TextFileName = newWordsFileName;
      Words = newWords;
      setTextLabelValue((Textlabel)t2textFileName, LabelT2TextFile+T2TextFileName);
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
    setTextLabelValue((Textlabel)imageNameLabel, "Input Image: "+newImageFileName);
  }
  return newImage;
}

void setup() {
  int ypos = 10;

  // Size has to be the very first statement, or setup() will be run twice
  size(FrameWidth, FrameHeight);

  frame.setResizable(true);  // call draw() when the window is resized
  frame.addComponentListener(new ComponentAdapter() { 
    public void componentResized(ComponentEvent e) { 
      if(e.getSource()==frame) { 
        redraw();
      } 
    } 
  });

  background(0);
  stroke(1);
  fill(0);
  imageMode(CENTER);
  smooth();
  noLoop();


  InputImage = loadImage(InputImageFileName);
  loadPixels();
  Font = createFont(FontName, 32);

  controlP5 = new ControlP5(this);
  controlWindow = controlP5.addControlWindow("Textorizer",300,515);
  controlWindow.setBackground(color(100));
  controlWindow.setUpdateMode(ControlWindow.NORMAL);

  // common controls
  imageNameLabel  = controlP5.addTextlabel("imageNameLabel",LabelInputImageFileName+InputImageFileName, 50,ypos);
  changeImageButton  = controlP5.addButton("changeImageButton",4, 10, ypos-3, 37, 12);
  changeImageButton.setLabel(LabelChange);


  ypos+=15; outputWidthSlider = controlP5.addSlider("outputWidthSlider",100,5000, OutputImageWidth, 10,ypos,SliderWidth,15);
  outputWidthSlider.setLabel(LabelOutputWidth);
  ypos+=20; bgOpacitySlider = controlP5.addSlider("Background Opacity",0,255, OutputBackgroundOpacity, 10,ypos, SliderWidth ,15); 

  ypos+=25; 
  svgFileLabel = controlP5.addTextlabel("svgFileLabel", 
                                        LabelSVGOutputFileName+SvgFileName,50,ypos);
  svgChangeButton = controlP5.addButton("svgChangeButton",4,10,ypos-3,37,12); 
  svgChangeButton.setLabel(LabelChange);

  ypos+=20; 
  outputImgFileLabel = 
    controlP5.addTextlabel("OutputImageFileName",
                           LabelOutputImageFileName+OutputImageFileName,
                           50, ypos); 
  outputImageChangeButton = controlP5.addButton("outputImageChangeButton",
                                                4,10,ypos-3,37,12);
  outputImageChangeButton.setLabel(LabelChange);


  ypos+=20;
  currentFontLabel = controlP5.addTextlabel("currentFontLabel",
                                            LabelFont+FontName,10,ypos); 
  ypos+=20; 
  fontSelector = controlP5.addScrollList(LabelSelectFont,10,ypos, 200,100); 

  for (int i=0;i<fontList.length;i++) {
    String fontNameAscii = fontList[i].replaceAll("[^\\p{ASCII}]", " ");
    controlP5.Button b=fontSelector.addItem(fontNameAscii,i);
    b.setId(1000+i);
  }

  ypos+=110;
  imageNameLabel.setWindow(controlWindow);
  changeImageButton.setWindow(controlWindow);
  svgFileLabel.setWindow(controlWindow);
  svgChangeButton.setWindow(controlWindow);
  outputImgFileLabel.setWindow(controlWindow);
  outputImageChangeButton.setWindow(controlWindow);
  currentFontLabel.setWindow(controlWindow);
  fontSelector.moveTo(controlWindow);

  bgOpacitySlider.setWindow(controlWindow);
  outputWidthSlider.setWindow(controlWindow);

  // Textorizer 1 controls
  textorizer1label = controlP5.addTextlabel("Textorizer1",LabelT1SeparatorIdle, 10,ypos);
  textorizer1label.setWindow(controlWindow);
  ypos+=20; t1numSlider=controlP5.addSlider(LabelT1NbStrokes,
                                            100,10000,1000, 10, ypos, SliderWidth,15);
  ypos+=20; t1thresholdSlider=controlP5.addSlider(LabelT1Threshold,
                                                  0,200,SliderWidth, 10,ypos, SliderWidth,15);
  ypos+=20; t1FontScaleRange = controlP5.addRange(LabelT1FontRange,
                                                  0,50,minFontScale,maxFontScale, 10,ypos,SliderWidth,15);

  ypos+=27; 
  t1changeWordsButton = controlP5.addButton("t1changeWordsButton",4, 10, ypos-3, 37, 12); 
  t1changeWordsButton.setLabel(LabelChange);
  t1wordsFileName = 
    controlP5.addTextlabel("t1wordsFileName",
                           ((T1WordsFileName==null)?"":LabelT1WordsFile+T1WordsFileName),
                           50,ypos); 
  ypos+=15;


  t1goButton=controlP5.addButton(LabelT1Go,
                                 4, 240,300, 50,20);

  t1numSlider.setWindow(controlWindow);
  t1thresholdSlider.setWindow(controlWindow);
  t1FontScaleRange.setWindow(controlWindow);
  t1wordsFileName.setWindow(controlWindow);
  t1changeWordsButton.setWindow(controlWindow);
  t1goButton.setWindow(controlWindow);


  // Textorizer 2 controls
  ypos+=10;textorizer2label = controlP5.addTextlabel("Textorizer2",LabelT2SeparatorIdle, 10,ypos);
  textorizer2label.setWindow(controlWindow);
  ypos+=20;t2textSize=controlP5.addSlider(LabelT2TextSize,4,50,T2FontSize, 10,ypos, SliderWidth,15); t2textSize.setWindow(controlWindow);
  ypos+=20;t2lineHeight=controlP5.addSlider(LabelT2LineHeight,.5,3,T2LineHeight, 10,ypos, SliderWidth,15); t2lineHeight.setWindow(controlWindow);
  ypos+=20;t2colorAdjustment=controlP5.addSlider(LabelT2ColourSaturation,0,255,T2ColourAdjustment, 10,ypos, SliderWidth,15); t2colorAdjustment.setWindow(controlWindow);
  ypos+=20;
  t2kerningSlider=controlP5.addSlider(LabelT2Kerning,-.5,.5,T2Kerning, 10,ypos, SliderWidth,15); t2kerningSlider.setWindow(controlWindow);
  ypos+=20;
  t2fontScaleFactorSlider=controlP5.addSlider(LabelT2FontScale,0,5,T2FontScaleFactor, 10,ypos, SliderWidth,15); t2fontScaleFactorSlider.setWindow(controlWindow);

  ypos+=27; 
  t2changeTextButton = controlP5.addButton("t2changeTextButon",4, 10,ypos-3, 37, 12); 
  t2changeTextButton.setLabel(LabelChange);
  t2changeTextButton.setWindow(controlWindow);
  t2textFileName = controlP5.addTextlabel("t2textFileName",((T2TextFileName==null)?"":LabelT2TextFile+T2TextFileName), 50,ypos); t2textFileName.setWindow(controlWindow);

  t2goButton=controlP5.addButton(LabelT2Go,4, 235,440, 55,20); 
  t2goButton.setWindow(controlWindow);

  // info label
  ypos+=25; controlP5.addTextlabel("About",LabelInfo, 0,ypos).setWindow(controlWindow);

  t1numSlider.setId(1); 
  t1thresholdSlider.setId(2); 
  bgOpacitySlider.setId(3);
  outputWidthSlider.setId(5);
  t1FontScaleRange.setId(4);
  fontSelector.setId(6);
  changeImageButton.setId(7);
  svgChangeButton.setId(8);
  outputImageChangeButton.setId(9);
  t1goButton.setId(10);
  t1changeWordsButton.setId(11);

  t2lineHeight.setId(100);
  t2textSize.setId(101);
  t2colorAdjustment.setId(102);
  t2goButton.setId(103);
  t2changeTextButton.setId(104);
  t2kerningSlider.setId(105);
  t2fontScaleFactorSlider.setId(106);

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
  t1goButton.hide(); t2goButton.hide();
  setTextLabelValue((Textlabel)textorizer1label, LabelT1SeparatorRunning);
  setTextLabelValue((Textlabel)textorizer2label, LabelT2SeparatorRunning);
  cursor(WAIT);
  background(255);

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

  image(OutputImage, width/2, height/2, fittingWidth, fittingHeight);

  cursor(ARROW);
  setTextLabelValue((Textlabel)textorizer1label, LabelT1SeparatorIdle);
  setTextLabelValue((Textlabel)textorizer2label, LabelT2SeparatorIdle);
  t1goButton.show(); t2goButton.show();
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
    setTextLabelValue((Textlabel)textorizer1label, LabelT1SeparatorRunning + progress + "%");

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

void controlEvent(ControlEvent theEvent) {
  int id=0;
  if (!theEvent.isController()) return;

  id=theEvent.controller().id();

  if (id==1) { // can't use switch because of type warnings
    NStrokes=((int)(theEvent.controller().value()));
  } else if (id==2) {
    Threshold=((int)(theEvent.controller().value()));
  } else if (id==3) {
    OutputBackgroundOpacity=((int)(theEvent.controller().value()));
  } else if (id==4) {
    minFontScale = ((Range)t1FontScaleRange).lowValue();
    maxFontScale = ((Range)t1FontScaleRange).highValue();
    if (minFontScale > maxFontScale) {
      minFontScale=maxFontScale;
      ((Range)t1FontScaleRange).setLowValue(minFontScale);
      controlWindow.update();
      controlWindow.show(); // shouldn't be needed but window won't refresh otherwise
    }
  } else if (id==5) { // output width
    OutputImageWidth = ((int)(theEvent.controller().value()));
    OutputImageHeight = OutputImageWidth * InputImage.height / InputImage.width;
  } else if (id==7) { // changeImageButton
    InputImage = loadInputImage(InputImageFileName);
  } else if (id==8) { // svgChangeButton
    SvgFileName = selectOutputFile(SvgFileName);
    setTextLabelValue((Textlabel)svgFileLabel,"SVG Output File: "+SvgFileName);
  } else if (id==9) { // outputImageChangeButton
    String s;
    OutputImageFileName = selectOutputFile(OutputImageFileName);
    setTextLabelValue((Textlabel)outputImgFileLabel, OutputImageFileName);
  } else if (id==10) { // run textorizer 1
    TextorizerMode=1;
    NeedsRerendering=true;
    redraw();
  } else if (id==11) {
    loadWords(1);
    //---- Textorizer 2 controls ---
  } else if (id==100) {
    T2LineHeight = theEvent.controller().value();
  } else if (id==101) {
    T2FontSize = theEvent.controller().value();
  } else if (id==102) {
    T2ColourAdjustment = theEvent.controller().value();
  } else if (id==103) {
    TextorizerMode=2;
    NeedsRerendering=true;
    redraw();
  } else if (id==104) { // t2changeTextButton
    loadWords(2);
  } else if (id==105) { // t2kerningSlider
    T2Kerning = theEvent.controller().value();
  } else if (id==106) { // t2fontScaleFactorSlider
    T2FontScaleFactor = theEvent.controller().value();
  } else if (id>=1000) {
    // ---- Font selector control ---
    FontName=fontList[(int)(theEvent.controller().value())];
    setTextLabelValue((Textlabel)currentFontLabel, "Font: "+FontName);
    //    ((Textlabel)currentFontLabel).setValue("Font: "+fontName);
    Font = createFont(FontName, 32);
  } else {
    println("warning: unhandled event on controller: "+id);
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
    setTextLabelValue((Textlabel)textorizer2label, LabelT2SeparatorRunning + progress + "%");

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
void setTextLabelValue(Textlabel label, String text) {
  label.setValue(text.replaceAll("[^\\p{ASCII}]", " "));
}
