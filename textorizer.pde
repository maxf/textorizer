/* textorizer: draws a picture using text
 * see: http://lapin-bleu.net/software/textorizer
 * Copyright Max Froumentin 2010
 * This software is distributed under the
 * W3C(R) SOFTWARE NOTICE AND LICENSE:
 * http://www.w3.org/Consortium/Legal/2002/copyright-software-20021231
 */

import guicomponents.*;
import java.util.List;
import java.io.*;
import javax.swing.*;
import java.awt.*;
import java.awt.event.*;

GWindow canvas;
GWinApplet canvasApplet;

// ====== Controls ======
int LeftColumnOffset = 5;
int RightColumnOffset = 305;
String[] fontList = PFont.list();

// common controls
TSlider outputWidthSlider, bgOpacitySlider;
GLabel imageNameLabel, fontLabel, textLabel, statusLabel, svgFileLabel, pngFileLabel, aboutLabel;
GButton changeImageButton, svgSaveButton, pngSaveButton, textFileButton, svgFileNameButton, pngFileNameButton;
GCombo fontSelector;
GTextField textArea;
GButton textLoadButton, textSaveButton, textSaveAsButton;
GOptionGroup modes;
GOption optionT1, optionT2;

// textorizer1 controls
GPanel t1Panel;
TSlider t1numSlider, t1thresholdSlider, t1FontScaleMin, t1FontScaleMax;
GButton t1goButton;

// textorizer2 controls
GPanel t2Panel;
TSlider t2lineHeight, t2textSize, t2colorAdjustment, t2kerningSlider, t2fontScaleFactorSlider;
GButton t2goButton;



// ====== Input Image ======
PImage InputImage;
String InputImageFileName="jetlag.jpg";

// ====== visible frame (showing the output) ======
int FrameWidth=500, FrameHeight=350;

// ====== Output Image ======
CanvasWinData canvasData = new CanvasWinData();
PGraphics OutputImage = canvasData.img;
int OutputImageWidth = FrameWidth, OutputImageHeight = FrameHeight;
int OutputBackgroundOpacity=50;
String PngFileName="textorizer.png";

String Text;
String FontName="FFScala";
String TextFileName = "textorizer.txt";
PFont Font;
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
// 1,2: textorizer version

Boolean NeedsRerendering = false;

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
String LabelOutputWidth = "Output size: ";
String LabelBackgroundOpacity = "Background: ";
//String LabelSVGOutputFileName = "SVG output file: ";
String LabelSaveSVG = "Save as SVG";
//String LabelOutputImageFileName = "Output image: ";
String LabelSavePNG = "Save as PNG";
String LabelFont = "Font: ";
String LabelText = "Text: ";
String LabelT1FontMin = "Min Font Size";
String LabelT1FontMax = "Max Font Size";

String LabelT1NbStrokes = "Strokes";
String LabelT1Threshold = "Threshold";
String LabelT1Go = "GO";
String LabelT2Go = "GO";
String LabelT2TextSize = "Text Size";
String LabelT2LineHeight = "Line Height";
String LabelT2ColourSaturation = "Colour Saturation";
String LabelT2Kerning = "Kerning";
String LabelT2FontScale = "Font Scale";
String LabelT2TextFile = "Text file (TXT format): ";

// ########################

void loadWords(Boolean ask) {
  if (ask) {
    TextFileName = selectInputFile(TextFileName);
  } 
  String[] strings = loadStrings(TextFileName);
  StringBuilder sb = new StringBuilder();
  for (int i=0;i<strings.length;i++) {
    sb.append(strings[i]);
    sb.append(System.getProperty("line.separator"));
  }
  Text = sb.toString();
  if (textArea!=null) textArea.setText(Text);
}

void saveText(Boolean saveAs) {
  if (saveAs) {
    TextFileName = selectOutputFile(TextFileName,"txt");
  } 
  String[] strings = new String[1];
  strings[0] = Text;
  saveStrings(TextFileName,strings);
}



PImage loadInputImage(String filename) {
  String newImageFileName = selectInputFile(filename);
  PImage newImage = loadImage(newImageFileName);

  if (newImage!=null && newImage.width!=-1 && newImage.height!=-1) {
    InputImageFileName=newImageFileName;
    loadPixels(); 
    changeImageButton.setText(fileName(newImageFileName));
  }
  return newImage;
}

