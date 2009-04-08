/* textorizer1_2: vectorises a picture into an SVG using text strings
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

//String ImageFileName="http://lapin-bleu.net/software/textorizer/textorizer1_2/data/london.jpg";
//String ImageFileName="http://farm1.static.flickr.com/33/59279271_fe73796ca6.jpg";
String ImageFileName="jetlag.jpg";
//String ImageFileName="http://localhost/gray.png";
String WordsFileName="words.txt";
String fontName="FFScala";

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
float T2FontSize=14.0;
float T2ColourAdjustment=0;


int originalWidth=500, originalHeight=350; // initial size of the window
int InputWidth, InputHeight; // width of the original picture

int bgOpacity=30;

// common controls
Controller bgOpacitySlider, imageNameLabel, wordsTextfield, wordsFileLabel, svgFileLabel, outputImgFileLabel, imageInfoLabel, wordsInfoLabel, outputImgInfoLabel, svgInfoLabel, textorizer1label, textorizer2label, currentFontLabel;
ScrollList fontSelector;

// textorizer1 controls
Controller t1numSlider, t1thresholdSlider, t1minFontSlider, t1maxFontSlider, t1goButton;

// textorizer2 controls
Controller t2lineHeight, t2textSize, t2colorAdjustment, t2goButton;

// Sobel convolution filter
float[][] Sx = {{-1,0,1}, {-2,0,2}, {-1,0,1}};
float[][] Sy = {{-1,-2,-1}, {0,0,0}, {1,2,1}};

// SVG export
String SvgFileName = "textorizer.svg";
StringBuffer SvgBuffer;
String[] SvgOutput;

// Image export
String OutputImageFileName = "textorizer.png";

void loadWords() {
  String newWordsFileName = selectFile(WordsFileName);
  String[] newWords = loadStrings(newWordsFileName);
  if (newWords != null) {
    WordsFileName = newWordsFileName;
    Words = newWords;
    ((Textlabel)wordsFileLabel).setValue("Words: " + WordsFileName);
  }
}


void loadImage() {
  String newImageFileName = selectFile(ImageFileName);
  PImage newImage = loadImage(newImageFileName);
  if (newImage!=null && newImage.width!=-1 && newImage.height!=-1) {
    ImageFileName=newImageFileName;
    Image=newImage;
    InputWidth=Image.width; InputHeight=Image.height;
    loadPixels(); 
    ((Textlabel)imageNameLabel).setValue("Image: "+ImageFileName);
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
  
  // load the words file
  Words=loadStrings(WordsFileName);

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

  //  progressSlider = controlP5.addSlider("Progress",0,100,42, 10,ypos, 100,20); ypos+=30; progressSlider.setWindow(controlWindow);

  // common controls
  imageNameLabel  = controlP5.addTextlabel("Image","Image: "+ImageFileName, 10,ypos); ypos+=15;

  imageInfoLabel  = controlP5.addTextlabel("ImageInfo","    (Press i to change)",10,ypos); ypos+=20;
  bgOpacitySlider = controlP5.addSlider("Background Opacity",0,255,bgOpacity, 10,ypos, 100,20); ypos+=30;
  wordsFileLabel = controlP5.addTextlabel("Words","Words: "+((WordsFileName==null)?"":WordsFileName), 10,ypos); ypos+=12; 
  wordsInfoLabel = controlP5.addTextlabel("WordsInfo","    (Press w to change)",10,ypos); ypos+=15;
  svgFileLabel = controlP5.addTextlabel("Svg","SVG output file: "+SvgFileName,10,ypos); ypos+=12; 
  svgInfoLabel = controlP5.addTextlabel("InfoSVG","    (Press s to change)",10,ypos); ypos+=15; 

  outputImgFileLabel = controlP5.addTextlabel("Img","PNG output file: "+OutputImageFileName,10,ypos); ypos+=12; 
  outputImgInfoLabel = controlP5.addTextlabel("InfoImg","    (Press o to change)",10,ypos); ypos+=30; 

  currentFontLabel = controlP5.addTextlabel("CurrentFont","Font: "+fontName,10,ypos); ypos+=20; 

  fontSelector = controlP5.addScrollList("Select Font",10,ypos, 200,100); ypos+=110;

  for (int i=0;i<fontList.length;i++) {
    controlP5.Button b=fontSelector.addItem(fontList[i],i);
    b.setId(1000+i);
  }

  imageNameLabel.setWindow(controlWindow);
  imageInfoLabel.setWindow(controlWindow);
  wordsFileLabel.setWindow(controlWindow);
  wordsInfoLabel.setWindow(controlWindow);
  svgFileLabel.setWindow(controlWindow);
  svgInfoLabel.setWindow(controlWindow);
  outputImgFileLabel.setWindow(controlWindow);
  outputImgInfoLabel.setWindow(controlWindow);
  currentFontLabel.setWindow(controlWindow);
  fontSelector.moveTo(controlWindow);

  bgOpacitySlider.setId(3);
  fontSelector.setId(6);
  bgOpacitySlider.setWindow(controlWindow);

  // Textorizer 1 controls
  textorizer1label = controlP5.addTextlabel("Textorizer1","---------------------- Textorizer 1 --------------------", 10,ypos);
  textorizer1label.setWindow(controlWindow);
  ypos+=20; t1numSlider=controlP5.addSlider("Number of Strokes",100,10000,1000, 10, ypos, 100,20);
  ypos+=25; t1thresholdSlider=controlP5.addSlider("Threshold",0,200,100, 10,ypos, 100,20);
  ypos+=25; t1minFontSlider  =controlP5.addSlider("Min Font Scale",0,50, minFontScale, 10, ypos, 100,20);
  ypos+=25; t1maxFontSlider  =controlP5.addSlider("Max Font Scale",0,50, maxFontScale, 10,ypos, 100,20);

  t1goButton=controlP5.addButton("Textorize!",4, 240,320, 50,20);

  t1numSlider.setId(1); 
  t1numSlider.setWindow(controlWindow);
  t1thresholdSlider.setId(2); 
  t1thresholdSlider.setWindow(controlWindow);
  t1minFontSlider.setId(4); 
  t1minFontSlider.setWindow(controlWindow);
  t1maxFontSlider.setId(5); 
  t1maxFontSlider.setWindow(controlWindow);
  t1goButton.setId(10);
  t1goButton.setWindow(controlWindow);


  // Textorizer 2 controls
  ypos+=40;textorizer2label = controlP5.addTextlabel("Textorizer2","---------------------- Textorizer 2 --------------------", 10,ypos);
  textorizer2label.setWindow(controlWindow);
  ypos+=20;t2lineHeight=controlP5.addSlider("Line Height",.5,3,T2LineHeight, 10,ypos, 100,20); t2lineHeight.setWindow(controlWindow);
  ypos+=25;t2textSize=controlP5.addSlider("Text Size",4,50,T2FontSize, 10,ypos, 100,20); t2textSize.setWindow(controlWindow);
  ypos+=25;t2colorAdjustment=controlP5.addSlider("Colour Saturation",0,255,T2ColourAdjustment, 10,ypos, 100,20); t2colorAdjustment.setWindow(controlWindow);
  t2goButton=controlP5.addButton("Textorize2!",4, 240,460, 55,20); t2goButton.setWindow(controlWindow);

  t2lineHeight.setId(100);
  t2textSize.setId(101);
  t2colorAdjustment.setId(102);
  t2goButton.setId(103);
}

int x,y,tx,ty;
float dx,dy,dmag2,vnear,b,textScale,dir,r;
color v,p;
String word;

void draw()
{
  controlWindow.hide();
  cursor(WAIT);
  background(255);

  if (Mode != 0) {
    setupSvg();
    setupFont();
    setupBgPicture();
    
    switch(Mode) {
    case 1: textorize(); break;
    case 2: textorize2(); break;
    }
  }
  //  fill(120);
  cursor(ARROW);
  controlWindow.update();
  controlP5.draw();
  controlWindow.show();
  save(OutputImageFileName);
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
    SvgBuffer.append("<g style='font-family:"+fontName+";font-size:32'>\n");
    break;
  }
}

void setupBgPicture() {
  // background picture
  float bgScaleX=float(width)/InputWidth, bgScaleY=float(height)/InputHeight;
  pushMatrix();
  scale(bgScaleX, bgScaleY);
  tint(255,bgOpacity);
  image(Image,0,0);
  popMatrix();
  SvgBuffer.append("<image x='0' y='0' width='"+width+"' height='"+height+"' preserveAspectRatio='none' opacity='"+bgOpacity/255.0+"' xlink:href='"+ImageFileName+"'/>\n");
}

void textorize() {
  fill(128);

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
        tx=int(float(x)*width/InputWidth);
        ty=int(float(y)*height/InputHeight);
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
  //  controlWindow.show(); 
  //  controlP5.draw();

  SvgBuffer.append("</g>\n</svg>\n");
  SvgOutput=new String[1];
  SvgOutput[0]=SvgBuffer.toString();
  saveStrings(SvgFileName, SvgOutput);
}


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
  } else if (id==10) {
    Mode=1;
    redraw();
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
    // ---- Font selector control ---
  } else if (id>=1000) {
    fontName=fontList[(int)(theEvent.controller().value())];
    ((Textlabel)currentFontLabel).setValue("Font: "+fontName);    
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
    loadWords();
  }
  if (key=='s') {
    SvgFileName=selectOutputFile(SvgFileName);
    ((Textlabel)svgFileLabel).setValue("SVG output file: "+SvgFileName);
  }
  if (key=='o') {
    OutputImageFileName=selectOutputFile(OutputImageFileName);
    ((Textlabel)outputImgFileLabel).setValue("PNG output file: "+OutputImageFileName);
  }
}

static String currentDirectory;
String selectFile(String previousFileName) {
  try {
    UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
  } catch (Exception e) {
    println(e);
  }
  JFileChooser jfc;
  if (currentDirectory != null)
    jfc = new JFileChooser(currentDirectory);
  else
    jfc = new JFileChooser();

  int r = jfc.showOpenDialog(this);

  if (r == JFileChooser.APPROVE_OPTION) {
    File file = jfc.getSelectedFile();
    jfc.hide();
    currentDirectory=jfc.getCurrentDirectory().getPath();
    return file.getPath();
  }
  else {
    jfc.hide();
    return previousFileName;
  }
}

String selectOutputFile(String previousFileName) {
  try {
    UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
  } catch (Exception e) {
    println(e);
  }
  JFileChooser jfc;
  if (currentDirectory != null)
    jfc = new JFileChooser(currentDirectory);
  else
    jfc = new JFileChooser();

  int r = jfc.showSaveDialog(this);

  if (r == JFileChooser.APPROVE_OPTION) {
    File file = jfc.getSelectedFile();
    jfc.hide();
    currentDirectory=jfc.getCurrentDirectory().getPath();
    return file.getPath();
  }
  else {
    jfc.hide();
    return previousFileName;
  }
}

// %%%%% Textorizer 2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


void textorize2()
{
  StringBuffer textbuffer = new StringBuffer();
  String text;

  setupSvg();
  setupFont();
  setupBgPicture();

  fill(128);

  textbuffer.append(Words[0]);
  for (int i=1;i<Words.length;i++) {
    textbuffer.append(' ');
    textbuffer.append(Words[i]);
  }
  text=textbuffer.toString();


  int nbletters = text.length();
  int ti=0;
  int y;
  float rx, scale;
  char c, charToPrint;
  color pixel;
  float imgScaleFactorX = float(Image.width)/width;
  float imgScaleFactorY = float(Image.height)/height;

  for (y=0; y < height; y+=T2FontSize*T2LineHeight) {
    rx=1;

    // skip any white space at the beginning of the line
    while (text.charAt(ti%nbletters) == ' ') ti++; 


    while (rx<width) {
      x=(int)floor(rx)-1;

      pixel = pixelAverageAt(int(x*imgScaleFactorX), int(y*imgScaleFactorY), 1);

      float r=red(pixel), g=green(pixel), b=blue(pixel);

      scale=2-brightness(pixel)/255.0;
      c=text.charAt(ti%nbletters);

      //      if (c < ' ' || c > '~') 
      //        c='?'; // we only support ascii :-(
      if (c > font.width.length)
        c='?'; // the font doesn't support this character


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

        textSize(T2FontSize*scale);
        text(charToPrint, x, y+T2FontSize*T2LineHeight);

        r=red(charColour); g=green(charColour); b=blue(charColour);
        SvgBuffer.append("<text x='"+rx+"' y='"+(y+T2FontSize*T2LineHeight)+"' font-size='"+(T2FontSize*scale)+"' fill='rgb("+int(r)+","+int(g)+","+int(b)+")'>"+charToPrint+"</text>\n");
        
        rx+=scale*font.width(c)*T2FontSize;
        ti++; // next letter 
      } 
      else {
        // advance one em 
        rx+=scale*font.width('m')*T2FontSize;
      }
    }
  }

  // framing rectangle. Should be a clipping path, but no FF support
  float outerFrameWidth=200;
  float innerFrameWidth=2;
  r=(outerFrameWidth-innerFrameWidth)/2;

  SvgBuffer.append("</g>\n<rect x='-"+r+"' y='-"+r+"' width='"+(width+2*r)+"' height='"+(height+2*r)+"' fill='none' stroke='white' stroke-width='"+(outerFrameWidth+innerFrameWidth)+"'/>\n\n</svg>\n");

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
