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

ControlP5 controlP5;
ControlWindow controlWindow; // the controls must be in a separate window, since the controls window must refresh constantly, while the rendering window only refreshes when you tell it to.

String ImageFileName="jetlag.jpg";
String T1WordsFileName="textorizer.txt";
String T2TextFileName="textorizer2.txt";
String fontName="FFScala";

String t1SeparatorStringIdle=   "---------------------- Textorizer 1 --------------------";
String t2SeparatorStringIdle=   "---------------------- Textorizer 2 --------------------";
String t1SeparatorStringRunning="----------------------- RENDERING ---------------------";
String t2SeparatorStringRunning="----------------------- RENDERING ---------------------";

PImage Image;
PFont font;
String[] Words;

int Mode=2; 
// 0: do nothing
// 1,2,3: textorizer version

String[] fontList = PFont.list();

int NStrokes = 1000;
float Threshold=100;
float minFontScale=5;
float maxFontScale=30;

float T2LineHeight=1.0;
float T2FontSize=12.0;
float T2ColourAdjustment=0;
float T2Kerning=0;
float T2FontScaleFactor=1.5;


int originalWidth=500, originalHeight=350; // initial size of the window
int InputWidth, InputHeight; // dimensions of the original picture
int CanvasWidth, CanvasHeight; // dimensions of the output canvas (the part of the output window where we're going to draw)
float InputAspectRatio, CanvasAspectRatio;

int bgOpacity=30;

// common controls
Controller bgOpacitySlider, imageNameLabel, svgFileLabel, outputImgFileLabel, changeImageButton, outputImageChangeButton, svgChangeButton, textorizer1label, textorizer2label, currentFontLabel;
ScrollList fontSelector;

// textorizer1 controls
Controller t1numSlider, t1thresholdSlider, t1minFontSlider, t1maxFontSlider, t1goButton, t1wordsFileName, t1changeWordsButton;

// textorizer2 controls
Controller t2lineHeight, t2textSize, t2colorAdjustment, t2goButton, t2textFileName, t2textFileLabel, t2changeTextButton, t2kerningSlider, t2fontScaleFactorSlider;

// Sobel convolution filter
float[][] Sx = {{-1,0,1}, {-2,0,2}, {-1,0,1}};
float[][] Sy = {{-1,-2,-1}, {0,0,0}, {1,2,1}};

// SVG export
String SvgFileName = "textorizer.svg";
StringBuffer SvgBuffer;
String[] SvgOutput;

// Image export
String OutputImageFileName = "textorizer.png";

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
      setTextLabelValue((Textlabel)t1wordsFileName, T1WordsFileName);
      // ((Textlabel)t1wordsFileName).setValue(T1WordsFileName);
    }
    break;
  case 2: // textorizer 2
    newWordsFileName = selectInputFile(T2TextFileName);
    newWords = loadStrings(newWordsFileName);
    if (newWords != null) {
      T2TextFileName = newWordsFileName;
      Words = newWords;
      setTextLabelValue((Textlabel)t2textFileName, T2TextFileName);
      //      ((Textlabel)t2textFileName).setValue(T2TextFileName);
    }
    break;
  }
}

void loadImage() {
  String newImageFileName = selectInputFile(ImageFileName);
  PImage newImage = loadImage(newImageFileName);

  if (newImage!=null && newImage.width!=-1 && newImage.height!=-1) {
    ImageFileName=newImageFileName;
    Image=newImage;
    InputWidth=Image.width; InputHeight=Image.height;
    loadPixels(); 
    setTextLabelValue((Textlabel)imageNameLabel, ImageFileName);
    //    ((Textlabel)imageNameLabel).setValue(ImageFileName);
  }
}