void setup() {
  int ypos = 10;

  // Size has to be the very first statement, or setup() will be run twice
  size(600,400);
  InputImage = loadImage(InputImageFileName);
  loadPixels();
  Font = createFont(FontName, 32);
  loadWords(false);

  //  G4P.setFont(this, "Serif", 14);
  G4P.setColorScheme(this, GCScheme.GREY_SCHEME);
  G4P.messagesEnabled(false);

  // common controls
  imageNameLabel  = new GLabel(this,LabelInputImageFileName,LeftColumnOffset,ypos,100);
  changeImageButton  = new GButton(this,InputImageFileName,83,ypos,200,12);

  ypos+=35;
  outputWidthSlider = new TSlider(this,LabelOutputWidth,LeftColumnOffset,ypos,OutputImageWidth,500,5000);

  ypos+=45; 
  bgOpacitySlider = new TSlider(this,LabelBackgroundOpacity,LeftColumnOffset,ypos,OutputBackgroundOpacity,0,255);

  ypos+=40;
  textLabel = new GLabel(this,LabelText,LeftColumnOffset,ypos,50);
  textFileButton = new GButton(this,TextFileName,LeftColumnOffset+50,ypos,230,12);
  ypos+=25;
  textArea = new GTextField(this, Text, LeftColumnOffset+50, ypos, 230, 100, true); 
  textArea.setText(Text);
  textSaveButton = new GButton(this,"Save",LeftColumnOffset,ypos,35,12);
  textSaveAsButton = new GButton(this,"Save as",LeftColumnOffset,ypos+20,35,12);

  ypos+=115;
  fontLabel = new GLabel(this,LabelFont,LeftColumnOffset,ypos,50); 
  fontSelector = new GCombo(this,fontList,7,LeftColumnOffset+50,ypos,230);


 
  ypos+=115;
  aboutLabel = new GLabel(this,"http://lapin-bleu.net/software/textorizer",0,ypos,500,12);
  aboutLabel.setFont("Sans Serif",9);
  
  // right column
  ypos=10;

  modes = new GOptionGroup();
  optionT1 = new GOption(this,"Textorizer 1",RightColumnOffset,ypos,100);
  modes.addOption(optionT1);
  optionT2 = new GOption(this,"Textorizer 2",RightColumnOffset+100,ypos,100);
  //  optionT2.setSelected(true);
  modes.addOption(optionT2);
  modes.setSelected(optionT2);

  ypos+=40;
  // Textorizer 2 controls
  t2Panel = new GPanel(this,"Textorizer 2 Controls",RightColumnOffset,ypos,290,290);
  int pypos = 20;
  t2textSize = new TSlider(this,LabelT2TextSize,5,pypos,T2FontSize,4.0,50.0,t2Panel);
  
  pypos+=45;
  t2lineHeight = new TSlider(this,LabelT2LineHeight,5,pypos,T2LineHeight,0.5,3.0,t2Panel);

  pypos+=45;
  t2colorAdjustment = new TSlider(this,LabelT2ColourSaturation,5,pypos,T2ColourAdjustment,0.0,255.0,t2Panel);

  pypos+=45;
  t2kerningSlider = new TSlider(this,LabelT2Kerning,5,pypos,T2Kerning,-.5,.5,t2Panel);

  pypos+=45;
  t2fontScaleFactorSlider = new TSlider(this,LabelT2FontScale,5,pypos,T2FontScaleFactor,0.0,5.0,t2Panel);
  pypos+=55;
  t2goButton=new GButton(this,LabelT2Go,5,pypos,80,20); 
  t2goButton.setColorScheme(GCScheme.GREEN_SCHEME);
  t2Panel.add(t2goButton);

  // Textorizer 1 controls
  t1Panel = new GPanel(this,"Textorizer 1 Controls",RightColumnOffset,ypos,290,250);
  pypos=20;
  t1numSlider = new TSlider(this,LabelT1NbStrokes,2,pypos,1000,100,10000,t1Panel);
  pypos+=45;
  t1thresholdSlider = new TSlider(this,LabelT1Threshold,5,pypos,150f,0f,200f,t1Panel);
  pypos+=45;
  t1FontScaleMin = new TSlider(this,LabelT1FontMin,5,pypos,minFontScale,0f,50f,t1Panel);
  pypos+=45;
  t1FontScaleMax = new TSlider(this,LabelT1FontMax,5,pypos,maxFontScale,0f,50f,t1Panel);
  pypos+=55;
  t1goButton = new GButton(this,LabelT1Go,5,pypos,80,20);
  t1goButton.setColorScheme(GCScheme.GREEN_SCHEME);
  t1Panel.add(t1goButton);

  ypos+=300;
  svgFileLabel = new GLabel(this,"SVG File:",RightColumnOffset,ypos,55,12);
  svgFileNameButton = new GButton(this,fileName(SvgFileName),RightColumnOffset+57,ypos,180,12);
  svgSaveButton = new GButton(this,"Save",RightColumnOffset+245,ypos,40,12); 
  ypos+=20;
  pngFileLabel = new GLabel(this,"PNG File:",RightColumnOffset,ypos,55,12);
  pngFileNameButton = new GButton(this,fileName(PngFileName),RightColumnOffset+57,ypos,180,12);
  pngSaveButton = new GButton(this,"Save",RightColumnOffset+245,ypos,40,12); 


  t1ControlsSetEnabled(false);
  t2ControlsSetEnabled(true);


  canvas = new GWindow(this,"Textorizer",800,500,FrameWidth,FrameHeight,false,P2D);
  canvas.addData(canvasData);
  canvas.setOnTop(false);
  canvas.addComponentListener(new ComponentAdapter() { 
    public void componentResized(ComponentEvent e) { 
      if(e.getSource()==canvas && canvasApplet!=null) canvasApplet.redraw();
    } 
  });
  canvas.addDrawHandler(this,"canvasDrawHandler");
}

void go() 
{
  if (TextorizerMode != 0) {
    OutputImage = createGraphics(OutputImageWidth, OutputImageHeight, JAVA2D);
    OutputImage.beginDraw();
    OutputImage.smooth();
    OutputImage.background(255);
    setupSvg();
    setupFont();
    setupBgPicture();

    switch(TextorizerMode) {
    case 1: 
      textorize(); 
      if (t1goButton!=null) t1goButton.setColorScheme(GCScheme.GREY_SCHEME);
    break;
    case 2: 
      textorize2(); 
      if (t2goButton!=null) t2goButton.setColorScheme(GCScheme.GREY_SCHEME);
      break;
    }
    OutputImage.endDraw();
  }
}

void draw()
{
  background(210);
}


void canvasDrawHandler(GWinApplet appc, GWinData data)
{
  canvasApplet = appc;
  if (OutputImage != null)
    canvasDraw();
  else {
    canvasApplet.noLoop();
    canvasApplet.background(0);
    canvasApplet.fill(255);
    canvasApplet.stroke(255);
    canvasApplet.textFont(Font,20);
    canvasApplet.text("Press GO to make the picture",100,100);
  }
}

void canvasDraw()
{
  canvasApplet.noLoop();
  canvasApplet.background(255);
  canvasApplet.cursor(WAIT);
  canvasApplet.smooth();
  cursor(WAIT);
  if (NeedsRerendering) {
    go();
    NeedsRerendering=false;
  }
  // fit the image best in the window
  int fittingWidth, fittingHeight;
  Insets insets = canvas.getInsets();
  int windowW = canvas.getWidth() - insets.left - insets.right;
  int windowH = canvas.getHeight() - insets.top - insets.bottom;

  if (windowW >= OutputImageWidth && windowH >= OutputImageHeight) {
    fittingWidth = OutputImageWidth;
    fittingHeight = OutputImageHeight;
  } else {
    if (float(windowW)/windowH > (float)OutputImageWidth/OutputImageHeight) {
      fittingHeight = windowH;
      fittingWidth = fittingHeight*OutputImageWidth/OutputImageHeight;
    } else {
      fittingWidth = windowW;
      fittingHeight = fittingWidth*OutputImageHeight/OutputImageWidth;
    }
  }

  canvasApplet.image(OutputImage, (windowW-fittingWidth)/2, (windowH-fittingHeight)/2, fittingWidth, fittingHeight);
  canvasApplet.cursor(ARROW);
  cursor(ARROW);
  canvasApplet.redraw();
}