void setup() {
  int ypos = 10;

  // Size has to be the very first statement, or setup() will be run twice
  size(originalWidth, originalHeight); 

  background(0);
  stroke(1);
  fill(0);
  smooth();
  noLoop();

  Image = loadImage(ImageFileName);
  loadPixels();
  InputWidth=Image.width; InputHeight=Image.height;
  



  font = createFont(fontName, 32);
  textFont(font);

  frame.setResizable(true);
  // call draw() when the window is resized
  frame.addComponentListener(new ComponentAdapter() { 
    public void componentResized(ComponentEvent e) { 
      if(e.getSource()==frame) { 
        redraw();
      } 
    } 
  });

  controlP5 = new ControlP5(this);
  controlP5.setAutoDraw(true);
  controlWindow = controlP5.addControlWindow("Textorizer",100,100,300,600);
  controlWindow.setBackground(color(40));
  controlWindow.setUpdateMode(ControlWindow.NORMAL);

  // common controls
  changeImageButton  = controlP5.addButton("Change Image >",4, 10,ypos-7, 75, 20); 
  imageNameLabel  = controlP5.addTextlabel("Image",ImageFileName, 90,ypos);
  ypos+=20;

  bgOpacitySlider = controlP5.addSlider("Background Opacity",0,255,bgOpacity, 10,ypos, 100,20); ypos+=30;

  svgChangeButton = controlP5.addButton("Change SVG >",4,10,ypos-7,67,20); 
  svgFileLabel = controlP5.addTextlabel("Svg",SvgFileName,80,ypos);
  ypos+=25; 

  outputImgFileLabel = controlP5.addTextlabel("Img",OutputImageFileName,123,ypos); 
  outputImageChangeButton = controlP5.addButton("Change Output Image >",4,10,ypos-7,110,20);
  ypos+=30;

  currentFontLabel = controlP5.addTextlabel("CurrentFont","Font: "+fontName,10,ypos); ypos+=20; 

  fontSelector = controlP5.addScrollList("Select Font",10,ypos, 200,100); ypos+=110;


  for (int i=0;i<fontList.length;i++) {
    String fontNameAscii = fontList[i].replaceAll("[^\\p{ASCII}]", " ");
    controlP5.Button b=fontSelector.addItem(fontNameAscii,i);
    b.setId(1000+i);
  }

  imageNameLabel.setWindow(controlWindow);
  changeImageButton.setWindow(controlWindow);
  svgFileLabel.setWindow(controlWindow);
  svgChangeButton.setWindow(controlWindow);
  outputImgFileLabel.setWindow(controlWindow);
  outputImageChangeButton.setWindow(controlWindow);
  currentFontLabel.setWindow(controlWindow);
  fontSelector.moveTo(controlWindow);

  bgOpacitySlider.setWindow(controlWindow);

  // Textorizer 1 controls
  textorizer1label = controlP5.addTextlabel("Textorizer1",t1SeparatorStringIdle, 10,ypos);
  textorizer1label.setWindow(controlWindow);
  ypos+=20; t1numSlider=controlP5.addSlider("Number of Strokes",100,10000,1000, 10, ypos, 100,20);
  ypos+=25; t1thresholdSlider=controlP5.addSlider("Threshold",0,200,100, 10,ypos, 100,20);
  ypos+=25; t1minFontSlider  =controlP5.addSlider("Min Font Scale",0,50, minFontScale, 10, ypos, 100,20);
  ypos+=25; t1maxFontSlider  =controlP5.addSlider("Max Font Scale",0,50, maxFontScale, 10,ypos, 100,20);

  ypos+=30; 
  t1changeWordsButton = controlP5.addButton("Change Words >",4, 10,ypos-7, 80, 20); 
  t1wordsFileName  =controlP5.addTextlabel("Words",((T1WordsFileName==null)?"":T1WordsFileName), 95,ypos); 
  ypos+=15;


  t1goButton=controlP5.addButton("Textorize!",4, 240,300, 50,20);

  t1numSlider.setWindow(controlWindow);
  t1thresholdSlider.setWindow(controlWindow);
  t1minFontSlider.setWindow(controlWindow);
  t1maxFontSlider.setWindow(controlWindow);
  t1wordsFileName.setWindow(controlWindow);
  t1changeWordsButton.setWindow(controlWindow);
  t1goButton.setWindow(controlWindow);


  // Textorizer 2 controls
  ypos+=30;textorizer2label = controlP5.addTextlabel("Textorizer2",t2SeparatorStringIdle, 10,ypos);
  textorizer2label.setWindow(controlWindow);
  ypos+=20;t2textSize=controlP5.addSlider("Text Size",4,50,T2FontSize, 10,ypos, 100,20); t2textSize.setWindow(controlWindow);
  ypos+=25;t2lineHeight=controlP5.addSlider("Line Height",.5,3,T2LineHeight, 10,ypos, 100,20); t2lineHeight.setWindow(controlWindow);
  ypos+=25;t2colorAdjustment=controlP5.addSlider("Colour Saturation",0,255,T2ColourAdjustment, 10,ypos, 100,20); t2colorAdjustment.setWindow(controlWindow);
  ypos+=25;
  t2kerningSlider=controlP5.addSlider("Kerning",-.5,.5,T2Kerning, 10,ypos, 100,20); t2kerningSlider.setWindow(controlWindow);
  ypos+=25;
  t2fontScaleFactorSlider=controlP5.addSlider("Font Scale",0,5,T2FontScaleFactor, 10,ypos, 100,20); t2fontScaleFactorSlider.setWindow(controlWindow);

  ypos+=35; 
  t2changeTextButton = controlP5.addButton("Change Text >",4, 10,ypos-7, 70, 20); t2changeTextButton.setWindow(controlWindow);
  t2textFileName = controlP5.addTextlabel("Text",((T2TextFileName==null)?"":T2TextFileName), 85,ypos); t2textFileName.setWindow(controlWindow);

  t2goButton=controlP5.addButton("Textorize2!",4, 235,460, 55,20); t2goButton.setWindow(controlWindow);

  // info label
  controlP5.addTextlabel("About","------ Textorizer - http://lapin-bleu.net/software/textorizer ------", 0,590).setWindow(controlWindow);
  


  t1numSlider.setId(1); 
  t1thresholdSlider.setId(2); 
  bgOpacitySlider.setId(3);
  t1minFontSlider.setId(4); 
  t1maxFontSlider.setId(5); 
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

void draw()
{
  t1goButton.hide(); t2goButton.hide();
  setTextLabelValue((Textlabel)textorizer1label, t1SeparatorStringRunning);
  setTextLabelValue((Textlabel)textorizer2label, t2SeparatorStringRunning);
  //  ((Textlabel)textorizer1label).setValue(t1SeparatorStringRunning);    
  //  ((Textlabel)textorizer2label).setValue(t2SeparatorStringRunning);    


  cursor(WAIT);
  background(255);

  if (Mode != 0) {
    CanvasAspectRatio = float(width)/height;
    InputAspectRatio = float(InputWidth)/InputHeight;
    
    if (CanvasAspectRatio > InputAspectRatio) {
      CanvasWidth=int(height*InputAspectRatio);
      CanvasHeight=height;
    }
    else {
      CanvasWidth=width; 
      CanvasHeight=int(width/InputAspectRatio);
    }

    setupSvg();
    setupFont();
    setupBgPicture();
    
    switch(Mode) {
    case 1: textorize(); break;
    case 2: textorize2(); break;
    }
  }
  cursor(ARROW);
  controlWindow.update();
  controlP5.draw();
  save(OutputImageFileName);

  t1goButton.show(); t2goButton.show();
  setTextLabelValue((Textlabel)textorizer1label, t1SeparatorStringIdle);
  setTextLabelValue((Textlabel)textorizer1label, t1SeparatorStringIdle);
  //  ((Textlabel)textorizer1label).setValue(t1SeparatorStringIdle);    
  //  ((Textlabel)textorizer2label).setValue(t2SeparatorStringIdle);    
}

void setupSvg() {
  SvgBuffer = new StringBuffer(4096);
  SvgBuffer.append("<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1//EN\" \"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd\">\n");
  SvgBuffer.append("<svg width='100%' height='100%' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' viewBox='0 0 "+width+" "+height+"'>\n");
}

void setupFont() {
  // font
  textFont(font);
  switch(Mode) {
  case 1:
    textAlign(CENTER);
    SvgBuffer.append("<g style='font-family:"+fontName+";font-size:32' text-anchor='middle'>\n");
    break;
  case 2:
    textAlign(LEFT);
    SvgBuffer.append("<g style='font-family:"+fontName+";font-size:32'>\n");
    break;
  }
}

void setupBgPicture() {
  // background picture
  float bgScale;

  if (float(width)/height > float(InputWidth)/InputHeight)
    bgScale =float(height)/InputHeight;
  else
    bgScale=float(width)/InputWidth;

  pushMatrix();
  scale(bgScale, bgScale);
  tint(255,bgOpacity);
  image(Image,0,0);
  popMatrix();
  SvgBuffer.append("<image x='0' y='0' width='"+CanvasWidth+"' height='"+CanvasHeight+"' opacity='"+bgOpacity/255.0+"' xlink:href='"+ImageFileName+"'/>\n");
}

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
void textorize() {
  int x,y,tx,ty;
  float dx,dy,dmag2,vnear,b,textScale,dir,r;
  color v,p;
  String word;
    
  fill(128);
  Words=loadStrings(T1WordsFileName);

  for (int h=0; h<NStrokes;h++) {
    x=int(random(2,InputWidth-3));
    y=int(random(2,InputHeight-3));
    v=Image.pixels[x+y*InputWidth];

    fill(v);
    dx=dy=0;
    for (int i=0; i<3; i++) {
      for (int j=0; j<3; j++) {
        p=Image.pixels[(x+i-1)+InputWidth*(y+j-1)];
        vnear=brightness(p);
        dx += Sx[j][i] * vnear;
        dy += Sy[j][i] * vnear;
      }  
    }
    dx/=8; dy/=8;
    
    dmag2=dx*dx + dy*dy;
    
    if (dmag2 > Threshold) {
      b = 2*(InputWidth + InputHeight) / 5000.0;
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
      textSize(textScale);
      
      pushMatrix();
      tx=int(float(x)*CanvasWidth/InputWidth);
      ty=int(float(y)*CanvasHeight/InputHeight);
      r=dir+PI/2;
      word=(String)(Words[h % Words.length]);
      
      // screen output
      translate(tx,ty);
      rotate(r);
      fill(v);
      text(word, 0,0);
      stroke(1.0,0.,0.);
      popMatrix();
      
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
    bgOpacity=((int)(theEvent.controller().value()));
  } else if (id==4) {
      minFontScale=((int)(theEvent.controller().value()));
      if (minFontScale > maxFontScale) {
        minFontScale=maxFontScale;
        t1minFontSlider.setValue(minFontScale);
        controlWindow.update();
        controlWindow.show(); // shouldn't be needed but window won't refresh otherwise
      }
  } else if (id==5) {
    maxFontScale=((int)(theEvent.controller().value()));
    if (minFontScale > maxFontScale) {
      minFontScale=maxFontScale;
      t1minFontSlider.setValue(minFontScale);
      controlWindow.update();
      controlWindow.show(); // shouldn't be needed but window won't refresh otherwise
    }
  } else if (id==7) { // changeImageButton
    loadImage();
  } else if (id==8) { // svgChangeButton
    SvgFileName = selectOutputFile(SvgFileName);
    setTextLabelValue((Textlabel)svgFileLabel,SvgFileName);
    //    ((Textlabel)svgFileLabel).setValue(SvgFileName);
  } else if (id==9) { // outputImageChangeButton
    String s;
    OutputImageFileName = selectOutputFile(OutputImageFileName);
    setTextLabelValue((Textlabel)outputImgFileLabel, OutputImageFileName);
    //    ((Textlabel)outputImgFileLabel).setValue(OutputImageFileName);
  } else if (id==10) {
    Mode=1;
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
    Mode=2;
    redraw();
  } else if (id==104) { // t2changeTextButton
    loadWords(2);
  } else if (id==105) { // t2kerningSlider
    T2Kerning = theEvent.controller().value();
  } else if (id==106) { // t2fontScaleFactorSlider
    T2FontScaleFactor = theEvent.controller().value();
  } else if (id>=1000) {
    // ---- Font selector control ---
    fontName=fontList[(int)(theEvent.controller().value())];
    setTextLabelValue((Textlabel)currentFontLabel, "Font: "+fontName);
    //    ((Textlabel)currentFontLabel).setValue("Font: "+fontName);
    font = createFont(fontName, 32);
    textFont(font);
  } else {
    println("warning: unhandled event on controller: "+id);
  }
}

void keyPressed()
{
  if(key==',') controlP5.window("controlP5window").hide();
  if(key=='.') controlP5.window("controlP5window").show();
  if(key=='i') {
    loadImage();
  }
  if(key=='w') {
    loadWords(1);
  }
  if(key=='t') {
    loadWords(2);
  }
  if (key=='s') {
    SvgFileName = selectOutputFile(SvgFileName);
    setTextLabelValue((Textlabel)svgFileLabel, SvgFileName);
    //    ((Textlabel)svgFileLabel).setValue(SvgFileName);
  }
  if (key=='o') {
    OutputImageFileName = selectOutputFile(OutputImageFileName);
    setTextLabelValue((Textlabel)outputImgFileLabel, OutputImageFileName);
    //    ((Textlabel)outputImgFileLabel).setValue(OutputImageFileName);
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

  int nbletters = text.length();
  int ti=0;
  int x,y;
  float rx, scale, r,g,b;
  char c, charToPrint;
  color pixel;
  float imgScaleFactorX = float(Image.width)/CanvasWidth;
  float imgScaleFactorY = float(Image.height)/CanvasHeight;

  for (y=0; y < CanvasHeight; y+=T2FontSize*T2LineHeight) {
    rx=1;

    // skip any white space at the beginning of the line
    while (text.charAt(ti%nbletters) == ' ') ti++; 


    while (rx<CanvasWidth) {
      x=(int)floor(rx)-1;

      pixel = pixelAverageAt(int(x*imgScaleFactorX), int(y*imgScaleFactorY), 1);

      r=red(pixel); g=green(pixel); b=blue(pixel);

      scale=2-brightness(pixel)/255.0;
      c=text.charAt(ti%nbletters);

      if (r+g+b<3*255) { // eliminate white 

        charToPrint=c;
        color charColour = color(r,g,b);
        if (T2ColourAdjustment>0) {
          float saturation = saturation(charColour);
          float newSaturation = (saturation+T2ColourAdjustment)>255?255:(saturation+T2ColourAdjustment);
          colorMode(HSB,255);
          charColour = color(hue(charColour), newSaturation, brightness(charColour));
          fill(charColour);
          colorMode(RGB,255);
        } else {
          fill(charColour);
        }

        textSize(T2FontSize * (1 + T2FontScaleFactor*pow(scale-1,3)));
        text(charToPrint, x, y+T2FontSize*T2LineHeight);

        r=red(charColour); g=green(charColour); b=blue(charColour);
        SvgBuffer.append("<text x='"+rx+"' y='"+(y+T2FontSize*T2LineHeight)+"' font-size='"+(T2FontSize*scale)+"' fill='rgb("+int(r)+","+int(g)+","+int(b)+")'>"+charToPrint+"</text>\n");
        
        rx+=textWidth(Character.toString(c)) * (1+T2Kerning);
        ti++; // next letter
      } 
      else {
        // advance one em 
        rx+=textWidth(" ") * (1+T2Kerning);
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

  SvgBuffer.append("</g>\n<rect x='-"+r+"' y='-"+r+"' width='"+(CanvasWidth+2*r)+"' height='"+(CanvasHeight+2*r)+"' fill='none' stroke='white' stroke-width='"+(outerFrameWidth+innerFrameWidth)+"'/>\n\n</svg>\n");

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
      if (x+i>=0 && x+i<InputWidth && y+j>=0 && y+j<InputHeight) {
        count++;
        pixel=Image.pixels[(x+i)+InputWidth*(y+j)]; 
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