void setupSvg() {
  SvgBuffer = new StringBuffer(4096);
  SvgBuffer.append("<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1//EN\" \"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd\">\n");
  SvgBuffer.append("<svg width='100%' height='100%' version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' viewBox='0 0 "+OutputImageWidth+" "+OutputImageWidth+"'>\n");
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
  String[] Words;

  Words=Text.split("\n");
  OutputImage.textFont(Font);

  for (int h=0; h<NStrokes;h++) {
    progress = 1+int(100.0*h/NStrokes);
    //    setTextLabelValue(textorizer1label, LabelT1SeparatorRunning + progress + "%");

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
}

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

void handleTextFieldEvents(GTextField textfield) 
{ 
  if (t2goButton != null) t2goButton.setColorScheme(GCScheme.GREEN_SCHEME);
  if (t1goButton != null) t1goButton.setColorScheme(GCScheme.GREEN_SCHEME);
  Text = textfield.getText();
}

void handleButtonEvents(GButton button) {
  Boolean t1changed = false, t2changed = false;
  if(button == changeImageButton) {
    InputImage = loadInputImage(InputImageFileName);
    t2changed = t2changed = true;
  } else if (button == svgFileNameButton) {
    SvgFileName = selectOutputFile(SvgFileName,"svg");
    svgFileNameButton.setText(fileName(SvgFileName));
  } else if (button == svgSaveButton) {
    SvgOutput=new String[1];
    SvgOutput[0]=SvgBuffer.toString();
    saveStrings(SvgFileName, SvgOutput);
  } else if (button == pngFileNameButton) {
    PngFileName = selectOutputFile(PngFileName,"png");
    pngFileNameButton.setText(PngFileName);
  } else if(button == pngSaveButton) {
    OutputImage.save(PngFileName);
  } else if(button == t1goButton) {
    TextorizerMode=1;
    NeedsRerendering=true;
    canvasDraw();
    t1goButton.setColorScheme(GCScheme.GREY_SCHEME);
    t2changed = true;
  } else if(button == t2goButton) {
    TextorizerMode=2;
    NeedsRerendering=true;
    canvasDraw();
    t1changed = true;
    t2goButton.setColorScheme(GCScheme.GREY_SCHEME);
  } else if (button == textFileButton) {
    loadWords(true);
    textFileButton.setText(fileName(TextFileName));
    t2changed = t2changed = true;
  } else if (button == textSaveButton) {
    saveText(false);
  } else if (button == textSaveAsButton) {
    saveText(true);
    textFileButton.setText(fileName(TextFileName));
  }
  if (t1changed && t1goButton != null) t1goButton.setColorScheme(GCScheme.GREEN_SCHEME);
  if (t2changed && t2goButton != null) t2goButton.setColorScheme(GCScheme.GREEN_SCHEME);
}

void handleSliderEvents(GSlider slider) {
  Boolean t1changed = false, t2changed = false;
  if (slider == t1numSlider) {
    NStrokes = slider.getValue();
    t1changed = true;
  } else if (slider == t1thresholdSlider) {
    Threshold = slider.getValuef();
    t1changed = true;
  } else if (slider == bgOpacitySlider) {
    OutputBackgroundOpacity = slider.getValue();
    t1changed = t2changed = true;
  } else if (slider == outputWidthSlider) {
    OutputImageWidth = slider.getValue();
    OutputImageHeight = OutputImageWidth * InputImage.height / InputImage.width;
    t1changed = t2changed = true;
  } else if (slider == t1FontScaleMin) {
    minFontScale = slider.getValuef();
    if (minFontScale > maxFontScale) {
      minFontScale=maxFontScale;
      slider.setValue(minFontScale);
    }
    t1changed = true;
  } else if (slider == t1FontScaleMax) {
    maxFontScale = slider.getValuef();
    if (minFontScale > maxFontScale) {
      maxFontScale=minFontScale;
      slider.setValue(maxFontScale);
    }
    t1changed=true;
  } else if (slider == t2lineHeight) {
    T2LineHeight = slider.getValuef();
    t2changed=true;
  } else if (slider == t2textSize) {
    T2FontSize = slider.getValuef();
    t2changed=true;
  } else if (slider == t2colorAdjustment) {
    t2changed=true;
    T2ColourAdjustment = slider.getValuef();
  } else if (slider == t2kerningSlider) {
    T2Kerning = slider.getValuef();
    t2changed = true;
  } else if (slider == t2fontScaleFactorSlider) {
    T2FontScaleFactor = slider.getValuef();
    t2changed = true;
  }  
  if (t1changed && t1goButton != null) t1goButton.setColorScheme(GCScheme.GREEN_SCHEME);
  if (t2changed && t2goButton != null) t2goButton.setColorScheme(GCScheme.GREEN_SCHEME);
}

void handleComboEvents(GCombo combo){
  if (t2goButton != null) t2goButton.setColorScheme(GCScheme.GREEN_SCHEME);
  if (t1goButton != null) t1goButton.setColorScheme(GCScheme.GREEN_SCHEME);
  if (combo == fontSelector) {
    // Get font name and size from
    String[] fs = combo.selectedText().split(" ");
    FontName = fs[0];
    Font = createFont(FontName,32);
  }
}	

public void handleOptionEvents(GOption selected, GOption deselected){
  if (selected == optionT1) {
    t1ControlsSetEnabled(true);
    t2ControlsSetEnabled(false);
  } else if (selected == optionT2) {
    t1ControlsSetEnabled(false);
    t2ControlsSetEnabled(true);
  }
}


String selectInputFile(String defaultName)
{
  String s;
  return ((s=selectInput())!=null) ? s : defaultName;
}

String selectOutputFile(String defaultName, String extension)
{
  String s;
  s = selectOutput("Choose a "+extension+" file");
  if (s==null) {
    s = defaultName; // user cancelled
  } else {
    if (!s.endsWith("."+extension)) s+="."+extension;
  }
  return s;
}


// %%%%% Textorizer 2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


void textorize2()
{
  //  StringBuffer textbuffer = new StringBuffer();
  //  String text;

  //  Words=loadStrings(T2TextFileName);
  fill(128);

//  textbuffer.append(Words[0]);
//  for (int i=1;i<Words.length;i++) {
//    textbuffer.append(' ');
//    textbuffer.append(Words[i]);
//  }
//  text=textbuffer.toString();

  String text = Text.replaceAll("\n"," ");

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
    //    statusLabel.setText("Running - "+progress+"%");
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

String fileName(String fullName)
{
  return fullName.substring(fullName.lastIndexOf("/")+1);
}


class CanvasWinData extends GWinData {
  public PGraphics img;
}

class TSlider extends GWSlider {
  GLabel l;
  static final int SliderWidth = 190, SliderOffset = 80;
  
  public TSlider(PApplet theApplet, String label, int x, int y, int init, int min, int max) {
    super(theApplet,x+SliderOffset,y,SliderWidth);
    this.setValueType(GWSlider.INTEGER);
    this.setLimits(init,min,max);
    l = new GLabel(theApplet, label, x, y, SliderOffset);
  }
  public TSlider(PApplet theApplet, String label, int x, int y, float init, float min, float max) {
    super(theApplet,x+SliderOffset,y,SliderWidth);
    this.setValueType(GWSlider.DECIMAL);
    this.setLimits(init,min,max);
    l = new GLabel(theApplet, label, x, y, SliderOffset);
  }
  public TSlider(PApplet theApplet, String label, int x, int y, int init, int min, int max, GPanel panel) {
    super(theApplet,x+SliderOffset,y,SliderWidth);
    this.setValueType(GWSlider.INTEGER);
    this.setLimits(init,min,max);
    l = new GLabel(theApplet, label, x, y, SliderOffset);
    panel.add(this);
    panel.add(l);
  }
  public TSlider(PApplet theApplet, String label, int x, int y, float init, float min, float max, GPanel panel) {
    super(theApplet,x+SliderOffset,y,SliderWidth);
    this.setValueType(GWSlider.DECIMAL);
    this.setLimits(init,min,max);
    l = new GLabel(theApplet, label, x, y, SliderOffset);
    panel.add(this);
    panel.add(l);
  }
  public void setEnabled(Boolean enabled) {
    l.setEnabled(enabled);
    super.setEnabled(enabled);
  }
}


void t1ControlsSetEnabled(Boolean enable) 
{
  if (t1Panel!=null) {
    t1Panel.setEnabled(enable);
    t1Panel.setVisible(enable);
    t1Panel.setCollapsed(!enable);
  }
}

void t2ControlsSetEnabled(Boolean enable) 
{
  if (t2Panel!=null) {
    t2Panel.setEnabled(enable);
    t2Panel.setVisible(enable);
    t2Panel.setCollapsed(!enable);
  }
}
